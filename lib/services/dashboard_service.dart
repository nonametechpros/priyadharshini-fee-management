import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_type.dart';
import '../models/dashboard_summary.dart';
import '../models/student.dart';

/// Admin-only reporting built on Firestore's server-side aggregate queries
/// (count / sum) so totals don't require downloading every student document.
class DashboardService {
  DashboardService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _students => _firestore.collection('students');
  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _fees => _firestore.collection('fees');

  Future<CourseTypeBreakdown> _breakdownFor(CourseType type) async {
    final base = _students.where('courseTypes', arrayContains: type.name);
    final agg = await base.aggregate(count(), sum('totalAmount'), sum('amountPaid')).get();
    final total = (agg.getSum('totalAmount') ?? 0).toDouble();
    final paid = (agg.getSum('amountPaid') ?? 0).toDouble();
    return CourseTypeBreakdown(
      count: agg.count ?? 0,
      collected: paid,
      pending: (total - paid).clamp(0, double.infinity),
    );
  }

  Future<DashboardSummary> fetchSummary() async {
    final overall = await _students.aggregate(count(), sum('totalAmount'), sum('amountPaid')).get();
    final totalStudents = overall.count ?? 0;
    final totalAmount = (overall.getSum('totalAmount') ?? 0).toDouble();
    final totalPaid = (overall.getSum('amountPaid') ?? 0).toDouble();

    final staffAgg = await _users.where('role', isEqualTo: 'staff').count().get();

    final results = await Future.wait([
      _breakdownFor(CourseType.mcwg),
      _breakdownFor(CourseType.mcwog),
      _breakdownFor(CourseType.lmv),
    ]);

    return DashboardSummary(
      totalStudents: totalStudents,
      totalStaff: staffAgg.count ?? 0,
      totalCollected: totalPaid,
      totalPending: (totalAmount - totalPaid).clamp(0, double.infinity),
      mcwg: results[0],
      mcwog: results[1],
      lmv: results[2],
    );
  }

  /// Total fee amount collected per month, for the trailing [months] months
  /// (oldest first, current month last).
  Future<List<MonthlyCollection>> fetchMonthlyCollections({int months = 6}) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - (months - 1), 1);

    final totals = <DateTime, double>{
      for (var i = 0; i < months; i++) DateTime(start.year, start.month + i, 1): 0,
    };

    final snap = await _fees.where('paymentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start)).get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final date = (data['paymentDate'] as Timestamp?)?.toDate();
      if (date == null) continue;
      final key = DateTime(date.year, date.month, 1);
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      totals.update(key, (v) => v + amount, ifAbsent: () => amount);
    }

    return totals.entries.map((e) => MonthlyCollection(month: e.key, amount: e.value)).toList()
      ..sort((a, b) => a.month.compareTo(b.month));
  }

  /// Total collected vs. pending for the Reports page's "Fee Summary" card
  /// and PDF export, over [start]..[end] inclusive (whole days), plus one
  /// row per payment made in that range for the PDF's itemized bill.
  /// [pending] is the sum of the *distinct* students who paid in the range's
  /// current outstanding balance — the same figure each row's `pending`
  /// draws from — so the card total and the PDF's footer total always agree;
  /// summing every row instead would double-count a student who paid more
  /// than once in the range.
  Future<FeeSummary> fetchFeeSummary({required DateTime start, required DateTime end}) async {
    final rangeEnd = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

    final feesSnap = await _fees
        .where('paymentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('paymentDate', isLessThanOrEqualTo: Timestamp.fromDate(rangeEnd))
        .orderBy('paymentDate')
        .get();

    // Live-lookup each row's student, so a payment shows the student's
    // current name/pending even if `studentName` predates that field being
    // stored on the payment, or the student was later renamed.
    final studentIds = <String>{
      for (final doc in feesSnap.docs)
        if ((doc.data()['studentId'] as String? ?? '').isNotEmpty) doc.data()['studentId'] as String,
    }.toList();
    final studentsById = <String, Student>{};
    for (var i = 0; i < studentIds.length; i += 30) {
      final chunk = studentIds.sublist(i, i + 30 > studentIds.length ? studentIds.length : i + 30);
      final snap = await _students.where(FieldPath.documentId, whereIn: chunk).get();
      for (final doc in snap.docs) {
        studentsById[doc.id] = Student.fromDoc(doc);
      }
    }

    var collected = 0.0;
    final rows = <FeeSummaryRow>[];
    for (final doc in feesSnap.docs) {
      final data = doc.data();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      collected += amount;

      final student = studentsById[data['studentId'] as String? ?? ''];
      final name = student != null && student.fullName.isNotEmpty
          ? student.fullName
          : (data['studentName'] as String? ?? 'Unknown student');

      rows.add(FeeSummaryRow(
        date: (data['paymentDate'] as Timestamp?)?.toDate() ?? start,
        studentName: name,
        collected: amount,
        pending: student?.amountPending ?? 0,
      ));
    }

    final pending = studentsById.values.fold<double>(0, (acc, s) => acc + s.amountPending);

    return FeeSummary(start: start, end: end, collected: collected, pending: pending, rows: rows);
  }
}

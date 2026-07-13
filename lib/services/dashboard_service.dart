import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_type.dart';
import '../models/dashboard_summary.dart';

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

  Set<CourseType> _courseTypesOf(Map<String, dynamic> data) {
    final list = data['courseTypes'] as List<dynamic>?;
    return list != null
        ? list.map((c) => courseTypeFromString(c as String)).toSet()
        : {courseTypeFromString(data['courseType'] as String? ?? 'twoWheeler')};
  }

  /// Per-month, per-course collected vs. pending for the Reports page's
  /// "Monthly Fee Summary" table. Pending for a month is the outstanding
  /// balance of students whose joining date falls in that month (there's no
  /// separate due-date field in the schema). A payment isn't tied to a
  /// specific course, so it's attributed to all of the paying student's
  /// course types — the same convention [_breakdownFor] already uses for
  /// multi-course students.
  Future<List<MonthlyFeeSummary>> fetchMonthlyFeeSummary({int months = 6}) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - (months - 1), 1);
    final monthKeys = [for (var i = 0; i < months; i++) DateTime(start.year, start.month + i, 1)];

    Map<DateTime, Map<CourseType, double>> emptyTotals() => {
          for (final m in monthKeys) m: {for (final c in selectableCourseTypes) c: 0},
        };

    final collectedTotals = emptyTotals();
    final feesSnap = await _fees.where('paymentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start)).get();
    final studentIds = <String>{};
    for (final doc in feesSnap.docs) {
      final id = doc.data()['studentId'] as String?;
      if (id != null && id.isNotEmpty) studentIds.add(id);
    }
    final studentCourseTypes = <String, Set<CourseType>>{};
    for (final id in studentIds) {
      final doc = await _students.doc(id).get();
      if (doc.exists) studentCourseTypes[id] = _courseTypesOf(doc.data()!);
    }
    for (final doc in feesSnap.docs) {
      final data = doc.data();
      final date = (data['paymentDate'] as Timestamp?)?.toDate();
      if (date == null) continue;
      final key = DateTime(date.year, date.month, 1);
      if (!collectedTotals.containsKey(key)) continue;
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      final courses = studentCourseTypes[data['studentId'] as String? ?? ''] ?? {};
      for (final c in courses) {
        if (!selectableCourseTypes.contains(c)) continue;
        collectedTotals[key]!.update(c, (v) => v + amount);
      }
    }

    final pendingTotals = emptyTotals();
    final studentsSnap = await _students.where('joiningDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start)).get();
    for (final doc in studentsSnap.docs) {
      final data = doc.data();
      final joining = (data['joiningDate'] as Timestamp?)?.toDate();
      if (joining == null) continue;
      final key = DateTime(joining.year, joining.month, 1);
      if (!pendingTotals.containsKey(key)) continue;
      final total = (data['totalAmount'] as num?)?.toDouble() ?? 0;
      final paid = (data['amountPaid'] as num?)?.toDouble() ?? 0;
      final pending = (total - paid).clamp(0, double.infinity);
      for (final c in _courseTypesOf(data)) {
        if (!selectableCourseTypes.contains(c)) continue;
        pendingTotals[key]!.update(c, (v) => v + pending);
      }
    }

    return [
      for (final m in monthKeys)
        for (final c in selectableCourseTypes)
          MonthlyFeeSummary(month: m, course: c, collected: collectedTotals[m]![c] ?? 0, pending: pendingTotals[m]![c] ?? 0),
    ];
  }
}

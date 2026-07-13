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

  /// The first calendar month (normalized to the 1st) that has any recorded
  /// payment, or `null` if no payments have been recorded yet. Anchors the
  /// Reports page's paginated "Monthly Fee Summary" view so it starts from
  /// real data instead of an arbitrary rolling window.
  Future<DateTime?> fetchEarliestPaymentMonth() async {
    final snap = await _fees.orderBy('paymentDate').limit(1).get();
    if (snap.docs.isEmpty) return null;
    final date = (snap.docs.first.data()['paymentDate'] as Timestamp?)?.toDate();
    if (date == null) return null;
    return DateTime(date.year, date.month, 1);
  }

  /// Total collected vs. pending per month for the Reports page's "Monthly
  /// Fee Summary" table, covering [months] months starting at [start].
  /// Pending for a month is the outstanding balance of students whose
  /// joining date falls in that month (there's no separate due-date field
  /// in the schema).
  Future<List<MonthlyFeeSummary>> fetchMonthlyFeeSummary({required DateTime start, int months = 6}) async {
    final monthKeys = [for (var i = 0; i < months; i++) DateTime(start.year, start.month + i, 1)];

    final collectedTotals = {for (final m in monthKeys) m: 0.0};
    final feesSnap = await _fees.where('paymentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start)).get();
    for (final doc in feesSnap.docs) {
      final data = doc.data();
      final date = (data['paymentDate'] as Timestamp?)?.toDate();
      if (date == null) continue;
      final key = DateTime(date.year, date.month, 1);
      if (!collectedTotals.containsKey(key)) continue;
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      collectedTotals.update(key, (v) => v + amount);
    }

    final pendingTotals = {for (final m in monthKeys) m: 0.0};
    final studentsSnap = await _students.where('joiningDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start)).get();
    for (final doc in studentsSnap.docs) {
      final data = doc.data();
      final joining = (data['joiningDate'] as Timestamp?)?.toDate();
      if (joining == null) continue;
      final key = DateTime(joining.year, joining.month, 1);
      if (!pendingTotals.containsKey(key)) continue;
      final total = (data['totalAmount'] as num?)?.toDouble() ?? 0;
      final paid = (data['amountPaid'] as num?)?.toDouble() ?? 0;
      pendingTotals.update(key, (v) => v + (total - paid).clamp(0, double.infinity));
    }

    return [
      for (final m in monthKeys) MonthlyFeeSummary(month: m, collected: collectedTotals[m] ?? 0, pending: pendingTotals[m] ?? 0),
    ];
  }
}

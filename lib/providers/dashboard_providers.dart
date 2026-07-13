import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity_log.dart';
import '../models/dashboard_summary.dart';
import '../services/activity_log_service.dart';
import 'service_providers.dart';

final dashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummary>((ref) {
  return ref.watch(dashboardServiceProvider).fetchSummary();
});

final monthlyCollectionsProvider = FutureProvider.autoDispose<List<MonthlyCollection>>((ref) {
  return ref.watch(dashboardServiceProvider).fetchMonthlyCollections();
});

final earliestPaymentMonthProvider = FutureProvider.autoDispose<DateTime?>((ref) {
  return ref.watch(dashboardServiceProvider).fetchEarliestPaymentMonth();
});

/// The year shown on the Reports page's "Monthly Fee Summary" table (always
/// the full January-December range), defaulting to the current year.
final selectedReportYearProvider = StateProvider.autoDispose<int>((ref) => DateTime.now().year);

/// The earliest and latest years the Prev/Next arrows may page between: the
/// year of the first recorded payment through the current year.
final reportsYearBoundsProvider = FutureProvider.autoDispose<({int minYear, int maxYear})>((ref) async {
  final earliest = await ref.watch(earliestPaymentMonthProvider.future);
  final now = DateTime.now();
  return (minYear: earliest?.year ?? now.year, maxYear: now.year);
});

final monthlyFeeSummaryProvider = FutureProvider.autoDispose<List<MonthlyFeeSummary>>((ref) async {
  final service = ref.watch(dashboardServiceProvider);
  final selectedYear = ref.watch(selectedReportYearProvider);
  return service.fetchMonthlyFeeSummary(start: DateTime(selectedYear, 1, 1), months: 12);
});

final recentActivityProvider = StreamProvider.autoDispose<List<ActivityLog>>((ref) {
  return ref.watch(activityLogServiceProvider).watchRecent();
});

/// Names for students referenced by legacy `payment_recorded` log entries
/// (see [displayDetailsFor]), so the Reports screen can show "for" a name
/// instead of a raw student ID without having to rewrite the audit trail.
final activityLogStudentNamesProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final logs = await ref.watch(recentActivityProvider.future);
  final ids = <String>{
    for (final log in logs)
      if (legacyPaymentLogIdPattern.firstMatch(log.details) case final match?) match.group(2)!,
  };
  if (ids.isEmpty) return {};
  return ref.watch(studentServiceProvider).fetchNamesById(ids);
});

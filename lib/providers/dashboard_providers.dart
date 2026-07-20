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

/// The date range shown on the Reports page's "Fee Summary" card, defaulting
/// to the 1st of the current month through today.
final selectedFeeSummaryRangeProvider = StateProvider.autoDispose<({DateTime start, DateTime end})>((ref) {
  final now = DateTime.now();
  return (start: DateTime(now.year, now.month, 1), end: DateTime(now.year, now.month, now.day));
});

final feeSummaryProvider = FutureProvider.autoDispose<FeeSummary>((ref) {
  final range = ref.watch(selectedFeeSummaryRangeProvider);
  return ref.watch(dashboardServiceProvider).fetchFeeSummary(start: range.start, end: range.end);
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

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

final monthlyFeeSummaryProvider = FutureProvider.autoDispose<List<MonthlyFeeSummary>>((ref) {
  return ref.watch(dashboardServiceProvider).fetchMonthlyFeeSummary();
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

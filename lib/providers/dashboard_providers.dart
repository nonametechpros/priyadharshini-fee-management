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

/// Null selects the paginated 6-months-at-a-time general view; a non-null
/// value filters the Reports page down to January through the current month
/// (for this year) or January through December (for a past year).
final selectedReportYearProvider = StateProvider.autoDispose<int?>((ref) => null);

/// 0-based page index into the general view, 6 months per page, starting
/// from [earliestPaymentMonthProvider].
final reportsPageProvider = StateProvider.autoDispose<int>((ref) => 0);

const reportsPageSize = 6;

/// True if a further (more recent) page exists without running past the
/// current month.
final reportsHasNextPageProvider = FutureProvider.autoDispose<bool>((ref) async {
  final earliest = await ref.watch(earliestPaymentMonthProvider.future);
  final now = DateTime.now();
  final anchor = earliest ?? DateTime(now.year, now.month, 1);
  final monthsBetween = (now.year - anchor.year) * 12 + (now.month - anchor.month) + 1;
  final maxPage = (monthsBetween - 1) ~/ reportsPageSize;
  return ref.watch(reportsPageProvider) < maxPage;
});

final monthlyFeeSummaryProvider = FutureProvider.autoDispose<List<MonthlyFeeSummary>>((ref) async {
  final service = ref.watch(dashboardServiceProvider);
  final selectedYear = ref.watch(selectedReportYearProvider);
  if (selectedYear != null) {
    return service.fetchMonthlyFeeSummary(start: DateTime(selectedYear, 1, 1), months: 12);
  }

  final earliest = await ref.watch(earliestPaymentMonthProvider.future);
  final now = DateTime.now();
  final anchor = earliest ?? DateTime(now.year, now.month, 1);
  final page = ref.watch(reportsPageProvider);
  final start = DateTime(anchor.year, anchor.month + page * reportsPageSize, 1);
  return service.fetchMonthlyFeeSummary(start: start, months: reportsPageSize);
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

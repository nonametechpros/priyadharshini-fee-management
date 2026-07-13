import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/course_type.dart';
import '../../models/dashboard_summary.dart';
import '../../providers/dashboard_providers.dart';
import '../../services/activity_log_service.dart';
import '../../services/monthly_fee_summary_pdf.dart';
import '../../utils/formatters.dart';
import '../../widgets/async_value_view.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final monthlyFeeAsync = ref.watch(monthlyFeeSummaryProvider);
    final activityAsync = ref.watch(recentActivityProvider);
    final studentNames = ref.watch(activityLogStudentNamesProvider).valueOrNull ?? const {};
    final selectedYear = ref.watch(selectedReportYearProvider);
    final page = ref.watch(reportsPageProvider);
    final hasNextPageAsync = ref.watch(reportsHasNextPageProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Collection & Pending Dues', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          AsyncValueView(
            value: summaryAsync,
            data: (context, summary) => _BreakdownTable(summary: summary),
          ),
          const SizedBox(height: 28),
          Text('Monthly Fee Summary', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                label: Text(selectedYear == null ? 'Select year' : '$selectedYear'),
                onPressed: () async {
                  final picked = await _pickYear(context, initial: selectedYear);
                  if (picked != null) ref.read(selectedReportYearProvider.notifier).state = picked;
                },
              ),
              if (selectedYear != null)
                IconButton(
                  tooltip: 'Clear year filter',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => ref.read(selectedReportYearProvider.notifier).state = null,
                ),
              TextButton.icon(
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('Export to PDF'),
                onPressed: monthlyFeeAsync.valueOrNull == null
                    ? null
                    : () => exportMonthlyFeeSummaryPdf(monthlyFeeAsync.valueOrNull!),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AsyncValueView(
            value: monthlyFeeAsync,
            data: (context, months) => _MonthlyFeeSummaryTable(months: months),
          ),
          if (selectedYear == null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Older 6 months',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: page > 0 ? () => ref.read(reportsPageProvider.notifier).state = page - 1 : null,
                ),
                IconButton(
                  tooltip: 'Newer 6 months',
                  icon: const Icon(Icons.chevron_right),
                  onPressed:
                      hasNextPageAsync.valueOrNull == true ? () => ref.read(reportsPageProvider.notifier).state = page + 1 : null,
                ),
              ],
            ),
          ],
          const SizedBox(height: 28),
          Text('Recent Activity', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          AsyncValueView(
            value: activityAsync,
            data: (context, logs) {
              if (logs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No activity recorded yet.'),
                );
              }
              return Column(
                children: logs
                    .map((log) {
                      final details = displayDetailsFor(log, studentNames);
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(details.isNotEmpty ? details : log.action),
                          subtitle: Text('By ${log.performedByName}'),
                          trailing: log.timestamp != null ? Text(formatDate(log.timestamp!)) : null,
                        ),
                      );
                    })
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MonthlyFeeSummaryTable extends StatelessWidget {
  const _MonthlyFeeSummaryTable({required this.months});

  final List<MonthlyFeeSummary> months;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(1.4),
            2: FlexColumnWidth(1.4),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))),
              children: [
                _cell(context, 'Month', isHeader: true),
                _cell(context, 'Collected', isHeader: true),
                _cell(context, 'Pending', isHeader: true),
              ],
            ),
            ...months.map(
              (m) => TableRow(
                children: [
                  _cell(context, DateFormat('MMM yyyy').format(m.month)),
                  _cell(context, formatCurrency(m.collected)),
                  _cell(context, formatCurrency(m.pending)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(BuildContext context, String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Text(
        text,
        style: isHeader
            ? Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)
            : Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

Future<int?> _pickYear(BuildContext context, {int? initial}) {
  final now = DateTime.now();
  var year = initial ?? now.year;

  return showDialog<int>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Select year'),
        content: DropdownButtonFormField<int>(
          value: year,
          decoration: const InputDecoration(labelText: 'Year'),
          items: [
            for (var y = now.year; y >= now.year - 10; y--) DropdownMenuItem(value: y, child: Text('$y')),
          ],
          onChanged: (v) => setState(() => year = v!),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(year), child: const Text('Apply')),
        ],
      ),
    ),
  );
}

class _BreakdownTable extends StatelessWidget {
  const _BreakdownTable({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final rows = {
      CourseType.mcwg.label: summary.mcwg,
      CourseType.mcwog.label: summary.mcwog,
      CourseType.lmv.label: summary.lmv,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1.4),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1.4),
            3: FlexColumnWidth(1.4),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))),
              children: [
                _cell(context, 'Course', isHeader: true),
                _cell(context, 'Students', isHeader: true),
                _cell(context, 'Collected', isHeader: true),
                _cell(context, 'Pending', isHeader: true),
              ],
            ),
            ...rows.entries.map(
              (e) => TableRow(
                children: [
                  _cell(context, e.key),
                  _cell(context, '${e.value.count}'),
                  _cell(context, formatCurrency(e.value.collected)),
                  _cell(context, formatCurrency(e.value.pending)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(BuildContext context, String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Text(
        text,
        style: isHeader
            ? Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)
            : Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/course_type.dart';
import '../../models/dashboard_summary.dart';
import '../../providers/dashboard_providers.dart';
import '../../services/activity_log_service.dart';
import '../../services/monthly_fee_summary_pdf.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/async_value_view.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _exporting = false;

  Future<void> _export(FeeSummary summary) async {
    setState(() => _exporting = true);
    try {
      await exportFeeSummaryPdf(summary);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final feeSummaryAsync = ref.watch(feeSummaryProvider);
    final activityAsync = ref.watch(recentActivityProvider);
    final studentNames = ref.watch(activityLogStudentNamesProvider).valueOrNull ?? const {};
    final selectedRange = ref.watch(selectedFeeSummaryRangeProvider);

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
          Text('Fee Summary', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              ActionChip(
                avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text('${formatDate(selectedRange.start)} - ${formatDate(selectedRange.end)}'),
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    initialDateRange: DateTimeRange(start: selectedRange.start, end: selectedRange.end),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked == null) return;
                  ref.read(selectedFeeSummaryRangeProvider.notifier).state = (start: picked.start, end: picked.end);
                },
              ),
              TextButton.icon(
                icon: _exporting
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: Text(_exporting ? 'Exporting…' : 'Export to PDF'),
                onPressed: (_exporting || feeSummaryAsync.valueOrNull == null)
                    ? null
                    : () => _export(feeSummaryAsync.valueOrNull!),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AsyncValueView(
            value: feeSummaryAsync,
            data: (context, summary) => _FeeSummaryCard(summary: summary),
          ),
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

class _FeeSummaryCard extends StatelessWidget {
  const _FeeSummaryCard({required this.summary});

  final FeeSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _AmountStat(label: 'Collected', value: summary.collected, color: AppColors.statusPaid),
            ),
            Expanded(
              child: _AmountStat(label: 'Pending', value: summary.pending, color: AppColors.brandRed),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountStat extends StatelessWidget {
  const _AmountStat({required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          formatCurrency(value),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
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

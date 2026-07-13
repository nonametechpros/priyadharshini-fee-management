import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/course_type.dart';
import '../../models/dashboard_summary.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/fee_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/payment_tile.dart';
import '../../widgets/summary_card.dart';
import 'all_payments_screen.dart';

/// Categorical colors for the three course types. Deliberately distinct from
/// the paid/pending/partial status colors used elsewhere, so course identity
/// is never mistaken for fee status.
const Map<CourseType, Color> _courseTypeColors = {
  CourseType.mcwg: Color(0xFF2A78D6),
  CourseType.mcwog: Color(0xFF4A3AA7),
  CourseType.lmv: Color(0xFFEB6834),
};

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(monthlyCollectionsProvider);
          ref.invalidate(recentPaymentsProvider);
        },
        child: AsyncValueView(
          value: summaryAsync,
          data: (context, summary) {
            final isWide = MediaQuery.sizeOf(context).width >= 900;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GridView.count(
                  crossAxisCount: isWide ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: isWide ? 2.2 : 1.5,
                  children: [
                    SummaryCard(label: 'Total Students', value: '${summary.totalStudents}', icon: Icons.groups_outlined),
                    SummaryCard(label: 'Total Staff', value: '${summary.totalStaff}', icon: Icons.badge_outlined),
                    SummaryCard(
                      label: 'Total Collected',
                      value: formatCurrency(summary.totalCollected),
                      icon: Icons.savings_outlined,
                      accentColor: AppColors.statusPaid,
                    ),
                    SummaryCard(
                      label: 'Total Pending',
                      value: formatCurrency(summary.totalPending),
                      icon: Icons.hourglass_bottom_outlined,
                      accentColor: AppColors.brandRed,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (isWide)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _ChartCard(title: 'Monthly Collections', child: const _MonthlyCollectionsChart()),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ChartCard(title: 'Course Distribution', child: _CourseTypePieChart(summary: summary)),
                        ),
                      ],
                    ),
                  )
                else ...[
                  _ChartCard(title: 'Monthly Collections', child: const _MonthlyCollectionsChart()),
                  const SizedBox(height: 24),
                  _ChartCard(title: 'Course Distribution', child: _CourseTypePieChart(summary: summary)),
                ],
                const SizedBox(height: 24),
                _ChartCard(title: 'Collections by Course Type', child: _CourseTypeBarChart(summary: summary)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Text('Recent Payments', style: Theme.of(context).textTheme.titleMedium)),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AllPaymentsScreen()),
                      ),
                      child: const Text('View all'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const _RecentPayments(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
            child: SizedBox(height: 220, child: child),
          ),
        ),
      ],
    );
  }
}

class _MonthlyCollectionsChart extends ConsumerWidget {
  const _MonthlyCollectionsChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyAsync = ref.watch(monthlyCollectionsProvider);
    return AsyncValueView(
      value: monthlyAsync,
      data: (context, months) {
        if (months.every((m) => m.amount == 0)) {
          return const Center(child: Text('No collections recorded yet.'));
        }
        final maxValue = months.fold<double>(0, (max, m) => m.amount > max ? m.amount : max);
        const lineColor = Color(0xFF2A78D6);

        return LineChart(
          LineChartData(
            minY: 0,
            maxY: maxValue <= 0 ? 10 : maxValue * 1.2,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxValue <= 0 ? 2 : (maxValue * 1.2) / 4,
              getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.divider, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final i = value.round();
                    if (i < 0 || i >= months.length || (value - i).abs() > 0.01) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(DateFormat('MMM').format(months[i].month), style: Theme.of(context).textTheme.bodySmall),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots
                    .map((s) => LineTooltipItem(
                          '${DateFormat('MMM yyyy').format(months[s.x.toInt()].month)}\n${formatCurrency(s.y)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ))
                    .toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [for (var i = 0; i < months.length; i++) FlSpot(i.toDouble(), months[i].amount)],
                isCurved: false,
                color: lineColor,
                barWidth: 2,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: true, color: lineColor.withValues(alpha: 0.08)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CourseTypePieChart extends StatelessWidget {
  const _CourseTypePieChart({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final counts = {
      CourseType.mcwg: summary.mcwg.count,
      CourseType.mcwog: summary.mcwog.count,
      CourseType.lmv: summary.lmv.count,
    };
    final total = counts.values.fold<int>(0, (a, b) => a + b);

    if (total == 0) {
      return const Center(child: Text('No students yet.'));
    }

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: counts.entries.map((e) {
                final color = _courseTypeColors[e.key]!;
                final pct = e.value / total * 100;
                return PieChartSectionData(
                  value: e.value.toDouble(),
                  color: color,
                  radius: 56,
                  title: e.value == 0 ? '' : '${pct.round()}%',
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: counts.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: _courseTypeColors[e.key], shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('${e.key.label} (${e.value})', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _RecentPayments extends ConsumerWidget {
  const _RecentPayments();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(recentPaymentsProvider);
    final studentNames = ref.watch(recentPaymentsStudentNamesProvider).valueOrNull ?? const {};

    return AsyncValueView(
      value: paymentsAsync,
      data: (context, payments) {
        if (payments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No payments recorded yet.'),
          );
        }
        return Column(
          children: payments.map((p) => PaymentTile(payment: p, studentName: studentNames[p.studentId])).toList(),
        );
      },
    );
  }
}

class _CourseTypeBarChart extends StatelessWidget {
  const _CourseTypeBarChart({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final groups = [summary.mcwg, summary.mcwog, summary.lmv];
    final labels = ['MCWG', 'MCWOG', 'LMV'];
    final maxValue = groups
        .expand((g) => [g.collected, g.pending])
        .fold<double>(0, (max, v) => v > max ? v : max);

    return BarChart(
      BarChartData(
        maxY: maxValue <= 0 ? 10 : maxValue * 1.2,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(labels[value.toInt().clamp(0, labels.length - 1)]),
              ),
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(groups.length, (i) {
          final g = groups[i];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(toY: g.collected, color: AppColors.statusPaid, width: 16, borderRadius: BorderRadius.circular(4)),
              BarChartRodData(toY: g.pending, color: AppColors.brandRed, width: 16, borderRadius: BorderRadius.circular(4)),
            ],
            barsSpace: 6,
          );
        }),
      ),
    );
  }
}

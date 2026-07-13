import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/fee_providers.dart';
import '../../services/payment_filter.dart';
import '../../utils/formatters.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/payment_tile.dart';

class AllPaymentsScreen extends ConsumerWidget {
  const AllPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(paymentListControllerProvider);
    final studentNames = ref.watch(paymentListStudentNamesProvider).valueOrNull ?? const {};

    return Scaffold(
      appBar: AppBar(title: const Text('All Payments')),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _PaymentDateRangeFilter(),
            ),
            Expanded(
              child: AsyncValueView(
                value: listState,
                data: (context, state) {
                  if (state.items.isEmpty) {
                    return const Center(child: Text('No payments found.'));
                  }
                  return RefreshIndicator(
                    onRefresh: () => ref.read(paymentListControllerProvider.notifier).refresh(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: state.items.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index == state.items.length) {
                          if (!state.hasMore) return const SizedBox.shrink();
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: state.isLoadingMore
                                  ? const CircularProgressIndicator()
                                  : OutlinedButton(
                                      onPressed: () => ref.read(paymentListControllerProvider.notifier).loadMore(),
                                      child: const Text('Load more'),
                                    ),
                            ),
                          );
                        }
                        final payment = state.items[index];
                        return PaymentTile(payment: payment, studentName: studentNames[payment.studentId]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentDateRangeFilter extends ConsumerWidget {
  const _PaymentDateRangeFilter();

  Future<void> _pickRange(BuildContext context, WidgetRef ref) async {
    final filter = ref.read(paymentFilterProvider);
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: filter.hasDateRange && filter.from != null && filter.to != null
          ? DateTimeRange(start: filter.from!, end: filter.to!)
          : null,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null) return;
    ref.read(paymentFilterProvider.notifier).state = filter.copyWith(from: picked.start, to: picked.end);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(paymentFilterProvider);
    final notifier = ref.read(paymentFilterProvider.notifier);
    final label = filter.from == null || filter.to == null
        ? 'Date range'
        : '${formatDate(filter.from!)} - ${formatDate(filter.to!)}';

    return Row(
      children: [
        ActionChip(
          avatar: const Icon(Icons.calendar_today_outlined, size: 16),
          label: Text(label),
          onPressed: () => _pickRange(context, ref),
        ),
        if (!filter.isEmpty) ...[
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Clear filters',
            icon: const Icon(Icons.close),
            onPressed: () => notifier.state = const PaymentFilter(),
          ),
        ],
      ],
    );
  }
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fee_payment.dart';
import '../services/payment_filter.dart';
import 'service_providers.dart';

final paymentsForStudentProvider = StreamProvider.autoDispose.family<List<FeePayment>, String>((ref, studentId) {
  return ref.watch(feeServiceProvider).watchPaymentsForStudent(studentId);
});

/// Latest 5 payments shown on the Admin dashboard; see [paymentListControllerProvider]
/// for the paginated, filterable "All Payments" view.
final recentPaymentsProvider = StreamProvider.autoDispose<List<FeePayment>>((ref) {
  return ref.watch(feeServiceProvider).watchRecentPayments(limit: 5);
});

/// Backfills the student name for any legacy payment in [payments] that
/// predates the `studentName` field on [FeePayment] (new payments carry
/// their own name and never need this lookup).
Future<List<FeePayment>> _withStudentNames(Ref ref, List<FeePayment> payments) async {
  final ids = payments.where((p) => p.studentName == null).map((p) => p.studentId).toSet();
  if (ids.isEmpty) return payments;
  final names = await ref.read(studentServiceProvider).fetchNamesById(ids);
  return [for (final p in payments) p.studentName != null ? p : p.copyWith(studentName: names[p.studentId])];
}

/// [recentPaymentsProvider]'s payments with every name already resolved, so
/// the dashboard has one thing to await and never renders a payment before
/// its name is known — resolving names as a second, separately-timed
/// provider let the UI briefly show a stale/incomplete names map (and thus
/// "Unknown student") whenever the payments list changed underneath it.
final recentPaymentsWithNamesProvider = FutureProvider.autoDispose<List<FeePayment>>((ref) async {
  final payments = await ref.watch(recentPaymentsProvider.future);
  return _withStudentNames(ref, payments);
});

final paymentFilterProvider = StateProvider.autoDispose<PaymentFilter>((ref) => const PaymentFilter());

class PaymentListState {
  final List<FeePayment> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;
  final bool isLoadingMore;

  const PaymentListState({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  PaymentListState copyWith({
    List<FeePayment>? items,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return PaymentListState(
      items: items ?? this.items,
      lastDocument: lastDocument ?? this.lastDocument,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Backs the "All Payments" screen: paginated (10/page) and filterable by
/// payment-date range, unlike [recentPaymentsProvider]'s fixed live top-5.
class PaymentListController extends AutoDisposeAsyncNotifier<PaymentListState> {
  @override
  FutureOr<PaymentListState> build() async {
    final filter = ref.watch(paymentFilterProvider);
    final result = await ref.watch(feeServiceProvider).fetchPaymentsPage(filter: filter);
    final items = await _withStudentNames(ref, result.items);
    return PaymentListState(items: items, lastDocument: result.lastDocument, hasMore: result.hasMore);
  }

  // Every state update below resolves names before publishing the new
  // state, rather than letting the UI watch a second, separately-timed
  // names provider — that pattern let a page of freshly-loaded payments
  // render against a stale names map (and thus "Unknown student") for a
  // moment after each scroll-triggered `loadMore()`.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    final filter = ref.read(paymentFilterProvider);
    final result = await ref.read(feeServiceProvider).fetchPaymentsPage(
          filter: filter,
          startAfter: current.lastDocument,
        );
    final newItems = await _withStudentNames(ref, result.items);

    state = AsyncData(PaymentListState(
      items: [...current.items, ...newItems],
      lastDocument: result.lastDocument,
      hasMore: result.hasMore,
    ));
  }

  Future<void> refresh() async {
    final filter = ref.read(paymentFilterProvider);
    state = const AsyncLoading<PaymentListState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final result = await ref.read(feeServiceProvider).fetchPaymentsPage(filter: filter);
      final items = await _withStudentNames(ref, result.items);
      return PaymentListState(items: items, lastDocument: result.lastDocument, hasMore: result.hasMore);
    });
  }
}

final paymentListControllerProvider =
    AsyncNotifierProvider.autoDispose<PaymentListController, PaymentListState>(PaymentListController.new);

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

/// Names for the students behind [recentPaymentsProvider], so the Admin
/// dashboard can show "Jane Doe" instead of a raw student ID.
final recentPaymentsStudentNamesProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final payments = await ref.watch(recentPaymentsProvider.future);
  final ids = payments.map((p) => p.studentId).toSet();
  if (ids.isEmpty) return {};
  return ref.watch(studentServiceProvider).fetchNamesById(ids);
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
    return PaymentListState(items: result.items, lastDocument: result.lastDocument, hasMore: result.hasMore);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    final filter = ref.read(paymentFilterProvider);
    final result = await ref.read(feeServiceProvider).fetchPaymentsPage(
          filter: filter,
          startAfter: current.lastDocument,
        );

    state = AsyncData(PaymentListState(
      items: [...current.items, ...result.items],
      lastDocument: result.lastDocument,
      hasMore: result.hasMore,
    ));
  }

  Future<void> refresh() async {
    final filter = ref.read(paymentFilterProvider);
    state = const AsyncLoading<PaymentListState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final result = await ref.read(feeServiceProvider).fetchPaymentsPage(filter: filter);
      return PaymentListState(items: result.items, lastDocument: result.lastDocument, hasMore: result.hasMore);
    });
  }
}

final paymentListControllerProvider =
    AsyncNotifierProvider.autoDispose<PaymentListController, PaymentListState>(PaymentListController.new);

/// Names for the students behind the current page of [paymentListControllerProvider].
final paymentListStudentNamesProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final state = await ref.watch(paymentListControllerProvider.future);
  final ids = state.items.map((p) => p.studentId).toSet();
  if (ids.isEmpty) return {};
  return ref.watch(studentServiceProvider).fetchNamesById(ids);
});

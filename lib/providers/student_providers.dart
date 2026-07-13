import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student.dart';
import '../services/student_filter.dart';
import 'service_providers.dart';

final studentFilterProvider = StateProvider<StudentFilter>((ref) => const StudentFilter());

class StudentListState {
  final List<Student> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;
  final bool isLoadingMore;

  const StudentListState({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  StudentListState copyWith({
    List<Student>? items,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return StudentListState(
      items: items ?? this.items,
      lastDocument: lastDocument ?? this.lastDocument,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class StudentListController extends AutoDisposeAsyncNotifier<StudentListState> {
  @override
  FutureOr<StudentListState> build() async {
    final filter = ref.watch(studentFilterProvider);
    final result = await ref.watch(studentServiceProvider).fetchPage(filter: filter);
    return StudentListState(items: result.items, lastDocument: result.lastDocument, hasMore: result.hasMore);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    final filter = ref.read(studentFilterProvider);
    final result = await ref.read(studentServiceProvider).fetchPage(
          filter: filter,
          startAfter: current.lastDocument,
        );

    state = AsyncData(StudentListState(
      items: [...current.items, ...result.items],
      lastDocument: result.lastDocument,
      hasMore: result.hasMore,
    ));
  }

  void removeStudent(String studentId) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      items: current.items.where((s) => s.id != studentId).toList(),
    ));
  }

  Future<void> refresh() async {
    final filter = ref.read(studentFilterProvider);
    state = const AsyncLoading<StudentListState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final result = await ref.read(studentServiceProvider).fetchPage(filter: filter);
      return StudentListState(items: result.items, lastDocument: result.lastDocument, hasMore: result.hasMore);
    });
  }
}

final studentListControllerProvider =
    AsyncNotifierProvider.autoDispose<StudentListController, StudentListState>(StudentListController.new);

final studentDetailProvider = StreamProvider.autoDispose.family<Student, String>((ref, studentId) {
  return ref.watch(studentServiceProvider).watchStudent(studentId);
});

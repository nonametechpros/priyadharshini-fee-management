import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/student_providers.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/student_filter_bar.dart';
import '../../widgets/student_list_tile.dart';
import 'add_edit_student_screen.dart';
import 'student_detail_screen.dart';

class StudentListScreen extends ConsumerWidget {
  const StudentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(studentListControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: StudentFilterBar(showStaffFilter: true),
            ),
            Expanded(
              child: AsyncValueView(
                value: listState,
                data: (context, state) {
                  if (state.items.isEmpty) {
                    return const Center(child: Text('No students found.'));
                  }
                  return RefreshIndicator(
                    onRefresh: () => ref.read(studentListControllerProvider.notifier).refresh(),
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
                                      onPressed: () =>
                                          ref.read(studentListControllerProvider.notifier).loadMore(),
                                      child: const Text('Load more'),
                                    ),
                            ),
                          );
                        }
                        final student = state.items[index];
                        return StudentListTile(
                          student: student,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => StudentDetailScreen(studentId: student.id)),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-student-fab',
        onPressed: () async {
          final saved = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddEditStudentScreen()),
          );
          if (saved == true) ref.read(studentListControllerProvider.notifier).refresh();
        },
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Student'),
      ),
    );
  }
}

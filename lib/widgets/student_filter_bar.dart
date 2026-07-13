import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course_type.dart';
import '../models/fee_status.dart';
import '../providers/staff_providers.dart';
import '../providers/student_providers.dart';
import '../services/student_filter.dart';

class StudentFilterBar extends ConsumerWidget {
  const StudentFilterBar({super.key, this.showStaffFilter = false});

  final bool showStaffFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(studentFilterProvider);
    final notifier = ref.read(studentFilterProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search by name...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => notifier.state = filter.copyWith(searchTerm: value),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _CourseTypeFilter(filter: filter, notifier: notifier),
              const SizedBox(width: 8),
              _FeeStatusFilter(filter: filter, notifier: notifier),
              if (showStaffFilter) ...[
                const SizedBox(width: 8),
                _StaffFilter(filter: filter, notifier: notifier),
              ],
              if (!filter.isEmpty) ...[
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Clear filters'),
                  onPressed: () => notifier.state = const StudentFilter(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CourseTypeFilter extends StatelessWidget {
  const _CourseTypeFilter({required this.filter, required this.notifier});

  final StudentFilter filter;
  final StateController<StudentFilter> notifier;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<CourseType?>(
      initialSelection: filter.courseType,
      label: const Text('Course'),
      width: 160,
      dropdownMenuEntries: const [
        DropdownMenuEntry(value: null, label: 'All courses'),
        DropdownMenuEntry(value: CourseType.mcwg, label: 'MCWG'),
        DropdownMenuEntry(value: CourseType.mcwog, label: 'MCWOG'),
        DropdownMenuEntry(value: CourseType.lmv, label: 'LMV'),
      ],
      onSelected: (value) =>
          notifier.state = filter.copyWith(courseType: value, clearCourseType: value == null),
    );
  }
}

class _FeeStatusFilter extends StatelessWidget {
  const _FeeStatusFilter({required this.filter, required this.notifier});

  final StudentFilter filter;
  final StateController<StudentFilter> notifier;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<FeeStatus?>(
      initialSelection: filter.feeStatus,
      label: const Text('Fee status'),
      width: 170,
      dropdownMenuEntries: const [
        DropdownMenuEntry(value: null, label: 'All statuses'),
        DropdownMenuEntry(value: FeeStatus.paid, label: 'Fully Paid'),
        DropdownMenuEntry(value: FeeStatus.partial, label: 'Partially Paid'),
        DropdownMenuEntry(value: FeeStatus.pending, label: 'Pending'),
      ],
      onSelected: (value) =>
          notifier.state = filter.copyWith(feeStatus: value, clearFeeStatus: value == null),
    );
  }
}

class _StaffFilter extends ConsumerWidget {
  const _StaffFilter({required this.filter, required this.notifier});

  final StudentFilter filter;
  final StateController<StudentFilter> notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffListProvider);
    return staffAsync.when(
      data: (staff) => DropdownMenu<String?>(
        initialSelection: filter.addedByUid,
        label: const Text('Staff'),
        width: 180,
        dropdownMenuEntries: [
          const DropdownMenuEntry(value: null, label: 'All staff'),
          ...staff.map((s) => DropdownMenuEntry(value: s.uid, label: s.name)),
        ],
        onSelected: (value) =>
            notifier.state = filter.copyWith(addedByUid: value, clearAddedByUid: value == null),
      ),
      loading: () => const SizedBox(width: 180, height: 56, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

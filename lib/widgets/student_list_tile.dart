import 'package:flutter/material.dart';
import '../models/course_type.dart';
import '../models/student.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'status_chip.dart';

class StudentListTile extends StatelessWidget {
  const StudentListTile({super.key, required this.student, required this.onTap});

  final Student student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: AppColors.brandRed.withValues(alpha: 0.12),
                foregroundColor: AppColors.brandRed,
                child: Text(student.firstName.isNotEmpty ? student.firstName[0].toUpperCase() : '?'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final c in student.courseTypes)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(c.icon, size: 14, color: Theme.of(context).colorScheme.outline),
                          ),
                        Flexible(
                          child: Text(
                            'Joined ${formatDate(student.joiningDate)}',
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusChip(status: student.feeStatus),
                  const SizedBox(height: 6),
                  Text(
                    'Due ${formatCurrency(student.amountPending)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: student.amountPending > 0 ? AppColors.brandRed : AppColors.statusPaid,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

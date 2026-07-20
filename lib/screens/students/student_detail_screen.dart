import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/fee_payment.dart';
import '../../models/student.dart';
import '../../providers/auth_providers.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/fee_providers.dart';
import '../../providers/service_providers.dart';
import '../../providers/student_providers.dart';
import '../../services/student_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/status_chip.dart';
import 'add_edit_student_screen.dart';
import 'record_payment_sheet.dart';

class StudentDetailScreen extends ConsumerWidget {
  const StudentDetailScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentDetailProvider(studentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Student Details')),
      body: AsyncValueView(
        value: studentAsync,
        data: (context, student) => _StudentDetailBody(student: student),
      ),
    );
  }
}

class _StudentDetailBody extends ConsumerWidget {
  const _StudentDetailBody({required this.student});

  final Student student;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final impact = await showDialog<StudentDeletionImpact>(
      context: context,
      builder: (_) => FutureBuilder<StudentDeletionImpact>(
        future: ref.read(studentServiceProvider).previewDeletionImpact(student.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const AlertDialog(
              content: SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
            );
          }
          final impact = snapshot.data!;
          return AlertDialog(
            title: const Text('Delete student?'),
            content: Text(
              'This permanently removes ${student.fullName}, along with '
              '${impact.paymentCount} payment${impact.paymentCount == 1 ? '' : 's'} '
              '(${formatCurrency(impact.totalPaymentAmount)}) and '
              '${impact.activityLogCount} activity log ${impact.activityLogCount == 1 ? 'entry' : 'entries'}. '
              'This cannot be undone.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.of(context).pop(impact), child: const Text('Delete')),
            ],
          );
        },
      ),
    );
    if (impact == null) return;
    if (!context.mounted) return;

    final appUser = ref.read(currentAppUserProvider).valueOrNull;
    if (appUser == null) return;

    final service = ref.read(studentServiceProvider);
    final listNotifier = ref.read(studentListControllerProvider.notifier);

    // Update the list and leave this screen before awaiting the delete:
    // once the document is gone, this screen's live watchStudent stream
    // errors on the missing doc and tears this widget down, which would
    // otherwise dispose `ref` before the steps below could run.
    listNotifier.removeStudent(student.id);
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(feeSummaryProvider);
    Navigator.of(context).pop();

    await service.deleteStudent(
      student.id,
      student.fullName,
      performedByUid: appUser.uid,
      performedByName: appUser.name,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsForStudentProvider(student.id));
    // Deleting now cascades to the student's fees/activity logs, which the
    // security rules restrict to Admin (see firestore.rules), so the action
    // is Admin-only here too rather than surfacing a permission error.
    final isAdmin = ref.watch(currentAppUserProvider).valueOrNull?.isAdmin ?? false;

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(student.fullName, style: Theme.of(context).textTheme.titleLarge),
                      ),
                      StatusChip(status: student.feeStatus),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(student.phoneNumber, style: Theme.of(context).textTheme.bodySmall),
                  const Divider(height: 28),
                  _DetailRow(label: 'Address', value: student.address),
                  _DetailRow(label: 'Course', value: student.courseTypesLabel),
                  _DetailRow(label: 'Date of birth', value: formatDate(student.dateOfBirth)),
                  _DetailRow(label: 'Joining date', value: formatDate(student.joiningDate)),
                  _DetailRow(label: 'Added by', value: student.addedByName),
                  const Divider(height: 28),
                  Row(
                    children: [
                      Expanded(child: _AmountStat(label: 'Total', value: student.totalAmount)),
                      Expanded(child: _AmountStat(label: 'Paid', value: student.amountPaid, color: AppColors.statusPaid)),
                      Expanded(child: _AmountStat(label: 'Pending', value: student.amountPending, color: AppColors.brandRed)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Record Payment'),
                  onPressed: student.amountPending <= 0
                      ? null
                      : () async {
                          final recorded = await showRecordPaymentSheet(context,
                              studentId: student.id,
                              studentName: student.fullName,
                              amountPending: student.amountPending);
                          if (recorded == true) {
                            ref.read(studentListControllerProvider.notifier).refresh();
                          }
                        },
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
                onPressed: () async {
                  final saved = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => AddEditStudentScreen(existing: student)),
                  );
                  if (saved == true) ref.read(studentListControllerProvider.notifier).refresh();
                },
              ),
              if (isAdmin) ...[
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'Delete student',
                  icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Text('Payment History', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          AsyncValueView(
            value: paymentsAsync,
            data: (context, payments) {
              if (payments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No payments recorded yet.'),
                );
              }
              return Column(
                children: payments
                    .map((p) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.receipt_long_outlined),
                            title: Text(formatCurrency(p.amount)),
                            subtitle: Text('${p.mode.label} • Recorded by ${p.recordedByName}'),
                            trailing: Text(formatDate(p.paymentDate)),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _AmountStat extends StatelessWidget {
  const _AmountStat({required this.label, required this.value, this.color});

  final String label;
  final double value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          formatCurrency(value),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}

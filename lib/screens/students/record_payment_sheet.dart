import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/fee_payment.dart';
import '../../providers/auth_providers.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/service_providers.dart';
import '../../utils/formatters.dart';

/// Shows the record-payment form as a modal bottom sheet. Returns `true` if
/// a payment was recorded.
Future<bool?> showRecordPaymentSheet(BuildContext context,
    {required String studentId, required String studentName, required double amountPending}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => RecordPaymentSheet(studentId: studentId, studentName: studentName, amountPending: amountPending),
  );
}

class RecordPaymentSheet extends ConsumerStatefulWidget {
  const RecordPaymentSheet({super.key, required this.studentId, required this.studentName, required this.amountPending});

  final String studentId;
  final String studentName;
  final double amountPending;

  @override
  ConsumerState<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<RecordPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  DateTime _paymentDate = DateTime.now();
  PaymentMode _mode = PaymentMode.cash;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final appUser = ref.read(currentAppUserProvider).valueOrNull;
    if (appUser == null) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await ref.read(feeServiceProvider).recordPayment(
            studentId: widget.studentId,
            studentName: widget.studentName,
            amount: double.parse(_amountController.text.trim()),
            paymentDate: _paymentDate,
            mode: _mode,
            recordedByUid: appUser.uid,
            recordedByName: appUser.name,
          );
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(monthlyFeeSummaryProvider);
      ref.invalidate(earliestPaymentMonthProvider);
      ref.invalidate(reportsYearBoundsProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _errorText = 'Could not record payment. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Record Payment', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Amount pending: ${formatCurrency(widget.amountPending)}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 18),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final parsed = double.tryParse(v.trim());
                if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _paymentDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _paymentDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Payment date', suffixIcon: Icon(Icons.calendar_today_outlined)),
                child: Text(formatDate(_paymentDate)),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<PaymentMode>(
              value: _mode,
              decoration: const InputDecoration(labelText: 'Payment mode'),
              items: PaymentMode.values
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
                  .toList(),
              onChanged: (m) => setState(() => _mode = m ?? _mode),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 14),
              Text(_errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Record Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

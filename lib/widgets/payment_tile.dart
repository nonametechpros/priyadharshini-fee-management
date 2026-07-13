import 'package:flutter/material.dart';
import '../models/fee_payment.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class PaymentTile extends StatelessWidget {
  const PaymentTile({super.key, required this.payment, required this.studentName});

  final FeePayment payment;
  final String? studentName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.receipt_long_outlined),
        title: Text(studentName ?? 'Unknown student'),
        subtitle: Text('${payment.mode.label} • Recorded by ${payment.recordedByName}'),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(formatCurrency(payment.amount), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.statusPaid)),
            Text(formatDate(payment.paymentDate), style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

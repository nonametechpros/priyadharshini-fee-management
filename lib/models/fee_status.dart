import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum FeeStatus { paid, partial, pending }

extension FeeStatusMeta on FeeStatus {
  String get label {
    switch (this) {
      case FeeStatus.paid:
        return 'Fully Paid';
      case FeeStatus.partial:
        return 'Partially Paid';
      case FeeStatus.pending:
        return 'Pending';
    }
  }

  Color get color {
    switch (this) {
      case FeeStatus.paid:
        return AppColors.statusPaid;
      case FeeStatus.partial:
        return AppColors.statusPartial;
      case FeeStatus.pending:
        return AppColors.statusPending;
    }
  }
}

FeeStatus feeStatusFor({required double totalAmount, required double amountPaid}) {
  if (amountPaid <= 0) return FeeStatus.pending;
  if (amountPaid >= totalAmount) return FeeStatus.paid;
  return FeeStatus.partial;
}

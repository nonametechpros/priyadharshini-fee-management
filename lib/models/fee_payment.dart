import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMode { cash, upi, card, bankTransfer, other }

extension PaymentModeLabel on PaymentMode {
  String get label {
    switch (this) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.upi:
        return 'UPI';
      case PaymentMode.card:
        return 'Card';
      case PaymentMode.bankTransfer:
        return 'Bank Transfer';
      case PaymentMode.other:
        return 'Other';
    }
  }
}

PaymentMode paymentModeFromString(String value) {
  return PaymentMode.values.firstWhere(
    (m) => m.name == value,
    orElse: () => PaymentMode.cash,
  );
}

class FeePayment {
  final String id;
  final String studentId;
  final double amount;
  final DateTime paymentDate;
  final PaymentMode mode;
  final String recordedBy;
  final String recordedByName;
  final DateTime? createdAt;

  const FeePayment({
    required this.id,
    required this.studentId,
    required this.amount,
    required this.paymentDate,
    required this.mode,
    required this.recordedBy,
    required this.recordedByName,
    this.createdAt,
  });

  factory FeePayment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FeePayment(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      paymentDate: (data['paymentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mode: paymentModeFromString(data['mode'] as String? ?? 'cash'),
      recordedBy: data['recordedBy'] as String? ?? '',
      recordedByName: data['recordedByName'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'amount': amount,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'mode': mode.name,
      'recordedBy': recordedBy,
      'recordedByName': recordedByName,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

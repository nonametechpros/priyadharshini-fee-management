/// Filter criteria for the All Payments screen: an inclusive payment-date range.
class PaymentFilter {
  final DateTime? from;
  final DateTime? to;

  const PaymentFilter({this.from, this.to});

  bool get hasDateRange => from != null || to != null;
  bool get isEmpty => !hasDateRange;

  PaymentFilter copyWith({
    DateTime? from,
    DateTime? to,
    bool clearDateRange = false,
  }) {
    return PaymentFilter(
      from: clearDateRange ? null : (from ?? this.from),
      to: clearDateRange ? null : (to ?? this.to),
    );
  }
}

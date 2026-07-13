import 'package:flutter/material.dart';
import '../models/fee_status.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final FeeStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status.label),
      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
      backgroundColor: status.color,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

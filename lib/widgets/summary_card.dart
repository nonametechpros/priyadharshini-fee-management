import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accentColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.brandRed;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

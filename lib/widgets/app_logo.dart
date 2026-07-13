import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 88, this.borderRadius = 20});

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        'assets/images/logo.jpg',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

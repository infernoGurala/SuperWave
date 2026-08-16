import 'package:flutter/material.dart';

/// App Logo widget rendering the exact high-resolution leaf logo asset.
class LeafLogo extends StatelessWidget {
  final double size;
  final bool isCircle;
  final double? borderRadius;

  const LeafLogo({
    super.key,
    this.size = 42,
    this.isCircle = true,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final double effectiveRadius = borderRadius ?? (isCircle ? size / 2 : 12);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(effectiveRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/app_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

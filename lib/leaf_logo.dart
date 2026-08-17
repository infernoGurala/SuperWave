import 'package:flutter/material.dart';
import 'theme/claude_theme.dart';

/// App Logo widget rendering the logo in a Claude Desktop-styled badge.
class LeafLogo extends StatelessWidget {
  final double size;
  final bool isCircle;
  final double? borderRadius;

  const LeafLogo({
    super.key,
    this.size = 36,
    this.isCircle = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final double effectiveRadius = borderRadius ?? (isCircle ? size / 2 : 10);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ClaudeTheme.bgElevated,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(effectiveRadius),
        border: Border.all(
          color: ClaudeTheme.accent.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius - 1),
        child: Padding(
          padding: EdgeInsets.all(size * 0.12),
          child: Image.asset(
            'assets/images/app_logo.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

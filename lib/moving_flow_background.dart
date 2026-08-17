import 'package:flutter/material.dart';
import 'theme/claude_theme.dart';

/// Minimalist canvas background matching the Claude Desktop aesthetic.
/// Distraction-free, clean matte dark surface with subtle warm vignette.
class MovingFlowBackground extends StatelessWidget {
  final Widget? child;

  const MovingFlowBackground({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ClaudeTheme.bgCanvas,
        gradient: RadialGradient(
          center: const Alignment(0.0, -0.6),
          radius: 1.4,
          colors: [
            const Color(0xFF1E1D1A), // Subtle warm ambient center
            ClaudeTheme.bgCanvas,
          ],
        ),
      ),
      child: child,
    );
  }
}

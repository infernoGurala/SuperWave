import 'dart:math';
import 'package:flutter/material.dart';

/// Animated flow background with rich, saturated colors that give
/// liquid glass something vivid to refract and blur.
///
/// The key insight: liquid glass needs HIGH CONTRAST and SATURATED
/// color behind it. Pastels on white just produce a white panel.
class MovingFlowBackground extends StatefulWidget {
  final Widget? child;

  const MovingFlowBackground({super.key, this.child});

  @override
  State<MovingFlowBackground> createState() => _MovingFlowBackgroundState();
}

class _MovingFlowBackgroundState extends State<MovingFlowBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Bold, saturated palette — the glass needs real color to refract
    const deepTeal = Color(0xFF0D9488);
    const emerald = Color(0xFF059669);
    const sky = Color(0xFF0EA5E9);
    const lime = Color(0xFF65A30D);
    const amber = Color(0xFFF59E0B);

    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, _) {
        final value = _gradientController.value;
        final dx1 = cos(value * 2 * pi);
        final dy1 = sin(value * 2 * pi);
        final dx2 = sin(value * 2 * pi);
        final dy2 = cos(value * 2 * pi);

        return Container(
          // A warm off-white base — not pure white
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFECFDF5), // mint-50
                Color(0xFFF0FDFA), // teal-50
                Color(0xFFECFDF5), // mint-50
              ],
            ),
          ),
          child: Stack(
            children: [
              // ── Large bold blobs with high opacity ──

              // Top-left: deep teal wash
              Positioned(
                top: -180 + dy1 * 90,
                left: -160 + dx1 * 90,
                width: 600,
                height: 600,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      stops: const [0.0, 0.4, 0.8],
                      colors: [
                        deepTeal.withValues(alpha: 0.55),
                        deepTeal.withValues(alpha: 0.25),
                        deepTeal.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom-right: emerald counter-blob
              Positioned(
                bottom: -180 + dy2 * 80,
                right: -180 + dx2 * 80,
                width: 600,
                height: 600,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      stops: const [0.0, 0.4, 0.8],
                      colors: [
                        emerald.withValues(alpha: 0.50),
                        emerald.withValues(alpha: 0.20),
                        emerald.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Center-right: sky blue accent for contrast variety
              Positioned(
                top: 120 - dy1 * 50,
                right: -80 - dx2 * 50,
                width: 420,
                height: 420,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      stops: const [0.0, 0.45, 0.85],
                      colors: [
                        sky.withValues(alpha: 0.40),
                        sky.withValues(alpha: 0.15),
                        sky.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom-left: lime warmth
              Positioned(
                bottom: 30 + dy1 * 60,
                left: -120 + dx2 * 60,
                width: 500,
                height: 500,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      stops: const [0.0, 0.4, 0.8],
                      colors: [
                        lime.withValues(alpha: 0.40),
                        lime.withValues(alpha: 0.15),
                        lime.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Center-top: amber warmth for multi-hue glass refraction
              Positioned(
                top: 50 + dx1 * 40,
                left: 100 + dy2 * 40,
                width: 350,
                height: 350,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      stops: const [0.0, 0.45, 0.85],
                      colors: [
                        amber.withValues(alpha: 0.30),
                        amber.withValues(alpha: 0.10),
                        amber.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              if (widget.child != null) widget.child!,
            ],
          ),
        );
      },
    );
  }
}

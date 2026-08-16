import 'package:flutter/material.dart';

/// Flow background with rich, saturated colors that give
/// liquid glass something vivid to refract and blur.
///
/// Static background with no bouncing or floating animations.
class MovingFlowBackground extends StatelessWidget {
  final Widget? child;

  const MovingFlowBackground({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    // Bold, saturated palette — the glass needs real color to refract
    const deepTeal = Color(0xFF0D9488);
    const emerald = Color(0xFF059669);
    const sky = Color(0xFF0EA5E9);
    const lime = Color(0xFF65A30D);
    const amber = Color(0xFFF59E0B);

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
          // ── Large bold blobs with high opacity (static positions) ──

          // Top-left: deep teal wash
          Positioned(
            top: -140,
            left: -120,
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
            bottom: -140,
            right: -140,
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
            top: 120,
            right: -60,
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
            bottom: 30,
            left: -100,
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
            top: 50,
            left: 100,
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

          ?child,
        ],
      ),
    );
  }
}

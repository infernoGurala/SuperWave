import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

/// A sidebar built on a single LiquidGlassLens surface.
///
/// The lens IS the glass. Near-zero tint, moderate blur, strong refraction
/// so the vivid background shows through as a frosted, distorted image —
/// the hallmark of real liquid glass.
class GlassSidebar extends StatefulWidget {
  const GlassSidebar({super.key});

  @override
  State<GlassSidebar> createState() => _GlassSidebarState();
}

class _GlassSidebarState extends State<GlassSidebar> {
  int _selectedIndex = 0;

  final List<_NavItemData> _navItems = const [
    _NavItemData(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    _NavItemData(icon: Icons.search_rounded, activeIcon: Icons.search_rounded, label: 'Search'),
    _NavItemData(icon: Icons.copy_rounded, activeIcon: Icons.copy_rounded, label: 'Library'),
    _NavItemData(icon: Icons.verified_outlined, activeIcon: Icons.verified_rounded, label: 'Badges'),
    _NavItemData(icon: Icons.notifications_none_rounded, activeIcon: Icons.notifications_rounded, label: 'Notifications', hasBadge: true),
    _NavItemData(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    // Outer container provides only the ambient drop-shadow for float.
    return Container(
      width: 76,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.14),
            blurRadius: 32,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // ── The one true glass surface ──
      child: LiquidGlassLens(
        style: const LiquidGlassStyle(
          shape: LiquidGlassShape.continuousRoundedRectangle(
            cornerRadius: 30,
            borderWidth: 1.4,
            lightIntensity: 2.2,
            lightDirection: 1.1,
            borderType: OpticalBorder(
              ambientIntensity: 2.0,
              borderSaturation: 1.8,
              borderSolidity: 0.3,
            ),
          ),
          refraction: LiquidGlassRefraction(
            distortion: 0.16,
            distortionWidth: 34,
            magnification: 1.04,
            chromaticAberration: 0.006,
          ),
          appearance: LiquidGlassAppearance(
            // NEAR-ZERO tint — the glass should be almost fully transparent
            // with only blur + refraction creating the glass feel.
            // The background colors must show through.
            color: Color(0x14FFFFFF),
            blur: LiquidGlassBlur(
              sigmaX: 8,
              sigmaY: 8,
            ),
            saturation: 1.2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── 1. macOS Traffic Light Dots ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildWindowDot(const Color(0xFFFF5F57)),
                  const SizedBox(width: 6),
                  _buildWindowDot(const Color(0xFFFEBC2E)),
                  const SizedBox(width: 6),
                  _buildWindowDot(const Color(0xFF28C840)),
                ],
              ),

              const SizedBox(height: 16),

              // ── 2. App Logo ──
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB954),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1DB954).withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    color: Colors.black,
                    size: 22,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── 3. Navigation Items ──
              Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_navItems.length, (index) {
                  final item = _navItems[index];
                  final isSelected = _selectedIndex == index;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: InkWell(
                      onTap: () => setState(() => _selectedIndex = index),
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 40,
                        width: 76,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Active tab — very translucent pill
                            if (isSelected)
                              Positioned.fill(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.40),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Left indicator pill
                            if (isSelected)
                              Positioned(
                                left: 2,
                                child: Container(
                                  width: 3,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: const Color(0xE6181A20),
                                    borderRadius: BorderRadius.circular(1.5),
                                  ),
                                ),
                              ),

                            // Icon
                            Icon(
                              isSelected ? item.activeIcon : item.icon,
                              color: isSelected
                                  ? const Color(0xFF181A20)
                                  : const Color(0xFF181A20).withValues(alpha: 0.50),
                              size: 20,
                            ),

                            // Notification badge dot
                            if (item.hasBadge)
                              Positioned(
                                top: 9,
                                right: 18,
                                child: Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF181A20),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              // ── 4. Play Button ──
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.40),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Color(0xFF181A20),
                    size: 22,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── 5. Device Button ──
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 0.6,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.speaker_group_outlined,
                    color: Color(0xFF181A20),
                    size: 16,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── 6. User Avatar ──
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.60),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWindowDot(Color color) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool hasBadge;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.hasBadge = false,
  });
}

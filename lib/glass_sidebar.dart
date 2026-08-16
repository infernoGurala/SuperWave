import 'dart:ui';
import 'package:flutter/material.dart';

/// Glass sidebar rendered with the exact Utopia app navigation bar material:
/// - 28px Sigma BackdropFilter blur
/// - Multi-layer shadow (depth shadow + soft ambient + top bevel light)
/// - Translucent tinted surface with white/light rim border (0.8 width)
/// - Inner gloss specular highlight gradient at the top
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
    _NavItemData(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const surfaceColor = Color(0xFFF2F1EC);
    const darkSurfaceColor = Color(0xFF140C1F);
    const borderRadius = BorderRadius.all(Radius.circular(32));

    return Container(
      width: 76,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.16),
            blurRadius: 28,
            offset: const Offset(0, 10),
            spreadRadius: -2,
          ),
          if (!isDark) ...[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.5),
              blurRadius: 1,
              offset: const Offset(0, -0.5),
            ),
          ],
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? darkSurfaceColor.withValues(alpha: 0.55)
                  : surfaceColor.withValues(alpha: 0.65),
              borderRadius: borderRadius,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.6),
                width: 0.8,
              ),
            ),
            child: Stack(
              children: [
                // Inner gloss highlight from Utopia nav bar material
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 32,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: isDark ? 0.06 : 0.25),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),

                // Navigation Items
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_navItems.length, (index) {
                      final item = _navItems[index];
                      final isSelected = _selectedIndex == index;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: InkWell(
                          onTap: () => setState(() => _selectedIndex = index),
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: 44,
                            width: 76,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Icon + Active dot
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 200),
                                      child: Icon(
                                        isSelected ? item.activeIcon : item.icon,
                                        key: ValueKey(isSelected),
                                        color: isSelected
                                            ? (isDark ? Colors.white : const Color(0xFF181A20))
                                            : (isDark
                                                ? Colors.white.withValues(alpha: 0.35)
                                                : const Color(0xFF181A20).withValues(alpha: 0.40)),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    // Active indicator dot
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOutCubic,
                                      width: isSelected ? 4 : 0,
                                      height: isSelected ? 4 : 0,
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white : const Color(0xFF181A20),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

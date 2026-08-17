import 'dart:ui';
import 'package:flutter/material.dart';
import 'theme/claude_theme.dart';

/// Floating capsule navigation dock ("flotion bar") with fluid hover expansion.
/// Default: Compact 56px capsule pill with centered icons & active indicator dot.
/// On Hover: Fluidly expands into a 180px rounded rectangular brick displaying tab names.
class GlassSidebar extends StatefulWidget {
  final int? selectedIndex;
  final ValueChanged<int>? onItemSelected;
  final VoidCallback? onHomeRoot;
  final String? vaultPath;
  final int totalNotes;
  final int totalFolders;
  final VoidCallback? onOpenVault;
  final bool isCollapsed;
  final ValueChanged<bool>? onCollapseChanged;

  const GlassSidebar({
    super.key,
    this.selectedIndex,
    this.onItemSelected,
    this.onHomeRoot,
    this.vaultPath,
    this.totalNotes = 0,
    this.totalFolders = 0,
    this.onOpenVault,
    this.isCollapsed = false,
    this.onCollapseChanged,
  });

  @override
  State<GlassSidebar> createState() => _GlassSidebarState();
}

class _GlassSidebarState extends State<GlassSidebar> with SingleTickerProviderStateMixin {
  int _localIndex = 0;
  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;

  int get _selectedIndex => widget.selectedIndex ?? _localIndex;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 190),
      reverseDuration: const Duration(milliseconds: 170),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    if (widget.selectedIndex == null) {
      setState(() => _localIndex = index);
    }
    widget.onItemSelected?.call(index);
    if (index == 0) {
      widget.onHomeRoot?.call();
    }
  }

  final List<_FloatingNavItem> _items = const [
    _FloatingNavItem(
      icon: Icons.home_rounded,
      label: 'Home',
    ),
    _FloatingNavItem(
      icon: Icons.settings_rounded,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _expandController.forward(),
      onExit: (_) => _expandController.reverse(),
      child: AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          final t = _expandAnimation.value;
          final double barWidth = lerpDouble(56.0, 180.0, t)!;
          final double radius = lerpDouble(28.0, 20.0, t)!;
          final borderRadius = BorderRadius.circular(radius);

          return Container(
            width: barWidth,
            margin: const EdgeInsets.fromLTRB(14, 18, 14, 18),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: lerpDouble(0.50, 0.65, t)!),
                  blurRadius: lerpDouble(22, 30, t)!,
                  offset: const Offset(0, 8),
                  spreadRadius: lerpDouble(-2, 1, t)!,
                ),
                if (t > 0.0)
                  BoxShadow(
                    color: ClaudeTheme.accent.withValues(alpha: 0.12 * t),
                    blurRadius: 18 * t,
                    spreadRadius: 0.5 * t,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: Container(
                  width: barWidth,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        ClaudeTheme.bgSurface,
                        ClaudeTheme.bgSidebar,
                        ClaudeTheme.bgCanvas,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    borderRadius: borderRadius,
                    border: Border.all(
                      color: ClaudeTheme.borderHover.withValues(
                        alpha: lerpDouble(0.60, 0.85, t)!,
                      ),
                      width: 1.0,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Specular top highlight
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 32,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(radius),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.10),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Navigation Tabs Column
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < _items.length; i++) ...[
                              _FloatingTabButton(
                                item: _items[i],
                                isSelected: _selectedIndex == i,
                                expandProgress: t,
                                onTap: () => _handleTap(i),
                              ),
                              if (i < _items.length - 1) const SizedBox(height: 3),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FloatingTabButton extends StatefulWidget {
  final _FloatingNavItem item;
  final bool isSelected;
  final double expandProgress;
  final VoidCallback onTap;

  const _FloatingTabButton({
    required this.item,
    required this.isSelected,
    required this.expandProgress,
    required this.onTap,
  });

  @override
  State<_FloatingTabButton> createState() => _FloatingTabButtonState();
}

class _FloatingTabButtonState extends State<_FloatingTabButton> {
  bool _isButtonHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final t = widget.expandProgress;

    final iconColor = isSelected
        ? ClaudeTheme.accent
        : (_isButtonHovered ? ClaudeTheme.textPrimary : ClaudeTheme.textSecondary);

    final textColor = isSelected
        ? ClaudeTheme.textPrimary
        : (_isButtonHovered ? ClaudeTheme.textPrimary : ClaudeTheme.textSecondary);

    return Tooltip(
      message: t > 0.5 ? '' : widget.item.label,
      waitDuration: const Duration(milliseconds: 300),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isButtonHovered = true),
        onExit: (_) => setState(() => _isButtonHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: 44,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: 170,
                maxWidth: 170,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Row(
                      children: [
                        // Centered Icon Anchor Container (Keeps icon exactly in geometric center of 56px capsule)
                        SizedBox(
                          width: 54,
                          height: 44,
                          child: Center(
                            child: Icon(
                              widget.item.icon,
                              size: 20,
                              color: iconColor,
                            ),
                          ),
                        ),
                        // Label text with fluid slide-fade synchronized to controller
                        Opacity(
                          opacity: t.clamp(0.0, 1.0),
                          child: Text(
                            widget.item.label,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: textColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Active indicator dot centered beneath icon when collapsed
                    Positioned(
                      left: 0,
                      width: 54,
                      bottom: 3,
                      child: Opacity(
                        opacity: isSelected ? (1.0 - t).clamp(0.0, 1.0) : 0.0,
                        child: Center(
                          child: Container(
                            width: 4.5,
                            height: 4.5,
                            decoration: BoxDecoration(
                              color: ClaudeTheme.accent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: ClaudeTheme.accent.withValues(alpha: 0.8),
                                  blurRadius: 4,
                                  spreadRadius: 0.5,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingNavItem {
  final IconData icon;
  final String label;

  const _FloatingNavItem({
    required this.icon,
    required this.label,
  });
}

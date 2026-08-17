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

class _GlassSidebarState extends State<GlassSidebar> {
  int _localIndex = 0;
  bool _isHovered = false;

  int get _selectedIndex => widget.selectedIndex ?? _localIndex;

  void _handleTap(int index) {
    if (widget.selectedIndex == null) {
      setState(() => _localIndex = index);
    }
    widget.onItemSelected?.call(index);
  }

  final List<_FloatingNavItem> _items = const [
    _FloatingNavItem(
      icon: Icons.home_rounded,
      label: 'Home',
    ),
    _FloatingNavItem(
      icon: Icons.search_rounded,
      label: 'Search',
    ),
    _FloatingNavItem(
      icon: Icons.settings_rounded,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final double barWidth = _isHovered ? 180.0 : 56.0;
    final borderRadius = BorderRadius.circular(_isHovered ? 20.0 : 28.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: const Cubic(0.2, 0.0, 0.0, 1.0),
        width: barWidth,
        margin: const EdgeInsets.fromLTRB(14, 18, 14, 18),
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.65 : 0.50),
              blurRadius: _isHovered ? 30 : 22,
              offset: const Offset(0, 8),
              spreadRadius: _isHovered ? 1 : -2,
            ),
            if (_isHovered)
              BoxShadow(
                color: ClaudeTheme.accent.withValues(alpha: 0.06),
                blurRadius: 18,
                spreadRadius: 0.5,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: const Cubic(0.2, 0.0, 0.0, 1.0),
              width: barWidth,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF262421),
                    Color(0xFF191816),
                    Color(0xFF121110),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
                borderRadius: borderRadius,
                border: Border.all(
                  color: const Color(0xFF3D3A34).withValues(alpha: _isHovered ? 0.90 : 0.70),
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: const Cubic(0.2, 0.0, 0.0, 1.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(_isHovered ? 20.0 : 28.0),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.12),
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
                            isExpanded: _isHovered,
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
      ),
    );
  }
}

class _FloatingTabButton extends StatefulWidget {
  final _FloatingNavItem item;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;

  const _FloatingTabButton({
    required this.item,
    required this.isSelected,
    required this.isExpanded,
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
    final isExpanded = widget.isExpanded;

    final iconColor = isSelected
        ? (isExpanded ? ClaudeTheme.accent : Colors.white)
        : (_isButtonHovered ? const Color(0xFFECEBE6) : const Color(0xFF8E8B82));

    final textColor = isSelected
        ? Colors.white
        : (_isButtonHovered ? const Color(0xFFECEBE6) : const Color(0xFFA8A59C));

    return Tooltip(
      message: isExpanded ? '' : widget.item.label,
      waitDuration: const Duration(milliseconds: 300),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isButtonHovered = true),
        onExit: (_) => setState(() => _isButtonHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: isExpanded
                  ? (isSelected
                      ? ClaudeTheme.accent.withValues(alpha: 0.14)
                      : (_isButtonHovered ? Colors.white.withValues(alpha: 0.05) : Colors.transparent))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isExpanded && isSelected
                  ? Border.all(
                      color: ClaudeTheme.accent.withValues(alpha: 0.32),
                      width: 1.0,
                    )
                  : Border.all(color: Colors.transparent, width: 1.0),
            ),
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
                        // Centered 46px Icon Anchor Container (Keeps icon exactly in place)
                        SizedBox(
                          width: 46,
                          height: 44,
                          child: Center(
                            child: Icon(
                              widget.item.icon,
                              size: 20,
                              color: iconColor,
                            ),
                          ),
                        ),
                        // Label text with fluid slide-fade
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          opacity: isExpanded ? 1.0 : 0.0,
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
                      width: 46,
                      bottom: 3,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        opacity: (!isExpanded && isSelected) ? 1.0 : 0.0,
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

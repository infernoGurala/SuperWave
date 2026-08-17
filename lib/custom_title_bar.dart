import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'theme/claude_theme.dart';

/// Custom Frameless Titlebar matching the Claude Desktop client.
/// Provides drag-to-move, maximize on double-click, and custom minimize / maximize / close window controls.
class CustomTitleBar extends StatefulWidget {
  final String? vaultName;
  final Widget? leading;
  final Widget? trailing;

  const CustomTitleBar({
    super.key,
    this.vaultName,
    this.leading,
    this.trailing,
  });

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> with WindowListener {
  bool _isMaximized = false;

  bool get _isDesktopPlatform {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  @override
  void initState() {
    super.initState();
    if (_isDesktopPlatform) {
      windowManager.addListener(this);
      _checkMaximized();
    }
  }

  @override
  void dispose() {
    if (_isDesktopPlatform) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _checkMaximized() async {
    try {
      final maximized = await windowManager.isMaximized();
      if (mounted) setState(() => _isMaximized = maximized);
    } catch (_) {}
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: ClaudeTheme.bgSidebar,
        border: Border(
          bottom: BorderSide(color: ClaudeTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Left section (Logo + App Name + Optional leading widget)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: ClaudeTheme.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'SuperWave',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: ClaudeTheme.textPrimary,
                  ),
                ),
                if (widget.vaultName != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: ClaudeTheme.bgCard,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: ClaudeTheme.border, width: 0.8),
                    ),
                    child: Text(
                      widget.vaultName!,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontFamily: 'monospace',
                        color: ClaudeTheme.textTertiary,
                      ),
                    ),
                  ),
                ],
                if (widget.leading != null) ...[
                  const SizedBox(width: 12),
                  widget.leading!,
                ],
              ],
            ),
          ),

          // Center: Drag to Move Window Area
          Expanded(
            child: _isDesktopPlatform
                ? const DragToMoveArea(
                    child: SizedBox(height: double.infinity),
                  )
                : const SizedBox(height: double.infinity),
          ),

          if (widget.trailing != null) widget.trailing!,

          // Right: Window Action Buttons (Minimize, Maximize, Close)
          if (_isDesktopPlatform) ...[
            _WindowButton(
              icon: Icons.horizontal_rule_rounded,
              tooltip: 'Minimize',
              iconSize: 13,
              onTap: () async {
                try {
                  await windowManager.minimize();
                } catch (_) {}
              },
            ),
            _WindowButton(
              icon: _isMaximized
                  ? Icons.filter_none_rounded
                  : Icons.crop_square_rounded,
              tooltip: _isMaximized ? 'Restore Down' : 'Maximize',
              iconSize: 12,
              onTap: () async {
                try {
                  if (await windowManager.isMaximized()) {
                    await windowManager.unmaximize();
                  } else {
                    await windowManager.maximize();
                  }
                } catch (_) {}
              },
            ),
            _WindowButton(
              icon: Icons.close_rounded,
              tooltip: 'Close',
              isCloseButton: true,
              iconSize: 14,
              onTap: () async {
                try {
                  await windowManager.close();
                } catch (_) {}
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final double iconSize;
  final bool isCloseButton;
  final VoidCallback onTap;

  const _WindowButton({
    required this.icon,
    required this.tooltip,
    this.iconSize = 13,
    this.isCloseButton = false,
    required this.onTap,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color iconColor;

    if (widget.isCloseButton) {
      bg = _isHovered ? ClaudeTheme.crimson : Colors.transparent;
      iconColor = _isHovered ? Colors.white : ClaudeTheme.textSecondary;
    } else {
      bg = _isHovered ? ClaudeTheme.bgCardHover : Colors.transparent;
      iconColor = _isHovered ? ClaudeTheme.textPrimary : ClaudeTheme.textSecondary;
    }

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 44,
            height: 38,
            alignment: Alignment.center,
            color: bg,
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

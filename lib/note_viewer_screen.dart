import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:path/path.dart' as p;
import 'settings_screen.dart';
import 'theme/claude_theme.dart';

/// Full-screen / Artifact-style Markdown Note Viewer matching Claude Desktop.
/// Focuses on calm typography, high legibility, reading stats, and clean actions.
class NoteViewerScreen extends StatefulWidget {
  final String filePath;
  final String? vaultPath;
  final AppShortcut? parentFolderShortcut;
  final AppShortcut? homeRootShortcut;

  const NoteViewerScreen({
    super.key,
    required this.filePath,
    this.vaultPath,
    this.parentFolderShortcut,
    this.homeRootShortcut,
  });

  @override
  State<NoteViewerScreen> createState() => _NoteViewerScreenState();
}

class _NoteViewerScreenState extends State<NoteViewerScreen> {
  String? _content;
  String? _error;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        setState(() => _error = 'Note file no longer exists on disk.');
        return;
      }
      final content = await file.readAsString();
      if (!mounted) return;
      setState(() {
        _content = content;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to read note: $e');
    }
  }

  void _returnToParentFolder() {
    final parentDir = p.dirname(widget.filePath);
    Navigator.of(context).pop(parentDir);
  }

  void _returnToRoot() {
    Navigator.of(context).pop('__ROOT__');
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isControl = HardwareKeyboard.instance.isControlPressed;
    final isAlt = HardwareKeyboard.instance.isAltPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;
    final isMeta = HardwareKeyboard.instance.isMetaPressed;
    final key = event.logicalKey;

    // 1. Parent folder shortcut
    if (widget.parentFolderShortcut != null) {
      final s = widget.parentFolderShortcut!;
      if (key == s.trigger &&
          s.control == isControl &&
          s.alt == isAlt &&
          s.shift == isShift &&
          s.meta == isMeta) {
        _returnToParentFolder();
        return KeyEventResult.handled;
      }
    }

    // Default Alt+Left fallback
    if (isAlt && key == LogicalKeyboardKey.arrowLeft) {
      _returnToParentFolder();
      return KeyEventResult.handled;
    }

    // 2. Escape key navigates to parent folder
    if (key == LogicalKeyboardKey.escape) {
      _returnToParentFolder();
      return KeyEventResult.handled;
    }

    // 3. Home Root shortcut (Default Ctrl+Space)
    if (widget.homeRootShortcut != null) {
      final s = widget.homeRootShortcut!;
      if (key == s.trigger &&
          s.control == isControl &&
          s.alt == isAlt &&
          s.shift == isShift &&
          s.meta == isMeta) {
        _returnToRoot();
        return KeyEventResult.handled;
      }
    }

    if (isControl && key == LogicalKeyboardKey.space) {
      _returnToRoot();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _copyToClipboard() {
    if (_content == null) return;
    Clipboard.setData(ClipboardData(text: _content!));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  int _getWordCount(String text) {
    return text.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
  }

  int _getReadingTime(int words) {
    return (words / 200).ceil().clamp(1, 999);
  }

  MarkdownStyleSheet _buildClaudeStyleSheet() {
    return MarkdownStyleSheet(
      p: TextStyle(
        fontSize: 15,
        height: 1.7,
        color: ClaudeTheme.textPrimary,
      ),
      h1: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: ClaudeTheme.textPrimary,
      ),
      h1Padding: const EdgeInsets.only(top: 24, bottom: 10),
      h2: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: ClaudeTheme.accent,
      ),
      h2Padding: const EdgeInsets.only(top: 20, bottom: 8),
      h3: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: ClaudeTheme.amber,
      ),
      h3Padding: const EdgeInsets.only(top: 16, bottom: 6),
      h4: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: ClaudeTheme.textPrimary,
      ),
      h5: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ClaudeTheme.textSecondary,
      ),
      h6: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: ClaudeTheme.textTertiary,
      ),
      strong: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      em: TextStyle(
        fontStyle: FontStyle.italic,
        color: ClaudeTheme.amber,
      ),
      del: TextStyle(
        color: ClaudeTheme.textTertiary,
        decoration: TextDecoration.lineThrough,
      ),
      a: TextStyle(
        color: ClaudeTheme.accent,
        decoration: TextDecoration.underline,
        decorationColor: ClaudeTheme.accent,
      ),
      code: TextStyle(
        fontFamily: 'Consolas',
        fontSize: 13,
        color: ClaudeTheme.accentHover,
        backgroundColor: ClaudeTheme.bgCode,
      ),
      codeblockDecoration: BoxDecoration(
        color: ClaudeTheme.bgCode,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ClaudeTheme.border, width: 1),
      ),
      codeblockPadding: const EdgeInsets.all(16),
      blockquote: TextStyle(
        fontSize: 14.5,
        fontStyle: FontStyle.italic,
        height: 1.6,
        color: ClaudeTheme.textSecondary,
      ),
      blockquoteDecoration: BoxDecoration(
        color: ClaudeTheme.bgCard,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: Border(
          left: BorderSide(color: ClaudeTheme.accent, width: 3),
        ),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      listBullet: TextStyle(
        fontSize: 15,
        color: ClaudeTheme.accent,
        fontWeight: FontWeight.w700,
      ),
      listBulletPadding: const EdgeInsets.only(right: 10),
      listIndent: 22,
      tableHead: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: ClaudeTheme.textPrimary,
      ),
      tableBody: TextStyle(
        fontSize: 13.5,
        color: ClaudeTheme.textSecondary,
      ),
      tableBorder: TableBorder.all(
        color: ClaudeTheme.border,
        width: 1,
      ),
      tableCellsPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      tableHeadCellsDecoration: BoxDecoration(
        color: ClaudeTheme.bgElevated,
      ),
      tableCellsDecoration: BoxDecoration(
        color: ClaudeTheme.bgCard,
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: ClaudeTheme.border, width: 1),
        ),
      ),
    );
  }

  List<_NoteBreadcrumbItem> _buildBreadcrumbItems() {
    final List<_NoteBreadcrumbItem> items = [];
    final vPath = widget.vaultPath;
    final fPath = widget.filePath;

    if (vPath != null && p.isWithin(vPath, fPath)) {
      final vaultName = p.basename(vPath);
      items.add(
        _NoteBreadcrumbItem(
          label: vaultName,
          targetPath: '__ROOT__',
          icon: Icons.shield_outlined,
        ),
      );

      final relPath = p.relative(fPath, from: vPath);
      final parts = p.split(relPath);

      var currentAccumPath = vPath;
      for (int i = 0; i < parts.length - 1; i++) {
        currentAccumPath = p.join(currentAccumPath, parts[i]);
        items.add(
          _NoteBreadcrumbItem(
            label: parts[i],
            targetPath: currentAccumPath,
            icon: Icons.folder_outlined,
          ),
        );
      }

      items.add(
        _NoteBreadcrumbItem(
          label: parts.last,
          targetPath: null,
          icon: Icons.article_outlined,
          isActive: true,
        ),
      );
    } else {
      final parentDir = p.dirname(fPath);
      items.add(
        _NoteBreadcrumbItem(
          label: p.basename(parentDir),
          targetPath: parentDir,
          icon: Icons.folder_outlined,
        ),
      );
      items.add(
        _NoteBreadcrumbItem(
          label: p.basename(fPath),
          targetPath: null,
          icon: Icons.article_outlined,
          isActive: true,
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final breadcrumbItems = _buildBreadcrumbItems();
    final words = _content != null ? _getWordCount(_content!) : 0;
    final readingTime = _getReadingTime(words);

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: ClaudeTheme.bgCanvas,
        body: SafeArea(
          child: Column(
            children: [
              // ── Claude Artifact Top Navigation Bar ──
              Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: ClaudeTheme.bgSidebar,
                  border: Border(
                    bottom: BorderSide(color: ClaudeTheme.border, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back to Folder (Alt+Left / Esc)',
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: ClaudeTheme.textSecondary,
                      ),
                      onPressed: _returnToParentFolder,
                    ),
                    const SizedBox(width: 8),

                    // Breadcrumbs
                    Expanded(
                      child: ClipRect(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (int i = 0; i < breadcrumbItems.length; i++) ...[
                                if (i > 0)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Icon(
                                      Icons.chevron_right_rounded,
                                      size: 15,
                                      color: ClaudeTheme.textTertiary,
                                    ),
                                  ),
                                _ViewerBreadcrumbSegment(
                                  item: breadcrumbItems[i],
                                  onTap: breadcrumbItems[i].targetPath != null
                                      ? () => Navigator.of(context).pop(breadcrumbItems[i].targetPath)
                                      : null,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Metadata Pills
                    if (_content != null) ...[
                      _buildMetaPill(
                        Icons.article_outlined,
                        '$words words',
                      ),
                      const SizedBox(width: 8),
                      _buildMetaPill(
                        Icons.schedule_rounded,
                        '$readingTime min read',
                      ),
                      const SizedBox(width: 12),
                    ],

                    // Copy Action
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _copied ? ClaudeTheme.sage : ClaudeTheme.textPrimary,
                        side: BorderSide(
                          color: _copied
                              ? ClaudeTheme.sage.withValues(alpha: 0.5)
                              : ClaudeTheme.border,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _content == null ? null : _copyToClipboard,
                      icon: Icon(
                        _copied ? Icons.check_rounded : Icons.copy_rounded,
                        size: 14,
                        color: _copied ? ClaudeTheme.sage : ClaudeTheme.textSecondary,
                      ),
                      label: Text(
                        _copied ? 'Copied' : 'Copy',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Reading Content Area ──
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: ClaudeTheme.crimson),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ClaudeTheme.crimson,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _returnToParentFolder,
                child: const Text('Return to Folder'),
              ),
            ],
          ),
        ),
      );
    }

    if (_content == null) {
      return Center(
        child: CircularProgressIndicator(
          color: ClaudeTheme.accent,
          strokeWidth: 2,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(48, 36, 48, 64),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: MarkdownBody(
            data: _content!,
            selectable: true,
            styleSheet: _buildClaudeStyleSheet(),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: ClaudeTheme.bgElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ClaudeTheme.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: ClaudeTheme.textTertiary),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: ClaudeTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBreadcrumbItem {
  final String label;
  final String? targetPath;
  final IconData icon;
  final bool isActive;

  const _NoteBreadcrumbItem({
    required this.label,
    required this.targetPath,
    required this.icon,
    this.isActive = false,
  });
}

class _ViewerBreadcrumbSegment extends StatefulWidget {
  final _NoteBreadcrumbItem item;
  final VoidCallback? onTap;

  const _ViewerBreadcrumbSegment({
    required this.item,
    this.onTap,
  });

  @override
  State<_ViewerBreadcrumbSegment> createState() => _ViewerBreadcrumbSegmentState();
}

class _ViewerBreadcrumbSegmentState extends State<_ViewerBreadcrumbSegment> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final clickable = widget.onTap != null;
    final isActive = widget.item.isActive;

    return Tooltip(
      message: clickable
          ? (widget.item.targetPath == '__ROOT__'
              ? 'Jump to Vault Root'
              : 'Jump to "${widget.item.label}"')
          : widget.item.label,
      child: MouseRegion(
        onEnter: clickable ? (_) => setState(() => _isHovered = true) : null,
        onExit: clickable ? (_) => setState(() => _isHovered = false) : null,
        cursor: clickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: _isHovered
                    ? Colors.white.withValues(alpha: 0.08)
                    : (isActive ? Colors.white.withValues(alpha: 0.04) : Colors.transparent),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.08)
                      : (_isHovered ? Colors.white.withValues(alpha: 0.12) : Colors.transparent),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.item.icon,
                    size: 14,
                    color: isActive
                        ? ClaudeTheme.accent
                        : (_isHovered ? ClaudeTheme.textPrimary : ClaudeTheme.textTertiary),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    widget.item.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? ClaudeTheme.textPrimary
                          : (_isHovered ? ClaudeTheme.textPrimary : ClaudeTheme.textSecondary),
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

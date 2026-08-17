import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as p;
import 'settings_screen.dart';
import 'theme/claude_theme.dart';
import 'theme/style_config_manager.dart';

class _HighlightSyntax extends md.InlineSyntax {
  _HighlightSyntax() : super(r'==([^=\n]+)==');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final rawText = match[1] ?? '';
    parser.addNode(md.Element.text('mark', rawText));
    return true;
  }
}

class _HighlightBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(
    md.Element element,
    TextStyle? preferredStyle,
  ) {
    final highlightColor = ClaudeTheme.renderColors.highlight;
    final baseStyle = preferredStyle ?? const TextStyle();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: highlightColor.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: highlightColor.withValues(alpha: 0.40),
          width: 0.8,
        ),
      ),
      child: Text(
        element.textContent,
        style: baseStyle.copyWith(
          color: highlightColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Full-screen / Artifact-style Markdown Note Viewer matching Claude Desktop.
/// Focuses on calm typography, high legibility, reading stats, and clean actions.
class NoteViewerScreen extends StatefulWidget {
  final String filePath;
  final String? vaultPath;
  final AppShortcut? parentFolderShortcut;
  final AppShortcut? homeRootShortcut;
  final ValueChanged<AppThemeId>? onThemeChanged;

  const NoteViewerScreen({
    super.key,
    required this.filePath,
    this.vaultPath,
    this.parentFolderShortcut,
    this.homeRootShortcut,
    this.onThemeChanged,
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
    final colors = ClaudeTheme.renderColors;
    final noteFont = ClaudeTheme.notesFont;
    final headingsFont = ClaudeTheme.headingsFont;
    final monoFont = ClaudeTheme.monospaceFont;

    return MarkdownStyleSheet(
      p: TextStyle(
        fontFamily: noteFont,
        fontSize: 15,
        height: 1.7,
        color: ClaudeTheme.textPrimary,
      ),
      h1: TextStyle(
        fontFamily: headingsFont,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: colors.h1,
      ),
      h1Padding: const EdgeInsets.only(top: 24, bottom: 10),
      h2: TextStyle(
        fontFamily: headingsFont,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: colors.h2,
      ),
      h2Padding: const EdgeInsets.only(top: 20, bottom: 8),
      h3: TextStyle(
        fontFamily: headingsFont,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: colors.h3,
      ),
      h3Padding: const EdgeInsets.only(top: 16, bottom: 6),
      h4: TextStyle(
        fontFamily: headingsFont,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: colors.h4,
      ),
      h5: TextStyle(
        fontFamily: headingsFont,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colors.h5,
      ),
      h6: TextStyle(
        fontFamily: headingsFont,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colors.h6,
      ),
      strong: TextStyle(
        fontFamily: noteFont,
        fontWeight: FontWeight.w700,
        color: colors.bold,
      ),
      em: TextStyle(
        fontFamily: noteFont,
        fontStyle: FontStyle.italic,
        color: colors.italic,
      ),
      del: TextStyle(
        fontFamily: noteFont,
        color: colors.strikethrough,
        decoration: TextDecoration.lineThrough,
      ),
      a: TextStyle(
        fontFamily: noteFont,
        color: colors.link,
        decoration: TextDecoration.underline,
        decorationColor: colors.link,
      ),
      code: TextStyle(
        fontFamily: monoFont,
        fontSize: 13,
        color: colors.inlineCode,
        backgroundColor: colors.codeBlockBg,
      ),
      codeblockDecoration: BoxDecoration(
        color: colors.codeBlockBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ClaudeTheme.border, width: 1),
      ),
      codeblockPadding: const EdgeInsets.all(16),
      blockquote: TextStyle(
        fontFamily: noteFont,
        fontSize: 14.5,
        fontStyle: FontStyle.italic,
        height: 1.6,
        color: colors.blockquoteText,
      ),
      blockquoteDecoration: BoxDecoration(
        color: ClaudeTheme.bgCard,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: Border(
          left: BorderSide(color: colors.blockquoteBorder, width: 3),
        ),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      listBullet: TextStyle(
        fontFamily: noteFont,
        fontSize: 15,
        color: colors.listBullet,
        fontWeight: FontWeight.w700,
      ),
      listBulletPadding: const EdgeInsets.only(right: 10),
      listIndent: 22,
      tableHead: TextStyle(
        fontFamily: headingsFont,
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: colors.tableHeader,
      ),
      tableBody: TextStyle(
        fontFamily: noteFont,
        fontSize: 13.5,
        color: colors.tableBody,
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
                      const SizedBox(width: 8),
                    ],

                    // Color Style & Theme Selector Button
                    _buildStyleSelectorButton(),
                    const SizedBox(width: 8),

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

  Widget _buildStyleSelectorButton() {
    return Tooltip(
      message: 'Customize Theme & Render Colors',
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: ClaudeTheme.textPrimary,
          side: BorderSide(
            color: ClaudeTheme.border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () => _showColorStyleSelectorDialog(context),
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: ClaudeTheme.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ClaudeTheme.accent.withValues(alpha: 0.6),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.palette_outlined,
              size: 14,
              color: ClaudeTheme.textSecondary,
            ),
          ],
        ),
        label: const Text(
          'Style',
          style: TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  void _showColorStyleSelectorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return _RenderStyleSelectorModal(
          vaultPath: widget.vaultPath,
          onThemeSelected: (themeId) {
            ClaudeTheme.setTheme(themeId);
            if (widget.vaultPath != null) {
              StyleConfigManager.saveThemeConfig(widget.vaultPath!, themeId);
            }
            widget.onThemeChanged?.call(themeId);
            setState(() {});
          },
          onRenderPresetSelected: (preset) {
            ClaudeTheme.setAllRenderOverrides(preset.overrides);
            if (widget.vaultPath != null) {
              StyleConfigManager.saveRenderConfig(
                widget.vaultPath!,
                ClaudeTheme.renderOverrides,
              );
            }
            setState(() {});
          },
          onResetRenderStyles: () {
            ClaudeTheme.resetAllRenderOverrides();
            if (widget.vaultPath != null) {
              StyleConfigManager.saveRenderConfig(
                widget.vaultPath!,
                ClaudeTheme.renderOverrides,
              );
            }
            setState(() {});
          },
        );
      },
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

    final noteTitle = p.basenameWithoutExtension(widget.filePath);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(48, 36, 48, 64),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Prominent Big Note Title ──
              SelectableText(
                noteTitle,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  height: 1.25,
                  color: ClaudeTheme.renderColors.h1,
                ),
              ),
              const SizedBox(height: 14),

              // ── Stylish Accent Divider Line ──
              Container(
                width: double.infinity,
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ClaudeTheme.accent.withValues(alpha: 0.65),
                      ClaudeTheme.border.withValues(alpha: 0.6),
                      ClaudeTheme.border.withValues(alpha: 0.1),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Rendered Markdown Content ──
              MarkdownBody(
                data: _content!,
                selectable: true,
                styleSheet: _buildClaudeStyleSheet(),
                inlineSyntaxes: [
                  _HighlightSyntax(),
                ],
                builders: {
                  'mark': _HighlightBuilder(),
                },
              ),
            ],
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

class _RenderColorPreset {
  final String name;
  final String description;
  final Color primary;
  final Color secondary;
  final Map<String, int> overrides;

  const _RenderColorPreset({
    required this.name,
    required this.description,
    required this.primary,
    required this.secondary,
    required this.overrides,
  });

  static const List<_RenderColorPreset> presets = [
    _RenderColorPreset(
      name: 'Terracotta Amber',
      description: 'Warm terracotta headings, glowing amber highlights and links',
      primary: Color(0xFFD97757),
      secondary: Color(0xFFD49B55),
      overrides: {
        'h1': 0xFFECEBE6,
        'h2': 0xFFD97757,
        'h3': 0xFFD49B55,
        'bold': 0xFFECEBE6,
        'italic': 0xFFD49B55,
        'link': 0xFFD97757,
        'highlight': 0xFFD49B55,
        'inlineCode': 0xFFE58B6D,
        'blockquoteBorder': 0xFFD97757,
        'listBullet': 0xFFD97757,
      },
    ),
    _RenderColorPreset(
      name: 'Obsidian Amethyst',
      description: 'Luminous lavender headers, vibrant purple highlights and violet accents',
      primary: Color(0xFFA78BFA),
      secondary: Color(0xFFC084FC),
      overrides: {
        'h1': 0xFFF5F3FF,
        'h2': 0xFFA78BFA,
        'h3': 0xFFC084FC,
        'bold': 0xFFFFFFFF,
        'italic': 0xFFC084FC,
        'link': 0xFFA78BFA,
        'highlight': 0xFFA855F7,
        'inlineCode': 0xFFC4B5FD,
        'blockquoteBorder': 0xFF8B5CF6,
        'listBullet': 0xFFA78BFA,
      },
    ),
    _RenderColorPreset(
      name: 'Forest Emerald',
      description: 'Calm jade emerald headings, soft sage highlights and mint links',
      primary: Color(0xFF34D399),
      secondary: Color(0xFFA7F3D0),
      overrides: {
        'h1': 0xFFECFDF5,
        'h2': 0xFF34D399,
        'h3': 0xFF6EE7B7,
        'bold': 0xFFF0FDF4,
        'italic': 0xFFA7F3D0,
        'link': 0xFF10B981,
        'highlight': 0xFF34D399,
        'inlineCode': 0xFF6EE7B7,
        'blockquoteBorder': 0xFF10B981,
        'listBullet': 0xFF34D399,
      },
    ),
    _RenderColorPreset(
      name: 'Nordic Frost Sky',
      description: 'Crisp glacial sky blue headings with cyan highlights and cool accents',
      primary: Color(0xFF38BDF8),
      secondary: Color(0xFF7DD3FC),
      overrides: {
        'h1': 0xFFF0F9FF,
        'h2': 0xFF38BDF8,
        'h3': 0xFF7DD3FC,
        'bold': 0xFFF8FAFC,
        'italic': 0xFFBAE6FD,
        'link': 0xFF0284C7,
        'highlight': 0xFF38BDF8,
        'inlineCode': 0xFF7DD3FC,
        'blockquoteBorder': 0xFF0EA5E9,
        'listBullet': 0xFF38BDF8,
      },
    ),
    _RenderColorPreset(
      name: 'Sunset Gold',
      description: 'Radiant amber gold headings with bright ochre accents and warm tones',
      primary: Color(0xFFF59E0B),
      secondary: Color(0xFFFDE68A),
      overrides: {
        'h1': 0xFFFFFBEB,
        'h2': 0xFFF59E0B,
        'h3': 0xFFFBBF24,
        'bold': 0xFFFEF3C7,
        'italic': 0xFFFDE68A,
        'link': 0xFFD97706,
        'highlight': 0xFFF59E0B,
        'inlineCode': 0xFFFBBF24,
        'blockquoteBorder': 0xFFD97706,
        'listBullet': 0xFFF59E0B,
      },
    ),
    _RenderColorPreset(
      name: 'Rose Coral',
      description: 'Vivid ruby coral headings, pastel pink highlights and bold accents',
      primary: Color(0xFFFB7185),
      secondary: Color(0xFFFDA4AF),
      overrides: {
        'h1': 0xFFFFF1F2,
        'h2': 0xFFFB7185,
        'h3': 0xFFFDA4AF,
        'bold': 0xFFFFE4E6,
        'italic': 0xFFFECDD3,
        'link': 0xFFE11D48,
        'highlight': 0xFFF43F5E,
        'inlineCode': 0xFFFDA4AF,
        'blockquoteBorder': 0xFFBE123C,
        'listBullet': 0xFFFB7185,
      },
    ),
    _RenderColorPreset(
      name: 'Monochrome Minimal',
      description: 'High-contrast clean white and slate gray palette for distraction-free reading',
      primary: Color(0xFFFFFFFF),
      secondary: Color(0xFF94A3B8),
      overrides: {
        'h1': 0xFFFFFFFF,
        'h2': 0xFFE2E8F0,
        'h3': 0xFFCBD5E1,
        'bold': 0xFFFFFFFF,
        'italic': 0xFF94A3B8,
        'link': 0xFFE2E8F0,
        'highlight': 0xFFCBD5E1,
        'inlineCode': 0xFFE2E8F0,
        'blockquoteBorder': 0xFF64748B,
        'listBullet': 0xFFE2E8F0,
      },
    ),
  ];
}

class _RenderStyleSelectorModal extends StatefulWidget {
  final String? vaultPath;
  final ValueChanged<AppThemeId> onThemeSelected;
  final ValueChanged<_RenderColorPreset> onRenderPresetSelected;
  final VoidCallback onResetRenderStyles;

  const _RenderStyleSelectorModal({
    required this.vaultPath,
    required this.onThemeSelected,
    required this.onRenderPresetSelected,
    required this.onResetRenderStyles,
  });

  @override
  State<_RenderStyleSelectorModal> createState() => _RenderStyleSelectorModalState();
}

class _RenderStyleSelectorModalState extends State<_RenderStyleSelectorModal> {
  int _activeTabIndex = 0; // 0 = Themes, 1 = Markdown Styles

  @override
  Widget build(BuildContext context) {
    final currentTheme = ClaudeTheme.current;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 660),
        child: Container(
          decoration: BoxDecoration(
            color: ClaudeTheme.bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClaudeTheme.borderHover, width: 1),
            boxShadow: ClaudeTheme.popupShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ClaudeTheme.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.palette_outlined,
                        size: 20,
                        color: ClaudeTheme.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Color Style & Themes',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: ClaudeTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Customize document theme and Markdown element render colors.',
                            style: TextStyle(
                              fontSize: 12,
                              color: ClaudeTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: ClaudeTheme.textSecondary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // ── Segmented Tab Switcher ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: ClaudeTheme.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ClaudeTheme.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabButton(
                          title: 'App Themes',
                          icon: Icons.auto_awesome_rounded,
                          index: 0,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildTabButton(
                          title: 'Markdown Colors',
                          icon: Icons.brush_outlined,
                          index: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Scrollable Tab Content ──
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: _activeTabIndex == 0
                      ? _buildThemesList(currentTheme)
                      : _buildRenderPresetsList(),
                ),
              ),

              // ── Bottom Action Footer ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: ClaudeTheme.bgSidebar,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  border: Border(
                    top: BorderSide(color: ClaudeTheme.border, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_activeTabIndex == 1)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: ClaudeTheme.textTertiary,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onPressed: () {
                          widget.onResetRenderStyles();
                          setState(() {});
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 14),
                        label: const Text(
                          'Reset to Theme Defaults',
                          style: TextStyle(fontSize: 12),
                        ),
                      )
                    else
                      Text(
                        'Changes apply live to note canvas',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: ClaudeTheme.textTertiary,
                        ),
                      ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: ClaudeTheme.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Done', style: TextStyle(fontSize: 12.5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required int index,
  }) {
    final isSelected = _activeTabIndex == index;
    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: () => setState(() => _activeTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? ClaudeTheme.accent.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isSelected ? ClaudeTheme.accent.withValues(alpha: 0.5) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? ClaudeTheme.accent : ClaudeTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? ClaudeTheme.textPrimary : ClaudeTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemesList(AppThemeData currentTheme) {
    return Column(
      children: [
        for (final theme in AppThemeData.allThemes) ...[
          _ViewerThemeCard(
            theme: theme,
            isSelected: currentTheme.id == theme.id,
            onSelect: () {
              widget.onThemeSelected(theme.id);
              setState(() {});
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildRenderPresetsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'SELECT A RENDER PALETTE PRESET',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: ClaudeTheme.textTertiary,
            ),
          ),
        ),
        for (final preset in _RenderColorPreset.presets) ...[
          _ViewerPresetCard(
            preset: preset,
            onSelect: () {
              widget.onRenderPresetSelected(preset);
              setState(() {});
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ViewerThemeCard extends StatefulWidget {
  final AppThemeData theme;
  final bool isSelected;
  final VoidCallback onSelect;

  const _ViewerThemeCard({
    required this.theme,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  State<_ViewerThemeCard> createState() => _ViewerThemeCardState();
}

class _ViewerThemeCardState extends State<_ViewerThemeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.theme.accent.withValues(alpha: 0.12)
                : (_isHovered ? ClaudeTheme.bgCardHover : ClaudeTheme.bgCard),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSelected
                  ? widget.theme.accent
                  : (_isHovered ? ClaudeTheme.borderHover : ClaudeTheme.border),
              width: widget.isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Theme icon / badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.theme.bgCanvas,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: widget.theme.border, width: 1),
                ),
                child: Center(
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: widget.theme.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Theme Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.theme.name,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: widget.isSelected ? widget.theme.accent : ClaudeTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.theme.description,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: ClaudeTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              // Color swatch dots
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final c in widget.theme.previewPalette.take(4))
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),

              // Selection Checkmark
              if (widget.isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: widget.theme.accent,
                )
              else
                Icon(
                  Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: ClaudeTheme.textTertiary.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewerPresetCard extends StatefulWidget {
  final _RenderColorPreset preset;
  final VoidCallback onSelect;

  const _ViewerPresetCard({
    required this.preset,
    required this.onSelect,
  });

  @override
  State<_ViewerPresetCard> createState() => _ViewerPresetCardState();
}

class _ViewerPresetCardState extends State<_ViewerPresetCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered ? ClaudeTheme.bgCardHover : ClaudeTheme.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered ? widget.preset.primary.withValues(alpha: 0.6) : ClaudeTheme.border,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Colored dual dot indicator
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: ClaudeTheme.bgCanvas,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ClaudeTheme.border, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.preset.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.preset.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Title & description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.preset.name,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: ClaudeTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.preset.description,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: ClaudeTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              // Apply indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.preset.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: widget.preset.primary.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  'Apply',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.preset.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

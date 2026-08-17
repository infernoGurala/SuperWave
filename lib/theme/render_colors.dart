import 'package:flutter/material.dart';
import 'claude_theme.dart';

/// Holds custom colors for each markdown rendering element.
///
/// Each theme provides sensible defaults via [defaultsFor].
/// Users can override any field; overrides are serialized as JSON
/// and merged over theme defaults at runtime.
class RenderColors {
  final Color bold;
  final Color italic;
  final Color strikethrough;
  final Color link;
  final Color highlight;
  final Color h1;
  final Color h2;
  final Color h3;
  final Color h4;
  final Color h5;
  final Color h6;
  final Color inlineCode;
  final Color codeBlockBg;
  final Color blockquoteText;
  final Color blockquoteBorder;
  final Color listBullet;
  final Color tableHeader;
  final Color tableBody;

  const RenderColors({
    required this.bold,
    required this.italic,
    required this.strikethrough,
    required this.link,
    required this.highlight,
    required this.h1,
    required this.h2,
    required this.h3,
    required this.h4,
    required this.h5,
    required this.h6,
    required this.inlineCode,
    required this.codeBlockBg,
    required this.blockquoteText,
    required this.blockquoteBorder,
    required this.listBullet,
    required this.tableHeader,
    required this.tableBody,
  });

  /// Returns the default render colors for the given theme.
  static RenderColors defaultsFor(AppThemeData theme) {
    return RenderColors(
      bold: theme.textPrimary,
      italic: theme.amber,
      strikethrough: theme.textTertiary,
      link: theme.accent,
      highlight: theme.amber,
      h1: theme.textPrimary,
      h2: theme.accent,
      h3: theme.amber,
      h4: theme.textPrimary,
      h5: theme.textSecondary,
      h6: theme.textTertiary,
      inlineCode: theme.accentHover,
      codeBlockBg: theme.bgCode,
      blockquoteText: theme.textSecondary,
      blockquoteBorder: theme.accent,
      listBullet: theme.accent,
      tableHeader: theme.textPrimary,
      tableBody: theme.textSecondary,
    );
  }

  /// All field names in display order, grouped by category.
  static const List<RenderColorEntry> entries = [
    // Text Styles
    RenderColorEntry('bold', 'Bold', 'TEXT STYLES', '**bold text**'),
    RenderColorEntry('italic', 'Italic', 'TEXT STYLES', '*italic text*'),
    RenderColorEntry('strikethrough', 'Strikethrough', 'TEXT STYLES', '~~strikethrough~~'),
    RenderColorEntry('link', 'Link', 'TEXT STYLES', '[link](url)'),
    RenderColorEntry('highlight', 'Highlight', 'TEXT STYLES', '==highlighted=='),
    // Headings
    RenderColorEntry('h1', 'Heading 1', 'HEADINGS', '# Heading'),
    RenderColorEntry('h2', 'Heading 2', 'HEADINGS', '## Heading'),
    RenderColorEntry('h3', 'Heading 3', 'HEADINGS', '### Heading'),
    RenderColorEntry('h4', 'Heading 4', 'HEADINGS', '#### Heading'),
    RenderColorEntry('h5', 'Heading 5', 'HEADINGS', '##### Heading'),
    RenderColorEntry('h6', 'Heading 6', 'HEADINGS', '###### Heading'),
    // Code & Blocks
    RenderColorEntry('inlineCode', 'Inline Code', 'CODE & BLOCKS', '`code`'),
    RenderColorEntry('codeBlockBg', 'Code Block BG', 'CODE & BLOCKS', '```code block```'),
    RenderColorEntry('blockquoteText', 'Blockquote', 'CODE & BLOCKS', '> quote'),
    RenderColorEntry('blockquoteBorder', 'Quote Border', 'CODE & BLOCKS', '> border accent'),
    // Lists & Tables
    RenderColorEntry('listBullet', 'List Bullet', 'LISTS & TABLES', '- bullet'),
    RenderColorEntry('tableHeader', 'Table Header', 'LISTS & TABLES', '| header |'),
    RenderColorEntry('tableBody', 'Table Body', 'LISTS & TABLES', '| cell |'),
  ];

  /// Get a color by its field name.
  Color getByName(String name) {
    switch (name) {
      case 'bold': return bold;
      case 'italic': return italic;
      case 'strikethrough': return strikethrough;
      case 'link': return link;
      case 'highlight': return highlight;
      case 'h1': return h1;
      case 'h2': return h2;
      case 'h3': return h3;
      case 'h4': return h4;
      case 'h5': return h5;
      case 'h6': return h6;
      case 'inlineCode': return inlineCode;
      case 'codeBlockBg': return codeBlockBg;
      case 'blockquoteText': return blockquoteText;
      case 'blockquoteBorder': return blockquoteBorder;
      case 'listBullet': return listBullet;
      case 'tableHeader': return tableHeader;
      case 'tableBody': return tableBody;
      default: return bold;
    }
  }

  /// Create render colors by merging user overrides over theme defaults.
  static RenderColors merge(RenderColors defaults, Map<String, int> overrides) {
    Color resolve(String name, Color fallback) {
      final v = overrides[name];
      return v != null ? Color(v) : fallback;
    }
    return RenderColors(
      bold: resolve('bold', defaults.bold),
      italic: resolve('italic', defaults.italic),
      strikethrough: resolve('strikethrough', defaults.strikethrough),
      link: resolve('link', defaults.link),
      highlight: resolve('highlight', defaults.highlight),
      h1: resolve('h1', defaults.h1),
      h2: resolve('h2', defaults.h2),
      h3: resolve('h3', defaults.h3),
      h4: resolve('h4', defaults.h4),
      h5: resolve('h5', defaults.h5),
      h6: resolve('h6', defaults.h6),
      inlineCode: resolve('inlineCode', defaults.inlineCode),
      codeBlockBg: resolve('codeBlockBg', defaults.codeBlockBg),
      blockquoteText: resolve('blockquoteText', defaults.blockquoteText),
      blockquoteBorder: resolve('blockquoteBorder', defaults.blockquoteBorder),
      listBullet: resolve('listBullet', defaults.listBullet),
      tableHeader: resolve('tableHeader', defaults.tableHeader),
      tableBody: resolve('tableBody', defaults.tableBody),
    );
  }

  /// Serialize only the overridden colors (those that differ from defaults).
  Map<String, int> toOverrides(RenderColors defaults) {
    final map = <String, int>{};
    void check(String name, Color current, Color def) {
      if (current.toARGB32() != def.toARGB32()) {
        map[name] = current.toARGB32();
      }
    }
    check('bold', bold, defaults.bold);
    check('italic', italic, defaults.italic);
    check('strikethrough', strikethrough, defaults.strikethrough);
    check('link', link, defaults.link);
    check('highlight', highlight, defaults.highlight);
    check('h1', h1, defaults.h1);
    check('h2', h2, defaults.h2);
    check('h3', h3, defaults.h3);
    check('h4', h4, defaults.h4);
    check('h5', h5, defaults.h5);
    check('h6', h6, defaults.h6);
    check('inlineCode', inlineCode, defaults.inlineCode);
    check('codeBlockBg', codeBlockBg, defaults.codeBlockBg);
    check('blockquoteText', blockquoteText, defaults.blockquoteText);
    check('blockquoteBorder', blockquoteBorder, defaults.blockquoteBorder);
    check('listBullet', listBullet, defaults.listBullet);
    check('tableHeader', tableHeader, defaults.tableHeader);
    check('tableBody', tableBody, defaults.tableBody);
    return map;
  }
}

/// Metadata about a single render color entry for the settings UI.
class RenderColorEntry {
  final String key;
  final String label;
  final String group;
  final String syntax;

  const RenderColorEntry(this.key, this.label, this.group, this.syntax);
}

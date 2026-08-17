import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'theme/claude_theme.dart';
import 'theme/font_manager.dart';
import 'theme/render_colors.dart';
import 'theme/style_config_manager.dart';

enum _SettingsTab {
  fileManager,
  appearance,
  hotkeys,
  about,
}

enum _AppearanceSubTab {
  themes,
  render,
}

enum _RenderSubSection {
  colors,
  fonts,
}

enum _EditingShortcutType {
  none,
  homeRoot,
  parentFolder,
}

class SettingsScreen extends StatefulWidget {
  final String? vaultPath;
  final ValueChanged<String?> onVaultPathChanged;
  final AppShortcut homeRootShortcut;
  final ValueChanged<AppShortcut> onShortcutChanged;
  final AppShortcut parentFolderShortcut;
  final ValueChanged<AppShortcut> onParentFolderShortcutChanged;
  final AppThemeId currentTheme;
  final ValueChanged<AppThemeId> onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.vaultPath,
    required this.onVaultPathChanged,
    required this.homeRootShortcut,
    required this.onShortcutChanged,
    this.parentFolderShortcut = const AppShortcut(
      trigger: LogicalKeyboardKey.arrowLeft,
      alt: true,
    ),
    required this.onParentFolderShortcutChanged,
    this.currentTheme = AppThemeId.claudeWarmDark,
    required this.onThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  _SettingsTab _activeTab = _SettingsTab.fileManager;
  _AppearanceSubTab _appearanceSubTab = _AppearanceSubTab.themes;
  _RenderSubSection _renderSubSection = _RenderSubSection.colors;
  _EditingShortcutType _editingShortcut = _EditingShortcutType.none;
  final FocusNode _shortcutFocusNode = FocusNode();

  // ── Fonts State ──
  final TextEditingController _fontSearchController = TextEditingController();
  String _fontSearchQuery = '';
  String _selectedFontCategory = 'all';
  String? _downloadingFontName;
  double _downloadProgress = 0.0;
  TypographySlot _activeSlot = TypographySlot.ui;

  @override
  void dispose() {
    _shortcutFocusNode.dispose();
    _fontSearchController.dispose();
    super.dispose();
  }

  Future<void> _openVault() async {
    setState(() => _isLoading = true);
    try {
      final String? selectedDirectory = await getDirectoryPath(
        confirmButtonText: 'Select Vault',
      );

      if (selectedDirectory != null) {
        widget.onVaultPathChanged(selectedDirectory);
      }
    } catch (e) {
      debugPrint('Error picking directory: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Folder picker error: $e'),
            backgroundColor: ClaudeTheme.crimson,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startEditingShortcut(_EditingShortcutType type) {
    setState(() {
      _editingShortcut = type;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_shortcutFocusNode.canRequestFocus) {
        _shortcutFocusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left Sidebar Settings Navigation ──
              SizedBox(
                width: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SETTINGS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        fontFamily: 'monospace',
                        color: ClaudeTheme.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SettingsNavItem(
                      icon: Icons.folder_open_rounded,
                      label: 'File Manager',
                      isSelected: _activeTab == _SettingsTab.fileManager,
                      onTap: () {
                        setState(() => _activeTab = _SettingsTab.fileManager);
                      },
                    ),
                    const SizedBox(height: 4),
                    _SettingsNavItem(
                      icon: Icons.palette_outlined,
                      label: 'Appearance',
                      isSelected: _activeTab == _SettingsTab.appearance,
                      onTap: () {
                        setState(() => _activeTab = _SettingsTab.appearance);
                      },
                    ),
                    const SizedBox(height: 4),
                    _SettingsNavItem(
                      icon: Icons.keyboard_rounded,
                      label: 'Hotkeys',
                      isSelected: _activeTab == _SettingsTab.hotkeys,
                      onTap: () {
                        setState(() => _activeTab = _SettingsTab.hotkeys);
                      },
                    ),
                    const SizedBox(height: 4),
                    _SettingsNavItem(
                      icon: Icons.info_outline_rounded,
                      label: 'About',
                      isSelected: _activeTab == _SettingsTab.about,
                      onTap: () {
                        setState(() => _activeTab = _SettingsTab.about);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),
              // Hairline vertical divider
              Container(
                width: 1.0,
                height: 480,
                color: ClaudeTheme.border,
              ),
              const SizedBox(width: 20),

              // ── Right Content Panel ──
              Expanded(
                child: SingleChildScrollView(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: _buildActiveContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveContent() {
    switch (_activeTab) {
      case _SettingsTab.fileManager:
        return _buildFileManagerContent();
      case _SettingsTab.appearance:
        return _buildAppearanceContent();
      case _SettingsTab.hotkeys:
        return _buildHotkeysContent();
      case _SettingsTab.about:
        return _buildAboutContent();
    }
  }

  Widget _buildFileManagerContent() {
    final vaultPath = widget.vaultPath;

    return Column(
      key: ValueKey('file_manager'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'File Manager',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: ClaudeTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Configure your local Markdown vault or Obsidian repository directory.',
          style: TextStyle(
            fontSize: 13,
            color: ClaudeTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: ClaudeTheme.bgSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ClaudeTheme.border, width: 1),
            boxShadow: ClaudeTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: ClaudeTheme.accentSubtle,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.folder_open_rounded,
                      size: 18,
                      color: ClaudeTheme.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vault Location',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: ClaudeTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Obsidian vault or notes folder',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: ClaudeTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (vaultPath != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: ClaudeTheme.bgCode,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ClaudeTheme.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 15,
                        color: ClaudeTheme.sage,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          vaultPath,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Consolas',
                            color: ClaudeTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: ClaudeTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : _openVault,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.folder_open_rounded, size: 15),
                  label: Text(
                    _isLoading
                        ? 'Opening...'
                        : (vaultPath == null ? 'Open Vault' : 'Change Vault Folder'),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceContent() {
    return Column(
      key: const ValueKey('appearance'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row with Title and Sub-Tab Switcher
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: ClaudeTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _appearanceSubTab == _AppearanceSubTab.themes
                        ? 'Choose your interface theme and visual aesthetic for SuperWave.'
                        : 'Customize colors for every markdown element (bold, highlight, links, code, headings, etc.).',
                    style: TextStyle(
                      fontSize: 13,
                      color: ClaudeTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Sub-Tab Switcher (Themes | Render)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: ClaudeTheme.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ClaudeTheme.border, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSubTabChip(
                    'Themes',
                    Icons.palette_outlined,
                    _AppearanceSubTab.themes,
                  ),
                  const SizedBox(width: 3),
                  _buildSubTabChip(
                    'Render',
                    Icons.brush_rounded,
                    _AppearanceSubTab.render,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Sub-Tab Content
        if (_appearanceSubTab == _AppearanceSubTab.themes) ...[
          for (final theme in AppThemeData.allThemes) ...[
            _ThemeSelectionCard(
              theme: theme,
              isSelected: widget.currentTheme == theme.id,
              onSelect: () => widget.onThemeChanged(theme.id),
            ),
            const SizedBox(height: 10),
          ],
        ] else ...[
          _buildRenderColorsContent(),
        ],
      ],
    );
  }

  Widget _buildSubTabChip(String label, IconData icon, _AppearanceSubTab tab) {
    final isSelected = _appearanceSubTab == tab;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => setState(() => _appearanceSubTab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? ClaudeTheme.accent.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? ClaudeTheme.accent.withValues(alpha: 0.5) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? ClaudeTheme.accent : ClaudeTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? ClaudeTheme.textPrimary : ClaudeTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRenderColorsContent() {
    final overridesCount = ClaudeTheme.renderOverrides.length;
    final defaults = RenderColors.defaultsFor(ClaudeTheme.current);

    // Group entries
    final groups = <String, List<RenderColorEntry>>{};
    for (final entry in RenderColors.entries) {
      groups.putIfAbsent(entry.group, () => []).add(entry);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Actions Bar (Reset All button + override count indicator)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: overridesCount > 0
                        ? ClaudeTheme.accent.withValues(alpha: 0.15)
                        : ClaudeTheme.bgCard,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: overridesCount > 0
                          ? ClaudeTheme.accent.withValues(alpha: 0.3)
                          : ClaudeTheme.border,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    overridesCount > 0
                        ? '$overridesCount CUSTOM OVERRIDE${overridesCount == 1 ? "" : "S"}'
                        : 'USING THEME DEFAULTS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                      color: overridesCount > 0
                          ? ClaudeTheme.accent
                          : ClaudeTheme.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            if (overridesCount > 0)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ClaudeTheme.crimson,
                  side: BorderSide(color: ClaudeTheme.crimson.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: _resetAllOverrides,
                icon: const Icon(Icons.restart_alt_rounded, size: 14),
                label: const Text('Reset All to Theme Defaults', style: TextStyle(fontSize: 11)),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Live Markdown Preview Card
        const _LiveMarkdownPreviewCard(),
        const SizedBox(height: 24),

        // Category Groups
        for (final group in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8, top: 8),
            child: Text(
              group.key,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                fontFamily: 'monospace',
                color: ClaudeTheme.textTertiary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: ClaudeTheme.bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ClaudeTheme.border, width: 1),
            ),
            child: Column(
              children: [
                for (int i = 0; i < group.value.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: ClaudeTheme.borderSubtle),
                  _RenderColorEntryRow(
                    entry: group.value[i],
                    currentColor: ClaudeTheme.renderColors.getByName(group.value[i].key),
                    defaultColor: defaults.getByName(group.value[i].key),
                    isOverridden: ClaudeTheme.renderOverrides.containsKey(group.value[i].key),
                    onEdit: () => _openColorPicker(group.value[i]),
                    onReset: () => _resetOverride(group.value[i].key),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Future<void> _openColorPicker(RenderColorEntry entry) async {
    final themeDefaults = RenderColors.defaultsFor(ClaudeTheme.current);
    final currentColor = ClaudeTheme.renderColors.getByName(entry.key);
    final defaultColor = themeDefaults.getByName(entry.key);

    final selectedColor = await showDialog<Color>(
      context: context,
      builder: (ctx) => _ColorPickerDialog(
        entry: entry,
        initialColor: currentColor,
        defaultColor: defaultColor,
      ),
    );

    if (selectedColor != null) {
      setState(() {
        ClaudeTheme.setRenderOverride(entry.key, selectedColor.toARGB32());
        if (widget.vaultPath != null) {
          StyleConfigManager.saveRenderConfig(
            widget.vaultPath!,
            ClaudeTheme.renderOverrides,
          );
        }
      });
    }
  }

  void _resetOverride(String key) {
    setState(() {
      ClaudeTheme.setRenderOverride(key, null);
      if (widget.vaultPath != null) {
        StyleConfigManager.saveRenderConfig(
          widget.vaultPath!,
          ClaudeTheme.renderOverrides,
        );
      }
    });
  }

  void _resetAllOverrides() {
    setState(() {
      ClaudeTheme.resetAllRenderOverrides();
      if (widget.vaultPath != null) {
        StyleConfigManager.saveRenderConfig(
          widget.vaultPath!,
          ClaudeTheme.renderOverrides,
        );
      }
    });
  }

  Widget _buildHotkeysContent() {
    return Column(
      key: const ValueKey('hotkeys'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hotkeys',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: ClaudeTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage keyboard shortcuts to quickly navigate and control the vault.',
          style: TextStyle(
            fontSize: 13,
            color: ClaudeTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // Home & Root shortcut card
        _buildShortcutCard(
          title: 'Go to Home & Root',
          description: 'Navigates back to the Home tab and resets navigation to the root folder.',
          shortcut: widget.homeRootShortcut,
          isEditing: _editingShortcut == _EditingShortcutType.homeRoot,
          onEdit: () => _startEditingShortcut(_EditingShortcutType.homeRoot),
          onSave: (newShortcut) {
            widget.onShortcutChanged(newShortcut);
            setState(() => _editingShortcut = _EditingShortcutType.none);
          },
          onCancel: () => setState(() => _editingShortcut = _EditingShortcutType.none),
        ),

        const SizedBox(height: 12),

        // Return to Parent Folder shortcut card
        _buildShortcutCard(
          title: 'Return to Parent Folder',
          description: 'Navigates up one level in the folder hierarchy to the parent directory.',
          shortcut: widget.parentFolderShortcut,
          isEditing: _editingShortcut == _EditingShortcutType.parentFolder,
          onEdit: () => _startEditingShortcut(_EditingShortcutType.parentFolder),
          onSave: (newShortcut) {
            widget.onParentFolderShortcutChanged(newShortcut);
            setState(() => _editingShortcut = _EditingShortcutType.none);
          },
          onCancel: () => setState(() => _editingShortcut = _EditingShortcutType.none),
        ),

        const SizedBox(height: 12),

        // Global Search shortcut card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: ClaudeTheme.bgSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ClaudeTheme.accent.withValues(alpha: 0.35), width: 1),
            boxShadow: ClaudeTheme.cardShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Icon(
                          Icons.travel_explore_rounded,
                          size: 16,
                          color: ClaudeTheme.accent,
                        ),
                        Text(
                          'Global Search Mode',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: ClaudeTheme.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ClaudeTheme.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'BUILT-IN SHORTCUT',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              letterSpacing: 0.5,
                              color: ClaudeTheme.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Press Ctrl + Space + Space (double-tap Space while holding Ctrl) to instantly activate recursive vault search across all folders.',
                      style: TextStyle(
                        fontSize: 12,
                        color: ClaudeTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildKeyBadge('CTRL'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text('+', style: TextStyle(color: ClaudeTheme.textTertiary, fontSize: 11)),
                  ),
                  _buildKeyBadge('SPACE'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text('+', style: TextStyle(color: ClaudeTheme.textTertiary, fontSize: 11)),
                  ),
                  _buildKeyBadge('SPACE'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutCard({
    required String title,
    required String description,
    required AppShortcut shortcut,
    required bool isEditing,
    required VoidCallback onEdit,
    required ValueChanged<AppShortcut> onSave,
    required VoidCallback onCancel,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClaudeTheme.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ClaudeTheme.border, width: 1),
        boxShadow: ClaudeTheme.cardShadow,
      ),
      child: isEditing
          ? Focus(
              focusNode: _shortcutFocusNode,
              autofocus: true,
              onKeyEvent: (FocusNode node, KeyEvent event) {
                if (event is! KeyDownEvent) return KeyEventResult.ignored;

                final pressedKey = event.logicalKey;
                if (pressedKey == LogicalKeyboardKey.escape) {
                  onCancel();
                  return KeyEventResult.handled;
                }

                final bool control = HardwareKeyboard.instance.isControlPressed;
                final bool alt = HardwareKeyboard.instance.isAltPressed;
                final bool shift = HardwareKeyboard.instance.isShiftPressed;
                final bool meta = HardwareKeyboard.instance.isMetaPressed;

                final isModifier = [
                  LogicalKeyboardKey.control,
                  LogicalKeyboardKey.controlLeft,
                  LogicalKeyboardKey.controlRight,
                  LogicalKeyboardKey.alt,
                  LogicalKeyboardKey.altLeft,
                  LogicalKeyboardKey.altRight,
                  LogicalKeyboardKey.shift,
                  LogicalKeyboardKey.shiftLeft,
                  LogicalKeyboardKey.shiftRight,
                  LogicalKeyboardKey.meta,
                  LogicalKeyboardKey.metaLeft,
                  LogicalKeyboardKey.metaRight,
                ].contains(pressedKey);

                if (!isModifier) {
                  onSave(AppShortcut(
                    trigger: pressedKey,
                    control: control,
                    alt: alt,
                    shift: shift,
                    meta: meta,
                  ));
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ClaudeTheme.accentSubtle,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.keyboard_rounded,
                        size: 26,
                        color: ClaudeTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Press new keys for "$title"...',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: ClaudeTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Press any modifier combination (Ctrl, Alt, Shift) + key. Press Esc to cancel.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: ClaudeTheme.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: onCancel,
                      child: const Text('Cancel (Esc)'),
                    ),
                  ],
                ),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: ClaudeTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: ClaudeTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Wrap(
                  spacing: 4,
                  children: shortcut
                      .getKeysList()
                      .map((key) => _buildKeyBadge(key))
                      .toList(),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: ClaudeTheme.border),
                    foregroundColor: ClaudeTheme.textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 13),
                  label: const Text('Edit', style: TextStyle(fontSize: 11.5)),
                ),
              ],
            ),
    );
  }

  Widget _buildAboutContent() {
    return Column(
      key: const ValueKey('about'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About SuperWave',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: ClaudeTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'A minimal, lightning-fast Markdown & Obsidian workspace client.',
          style: TextStyle(
            fontSize: 13,
            color: ClaudeTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: ClaudeTheme.bgSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ClaudeTheme.border, width: 1),
            boxShadow: ClaudeTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'SuperWave Desktop',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ClaudeTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'v1.0.0',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontFamily: 'monospace',
                      color: ClaudeTheme.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Styled after the minimal, distraction-free Claude Desktop design system with fast local file exploration.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: ClaudeTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeyBadge(String key) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: ClaudeTheme.bgCode,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: ClaudeTheme.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        key,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
          color: ClaudeTheme.textPrimary,
        ),
      ),
    );
  }
}

class _ThemeSelectionCard extends StatefulWidget {
  final AppThemeData theme;
  final bool isSelected;
  final VoidCallback onSelect;

  const _ThemeSelectionCard({
    required this.theme,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  State<_ThemeSelectionCard> createState() => _ThemeSelectionCardState();
}

class _ThemeSelectionCardState extends State<_ThemeSelectionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isSelected = widget.isSelected;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.accent.withValues(alpha: 0.08)
                : (_isHovered ? ClaudeTheme.bgElevated : ClaudeTheme.bgSurface),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? theme.accent.withValues(alpha: 0.8)
                  : (_isHovered ? ClaudeTheme.borderHover : ClaudeTheme.border),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.accent.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : ClaudeTheme.cardShadow,
          ),
          child: Row(
            children: [
              // Theme icon / radio
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.accent
                      : (_isHovered
                          ? ClaudeTheme.accent.withValues(alpha: 0.15)
                          : ClaudeTheme.bgCard),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? theme.accent : ClaudeTheme.border,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    isSelected ? Icons.check_rounded : Icons.palette_outlined,
                    size: 16,
                    color: isSelected ? Colors.white : ClaudeTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          theme.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: ClaudeTheme.textPrimary,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.accent.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                                color: theme.accent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      theme.description,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: ClaudeTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Color palette preview bubbles
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final color in theme.previewPalette) ...[
                    Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SettingsNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? ClaudeTheme.bgElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? ClaudeTheme.accent : ClaudeTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? ClaudeTheme.textPrimary : ClaudeTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppShortcut {
  final LogicalKeyboardKey trigger;
  final bool control;
  final bool alt;
  final bool shift;
  final bool meta;

  const AppShortcut({
    required this.trigger,
    this.control = false,
    this.alt = false,
    this.shift = false,
    this.meta = false,
  });

  List<String> getKeysList() {
    final List<String> keys = [];
    if (control) keys.add('CTRL');
    if (alt) keys.add('ALT');
    if (shift) keys.add('SHIFT');
    if (meta) keys.add('CMD');

    String keyLabel = trigger.keyLabel;
    if (trigger == LogicalKeyboardKey.space) {
      keyLabel = 'SPACE';
    } else if (trigger == LogicalKeyboardKey.arrowLeft) {
      keyLabel = 'LEFT';
    } else if (trigger == LogicalKeyboardKey.arrowRight) {
      keyLabel = 'RIGHT';
    } else if (trigger == LogicalKeyboardKey.arrowUp) {
      keyLabel = 'UP';
    } else if (trigger == LogicalKeyboardKey.arrowDown) {
      keyLabel = 'DOWN';
    } else if (trigger == LogicalKeyboardKey.escape) {
      keyLabel = 'ESC';
    } else if (trigger == LogicalKeyboardKey.backspace) {
      keyLabel = 'BACKSPACE';
    }
    keys.add(keyLabel.toUpperCase());
    return keys;
  }

  SingleActivator toActivator() {
    return SingleActivator(
      trigger,
      control: control,
      alt: alt,
      shift: shift,
      meta: meta,
    );
  }
}

class _LiveMarkdownPreviewCard extends StatelessWidget {
  const _LiveMarkdownPreviewCard();

  @override
  Widget build(BuildContext context) {
    final colors = ClaudeTheme.renderColors;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClaudeTheme.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ClaudeTheme.borderHover, width: 1),
        boxShadow: ClaudeTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.remove_red_eye_outlined, size: 14, color: ClaudeTheme.accent),
              const SizedBox(width: 6),
              Text(
                'LIVE MARKDOWN PREVIEW',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  letterSpacing: 1.0,
                  color: ClaudeTheme.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '# Heading 1 Document Title',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: colors.h1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '## Heading 2 Section',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: colors.h2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '### Heading 3 Subsection',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.h3,
            ),
          ),
          const SizedBox(height: 10),
          // Paragraph with inline elements
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              Text('Regular text,', style: TextStyle(color: ClaudeTheme.textPrimary, fontSize: 13.5)),
              Text('bold emphasis,', style: TextStyle(color: colors.bold, fontWeight: FontWeight.w700, fontSize: 13.5)),
              Text('italic text,', style: TextStyle(color: colors.italic, fontStyle: FontStyle.italic, fontSize: 13.5)),
              Text('strikethrough,', style: TextStyle(color: colors.strikethrough, decoration: TextDecoration.lineThrough, fontSize: 13.5)),
              Text('hyperlink,', style: TextStyle(color: colors.link, decoration: TextDecoration.underline, fontSize: 13.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: colors.highlight.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: colors.highlight.withValues(alpha: 0.40), width: 0.8),
                ),
                child: Text('==highlighted==', style: TextStyle(color: colors.highlight, fontWeight: FontWeight.w600, fontSize: 12.5)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: colors.codeBlockBg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: ClaudeTheme.border, width: 0.8),
                ),
                child: Text('`inline code`', style: TextStyle(fontFamily: 'Consolas', color: colors.inlineCode, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Blockquote preview
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            decoration: BoxDecoration(
              color: ClaudeTheme.bgCard,
              borderRadius: const BorderRadius.only(topRight: Radius.circular(6), bottomRight: Radius.circular(6)),
              border: Border(left: BorderSide(color: colors.blockquoteBorder, width: 3)),
            ),
            child: Text(
              '> Beautiful thoughts, organized simply and rendered with custom colors.',
              style: TextStyle(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                color: colors.blockquoteText,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // List bullet preview
          Row(
            children: [
              Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.listBullet)),
              Text('First list item with custom bullet color', style: TextStyle(fontSize: 13, color: ClaudeTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RenderColorEntryRow extends StatefulWidget {
  final RenderColorEntry entry;
  final Color currentColor;
  final Color defaultColor;
  final bool isOverridden;
  final VoidCallback onEdit;
  final VoidCallback onReset;

  const _RenderColorEntryRow({
    required this.entry,
    required this.currentColor,
    required this.defaultColor,
    required this.isOverridden,
    required this.onEdit,
    required this.onReset,
  });

  @override
  State<_RenderColorEntryRow> createState() => _RenderColorEntryRowState();
}

class _RenderColorEntryRowState extends State<_RenderColorEntryRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final color = widget.currentColor;
    final rgb = color.toARGB32() & 0x00FFFFFF;
    final hexString = '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: _isHovered ? ClaudeTheme.bgCardHover : Colors.transparent,
        child: Row(
          children: [
            // Left: Label + Syntax badge
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Text(
                    entry.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ClaudeTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: ClaudeTheme.bgElevated,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: ClaudeTheme.border, width: 0.8),
                    ),
                    child: Text(
                      entry.syntax,
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: ClaudeTheme.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Middle: Status badge if overridden
            if (widget.isOverridden)
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ClaudeTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'CUSTOM',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: ClaudeTheme.accent,
                  ),
                ),
              ),

            // Right: Color Swatch + Hex label + Edit / Reset buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Color chip / preview (Clickable to pick color)
                Tooltip(
                  message: 'Click to edit color',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: widget.onEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ClaudeTheme.bgElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: ClaudeTheme.borderHover, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hexString,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              color: ClaudeTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Reset button (if overridden)
                if (widget.isOverridden)
                  IconButton(
                    icon: const Icon(Icons.undo_rounded, size: 15),
                    tooltip: 'Reset to Theme Default',
                    onPressed: widget.onReset,
                    style: IconButton.styleFrom(
                      foregroundColor: ClaudeTheme.textTertiary,
                      padding: const EdgeInsets.all(6),
                      minimumSize: const Size(28, 28),
                    ),
                  )
                else
                  const SizedBox(width: 28),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final RenderColorEntry entry;
  final Color initialColor;
  final Color defaultColor;

  const _ColorPickerDialog({
    required this.entry,
    required this.initialColor,
    required this.defaultColor,
  });

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _selectedColor;
  late TextEditingController _hexController;
  String? _hexError;

  static const List<Color> _presetPalette = [
    // Vibrant Reds & Oranges
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFEA580C),
    Color(0xFFF59E0B),
    Color(0xFFEAB308),
    // Greens & Teals
    Color(0xFF10B981),
    Color(0xFF059669),
    Color(0xFF14B8A6),
    Color(0xFF06B6D4),
    // Blues & Purples
    Color(0xFF38BDF8),
    Color(0xFF3B82F6),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFA855F7),
    // Pinks & Neutrals
    Color(0xFFEC4899),
    Color(0xFFF43F5E),
    Color(0xFFFFFFFF),
    Color(0xFFD4D4D8),
    Color(0xFF71717A),
    Color(0xFF27272A),
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _hexController = TextEditingController(text: _formatHex(_selectedColor));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _formatHex(Color c) {
    final rgb = c.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  void _onHexChanged(String text) {
    var clean = text.replaceAll('#', '').trim();
    if (clean.length == 6) {
      final val = int.tryParse('FF$clean', radix: 16);
      if (val != null) {
        setState(() {
          _selectedColor = Color(val);
          _hexError = null;
        });
        return;
      }
    }
    setState(() {
      _hexError = 'Enter 6 hex digits (e.g. #FF5500)';
    });
  }

  void _selectColor(Color c) {
    setState(() {
      _selectedColor = c;
      _hexController.text = _formatHex(c);
      _hexError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ClaudeTheme.current;
    final themeColors = [
      currentTheme.accent,
      currentTheme.accentHover,
      currentTheme.amber,
      currentTheme.sage,
      currentTheme.sky,
      currentTheme.lavender,
      currentTheme.crimson,
      currentTheme.textPrimary,
      currentTheme.textSecondary,
      currentTheme.bgElevated,
    ];

    return Dialog(
      backgroundColor: ClaudeTheme.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: ClaudeTheme.borderHover, width: 1),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Customize ${widget.entry.label}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ClaudeTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      foregroundColor: ClaudeTheme.textSecondary,
                      padding: const EdgeInsets.all(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Hex Input Row with Live Swatch
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ClaudeTheme.bgSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ClaudeTheme.border, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _selectedColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _hexController,
                        onChanged: _onHexChanged,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          color: ClaudeTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: '#RRGGBB',
                          labelText: 'HEX COLOR CODE',
                          labelStyle: TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: ClaudeTheme.textTertiary,
                          ),
                          errorText: _hexError,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: ClaudeTheme.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Theme Palette Section
              Text(
                'CURRENT THEME PALETTE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  letterSpacing: 0.8,
                  color: ClaudeTheme.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in themeColors)
                    _buildColorChip(c),
                ],
              ),
              const SizedBox(height: 16),

              // Vibrant Spectrum Section
              Text(
                'PRESET PALETTE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  letterSpacing: 0.8,
                  color: ClaudeTheme.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in _presetPalette)
                    _buildColorChip(c),
                ],
              ),
              const SizedBox(height: 20),

              // Dialog Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => _selectColor(widget.defaultColor),
                    icon: const Icon(Icons.restart_alt_rounded, size: 14),
                    label: const Text('Reset to Default', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: ClaudeTheme.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: ClaudeTheme.accent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(_selectedColor),
                        child: const Text('Apply Color'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorChip(Color c) {
    final isSelected = c.toARGB32() == _selectedColor.toARGB32();
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => _selectColor(c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: c.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? const Center(
                child: Icon(Icons.check_rounded, size: 14, color: Colors.white),
              )
            : null,
      ),
    );
  }
}

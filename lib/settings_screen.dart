import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/claude_theme.dart';

enum _SettingsTab {
  fileManager,
  appearance,
  hotkeys,
  about,
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
  _EditingShortcutType _editingShortcut = _EditingShortcutType.none;
  final FocusNode _shortcutFocusNode = FocusNode();

  @override
  void dispose() {
    _shortcutFocusNode.dispose();
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
          'Choose your interface theme and visual aesthetic for SuperWave.',
          style: TextStyle(
            fontSize: 13,
            color: ClaudeTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // List of Theme Cards
        for (final theme in AppThemeData.allThemes) ...[
          _ThemeSelectionCard(
            theme: theme,
            isSelected: widget.currentTheme == theme.id,
            onSelect: () => widget.onThemeChanged(theme.id),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
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

        // Magic Global Search shortcut card
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
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 15,
                          color: Color(0xFFF6AD55),
                        ),
                        Text(
                          'Magic Global Search',
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
                            'BUILT-IN MAGIC',
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
                      'Hold Ctrl for 1 second to arm the magic glow, then press Space to activate recursive vault search.',
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
                  _buildKeyBadge('HOLD CTRL (1s)'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text('+', style: TextStyle(color: ClaudeTheme.textTertiary, fontSize: 11)),
                  ),
                  _buildKeyBadge('SPACE KEY'),
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

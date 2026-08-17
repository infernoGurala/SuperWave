import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';
import 'custom_title_bar.dart';
import 'glass_sidebar.dart';
import 'note_viewer_screen.dart';
import 'settings_screen.dart';
import 'theme/claude_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    try {
      await windowManager.ensureInitialized();
      const windowOptions = WindowOptions(
        size: Size(1200, 780),
        minimumSize: Size(780, 520),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
        title: 'SuperWave',
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (e) {
      debugPrint('Window manager initialization notice: $e');
    }
  }

  runApp(const SuperWaveApp());
}

class SuperWaveApp extends StatefulWidget {
  final String? initialVaultPath;
  const SuperWaveApp({super.key, this.initialVaultPath});

  @override
  State<SuperWaveApp> createState() => _SuperWaveAppState();
}

class _SuperWaveAppState extends State<SuperWaveApp> {
  int _currentTab = 0;
  String? _vaultPath;
  final GlobalKey<_HomeScreenState> _homeKey = GlobalKey<_HomeScreenState>();

  @override
  void initState() {
    super.initState();
    _vaultPath = widget.initialVaultPath;
  }

  @override
  void didUpdateWidget(covariant SuperWaveApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialVaultPath != oldWidget.initialVaultPath) {
      setState(() {
        _vaultPath = widget.initialVaultPath;
      });
    }
  }

  AppShortcut _homeRootShortcut = const AppShortcut(
    trigger: LogicalKeyboardKey.space,
    control: true,
  );

  AppShortcut _parentFolderShortcut = const AppShortcut(
    trigger: LogicalKeyboardKey.arrowLeft,
    alt: true,
  );

  AppThemeId _currentTheme = AppThemeId.claudeWarmDark;

  void _goToHomeAndRoot() {
    if (_homeKey.currentState?.isCtrlMagicArmed == true ||
        _homeKey.currentState?.wasJustMagicActivated == true) {
      // Magic is armed or just activated: Space triggers Global Search activation, not Home Root!
      return;
    }
    if (_currentTab != 0) {
      setState(() {
        _currentTab = 0;
      });
    } else {
      _homeKey.currentState?.resetToRoot();
    }
  }

  void _goUpParentFolder() {
    if (_currentTab == 0) {
      _homeKey.currentState?.goUpOneFolder();
    }
  }

  void _openSearch() {
    setState(() {
      _currentTab = 1;
    });
  }

  Future<void> _pickVault() async {
    try {
      final String? selected = await getDirectoryPath(
        confirmButtonText: 'Select Vault',
      );
      if (selected != null) {
        setState(() {
          _vaultPath = selected;
          _currentTab = 0;
        });
      }
    } catch (e) {
      debugPrint('Error picking vault: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaultDirName = _vaultPath
        ?.split(RegExp(r'[/\\]'))
        .where((s) => s.isNotEmpty)
        .lastOrNull;

    return MaterialApp(
      title: 'SuperWave',
      debugShowCheckedModeBanner: false,
      theme: ClaudeTheme.darkTheme,
      home: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          _homeRootShortcut.toActivator(): _goToHomeAndRoot,
          _parentFolderShortcut.toActivator(): _goUpParentFolder,
          const SingleActivator(LogicalKeyboardKey.keyK, control: true): _openSearch,
          const SingleActivator(LogicalKeyboardKey.keyK, meta: true): _openSearch,
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: ClaudeTheme.bgCanvas,
            body: Column(
              children: [
                // ── Claude Desktop Custom Frameless Titlebar ──
                CustomTitleBar(
                  vaultName: vaultDirName,
                ),

                // ── Main Body: Floating Capsule Bar + Padded Canvas ──
                Expanded(
                  child: Stack(
                    children: [
                      // Active Screen Content
                      Positioned.fill(
                        left: 84,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _buildScreen(_currentTab),
                        ),
                      ),

                      // Floating Capsule Navigation Bar
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GlassSidebar(
                          selectedIndex: _currentTab,
                          vaultPath: _vaultPath,
                          totalNotes: _homeKey.currentState?.totalNotes ?? 0,
                          totalFolders: _homeKey.currentState?.totalFolders ?? 0,
                          onOpenVault: _pickVault,
                          onHomeRoot: _goToHomeAndRoot,
                          onItemSelected: (index) {
                            setState(() => _currentTab = index);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return _HomeScreen(
          key: _homeKey,
          vaultPath: _vaultPath,
          homeRootShortcut: _homeRootShortcut,
          onHomeRoot: _goToHomeAndRoot,
          parentFolderShortcut: _parentFolderShortcut,
          onParentFolder: _goUpParentFolder,
          onOpenSettings: () {
            setState(() => _currentTab = 2);
          },
          onOpenVault: _pickVault,
        );
      case 1:
        return _SearchScreen(
          key: const ValueKey('search'),
          vaultPath: _vaultPath,
          onOpenNote: (path) {
            Navigator.of(context).push<String>(
              MaterialPageRoute(
                builder: (_) => NoteViewerScreen(
                  filePath: path,
                  vaultPath: _vaultPath,
                  parentFolderShortcut: _parentFolderShortcut,
                  homeRootShortcut: _homeRootShortcut,
                ),
              ),
            ).then((resultDir) {
              if (resultDir != null && resultDir.isNotEmpty) {
                setState(() {
                  _currentTab = 0;
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (resultDir == '__ROOT__') {
                    _homeKey.currentState?.resetToRoot();
                  } else {
                    _homeKey.currentState?.navigateToFolder(resultDir);
                  }
                });
              }
            });
          },
        );
      case 2:
        return SettingsScreen(
          key: const ValueKey('settings'),
          vaultPath: _vaultPath,
          onVaultPathChanged: (path) {
            setState(() => _vaultPath = path);
          },
          homeRootShortcut: _homeRootShortcut,
          onShortcutChanged: (shortcut) {
            setState(() => _homeRootShortcut = shortcut);
          },
          parentFolderShortcut: _parentFolderShortcut,
          onParentFolderShortcutChanged: (shortcut) {
            setState(() => _parentFolderShortcut = shortcut);
          },
          currentTheme: _currentTheme,
          onThemeChanged: (themeId) {
            setState(() {
              _currentTheme = themeId;
              ClaudeTheme.setTheme(themeId);
            });
          },
        );
      default:
        return _HomeScreen(
          key: _homeKey,
          vaultPath: _vaultPath,
          homeRootShortcut: _homeRootShortcut,
          onHomeRoot: _goToHomeAndRoot,
          parentFolderShortcut: _parentFolderShortcut,
          onParentFolder: _goUpParentFolder,
          onOpenSettings: () {
            setState(() => _currentTab = 2);
          },
          onOpenVault: _pickVault,
        );
    }
  }
}

enum _ViewMode { grid, list }
enum _SortBy { name, modified }
enum _FilterType { all, notesOnly, foldersOnly, favorites }

class _HomeScreen extends StatefulWidget {
  final String? vaultPath;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenVault;
  final AppShortcut? homeRootShortcut;
  final VoidCallback? onHomeRoot;
  final AppShortcut? parentFolderShortcut;
  final VoidCallback? onParentFolder;

  const _HomeScreen({
    super.key,
    required this.vaultPath,
    this.onOpenSettings,
    this.onOpenVault,
    this.homeRootShortcut,
    this.onHomeRoot,
    this.parentFolderShortcut,
    this.onParentFolder,
  });

  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen> with TickerProviderStateMixin {
  List<_CardData> _cards = [];
  final List<String> _navigationStack = [];
  final Set<String> _favoritePaths = {};
  bool _error = false;
  bool _isLoading = false;

  _ViewMode _viewMode = _ViewMode.grid;
  _SortBy _sortBy = _SortBy.name;
  _FilterType _activeFilter = _FilterType.all;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  // ── Magic Hold Ctrl + Space State & Animations ──
  late final AnimationController _ctrlChargeController;
  Timer? _ctrlHoldTimer;
  Timer? _armedDisarmTimer;
  bool _isHoldingCtrl = false;
  bool _isCtrlMagicArmed = false;
  bool _isGlobalSearchMode = false;
  bool _isGlobalLoading = false;
  List<_CardData> _globalCards = [];

  DateTime? _lastMagicActivatedAt;

  bool get isCtrlMagicArmed => _isCtrlMagicArmed;
  bool get isGlobalSearchMode => _isGlobalSearchMode;
  bool get wasJustMagicActivated =>
      _lastMagicActivatedAt != null &&
      DateTime.now().difference(_lastMagicActivatedAt!).inMilliseconds < 600;

  int get totalNotes => (_isGlobalSearchMode ? _globalCards : _cards).where((c) => !c.isFolder).length;
  int get totalFolders => (_isGlobalSearchMode ? _globalCards : _cards).where((c) => c.isFolder).length;

  List<_CardData> get _filteredCards {
    List<_CardData> result = _isGlobalSearchMode ? List.from(_globalCards) : List.from(_cards);

    // Apply quick filter
    if (_activeFilter == _FilterType.notesOnly) {
      result = result.where((c) => !c.isFolder).toList();
    } else if (_activeFilter == _FilterType.foldersOnly) {
      result = result.where((c) => c.isFolder).toList();
    } else if (_activeFilter == _FilterType.favorites) {
      result = result.where((c) => _favoritePaths.contains(c.fullPath)).toList();
    }

    // Apply search query
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((card) {
        final titleMatch = card.title.toLowerCase().contains(query);
        final pathMatch = card.relativePath?.toLowerCase().contains(query) ?? false;
        return titleMatch || pathMatch;
      }).toList();
    }

    // Apply sorting
    result.sort((a, b) {
      if (a.isFolder && !b.isFolder) return -1;
      if (!a.isFolder && b.isFolder) return 1;

      if (_sortBy == _SortBy.modified && a.modifiedDate != null && b.modifiedDate != null) {
        return b.modifiedDate!.compareTo(a.modifiedDate!);
      }
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return result;
  }

  @override
  void initState() {
    super.initState();
    _loadVault();
    _searchFocusNode.addListener(_handleFocusChange);

    _ctrlChargeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    HardwareKeyboard.instance.addHandler(_handleGlobalHardwareKey);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
        _searchController.selection = TextSelection.collapsed(
          offset: _searchController.text.length,
        );
      }
    });
  }

  void _handleFocusChange() {
    if (_searchFocusNode.hasFocus && mounted) {
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalHardwareKey);
    _ctrlHoldTimer?.cancel();
    _armedDisarmTimer?.cancel();
    _ctrlChargeController.dispose();
    _searchFocusNode.removeListener(_handleFocusChange);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _handleGlobalHardwareKey(KeyEvent event) {
    final key = event.logicalKey;
    final isControlKey = key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight ||
        key == LogicalKeyboardKey.control;

    if (event is KeyDownEvent) {
      if (isControlKey) {
        if (!_isHoldingCtrl && !_isCtrlMagicArmed) {
          _isHoldingCtrl = true;
          _ctrlChargeController.forward(from: 0.0);
          _ctrlHoldTimer?.cancel();
          _ctrlHoldTimer = Timer(const Duration(milliseconds: 1000), () {
            if (mounted && _isHoldingCtrl) {
              setState(() {
                _isCtrlMagicArmed = true;
                _isHoldingCtrl = false;
              });
              _ctrlChargeController.value = 1.0;

              _armedDisarmTimer?.cancel();
              _armedDisarmTimer = Timer(const Duration(seconds: 10), () {
                if (mounted && _isCtrlMagicArmed) {
                  _disarmMagic();
                }
              });
            }
          });
          setState(() {});
        }
      } else if (_isCtrlMagicArmed) {
        if (key == LogicalKeyboardKey.space) {
          _activateGlobalSearch();
          return true;
        } else if (key == LogicalKeyboardKey.escape) {
          _disarmMagic();
          return true;
        }
      } else if (_isHoldingCtrl && !_isCtrlMagicArmed && !isControlKey) {
        // Interrupted by another key while charging
        _isHoldingCtrl = false;
        _ctrlHoldTimer?.cancel();
        _ctrlChargeController.reverse();
        setState(() {});
      }
    } else if (event is KeyUpEvent) {
      if (isControlKey) {
        _isHoldingCtrl = false;
        _ctrlHoldTimer?.cancel();
        if (!_isCtrlMagicArmed) {
          _ctrlChargeController.reverse();
          setState(() {});
        }
      }
    }

    return false;
  }

  void _activateGlobalSearch() {
    _lastMagicActivatedAt = DateTime.now();
    _armedDisarmTimer?.cancel();
    _ctrlHoldTimer?.cancel();
    _ctrlChargeController.reset();

    setState(() {
      _isCtrlMagicArmed = false;
      _isHoldingCtrl = false;
      _isGlobalSearchMode = true;
      _activeFilter = _FilterType.all;
    });

    _loadGlobalVaultItems();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
        _searchController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _searchController.text.length,
        );
      }
    });
  }

  void _disarmMagic() {
    _armedDisarmTimer?.cancel();
    _ctrlHoldTimer?.cancel();
    _ctrlChargeController.reset();
    if (mounted) {
      setState(() {
        _isCtrlMagicArmed = false;
        _isHoldingCtrl = false;
      });
    }
  }

  void _exitGlobalSearch() {
    setState(() {
      _isGlobalSearchMode = false;
    });
    _ensureSearchFocus();
  }

  void _ensureSearchFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_searchFocusNode.hasFocus) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _clearSearch() {
    if (_searchQuery.isNotEmpty || _searchController.text.isNotEmpty) {
      _searchController.clear();
      _searchQuery = '';
    }
  }

  @override
  void didUpdateWidget(covariant _HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.vaultPath != oldWidget.vaultPath) {
      _navigationStack.clear();
      _loadVault();
      if (_isGlobalSearchMode) {
        _loadGlobalVaultItems();
      }
      _ensureSearchFocus();
    }
  }

  void resetToRoot() {
    _clearSearch();
    if (_isGlobalSearchMode) {
      setState(() {
        _isGlobalSearchMode = false;
      });
    }
    if (_navigationStack.isNotEmpty) {
      setState(() {
        _navigationStack.clear();
        _loadVault();
      });
    }
    _ensureSearchFocus();
  }

  void goUpOneFolder() {
    if (_isGlobalSearchMode) {
      _exitGlobalSearch();
      return;
    }
    if (_navigationStack.isNotEmpty) {
      _clearSearch();
      setState(() {
        _navigationStack.removeLast();
        _loadVault();
      });
      _ensureSearchFocus();
    }
  }

  void navigateToFolder(String folderPath) {
    _clearSearch();
    final root = widget.vaultPath;
    if (root != null && Directory(folderPath).existsSync()) {
      setState(() {
        _isGlobalSearchMode = false;
        _navigationStack.clear();
        if (folderPath != root && p.isWithin(root, folderPath)) {
          final relative = p.relative(folderPath, from: root);
          final parts = p.split(relative);
          String current = root;
          for (final part in parts) {
            current = p.join(current, part);
            _navigationStack.add(current);
          }
        }
        _loadVault();
      });
    }
    _ensureSearchFocus();
  }

  void _loadGlobalVaultItems() {
    final rootPath = widget.vaultPath;
    if (rootPath == null) {
      setState(() {
        _globalCards = [];
        _isGlobalLoading = false;
      });
      return;
    }

    setState(() => _isGlobalLoading = true);

    try {
      final dir = Directory(rootPath);
      if (!dir.existsSync()) {
        setState(() {
          _globalCards = [];
          _isGlobalLoading = false;
        });
        return;
      }

      final List<_CardData> loaded = [];
      final entities = dir.listSync(recursive: true, followLinks: false);

      for (final entity in entities) {
        final relPath = p.relative(entity.path, from: rootPath);
        final segments = p.split(relPath);
        if (segments.any((s) => s.startsWith('.'))) continue;

        final name = p.basename(entity.path);
        if (name == 'super.json') continue;

        if (entity is Directory) {
          int count = 0;
          try {
            count = entity
                .listSync()
                .where((e) => !p.basename(e.path).startsWith('.') && p.basename(e.path) != 'super.json')
                .length;
          } catch (_) {}

          final stats = entity.statSync();
          final parentRel = p.dirname(relPath);
          final subtitle = parentRel == '.' || parentRel.isEmpty
              ? '$count item${count == 1 ? "" : "s"}'
              : '$parentRel • $count item${count == 1 ? "" : "s"}';

          loaded.add(
            _CardData(
              title: name,
              subtitle: subtitle,
              icon: Icons.folder_rounded,
              accentColor: const Color(0xFFE5C07B),
              isFolder: true,
              fullPath: entity.path,
              relativePath: relPath,
              modifiedDate: stats.modified,
              itemCount: count,
            ),
          );
        } else if (entity is File && name.endsWith('.md')) {
          final stats = entity.statSync();
          final formattedDate =
              "${stats.modified.year}-${stats.modified.month.toString().padLeft(2, '0')}-${stats.modified.day.toString().padLeft(2, '0')}";
          final parentRel = p.dirname(relPath);
          final subtitle = parentRel == '.' || parentRel.isEmpty
              ? formattedDate
              : '$parentRel • $formattedDate';

          loaded.add(
            _CardData(
              title: p.basenameWithoutExtension(entity.path),
              subtitle: subtitle,
              icon: Icons.description_outlined,
              accentColor: const Color(0xFF9893A5),
              isFolder: false,
              fullPath: entity.path,
              relativePath: relPath,
              modifiedDate: stats.modified,
            ),
          );
        }
      }

      setState(() {
        _globalCards = loaded;
        _isGlobalLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading global vault items: $e');
      setState(() {
        _globalCards = [];
        _isGlobalLoading = false;
      });
    }
  }

  _ViewMode _loadFolderViewMode(String folderPath) {
    try {
      final configFile = File(p.join(folderPath, 'super.json'));
      if (configFile.existsSync()) {
        final content = configFile.readAsStringSync();
        final decoded = jsonDecode(content);
        if (decoded is Map) {
          final viewType = decoded['view_type'] ?? decoded['viewMode'] ?? decoded['view'];
          if (viewType == 'list') {
            return _ViewMode.list;
          } else if (viewType == 'grid') {
            return _ViewMode.grid;
          }
        }
      } else {
        final config = {
          'view_type': 'grid',
        };
        configFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(config));
        return _ViewMode.grid;
      }
    } catch (e) {
      debugPrint('Error loading/creating super.json for $folderPath: $e');
    }
    return _ViewMode.grid;
  }

  void _saveFolderViewMode(String folderPath, _ViewMode mode) {
    try {
      final configFile = File(p.join(folderPath, 'super.json'));
      Map<String, dynamic> config = {};
      if (configFile.existsSync()) {
        try {
          final content = configFile.readAsStringSync();
          final decoded = jsonDecode(content);
          if (decoded is Map<String, dynamic>) {
            config = Map<String, dynamic>.from(decoded);
          } else if (decoded is Map) {
            config = Map<String, dynamic>.from(decoded.cast<String, dynamic>());
          }
        } catch (_) {}
      }
      config['view_type'] = mode == _ViewMode.grid ? 'grid' : 'list';
      configFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(config));
    } catch (e) {
      debugPrint('Error saving super.json for $folderPath: $e');
    }
  }

  void _loadVault() {
    final rootPath = widget.vaultPath;
    if (rootPath == null) {
      setState(() {
        _cards = [];
        _error = false;
      });
      return;
    }

    final currentPath = _navigationStack.isEmpty ? rootPath : _navigationStack.last;
    setState(() => _isLoading = true);

    try {
      final dir = Directory(currentPath);
      if (!dir.existsSync()) {
        setState(() {
          _cards = [];
          _error = true;
          _isLoading = false;
        });
        return;
      }

      final loadedViewMode = _loadFolderViewMode(currentPath);
      final entities = dir.listSync();
      final List<_CardData> loaded = [];

      for (final entity in entities) {
        final name = p.basename(entity.path);
        if (name.startsWith('.') || name == 'super.json') continue;

        if (entity is Directory) {
          int count = 0;
          try {
            count = entity
                .listSync()
                .where((e) => !p.basename(e.path).startsWith('.') && p.basename(e.path) != 'super.json')
                .length;
          } catch (_) {}

          final stats = entity.statSync();
          final relPath = p.relative(entity.path, from: rootPath);

          loaded.add(
            _CardData(
              title: name,
              subtitle: '$count item${count == 1 ? "" : "s"}',
              icon: Icons.folder_rounded,
              accentColor: const Color(0xFFE5C07B), // Warm amber from inferno-customizer
              isFolder: true,
              fullPath: entity.path,
              relativePath: relPath,
              modifiedDate: stats.modified,
              itemCount: count,
            ),
          );
        } else if (entity is File && name.endsWith('.md')) {
          final stats = entity.statSync();
          final formattedDate =
              "${stats.modified.year}-${stats.modified.month.toString().padLeft(2, '0')}-${stats.modified.day.toString().padLeft(2, '0')}";
          final relPath = p.relative(entity.path, from: rootPath);

          loaded.add(
            _CardData(
              title: p.basenameWithoutExtension(entity.path),
              subtitle: formattedDate,
              icon: Icons.description_outlined,
              accentColor: const Color(0xFF9893A5),
              isFolder: false,
              fullPath: entity.path,
              relativePath: relPath,
              modifiedDate: stats.modified,
            ),
          );
        }
      }

      setState(() {
        _cards = loaded;
        _viewMode = loadedViewMode;
        _error = false;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading vault: $e');
      setState(() {
        _cards = [];
        _error = true;
        _isLoading = false;
      });
    }
  }

  void _toggleFavorite(String path) {
    setState(() {
      if (_favoritePaths.contains(path)) {
        _favoritePaths.remove(path);
      } else {
        _favoritePaths.add(path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (widget.vaultPath == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: ClaudeTheme.bgCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: ClaudeTheme.border, width: 1),
                ),
                child: Icon(
                  Icons.folder_open_outlined,
                  size: 42,
                  color: ClaudeTheme.accent,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'No Vault Folder Selected',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: ClaudeTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: ClaudeTheme.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: widget.onOpenVault ?? widget.onOpenSettings,
                    icon: const Icon(Icons.folder_open_rounded, size: 15),
                    label: const Text(
                      'Open Vault Folder',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: ClaudeTheme.border),
                      foregroundColor: ClaudeTheme.textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: widget.onOpenSettings,
                    icon: const Icon(Icons.settings_outlined, size: 15),
                    label: const Text('Go to Settings'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading || (_isGlobalSearchMode && _isGlobalLoading)) {
      return Center(
        child: CircularProgressIndicator(
          color: ClaudeTheme.accent,
          strokeWidth: 2,
        ),
      );
    }

    if (_error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 42, color: ClaudeTheme.crimson),
              const SizedBox(height: 14),
              Text(
                'Failed to read vault directory. Please verify the folder path in settings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ClaudeTheme.crimson,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: widget.onOpenSettings,
                child: const Text('Go to Settings'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top Breadcrumbs Bar (Teleporting Crumbs) ──
        _buildBreadcrumbs(),

        // ── Cards Grid / List Display ──
        Expanded(
          child: _buildItemsDisplay(),
        ),

        // ── Minimal Search / Filter HUD (At the Bottom) ──
        _buildClaudeSearchBar(),
      ],
    );
  }

  Widget _buildBreadcrumbs() {
    final rootPath = widget.vaultPath;
    if (rootPath == null) return const SizedBox.shrink();

    final vaultName = p.basename(rootPath).isEmpty ? 'Vault' : p.basename(rootPath);
    final isAtRoot = _navigationStack.isEmpty && !_isGlobalSearchMode;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 2),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Row(
            children: [
              // Up / Back arrow button if inside a folder or global search
              if (!isAtRoot) ...[
                _BreadcrumbBackButton(
                  tooltip: 'Go Up (Alt+Left / Esc)',
                  onTap: goUpOneFolder,
                ),
                const SizedBox(width: 8),
              ],

              // Breadcrumb segments
              Expanded(
                child: ClipRect(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Root segment
                        _BreadcrumbSegment(
                          label: vaultName,
                          icon: Icons.folder_copy_outlined,
                          isActive: isAtRoot,
                          tooltip: isAtRoot ? vaultName : 'Jump to "$vaultName" (Root)',
                          onTap: isAtRoot ? null : resetToRoot,
                        ),

                        // Subfolder segments
                        for (int i = 0; i < _navigationStack.length; i++) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: Color(0xFF737169),
                            ),
                          ),
                          _BreadcrumbSegment(
                            label: p.basename(_navigationStack[i]),
                            icon: Icons.folder_rounded,
                            isActive: !_isGlobalSearchMode && i == _navigationStack.length - 1,
                            tooltip: (!_isGlobalSearchMode && i == _navigationStack.length - 1)
                                ? p.basename(_navigationStack[i])
                                : 'Jump to "${p.basename(_navigationStack[i])}"',
                            onTap: (i == _navigationStack.length - 1 && !_isGlobalSearchMode)
                                ? null
                                : () => navigateToFolder(_navigationStack[i]),
                          ),
                        ],

                        // Global search indicator if active
                        if (_isGlobalSearchMode) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: Color(0xFF737169),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ClaudeTheme.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: ClaudeTheme.accent.withValues(alpha: 0.28),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.travel_explore_rounded,
                                  size: 14,
                                  color: ClaudeTheme.accent,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Global Search',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: ClaudeTheme.accent,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  borderRadius: BorderRadius.circular(4),
                                  onTap: _exitGlobalSearch,
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 13,
                                    color: ClaudeTheme.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClaudeSearchBar() {
    return AnimatedBuilder(
      animation: _ctrlChargeController,
      builder: (context, _) {
        final chargeProgress = _ctrlChargeController.value;

        // Clean, simple container styling across all states (no neon glow/aura)
        final containerBg = ClaudeTheme.searchBarBg;
        final containerShadow = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ];

        Color borderColor;
        if (_isCtrlMagicArmed || _isGlobalSearchMode) {
          borderColor = ClaudeTheme.accent.withValues(alpha: 0.55);
        } else if (_isHoldingCtrl) {
          borderColor = Color.lerp(
            _searchFocusNode.hasFocus
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.05),
            ClaudeTheme.accent.withValues(alpha: 0.55),
            chargeProgress,
          )!;
        } else {
          borderColor = _searchFocusNode.hasFocus
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.05);
        }

        // Prefix Icon & Hint Text
        Widget prefixIcon;
        String hintText;

        if (_isCtrlMagicArmed) {
          prefixIcon = Icon(
            Icons.auto_awesome_rounded,
            size: 17,
            color: ClaudeTheme.accent,
          );
          hintText = 'Magic Armed! Press [SPACE] to search vault...';
        } else if (_isGlobalSearchMode) {
          prefixIcon = Icon(
            Icons.travel_explore_rounded,
            size: 17,
            color: ClaudeTheme.accent,
          );
          hintText = 'Global Search: Search all notes & folders across vault...';
        } else {
          prefixIcon = const Icon(
            Icons.search_rounded,
            size: 17,
            color: Color(0xFFA8A69E),
          );
          hintText = 'Search';
        }

        // Suffix Widget
        Widget suffixWidget;
        if (_isCtrlMagicArmed) {
          suffixWidget = GestureDetector(
            onTap: _activateGlobalSearch,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ClaudeTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: ClaudeTheme.accent.withValues(alpha: 0.4),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.space_bar_rounded, size: 13, color: ClaudeTheme.accent),
                    const SizedBox(width: 4),
                    Text(
                      'PRESS SPACE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        fontFamily: 'monospace',
                        color: ClaudeTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else if (_isGlobalSearchMode) {
          suffixWidget = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 15),
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _searchFocusNode.requestFocus();
                  },
                ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(5),
                  onTap: _exitGlobalSearch,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ClaudeTheme.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: ClaudeTheme.accent.withValues(alpha: 0.35), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.travel_explore_rounded, size: 12, color: ClaudeTheme.accent),
                        const SizedBox(width: 4),
                        Text(
                          'GLOBAL MODE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            fontFamily: 'monospace',
                            color: ClaudeTheme.accent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.close_rounded, size: 11, color: ClaudeTheme.textTertiary),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        } else if (_isHoldingCtrl) {
          final remaining = ((1000 - chargeProgress * 1000) / 1000).clamp(0.0, 1.0);
          suffixWidget = Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: ClaudeTheme.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: ClaudeTheme.accent.withValues(alpha: 0.35), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 12, color: ClaudeTheme.accent),
                      const SizedBox(width: 4),
                      Text(
                        'HOLD CTRL (${remaining.toStringAsFixed(1)}s)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          color: ClaudeTheme.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          suffixWidget = _searchQuery.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 15),
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _searchFocusNode.requestFocus();
                  },
                );
        }

        final currentCount = _isGlobalSearchMode ? _globalCards.length : _cards.length;

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Filter Chips Row
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildFilterChip('All', _FilterType.all, currentCount),
                              const SizedBox(width: 6),
                              _buildFilterChip('Notes', _FilterType.notesOnly, totalNotes),
                              const SizedBox(width: 6),
                              _buildFilterChip('Folders', _FilterType.foldersOnly, totalFolders),
                              const SizedBox(width: 6),
                              _buildFilterChip('Favorites', _FilterType.favorites, _favoritePaths.length),
                              if (_isGlobalSearchMode) ...[
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: ClaudeTheme.accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.all_inclusive_rounded, size: 12, color: ClaudeTheme.accent),
                                      const SizedBox(width: 4),
                                      Text(
                                        'GLOBAL VAULT',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'monospace',
                                          letterSpacing: 0.6,
                                          color: ClaudeTheme.accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_filteredCards.length} items',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Color(0xFF737169),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(5),
                        onTap: () {
                          setState(() {
                            _sortBy = _sortBy == _SortBy.name ? _SortBy.modified : _SortBy.name;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Icon(
                            _sortBy == _SortBy.name
                                ? Icons.sort_by_alpha_rounded
                                : Icons.calendar_today_rounded,
                            size: 15,
                            color: const Color(0xFF737169),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        borderRadius: BorderRadius.circular(5),
                        onTap: () {
                          final newMode = _viewMode == _ViewMode.grid ? _ViewMode.list : _ViewMode.grid;
                          setState(() {
                            _viewMode = newMode;
                          });
                          final rootPath = widget.vaultPath;
                          if (rootPath != null) {
                            final currentPath = _navigationStack.isEmpty ? rootPath : _navigationStack.last;
                            _saveFolderViewMode(currentPath, newMode);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Icon(
                            _viewMode == _ViewMode.grid
                                ? Icons.view_list_rounded
                                : Icons.grid_view_rounded,
                            size: 16,
                            color: const Color(0xFF737169),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Search Bar Box
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: containerBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor,
                        width: 1.0,
                      ),
                      boxShadow: containerShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isHoldingCtrl && chargeProgress > 0.0 && !_isCtrlMagicArmed)
                            LinearProgressIndicator(
                              value: chargeProgress,
                              minHeight: 2.0,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(ClaudeTheme.accent),
                            ),
                          TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            autofocus: true,
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                            },
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFFECEBE6),
                            ),
                            decoration: InputDecoration(
                              filled: false,
                              hintText: hintText,
                              hintStyle: TextStyle(
                                color: _isCtrlMagicArmed
                                    ? ClaudeTheme.accent
                                    : const Color(0xFF737169),
                                fontSize: 13,
                              ),
                              prefixIcon: prefixIcon,
                              suffixIcon: suffixWidget,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, _FilterType filter, int count) {
    final isActive = _activeFilter == filter;

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        setState(() => _activeFilter = filter);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? Colors.white.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.04),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? const Color(0xFFECEBE6) : const Color(0xFFA8A69E),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  color: isActive ? ClaudeTheme.accent : const Color(0xFF737169),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemsDisplay() {
    final filtered = _filteredCards;
    final isAtRoot = _navigationStack.isEmpty;

    if (_cards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.folder_zip_outlined,
                size: 44,
                color: Color(0xFF737169),
              ),
              const SizedBox(height: 14),
              const Text(
                'This Folder is Empty',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFECEBE6),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'No subfolders or markdown (.md) notes were found here.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF737169),
                ),
              ),
              if (!isAtRoot) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: goUpOneFolder,
                  icon: const Icon(Icons.arrow_back_rounded, size: 13),
                  label: const Text('Go Back (Alt+Left)'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 44,
                color: Color(0xFF737169),
              ),
              const SizedBox(height: 14),
              Text(
                'No items matching "$_searchQuery"',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFECEBE6),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try a different search query or clear the filter above.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF737169),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _activeFilter = _FilterType.all;
                  });
                },
                child: const Text('Reset Search & Filters'),
              ),
            ],
          ),
        ),
      );
    }

    if (_viewMode == _ViewMode.list) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: _buildListView(filtered),
          ),
        ),
      );
    }

    // Inferno-customizer style separated or unified grid
    final folders = filtered.where((c) => c.isFolder).toList();
    final files = filtered.where((c) => !c.isFolder).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Folders Section (if present) ──
              if (folders.isNotEmpty) ...[
                if (files.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 10, top: 4),
                    child: Text(
                      'FOLDERS',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        fontFamily: 'monospace',
                        color: Color(0xFF797593),
                      ),
                    ),
                  ),
                _buildCardGrid(folders),
              ],

              if (folders.isNotEmpty && files.isNotEmpty)
                const SizedBox(height: 24),

              // ── Notes Section (if present) ──
              if (files.isNotEmpty) ...[
                if (folders.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 10, top: 4),
                    child: Text(
                      'NOTES',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        fontFamily: 'monospace',
                        color: Color(0xFF797593),
                      ),
                    ),
                  ),
                _buildCardGrid(files),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardGrid(List<_CardData> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 700
            ? 3
            : (constraints.maxWidth > 460 ? 2 : 1);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 2.1,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final card = items[index];
            final isFav = _favoritePaths.contains(card.fullPath);

            return _InfernoCustomizerCard(
              card: card,
              isFavorite: isFav,
              onToggleFavorite: () => _toggleFavorite(card.fullPath),
              onTap: () => _onItemTap(card),
            );
          },
        );
      },
    );
  }

  Widget _buildListView(List<_CardData> items) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF21201D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
        itemBuilder: (context, index) {
          final card = items[index];
          final isFav = _favoritePaths.contains(card.fullPath);

          return _ClaudeListRow(
            card: card,
            isFavorite: isFav,
            onToggleFavorite: () => _toggleFavorite(card.fullPath),
            onTap: () => _onItemTap(card),
          );
        },
      ),
    );
  }

  void _onItemTap(_CardData card) {
    if (card.isFolder) {
      _clearSearch();
      final root = widget.vaultPath;
      if (_isGlobalSearchMode && root != null && p.isWithin(root, card.fullPath)) {
        final relative = p.relative(card.fullPath, from: root);
        final parts = p.split(relative);
        final List<String> newStack = [];
        String current = root;
        for (final part in parts) {
          current = p.join(current, part);
          newStack.add(current);
        }
        setState(() {
          _isGlobalSearchMode = false;
          _navigationStack.clear();
          _navigationStack.addAll(newStack);
          _loadVault();
        });
      } else {
        setState(() {
          _navigationStack.add(card.fullPath);
          _loadVault();
        });
      }
      _ensureSearchFocus();
    } else {
      Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => NoteViewerScreen(
            filePath: card.fullPath,
            vaultPath: widget.vaultPath,
            parentFolderShortcut: widget.parentFolderShortcut,
            homeRootShortcut: widget.homeRootShortcut,
          ),
        ),
      ).then((resultDir) {
        if (resultDir != null && resultDir.isNotEmpty) {
          if (resultDir == '__ROOT__') {
            resetToRoot();
          } else {
            navigateToFolder(resultDir);
          }
        }
        _ensureSearchFocus();
      });
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isControl = HardwareKeyboard.instance.isControlPressed;
    final isMeta = HardwareKeyboard.instance.isMetaPressed;
    final isAlt = HardwareKeyboard.instance.isAltPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;
    final key = event.logicalKey;

    // 0. Magic Armed Space or Escape Handling
    if (_isCtrlMagicArmed) {
      if (key == LogicalKeyboardKey.space) {
        _activateGlobalSearch();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.escape) {
        _disarmMagic();
        return KeyEventResult.handled;
      }
    }

    // 1. Home directory shortcut check (Global / Always active)
    if (widget.homeRootShortcut != null) {
      final s = widget.homeRootShortcut!;
      if (key == s.trigger &&
          s.control == isControl &&
          s.alt == isAlt &&
          s.shift == isShift &&
          s.meta == isMeta) {
        widget.onHomeRoot?.call();
        return KeyEventResult.handled;
      }
    }

    // Default Ctrl+Space or Ctrl+H / Alt+Home fallback for Home Root (only if not armed and not in global search)
    if (!_isCtrlMagicArmed && !_isGlobalSearchMode && ((isControl && key == LogicalKeyboardKey.space) ||
        ((isControl || isAlt) && (key == LogicalKeyboardKey.home || key == LogicalKeyboardKey.keyH)))) {
      widget.onHomeRoot?.call();
      return KeyEventResult.handled;
    }

    // 2. Return to Parent Folder shortcut check (Default Alt+Left)
    if (widget.parentFolderShortcut != null) {
      final s = widget.parentFolderShortcut!;
      if (key == s.trigger &&
          s.control == isControl &&
          s.alt == isAlt &&
          s.shift == isShift &&
          s.meta == isMeta) {
        goUpOneFolder();
        return KeyEventResult.handled;
      }
    }

    // Default Alt+Left fallback for returning to parent folder
    if (isAlt && key == LogicalKeyboardKey.arrowLeft) {
      goUpOneFolder();
      return KeyEventResult.handled;
    }

    // 3. Escape key: clear search or exit global search or navigate up directory hierarchy
    if (key == LogicalKeyboardKey.escape) {
      if (_searchQuery.isNotEmpty || _searchController.text.isNotEmpty) {
        _searchController.clear();
        setState(() => _searchQuery = '');
        _ensureSearchFocus();
        return KeyEventResult.handled;
      }
      if (_isGlobalSearchMode) {
        _exitGlobalSearch();
        return KeyEventResult.handled;
      }
      if (_navigationStack.isNotEmpty) {
        goUpOneFolder();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // 4. Backspace key handling (always removes text smoothly)
    if (key == LogicalKeyboardKey.backspace) {
      if (_searchController.text.isNotEmpty) {
        final text = _searchController.text;
        final sel = _searchController.selection;

        if (sel.isValid && !sel.isCollapsed && sel.start >= 0 && sel.end <= text.length) {
          final newText = text.replaceRange(sel.start, sel.end, '');
          _searchController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: sel.start),
          );
          setState(() => _searchQuery = newText);
          _ensureSearchFocus();
          return KeyEventResult.handled;
        }

        final cursor = sel.isValid && sel.baseOffset > 0 ? sel.baseOffset : text.length;
        if (cursor > 0 && cursor <= text.length) {
          final newText = text.replaceRange(cursor - 1, cursor, '');
          _searchController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: cursor - 1),
          );
          setState(() => _searchQuery = newText);
          _ensureSearchFocus();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.handled;
    }

    // 5. Ignore modifier combinations (Ctrl+C, Ctrl+V, etc.)
    if (isControl || isAlt || isMeta) return KeyEventResult.ignored;

    // 6. Type-to-search: automatically routes keystrokes to the search box
    if (!_searchFocusNode.hasFocus) {
      final character = event.character;
      if (character != null && character.isNotEmpty && character.codeUnitAt(0) >= 32) {
        _searchFocusNode.requestFocus();
        final currentText = _searchController.text;
        final newText = currentText + character;
        _searchController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
        setState(() => _searchQuery = newText);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }
}

/// Pure-fill, borderless minimal card matching inferno-customizer's dashboard card.
/// Features dynamic spotlight & glare radial glow on hover, pure fill transitions,
/// crisp icon title row, and monospace meta bottom row.
class _InfernoCustomizerCard extends StatefulWidget {
  final _CardData card;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;

  const _InfernoCustomizerCard({
    required this.card,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onTap,
  });

  @override
  State<_InfernoCustomizerCard> createState() => _InfernoCustomizerCardState();
}

class _InfernoCustomizerCardState extends State<_InfernoCustomizerCard> {
  bool _isHovered = false;
  bool _isPressed = false;
  Offset _mousePos = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final card = widget.card;

    // Inferno customizer pure fill colors matching current theme
    final bgColor = _isHovered
        ? ClaudeTheme.cardHoverColor
        : ClaudeTheme.cardBaseColor;

    final double translateY = _isPressed ? -1.0 : (_isHovered ? -4.0 : 0.0);
    final double scale = _isPressed ? 0.98 : (_isHovered ? 1.025 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      onHover: (event) {
        setState(() {
          _mousePos = event.localPosition;
        });
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: const Cubic(0.25, 0.8, 0.25, 1.0),
          transform: Matrix4.identity()
            ..translateByDouble(0.0, translateY, 0.0, 1.0)
            ..scaleByDouble(scale, scale, 1.0, 1.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: null, // Pure fill: No edge strokes / borders!
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.45 : 0.25),
                blurRadius: _isHovered ? 24.0 : 16.0,
                offset: Offset(0, _isHovered ? 8.0 : 4.0),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                final shortestSide = width < height ? width : height;

                final spotlightRadius = shortestSide > 0 ? 250.0 / shortestSide : 1.0;
                final alignmentX = width > 0 ? (_mousePos.dx / width) * 2 - 1 : 0.0;
                final alignmentY = height > 0 ? (_mousePos.dy / height) * 2 - 1 : 0.0;
                final mouseAlignment = Alignment(alignmentX, alignmentY);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Spotlight radial glow following cursor
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: _isHovered ? 1.0 : 0.0,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: mouseAlignment,
                              radius: spotlightRadius,
                              colors: [
                                Colors.white.withValues(alpha: 0.05),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.8],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Glare overlay
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: _isHovered ? 1.0 : 0.0,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            backgroundBlendMode: BlendMode.overlay,
                            gradient: RadialGradient(
                              center: mouseAlignment,
                              radius: 1.2,
                              colors: [
                                Colors.white.withValues(alpha: 0.06),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.6],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Minimal Card Content (Title Row + Bottom Meta Row)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Title Row
                          Row(
                            children: [
                              Icon(
                                card.icon,
                                color: card.isFolder
                                    ? ClaudeTheme.folderAccent
                                    : ClaudeTheme.noteAccent,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  card.title,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                    color: ClaudeTheme.textPrimary,
                                  ),
                                ),
                              ),
                              if (widget.isFavorite)
                                const Icon(
                                  Icons.star_rounded,
                                  size: 15,
                                  color: Color(0xFFEA9D34),
                                ),
                            ],
                          ),

                          const Spacer(),

                          // Card Bottom Subtitle Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  card.subtitle,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w500,
                                    color: ClaudeTheme.textSecondary.withValues(alpha: 0.75),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ClaudeListRow extends StatefulWidget {
  final _CardData card;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;

  const _ClaudeListRow({
    required this.card,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onTap,
  });

  @override
  State<_ClaudeListRow> createState() => _ClaudeListRowState();
}

class _ClaudeListRowState extends State<_ClaudeListRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final card = widget.card;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: _isHovered ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
          child: Row(
            children: [
              Icon(
                card.icon,
                size: 18,
                color: card.isFolder
                    ? ClaudeTheme.folderAccent
                    : ClaudeTheme.noteAccent,
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Text(
                  card.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: ClaudeTheme.textPrimary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  card.isFolder ? 'FOLDER' : 'NOTE',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: ClaudeTheme.textTertiary,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  card.subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: ClaudeTheme.textTertiary,
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

class _BreadcrumbSegment extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final String? tooltip;
  final VoidCallback? onTap;

  const _BreadcrumbSegment({
    required this.label,
    required this.icon,
    required this.isActive,
    this.tooltip,
    this.onTap,
  });

  @override
  State<_BreadcrumbSegment> createState() => _BreadcrumbSegmentState();
}

class _BreadcrumbSegmentState extends State<_BreadcrumbSegment> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final clickable = widget.onTap != null;

    final content = MouseRegion(
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
                  : (widget.isActive ? Colors.white.withValues(alpha: 0.04) : Colors.transparent),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: widget.isActive
                    ? Colors.white.withValues(alpha: 0.10)
                    : (_isHovered ? Colors.white.withValues(alpha: 0.12) : Colors.transparent),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 14,
                  color: widget.isActive
                      ? ClaudeTheme.accent
                      : (_isHovered ? const Color(0xFFECEBE6) : const Color(0xFF9893A5)),
                ),
                const SizedBox(width: 5),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                    color: widget.isActive
                        ? const Color(0xFFECEBE6)
                        : (_isHovered ? const Color(0xFFECEBE6) : const Color(0xFFA8A69E)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: content,
      );
    }
    return content;
  }
}

class _BreadcrumbBackButton extends StatefulWidget {
  final String tooltip;
  final VoidCallback onTap;

  const _BreadcrumbBackButton({
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_BreadcrumbBackButton> createState() => _BreadcrumbBackButtonState();
}

class _BreadcrumbBackButtonState extends State<_BreadcrumbBackButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: _isHovered ? Colors.white.withValues(alpha: 0.10) : const Color(0xFF24221F),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _isHovered ? Colors.white.withValues(alpha: 0.18) : const Color(0xFF3B3835),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 14,
              color: Color(0xFFECEBE6),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool isFolder;
  final String fullPath;
  final String? relativePath;
  final DateTime? modifiedDate;
  final int itemCount;

  const _CardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.isFolder,
    required this.fullPath,
    this.relativePath,
    this.modifiedDate,
    this.itemCount = 0,
  });
}

class _SearchScreen extends StatefulWidget {
  final String? vaultPath;
  final ValueChanged<String>? onOpenNote;

  const _SearchScreen({super.key, this.vaultPath, this.onOpenNote});

  @override
  State<_SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<_SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<_SearchResult> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String query) {
    final root = widget.vaultPath;
    if (root == null || query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final dir = Directory(root);
      if (!dir.existsSync()) {
        setState(() {
          _results = [];
          _isSearching = false;
        });
        return;
      }

      final q = query.trim().toLowerCase();
      final List<_SearchResult> matches = [];

      final entities = dir.listSync(recursive: true);
      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.md')) {
          final fileName = p.basenameWithoutExtension(entity.path);
          final relativePath = p.relative(entity.path, from: root);

          if (fileName.toLowerCase().contains(q)) {
            matches.add(_SearchResult(
              filePath: entity.path,
              relativePath: relativePath,
              title: fileName,
              matchType: 'Filename match',
            ));
          } else {
            try {
              final content = entity.readAsStringSync();
              final lines = content.split('\n');
              for (int i = 0; i < lines.length; i++) {
                if (lines[i].toLowerCase().contains(q)) {
                  matches.add(_SearchResult(
                    filePath: entity.path,
                    relativePath: relativePath,
                    title: fileName,
                    matchType: 'Line ${i + 1}: ${lines[i].trim()}',
                  ));
                  break; // 1 match per file
                }
              }
            } catch (_) {}
          }
        }
      }

      setState(() {
        _results = matches;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() {
        _results = [];
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deep Search',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: ClaudeTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Search across note titles, contents, and subdirectories in your vault.',
                style: TextStyle(
                  fontSize: 13,
                  color: ClaudeTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _search,
                decoration: InputDecoration(
                  hintText: 'Type to search all markdown notes in vault...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 15),
                          onPressed: () {
                            _controller.clear();
                            _search('');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              if (widget.vaultPath == null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text(
                      'Please configure a vault in settings to enable full-text search.',
                      style: TextStyle(color: ClaudeTheme.textTertiary),
                    ),
                  ),
                ),
              ] else if (_isSearching) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: CircularProgressIndicator(
                      color: ClaudeTheme.accent,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ] else if (_results.isNotEmpty) ...[
                Text(
                  '${_results.length} results found',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontFamily: 'monospace',
                    color: ClaudeTheme.textTertiary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: ClaudeTheme.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ClaudeTheme.border, width: 1),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _results.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: ClaudeTheme.border),
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      return ListTile(
                        leading: Icon(
                          Icons.description_rounded,
                          size: 18,
                          color: ClaudeTheme.accent,
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: ClaudeTheme.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '${item.relativePath} • ${item.matchType}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: ClaudeTheme.textTertiary,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: ClaudeTheme.textTertiary,
                        ),
                        onTap: () {
                          widget.onOpenNote?.call(item.filePath);
                        },
                      );
                    },
                  ),
                ),
              ] else if (_controller.text.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No notes found matching "${_controller.text}"',
                      style: TextStyle(color: ClaudeTheme.textTertiary),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResult {
  final String filePath;
  final String relativePath;
  final String title;
  final String matchType;

  const _SearchResult({
    required this.filePath,
    required this.relativePath,
    required this.title,
    required this.matchType,
  });
}

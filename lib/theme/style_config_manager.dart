import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'claude_theme.dart';
import 'font_manager.dart';

/// Manages loading and persisting theme, render, and font configuration files
/// in `<vaultPath>/.superwave/style/theme.json` and `<vaultPath>/.superwave/style/render.json`.
class StyleConfigManager {
  static String getStyleDir(String vaultPath) => p.join(vaultPath, '.superwave', 'style');
  static String getThemeFile(String vaultPath) => p.join(getStyleDir(vaultPath), 'theme.json');
  static String getRenderFile(String vaultPath) => p.join(getStyleDir(vaultPath), 'render.json');
  static String getFontsDir(String vaultPath) => p.join(getStyleDir(vaultPath), 'fonts');

  /// Load theme.json, render.json, and local font files from the vault's `.superwave/style/` folder.
  static Future<void> loadConfig(String vaultPath, {ValueChanged<AppThemeId>? onThemeLoaded}) async {
    loadThemeConfig(vaultPath, onThemeLoaded: onThemeLoaded);
    loadRenderConfig(vaultPath);
    await FontManager.loadAllVaultFonts(vaultPath);
  }

  /// Load theme configuration from `<vaultPath>/.superwave/style/theme.json`.
  static AppThemeId? loadThemeConfig(String vaultPath, {ValueChanged<AppThemeId>? onThemeLoaded}) {
    try {
      final file = File(getThemeFile(vaultPath));
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        final decoded = jsonDecode(content);
        if (decoded is Map) {
          final themeStr = decoded['theme'] ?? decoded['themeId'] ?? decoded['id'];
          if (themeStr is String) {
            for (final theme in AppThemeId.values) {
              if (theme.name.toLowerCase() == themeStr.toLowerCase()) {
                ClaudeTheme.setTheme(theme);
                onThemeLoaded?.call(theme);
                return theme;
              }
            }
          }
        }
      } else {
        // Auto-create initial theme.json with the current theme
        saveThemeConfig(vaultPath, ClaudeTheme.current.id);
      }
    } catch (e) {
      debugPrint('Error loading theme config from $vaultPath: $e');
    }
    return null;
  }

  /// Save theme configuration to `<vaultPath>/.superwave/style/theme.json`.
  static void saveThemeConfig(String vaultPath, AppThemeId themeId) {
    try {
      final dir = Directory(getStyleDir(vaultPath));
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final file = File(getThemeFile(vaultPath));
      final themeData = AppThemeData.fromId(themeId);
      final jsonMap = {
        'theme': themeId.name,
        'name': themeData.name,
        'description': themeData.description,
      };
      file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(jsonMap));
    } catch (e) {
      debugPrint('Error saving theme config to $vaultPath: $e');
    }
  }

  /// Load render overrides and typography configuration from `<vaultPath>/.superwave/style/render.json`.
  static Map<String, int> loadRenderConfig(String vaultPath) {
    try {
      final file = File(getRenderFile(vaultPath));
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        final decoded = jsonDecode(content);
        if (decoded is Map) {
          // 1. Parse font typography assignments
          if (decoded['fonts'] is Map) {
            final fontMap = Map<String, String>.from(
              (decoded['fonts'] as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
            );
            ClaudeTheme.setAllFontAssignments(fontMap);
          }

          // 2. Parse color overrides
          final Map<String, int> overrides = {};
          final rawMap = decoded['overrides'] is Map ? decoded['overrides'] as Map : decoded;
          for (final entry in rawMap.entries) {
            final key = entry.key.toString();
            if (key == 'fonts' || key == 'downloaded_fonts') continue;
            final val = entry.value;
            if (val is int) {
              overrides[key] = val;
            } else if (val is String) {
              // Parse hex string e.g. "#FF5722" or "FF5722"
              var clean = val.replaceAll('#', '').trim();
              if (clean.length == 6) clean = 'FF$clean';
              if (clean.length == 8) {
                final intVal = int.tryParse(clean, radix: 16);
                if (intVal != null) {
                  overrides[key] = intVal;
                }
              }
            } else if (val is Map && val['argb'] is int) {
              overrides[key] = val['argb'] as int;
            } else if (val is Map && val['hex'] is String) {
              var clean = (val['hex'] as String).replaceAll('#', '').trim();
              if (clean.length == 6) clean = 'FF$clean';
              if (clean.length == 8) {
                final intVal = int.tryParse(clean, radix: 16);
                if (intVal != null) {
                  overrides[key] = intVal;
                }
              }
            }
          }
          ClaudeTheme.setAllRenderOverrides(overrides);
          return overrides;
        }
      } else {
        // Auto-create initial render.json
        saveRenderConfig(vaultPath, ClaudeTheme.renderOverrides);
      }
    } catch (e) {
      debugPrint('Error loading render config from $vaultPath: $e');
    }
    return {};
  }

  /// Save render overrides and typography configuration to `<vaultPath>/.superwave/style/render.json`.
  static void saveRenderConfig(String vaultPath, Map<String, int> overrides) {
    try {
      final dir = Directory(getStyleDir(vaultPath));
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final file = File(getRenderFile(vaultPath));

      // Read existing JSON to preserve other top-level keys
      Map<String, dynamic> existingJson = {};
      if (file.existsSync()) {
        try {
          final content = file.readAsStringSync();
          final decoded = jsonDecode(content);
          if (decoded is Map<String, dynamic>) {
            existingJson = decoded;
          } else if (decoded is Map) {
            existingJson = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      }

      // Build color overrides map
      final Map<String, dynamic> overridesMap = {};
      for (final entry in overrides.entries) {
        final rgb = entry.value & 0x00FFFFFF;
        final hex = '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
        overridesMap[entry.key] = {
          'hex': hex,
          'argb': entry.value,
        };
      }

      // Build downloaded fonts list from local directory
      final installedFonts = FontManager.getInstalledFonts(vaultPath);

      final jsonMap = {
        ...existingJson,
        'fonts': ClaudeTheme.fontAssignments,
        'downloaded_fonts': installedFonts,
        'overrides': overridesMap,
      };

      file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(jsonMap));
    } catch (e) {
      debugPrint('Error saving render config to $vaultPath: $e');
    }
  }

  /// Save font assignments directly to `<vaultPath>/.superwave/style/render.json`.
  static void saveFontAssignment(String vaultPath, String slot, String? family) {
    ClaudeTheme.setFontAssignment(slot, family);
    saveRenderConfig(vaultPath, ClaudeTheme.renderOverrides);
  }
}


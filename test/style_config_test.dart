import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:superwave/main.dart';
import 'package:superwave/theme/claude_theme.dart';
import 'package:superwave/theme/style_config_manager.dart';

void main() {
  test('StyleConfigManager creates and saves theme.json and render.json in .superwave/style/', () {
    final tempDir = Directory.systemTemp.createTempSync('superwave_style_test_');
    try {
      // 1. Save theme config
      StyleConfigManager.saveThemeConfig(tempDir.path, AppThemeId.nordicArctic);
      final themeFile = File(p.join(tempDir.path, '.superwave', 'style', 'theme.json'));
      expect(themeFile.existsSync(), isTrue);

      final themeJson = jsonDecode(themeFile.readAsStringSync());
      expect(themeJson['theme'], equals('nordicArctic'));
      expect(themeJson['name'], equals('Nordic Arctic'));

      // 2. Save render config with custom overrides
      const customBold = Color(0xFF10B981);
      const customHighlight = Color(0xFFFF5722);
      final overrides = {
        'bold': customBold.toARGB32(),
        'highlight': customHighlight.toARGB32(),
      };
      StyleConfigManager.saveRenderConfig(tempDir.path, overrides);

      final renderFile = File(p.join(tempDir.path, '.superwave', 'style', 'render.json'));
      expect(renderFile.existsSync(), isTrue);

      final renderJson = jsonDecode(renderFile.readAsStringSync());
      expect(renderJson['overrides'], isNotNull);
      expect(renderJson['overrides']['bold']['argb'], equals(customBold.toARGB32()));
      expect(renderJson['overrides']['bold']['hex'], equals('#10B981'));
      expect(renderJson['overrides']['highlight']['argb'], equals(customHighlight.toARGB32()));

      // 3. Test loading theme & render config back
      ClaudeTheme.resetAllRenderOverrides();
      ClaudeTheme.setTheme(AppThemeId.claudeWarmDark);

      AppThemeId? loadedTheme;
      StyleConfigManager.loadConfig(tempDir.path, onThemeLoaded: (t) => loadedTheme = t);

      expect(loadedTheme, equals(AppThemeId.nordicArctic));
      expect(ClaudeTheme.current.id, equals(AppThemeId.nordicArctic));
      expect(ClaudeTheme.renderColors.bold.toARGB32(), equals(customBold.toARGB32()));
      expect(ClaudeTheme.renderColors.highlight.toARGB32(), equals(customHighlight.toARGB32()));
    } finally {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  });

  testWidgets('SuperWaveApp automatically creates .superwave/style/theme.json and render.json on vault load',
      (WidgetTester tester) async {
    final tempDir = Directory.systemTemp.createTempSync('superwave_app_style_test_');
    try {
      File(p.join(tempDir.path, 'Test.md')).writeAsStringSync('# Test Note');

      await tester.pumpWidget(SuperWaveApp(initialVaultPath: tempDir.path));
      await tester.pumpAndSettle();

      final themeFile = File(p.join(tempDir.path, '.superwave', 'style', 'theme.json'));
      final renderFile = File(p.join(tempDir.path, '.superwave', 'style', 'render.json'));

      expect(themeFile.existsSync(), isTrue);
      expect(renderFile.existsSync(), isTrue);

      // Verify theme.json contains valid theme data
      final themeContent = jsonDecode(themeFile.readAsStringSync());
      expect(themeContent['theme'], isNotNull);

      // Verify render.json contains overrides map
      final renderContent = jsonDecode(renderFile.readAsStringSync());
      expect(renderContent['overrides'], isNotNull);
    } finally {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  });
}

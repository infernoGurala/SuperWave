import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superwave/settings_screen.dart';
import 'package:superwave/theme/claude_theme.dart';

void main() {
  testWidgets('Appearance tab renders 5 themes and switches theme when selected', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    AppThemeId currentTheme = AppThemeId.claudeWarmDark;
    ClaudeTheme.setTheme(currentTheme);

    await tester.pumpWidget(
      MaterialApp(
        theme: ClaudeTheme.darkTheme,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SettingsScreen(
                vaultPath: '/mock/vault',
                onVaultPathChanged: (_) {},
                homeRootShortcut: const AppShortcut(
                  trigger: LogicalKeyboardKey.space,
                  control: true,
                ),
                onShortcutChanged: (_) {},
                parentFolderShortcut: const AppShortcut(
                  trigger: LogicalKeyboardKey.arrowLeft,
                  alt: true,
                ),
                onParentFolderShortcutChanged: (_) {},
                currentTheme: currentTheme,
                onThemeChanged: (newTheme) {
                  setState(() {
                    currentTheme = newTheme;
                    ClaudeTheme.setTheme(newTheme);
                  });
                },
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on Appearance Tab in Settings navigation
    final appearanceNav = find.text('Appearance');
    expect(appearanceNav, findsOneWidget);
    await tester.tap(appearanceNav);
    await tester.pumpAndSettle();

    // Verify sub-tab switcher is present
    expect(find.text('Themes'), findsOneWidget);
    expect(find.text('Render'), findsOneWidget);

    // Verify all 5 themes are displayed
    expect(find.text('Claude Warm Dark'), findsOneWidget);
    expect(find.text('Obsidian Onyx'), findsOneWidget);
    expect(find.text('Evergreen Forest'), findsOneWidget);
    expect(find.text('Nordic Arctic'), findsOneWidget);
    expect(find.text('Espresso Amber'), findsOneWidget);

    // Initial theme has ACTIVE badge
    expect(find.text('ACTIVE'), findsOneWidget);

    // Select Obsidian Onyx
    await tester.tap(find.text('Obsidian Onyx'));
    await tester.pumpAndSettle();

    expect(currentTheme, equals(AppThemeId.obsidianOnyx));
    expect(ClaudeTheme.current.id, equals(AppThemeId.obsidianOnyx));
    expect(find.text('ACTIVE'), findsOneWidget);

    // Select Nordic Arctic
    await tester.tap(find.text('Nordic Arctic'));
    await tester.pumpAndSettle();

    expect(currentTheme, equals(AppThemeId.nordicArctic));
    expect(ClaudeTheme.current.id, equals(AppThemeId.nordicArctic));
  });

  testWidgets('Render sub-tab displays markdown customization categories, preview, and allows color overrides',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    AppThemeId currentTheme = AppThemeId.claudeWarmDark;
    ClaudeTheme.setTheme(currentTheme);
    ClaudeTheme.resetAllRenderOverrides();

    await tester.pumpWidget(
      MaterialApp(
        theme: ClaudeTheme.darkTheme,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SettingsScreen(
                vaultPath: '/mock/vault',
                onVaultPathChanged: (_) {},
                homeRootShortcut: const AppShortcut(
                  trigger: LogicalKeyboardKey.space,
                  control: true,
                ),
                onShortcutChanged: (_) {},
                parentFolderShortcut: const AppShortcut(
                  trigger: LogicalKeyboardKey.arrowLeft,
                  alt: true,
                ),
                onParentFolderShortcutChanged: (_) {},
                currentTheme: currentTheme,
                onThemeChanged: (newTheme) {
                  setState(() {
                    currentTheme = newTheme;
                    ClaudeTheme.setTheme(newTheme);
                  });
                },
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Go to Appearance tab
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();

    // Switch to Render sub-tab
    await tester.tap(find.text('Render'));
    await tester.pumpAndSettle();

    // Verify Live Markdown Preview is rendered
    expect(find.text('LIVE MARKDOWN PREVIEW'), findsOneWidget);
    expect(find.text('# Heading 1 Document Title'), findsOneWidget);
    expect(find.text('==highlighted=='), findsNWidgets(2)); // in live preview and syntax badge

    // Verify category groups
    expect(find.text('TEXT STYLES'), findsOneWidget);
    expect(find.text('HEADINGS'), findsOneWidget);
    expect(find.text('CODE & BLOCKS'), findsOneWidget);
    expect(find.text('LISTS & TABLES'), findsOneWidget);

    // Verify element entries
    expect(find.text('Bold'), findsOneWidget);
    expect(find.text('Highlight'), findsOneWidget);
    expect(find.text('Link'), findsOneWidget);
    expect(find.text('Inline Code'), findsOneWidget);

    // Test setting a custom override programmatically
    const customHighlight = Color(0xFFFF0055);
    ClaudeTheme.setRenderOverride('highlight', customHighlight.toARGB32());
    await tester.pumpAndSettle();

    expect(ClaudeTheme.renderColors.highlight.toARGB32(), equals(customHighlight.toARGB32()));
    expect(ClaudeTheme.renderOverrides.containsKey('highlight'), isTrue);

    // Test resetting override
    ClaudeTheme.resetAllRenderOverrides();
    await tester.pumpAndSettle();

    expect(ClaudeTheme.renderOverrides.isEmpty, isTrue);
  });
}

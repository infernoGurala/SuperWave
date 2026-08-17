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
}

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superwave/main.dart';
import 'package:superwave/settings_screen.dart';

void main() {
  testWidgets('Default Ctrl+Space hotkey navigates to Home tab', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const SuperWaveApp());
    await tester.pumpAndSettle();

    // Verify we start on the Home screen (shows "No Vault Folder Selected")
    expect(find.text('No Vault Folder Selected'), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);

    // Switch to Settings tab using the settings button
    final settingsButton = find.text('Go to Settings');
    expect(settingsButton, findsOneWidget);
    await tester.tap(settingsButton);
    await tester.pumpAndSettle();

    // Verify we are now on the Settings screen
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('No Vault Folder Selected'), findsNothing);

    // Press Ctrl + Space
    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pumpAndSettle();

    // Verify we navigated back to the Home screen
    expect(find.text('No Vault Folder Selected'), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);
  });

  testWidgets('Hotkey is editable and dynamic shortcut works', (WidgetTester tester) async {
    await tester.pumpWidget(const SuperWaveApp());
    await tester.pumpAndSettle();

    // Go to Settings screen
    final settingsButton = find.text('Go to Settings');
    await tester.tap(settingsButton);
    await tester.pumpAndSettle();

    // Go to Hotkeys tab in Settings
    final hotkeysTab = find.text('Hotkeys');
    await tester.tap(hotkeysTab);
    await tester.pumpAndSettle();

    // Verify both shortcuts are listed
    expect(find.text('Go to Home & Root'), findsOneWidget);
    expect(find.text('Return to Parent Folder'), findsOneWidget);

    // Verify key badges display defaults
    expect(find.text('CTRL'), findsNWidgets(2));
    expect(find.text('SPACE'), findsNWidgets(3));
    expect(find.text('ALT'), findsOneWidget);
    expect(find.text('LEFT'), findsOneWidget);

    // Click first Edit button (for Home & Root)
    final editButton = find.text('Edit').first;
    await tester.tap(editButton);
    await tester.pumpAndSettle();

    // Verify listener is active
    expect(find.textContaining('Press new keys'), findsOneWidget);

    // Press Alt + G
    await tester.sendKeyDownEvent(LogicalKeyboardKey.alt);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.alt);
    await tester.pumpAndSettle();

    // Verify editing state is finished
    expect(find.textContaining('Press new keys'), findsNothing);

    // Verify UI displays new key badge "G"
    expect(find.text('G'), findsOneWidget);

    // Press old shortcut (Ctrl + Space)
    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pumpAndSettle();

    // Verify we are STILL on the Settings screen (Ctrl+Space should do nothing now)
    expect(find.byType(SettingsScreen), findsOneWidget);

    // Press new shortcut (Alt + G)
    await tester.sendKeyDownEvent(LogicalKeyboardKey.alt);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.alt);
    await tester.pumpAndSettle();

    // Verify we navigated back to the Home screen
    expect(find.text('No Vault Folder Selected'), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);
  });
}

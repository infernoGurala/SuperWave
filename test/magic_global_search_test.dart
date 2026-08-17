import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superwave/main.dart';

void main() {
  testWidgets('Pressing Ctrl + Space + Space instantly activates Global Search Mode',
      (WidgetTester tester) async {
    final tempDir = Directory.systemTemp.createTempSync('superwave_test_vault_');
    try {
      final subFolder = Directory('${tempDir.path}/Projects')..createSync();
      File('${tempDir.path}/RootNote.md').writeAsStringSync('# Root Note');
      File('${subFolder.path}/SubNote.md').writeAsStringSync('# Sub Note');

      await tester.pumpWidget(SuperWaveApp(initialVaultPath: tempDir.path));
      await tester.pumpAndSettle();

      // Verify notes in root are loaded
      expect(find.text('RootNote'), findsOneWidget);
      expect(find.text('SubNote'), findsNothing); // In subfolder, not visible at root initially

      // Press Ctrl + Space (1st space)
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump(const Duration(milliseconds: 100));

      // Press Space again within double-tap window (2nd space -> Ctrl + Space + Space!)
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      // Verify Global Search mode is ACTIVE instantly!
      expect(find.text('GLOBAL MODE'), findsOneWidget);
      expect(find.textContaining('Global Search: Search all notes & folders'), findsOneWidget);
      expect(find.text('SubNote'), findsOneWidget);
      expect(find.text('Projects'), findsOneWidget);

      // Press Escape -> exits Global Search mode back to normal
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('GLOBAL MODE'), findsNothing);
      expect(find.text('SubNote'), findsNothing);
      expect(find.text('RootNote'), findsOneWidget);
    } finally {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  });
}

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superwave/main.dart';

void main() {
  testWidgets('Holding Ctrl for 1s arms magic and pressing Space activates Global Search',
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

      // Verify initial Ctrl press starts charging
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('HOLD CTRL'), findsOneWidget);

      // Release early (<1s) -> resets
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('HOLD CTRL'), findsNothing);
      expect(find.textContaining('PRESS SPACE'), findsNothing);

      // Now hold Ctrl for full 1 second
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.pump(const Duration(milliseconds: 1100));

      // Verify magic is ARMED! (Shows PRESS SPACE badge and magic text)
      expect(find.text('PRESS SPACE'), findsOneWidget);
      expect(find.textContaining('Magic Armed'), findsOneWidget);

      // Press Space while armed -> activates Global Search!
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      // Verify Global Search mode is ACTIVE and finds both root & nested files/folders
      expect(find.text('GLOBAL MODE'), findsOneWidget);
      expect(find.textContaining('Search all notes & folders'), findsOneWidget);
      expect(find.text('SubNote'), findsOneWidget);
      expect(find.text('Projects'), findsOneWidget);

      // Press Escape -> exits Global Search mode back to normal
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('GLOBAL MODE'), findsNothing);
    } finally {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  });
}

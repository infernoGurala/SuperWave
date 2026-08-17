import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superwave/note_viewer_screen.dart';

void main() {
  testWidgets('note viewer renders markdown', (tester) async {
    await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('sw_note_test');
      final file = File('${dir.path}/test_note.md');
      await file.writeAsString(
        '# Heading One\n\nSome **bold** and *italic* text with `code`.\n\n'
        '- item one\n- item two\n\n> a quote\n\n[link](https://example.com)',
      );

      await tester.pumpWidget(
        MaterialApp(home: NoteViewerScreen(filePath: file.path)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.text('Heading One'), findsOneWidget);
      expect(find.textContaining('Some'), findsOneWidget);
      expect(find.textContaining('item one'), findsOneWidget);
      expect(find.textContaining('a quote'), findsOneWidget);

      await file.delete();
      await dir.delete(recursive: true);
    });
  });

  testWidgets('note viewer handles missing file', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: NoteViewerScreen(
            filePath: r'Z:\definitely\missing\note.md',
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.textContaining('no longer exists'), findsOneWidget);
    });
  });
}
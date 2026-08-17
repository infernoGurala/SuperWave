import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:superwave/main.dart';
import 'package:superwave/note_viewer_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('superwave_crumb_vault_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('HomeScreen shows breadcrumbs and teleports to clicked parent folder',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final level1 = Directory(p.join(tempDir.path, 'Level1'))..createSync();
    final level2 = Directory(p.join(level1.path, 'Level2'))..createSync();
    File(p.join(level2.path, 'deep_note.md')).writeAsStringSync('# Deep Note');
    File(p.join(level1.path, 'level1_note.md')).writeAsStringSync('# Level 1 Note');
    File(p.join(tempDir.path, 'root_note.md')).writeAsStringSync('# Root Note');

    final vaultName = p.basename(tempDir.path);

    await tester.pumpWidget(
      MaterialApp(
        home: SuperWaveApp(initialVaultPath: tempDir.path),
      ),
    );
    await tester.pumpAndSettle();

    // Verify root breadcrumb is present at top
    expect(find.text(vaultName), findsWidgets);
    expect(find.text('root_note'), findsOneWidget);

    // Navigate to Level1
    await tester.tap(find.text('Level1'));
    await tester.pumpAndSettle();

    // Verify breadcrumb shows Root and Level1
    expect(find.text('Level1'), findsWidgets);
    expect(find.text('level1_note'), findsOneWidget);

    // Navigate to Level2
    await tester.tap(find.text('Level2'));
    await tester.pumpAndSettle();

    // Verify breadcrumb shows Root, Level1, and Level2
    expect(find.text('Level2'), findsWidgets);
    expect(find.text('deep_note'), findsOneWidget);

    // Click on Level1 in the breadcrumb to teleport back to Level1
    await tester.tap(find.text('Level1'));
    await tester.pumpAndSettle();

    // Should now be back in Level1
    expect(find.text('level1_note'), findsOneWidget);
    expect(find.text('deep_note'), findsNothing);

    // Click on Vault Root in the breadcrumb to teleport to Root
    final rootCrumbs = find.text(vaultName);
    await tester.tap(rootCrumbs.last);
    await tester.pumpAndSettle();

    // Should now be back in Vault Root
    expect(find.text('root_note'), findsOneWidget);
    expect(find.text('level1_note'), findsNothing);
  });

  testWidgets('NoteViewerScreen shows breadcrumbs and teleports to clicked parent folder on pop',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() async {
      final level1 = Directory(p.join(tempDir.path, 'Level1'))..createSync();
      final level2 = Directory(p.join(level1.path, 'Level2'))..createSync();
      File(p.join(level2.path, 'my_note.md')).writeAsStringSync('# Hello World\nContent');

      final vaultName = p.basename(tempDir.path);

      await tester.pumpWidget(
        MaterialApp(
          home: SuperWaveApp(initialVaultPath: tempDir.path),
        ),
      );
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();

      // Navigate to Level1 -> Level2 -> open my_note
      await tester.tap(find.text('Level1'));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();

      await tester.tap(find.text('Level2'));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();

      await tester.tap(find.text('my_note'));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify we are in NoteViewerScreen
      expect(find.byType(NoteViewerScreen), findsOneWidget);
      expect(find.text('Hello World'), findsOneWidget);

      // Verify breadcrumbs in NoteViewerScreen contain Vault, Level1, Level2, and my_note.md
      expect(find.text(vaultName), findsWidgets);
      expect(find.text('Level1'), findsWidgets);
      expect(find.text('Level2'), findsWidgets);
      expect(find.textContaining('my_note'), findsWidgets);

      // Click on Level1 breadcrumb to teleport straight to Level1
      final level1Crumbs = find.text('Level1');
      await tester.tap(level1Crumbs.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Should pop NoteViewerScreen and navigate to Level1
      expect(find.byType(NoteViewerScreen), findsNothing);
      expect(find.text('Level2'), findsOneWidget); // Level2 folder is visible inside Level1
    });
  });
}

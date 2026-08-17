import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:superwave/main.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('superwave_test_vault_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('Creates super.json automatically on directory load and toggles view mode',
      (WidgetTester tester) async {
    // Create some notes and folders in temp vault
    final note1 = File(p.join(tempDir.path, 'note1.md'));
    note1.writeAsStringSync('# Test Note 1');
    final folderA = Directory(p.join(tempDir.path, 'FolderA'));
    folderA.createSync();
    final noteInFolderA = File(p.join(folderA.path, 'subnote.md'));
    noteInFolderA.writeAsStringSync('# Subnote');

    // Build the app with temp vault
    await tester.pumpWidget(
      MaterialApp(
        home: SuperWaveApp(initialVaultPath: tempDir.path),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify super.json was created in root
    final rootSuperJson = File(p.join(tempDir.path, 'super.json'));
    expect(rootSuperJson.existsSync(), isTrue);
    final rootContent = jsonDecode(rootSuperJson.readAsStringSync());
    expect(rootContent['view_type'], 'grid');

    // Verify super.json is NOT rendered as a card
    expect(find.text('super'), findsNothing);
    expect(find.text('note1'), findsOneWidget);
    expect(find.text('FolderA'), findsOneWidget);

    // 2. Find and click view mode toggle button (switches to list view)
    final toggleButton = find.byIcon(Icons.view_list_rounded);
    expect(toggleButton, findsOneWidget);
    await tester.tap(toggleButton);
    await tester.pumpAndSettle();

    // Verify root super.json now has view_type: list
    final updatedRootContent = jsonDecode(rootSuperJson.readAsStringSync());
    expect(updatedRootContent['view_type'], 'list');
    expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);

    // 3. Navigate into FolderA
    await tester.tap(find.text('FolderA'));
    await tester.pumpAndSettle();

    // Verify super.json was created for FolderA with default 'grid'
    final folderASuperJson = File(p.join(folderA.path, 'super.json'));
    expect(folderASuperJson.existsSync(), isTrue);
    final folderAContent = jsonDecode(folderASuperJson.readAsStringSync());
    expect(folderAContent['view_type'], 'grid');

    // FolderA should now display grid view icon (meaning current mode is grid)
    expect(find.byIcon(Icons.view_list_rounded), findsOneWidget);
    expect(find.text('subnote'), findsOneWidget);

    // 4. Navigate back up to Root (Escape when search is empty navigates up)
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    // Root should still remember list view from super.json
    expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
  });

  testWidgets('Respects existing super.json view_type when opening folder',
      (WidgetTester tester) async {
    // Pre-create FolderWithList and set its super.json to list
    final folderWithList = Directory(p.join(tempDir.path, 'FolderWithList'));
    folderWithList.createSync();
    final listConfig = File(p.join(folderWithList.path, 'super.json'));
    listConfig.writeAsStringSync(jsonEncode({'view_type': 'list'}));
    File(p.join(folderWithList.path, 'list_note.md')).writeAsStringSync('# List note');

    // Pre-create FolderWithGrid and set its super.json to grid
    final folderWithGrid = Directory(p.join(tempDir.path, 'FolderWithGrid'));
    folderWithGrid.createSync();
    final gridConfig = File(p.join(folderWithGrid.path, 'super.json'));
    gridConfig.writeAsStringSync(jsonEncode({'view_type': 'grid'}));
    File(p.join(folderWithGrid.path, 'grid_note.md')).writeAsStringSync('# Grid note');

    await tester.pumpWidget(
      MaterialApp(
        home: SuperWaveApp(initialVaultPath: tempDir.path),
      ),
    );
    await tester.pumpAndSettle();

    // Open FolderWithList
    await tester.tap(find.text('FolderWithList'));
    await tester.pumpAndSettle();

    // Should be list mode (toggle icon shows grid_view_rounded)
    expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
    expect(find.text('list_note'), findsOneWidget);

    // Go back to root
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    // Open FolderWithGrid
    await tester.tap(find.text('FolderWithGrid'));
    await tester.pumpAndSettle();

    // Should be grid mode (toggle icon shows view_list_rounded)
    expect(find.byIcon(Icons.view_list_rounded), findsOneWidget);
    expect(find.text('grid_note'), findsOneWidget);
  });

  testWidgets('Preserves custom fields in super.json when changing view mode',
      (WidgetTester tester) async {
    final folder = Directory(p.join(tempDir.path, 'CustomFolder'));
    folder.createSync();
    final configFile = File(p.join(folder.path, 'super.json'));
    configFile.writeAsStringSync(
      jsonEncode({'view_type': 'grid', 'custom_key': 'custom_value', 'version': 1}),
    );
    File(p.join(folder.path, 'note.md')).writeAsStringSync('# Note');

    await tester.pumpWidget(
      MaterialApp(
        home: SuperWaveApp(initialVaultPath: tempDir.path),
      ),
    );
    await tester.pumpAndSettle();

    // Open CustomFolder
    await tester.tap(find.text('CustomFolder'));
    await tester.pumpAndSettle();

    // Toggle view mode to list
    final toggleButton = find.byIcon(Icons.view_list_rounded);
    await tester.tap(toggleButton);
    await tester.pumpAndSettle();

    final updated = jsonDecode(configFile.readAsStringSync());
    expect(updated['view_type'], 'list');
    expect(updated['custom_key'], 'custom_value');
    expect(updated['version'], 1);
  });

  testWidgets('Folder item count excludes super.json',
      (WidgetTester tester) async {
    final folder = Directory(p.join(tempDir.path, 'TestFolder'));
    folder.createSync();
    File(p.join(folder.path, 'super.json')).writeAsStringSync(jsonEncode({'view_type': 'grid'}));
    File(p.join(folder.path, 'one.md')).writeAsStringSync('# One');
    File(p.join(folder.path, 'two.md')).writeAsStringSync('# Two');

    await tester.pumpWidget(
      MaterialApp(
        home: SuperWaveApp(initialVaultPath: tempDir.path),
      ),
    );
    await tester.pumpAndSettle();

    // Subtitle should say '2 items' (not 3 items)
    expect(find.text('2 items'), findsOneWidget);
  });
}

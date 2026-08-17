import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superwave/glass_sidebar.dart';
import 'package:superwave/theme/claude_theme.dart';

void main() {
  testWidgets('GlassSidebar expands into rectangle brick with item names on hover',
      (WidgetTester tester) async {
    int selectedTab = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: ClaudeTheme.darkTheme,
        home: Scaffold(
          body: GlassSidebar(
            selectedIndex: selectedTab,
            onItemSelected: (index) => selectedTab = index,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // In initial collapsed state (width 56px + 28px margin = 84px)
    final sidebarBoxFinder = find.descendant(
      of: find.byType(GlassSidebar),
      matching: find.byType(Container),
    ).first;
    final RenderBox initialBox = tester.renderObject(sidebarBoxFinder);
    expect(initialBox.size.width, equals(84.0));

    // Hover mouse over the sidebar
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);

    await gesture.moveTo(tester.getCenter(find.byType(GlassSidebar)));
    await tester.pumpAndSettle();

    // Verify sidebar expanded to 180px width (+ 28px margin = 208px)
    final RenderBox expandedBox = tester.renderObject(sidebarBoxFinder);
    expect(expandedBox.size.width, equals(208.0));

    // Verify tab names are visible
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Tap Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(selectedTab, equals(1));

    // Move mouse away -> contracts back to 84px (56px width)
    await gesture.moveTo(const Offset(500, 500));
    await tester.pumpAndSettle();

    final RenderBox collapsedBox = tester.renderObject(sidebarBoxFinder);
    expect(collapsedBox.size.width, equals(84.0));
  });
}

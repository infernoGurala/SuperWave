import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superwave/custom_title_bar.dart';

void main() {
  testWidgets('CustomTitleBar renders app title and vault badge', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomTitleBar(
            vaultName: 'Personal Vault',
          ),
        ),
      ),
    );

    expect(find.text('SuperWave'), findsOneWidget);
    expect(find.text('Personal Vault'), findsOneWidget);
  });
}

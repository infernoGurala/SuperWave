import 'package:flutter_test/flutter_test.dart';

import 'package:superwave/main.dart';

void main() {
  testWidgets('SuperWaveApp renders smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SuperWaveApp());
  });
}


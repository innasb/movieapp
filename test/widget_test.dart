import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:watchy/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WatchyApp());

    // Verify that our app loads by looking for the MOVIES title in the AppBar.
    expect(find.text('MOVIES'), findsOneWidget);
  });
}

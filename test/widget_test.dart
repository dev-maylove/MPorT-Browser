import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mport_browser/app.dart';

void main() {
  testWidgets('MPorT Browser app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MporTBrowserApp());
    // Allow post-frame init to start (controller.initialize).
    await tester.pump();
    // App should render without throwing.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

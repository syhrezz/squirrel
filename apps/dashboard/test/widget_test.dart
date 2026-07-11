import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mr_squirrel_dashboard/main.dart';

void main() {
  testWidgets('Dashboard app smoke test', (WidgetTester tester) async {
    // Basic smoke test — verifies the app builds without crashing.
    await tester.pumpWidget(const DashboardApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

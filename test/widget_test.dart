import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cp_expiry_tracker/main.dart';

void main() {
  testWidgets('app starts on the home page with an empty state',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ExpiryTrackerApp());

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text(ExpiryTrackerApp.title), findsOneWidget);
    expect(find.text(HomePage.emptyMessage), findsOneWidget);
  });

  testWidgets('app uses Material 3 theme', (WidgetTester tester) async {
    await tester.pumpWidget(const ExpiryTrackerApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, ExpiryTrackerApp.title);
    expect(app.theme?.useMaterial3, isTrue);
  });
}

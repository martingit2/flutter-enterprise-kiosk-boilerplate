import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taskhamster/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskhamsterApp());

    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
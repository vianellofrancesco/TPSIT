// Smoke test dell'app GreenGrid.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:client/main.dart';

void main() {
  testWidgets('GreenGrid smoke test — la Home mostra il titolo', (tester) async {
    await tester.pumpWidget(const GreenGridApp());

    // L'AppBar mostra "GreenGrid".
    expect(find.text('GreenGrid'), findsOneWidget);

    // Il FAB "+" per aggiungere una zona è presente.
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}

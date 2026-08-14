import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bherung/main.dart';

void main() {
  testWidgets('POS Toko Madura & Sembako smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify brand header & Toko Madura 24 Jam indicators
    expect(find.text('TOKO MADURA BHERUNG'), findsOneWidget);
    expect(find.text('24 JAM'), findsOneWidget);

    // Verify categories
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Beras & Sembako'), findsOneWidget);

    // Verify at least one sembako product
    expect(find.text('Beras Ramos Setra Pulen 5kg'), findsOneWidget);

    // Tap on a product to add to cart
    await tester.tap(find.text('Beras Ramos Setra Pulen 5kg'));
    await tester.pumpAndSettle();

    // Reset view
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}

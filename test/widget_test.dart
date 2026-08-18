import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bherung/main.dart';
import 'package:bherung/models/sample_data.dart';

void main() {
  testWidgets('POS Toko Madura & Sembako smoke test', (WidgetTester tester) async {
    // Seed initial products in mock storage for smoke testing
    final mockProducts = sampleProducts.take(3).map((p) => p.toJson()).toList();
    SharedPreferences.setMockInitialValues({
      'bherung_products_json_v1': jsonEncode(mockProducts),
    });

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify Lock screen is present and unlock with PIN 1234
    if (find.text('1').evaluate().isNotEmpty) {
      await tester.tap(find.text('1'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('2'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('3'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();
    }

    // Verify brand header & Toko Madura 24 Jam indicators
    expect(find.text('Bherung'), findsOneWidget);
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

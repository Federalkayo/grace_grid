import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grace_grid/main.dart';

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MockHttpOverrides();

  testWidgets('GraceGridApp smoke test loads main app shell directly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GraceGridApp(),
      ),
    );

    await tester.pump();
    expect(find.byType(GraceGridApp), findsOneWidget);

    // Verify Bible tab navigation item is displayed
    expect(find.byIcon(Icons.menu_book), findsWidgets);
  });
}

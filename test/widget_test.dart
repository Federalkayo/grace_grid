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

  testWidgets('GraceGridApp smoke test loads and transitions from splash to main shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GraceGridApp(),
      ),
    );

    // Initial splash frame
    await tester.pump();
    expect(find.byType(GraceGridApp), findsOneWidget);

    // Tap to skip splash screen and advance frames
    await tester.tap(find.byType(GraceGridApp));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 800));

    // Verify Bible tab navigation item is displayed
    expect(find.byIcon(Icons.menu_book), findsWidgets);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grace_grid/features/splash/book_flip_splash_screen.dart';

void main() {
  testWidgets('BookFlipSplashScreen renders logo and title initially', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: BookFlipSplashScreen(
            animationDuration: Duration(milliseconds: 500),
          ),
        ),
      ),
    );

    // Initial frame to trigger postFrameCallback
    await tester.pump();
    expect(find.text('GRACEGRID'), findsWidgets);
    expect(find.text('SANCTUARY'), findsOneWidget);
    expect(find.text('Tap anywhere to skip'), findsOneWidget);
  });

  testWidgets('BookFlipSplashScreen navigates to nextScreen after animation completes', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: BookFlipSplashScreen(
            nextScreen: Scaffold(body: Text('DUMMY_TARGET')),
            animationDuration: Duration(milliseconds: 200),
          ),
        ),
      ),
    );

    // Initial frame to trigger postFrameCallback & start controller
    await tester.pump();
    // Advance time through splash animation controller
    await tester.pump(const Duration(milliseconds: 300));
    // Advance time through route transition controller
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('DUMMY_TARGET'), findsOneWidget);
  });

  testWidgets('Tapping BookFlipSplashScreen skips animation and navigates to nextScreen immediately', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: BookFlipSplashScreen(
            nextScreen: Scaffold(body: Text('DUMMY_TARGET')),
            animationDuration: Duration(milliseconds: 3000),
          ),
        ),
      ),
    );

    await tester.pump(); // Flush postFrameCallback
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('DUMMY_TARGET'), findsOneWidget);
  });
}

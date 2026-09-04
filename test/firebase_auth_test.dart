import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:grace_grid/core/services/firebase_auth_service.dart';
import 'package:grace_grid/core/providers/auth_provider.dart';
import 'package:grace_grid/features/auth/login_signup_modal.dart';

void main() {
  group('FirebaseAuthService Exception Mapping Tests', () {
    test('maps email-already-in-use code to user-friendly message', () {
      final exc = FirebaseAuthException(code: 'email-already-in-use');
      final msg = FirebaseAuthService.mapFirebaseAuthException(exc);
      expect(msg, contains('account already exists'));
    });

    test('maps invalid-email code to user-friendly message', () {
      final exc = FirebaseAuthException(code: 'invalid-email');
      final msg = FirebaseAuthService.mapFirebaseAuthException(exc);
      expect(msg, contains('invalid'));
    });

    test('maps wrong-password code to user-friendly message', () {
      final exc = FirebaseAuthException(code: 'wrong-password');
      final msg = FirebaseAuthService.mapFirebaseAuthException(exc);
      expect(msg, contains('Incorrect email or password'));
    });

    test('maps weak-password code to user-friendly message', () {
      final exc = FirebaseAuthException(code: 'weak-password');
      final msg = FirebaseAuthService.mapFirebaseAuthException(exc);
      expect(msg, contains('too weak'));
    });
  });

  group('AuthNotifier State & Provider Tests', () {
    test('initial state is guest by default', () {
      final notifier = AuthNotifier(FirebaseAuthService());
      expect(notifier.state.status, equals(AuthStatus.guest));
      expect(notifier.state.isGuest, isTrue);
      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.profile.name, equals('Believer Guest'));
    });

    test('signup with invalid email sets error message', () async {
      final notifier = AuthNotifier(FirebaseAuthService());
      final result = await notifier.signup(name: 'Test', email: 'invalidemail', password: '123');
      expect(result, isFalse);
      expect(notifier.state.errorMessage, isNotNull);
      expect(notifier.state.errorMessage, contains('valid email'));
    });

    test('login with empty credentials sets error message', () async {
      final notifier = AuthNotifier(FirebaseAuthService());
      final result = await notifier.login(email: '', password: '');
      expect(result, isFalse);
      expect(notifier.state.errorMessage, isNotNull);
    });
  });

  group('LoginSignupModal UI Tests', () {
    testWidgets('LoginSignupModal displays Log In fields and toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LoginSignupModal(),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('Toggling to Sign Up displays Display Name and Confirm Password', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LoginSignupModal(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.text('Sign Up'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Join the Fellowship'), findsOneWidget);
      expect(find.text('Display Name'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });
  });
}

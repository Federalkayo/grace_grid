import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service providing Firebase Email Authentication operations and error code translations.
class FirebaseAuthService {
  final FirebaseAuth? _customAuth;

  FirebaseAuthService({FirebaseAuth? auth}) : _customAuth = auth;

  FirebaseAuth? get _auth {
    if (_customAuth != null) return _customAuth;
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      debugPrint('FirebaseAuth instance not available: $e');
      return null;
    }
  }

  /// Returns the active Firebase user, if any.
  User? get currentUser {
    try {
      return _auth?.currentUser;
    } catch (e) {
      debugPrint('FirebaseAuth.currentUser exception: $e');
      return null;
    }
  }

  /// Real-time stream of authentication state changes.
  Stream<User?> get authStateChanges {
    final instance = _auth;
    if (instance == null) {
      return Stream.value(null);
    }
    try {
      return instance.authStateChanges();
    } catch (e) {
      debugPrint('FirebaseAuth.authStateChanges stream exception: $e');
      return Stream.value(null);
    }
  }

  /// Signs up a user using Email and Password, with an optional Display Name.
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Please enter a valid email address.',
      );
    }

    if (password.length < 6) {
      throw FirebaseAuthException(
        code: 'weak-password',
        message: 'Password must be at least 6 characters long.',
      );
    }

    final instance = _auth;
    if (instance == null) {
      // Fallback for offline/unconfigured environment
      throw FirebaseAuthException(
        code: 'no-app',
        message: 'Firebase is not initialized. Please ensure google-services.json is configured.',
      );
    }

    try {
      final credential = await instance.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      if (displayName != null && displayName.trim().isNotEmpty && credential.user != null) {
        await credential.user!.updateDisplayName(displayName.trim());
        await credential.user!.reload();
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: mapFirebaseAuthException(e),
      );
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'An unexpected error occurred during signup: ${e.toString()}',
      );
    }
  }

  /// Signs in an existing user using Email and Password.
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Please enter a valid email address.',
      );
    }

    if (password.isEmpty) {
      throw FirebaseAuthException(
        code: 'wrong-password',
        message: 'Please enter your password.',
      );
    }

    final instance = _auth;
    if (instance == null) {
      // Fallback for offline/unconfigured environment
      throw FirebaseAuthException(
        code: 'no-app',
        message: 'Firebase is not initialized. Please ensure google-services.json is configured.',
      );
    }

    try {
      return await instance.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: mapFirebaseAuthException(e),
      );
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'An unexpected error occurred during sign in: ${e.toString()}',
      );
    }
  }

  /// Sends a password reset email to the given Email address.
  Future<void> sendPasswordResetEmail({required String email}) async {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Please enter a valid email address.',
      );
    }

    final instance = _auth;
    if (instance == null) {
      throw FirebaseAuthException(
        code: 'no-app',
        message: 'Firebase is not initialized. Please ensure google-services.json is configured.',
      );
    }

    try {
      await instance.sendPasswordResetEmail(email: cleanEmail);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: mapFirebaseAuthException(e),
      );
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'Unable to send password reset email: ${e.toString()}',
      );
    }
  }

  /// Signs out the currently authenticated user.
  Future<void> signOut() async {
    final instance = _auth;
    if (instance == null) return;
    try {
      await instance.signOut();
    } catch (e) {
      debugPrint('Error during FirebaseAuth signOut: $e');
    }
  }

  /// Maps Firebase Auth error codes to user-friendly error messages.
  static String mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email address. Try signing in instead.';
      case 'invalid-email':
        return 'The email address format is invalid.';
      case 'user-not-found':
        return 'No account found matching this email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a few minutes before trying again.';
      case 'operation-not-allowed':
        return 'Email/Password authentication is not enabled in Firebase project console.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication failed (${e.code}). Please try again.';
    }
  }
}

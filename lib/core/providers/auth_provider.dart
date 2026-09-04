import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_auth_service.dart';

enum AuthStatus { guest, authenticated }

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final int streakDays;
  final int versesReadCount;
  final int sermonNotesCount;
  final int prayersSharedCount;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.streakDays,
    required this.versesReadCount,
    required this.sermonNotesCount,
    required this.prayersSharedCount,
  });

  static const guestDefault = UserProfile(
    id: 'guest',
    name: 'Believer Guest',
    email: 'guest@gracegrid.sanctuary',
    avatarUrl: '',
    streakDays: 4,
    versesReadCount: 142,
    sermonNotesCount: 12,
    prayersSharedCount: 0,
  );

  factory UserProfile.fromFirebaseUser(User user) {
    return UserProfile(
      id: user.uid,
      name: (user.displayName != null && user.displayName!.trim().isNotEmpty)
          ? user.displayName!
          : (user.email?.split('@').first ?? 'Grace Believer'),
      email: user.email ?? 'believer@gracegrid.sanctuary',
      avatarUrl: user.photoURL ?? '',
      streakDays: 7,
      versesReadCount: 310,
      sermonNotesCount: 24,
      prayersSharedCount: 12,
    );
  }
}

class AuthState {
  final AuthStatus status;
  final UserProfile profile;
  final String? pendingGatedActionName;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    required this.status,
    required this.profile,
    this.pendingGatedActionName,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isGuest => status == AuthStatus.guest;

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? profile,
    String? pendingGatedActionName,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      pendingGatedActionName: pendingGatedActionName ?? this.pendingGatedActionName,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuthService _authService;
  StreamSubscription<User?>? _authSubscription;

  AuthNotifier(this._authService)
      : super(
          const AuthState(
            status: AuthStatus.guest,
            profile: UserProfile.guestDefault,
          ),
        ) {
    _initAuthListener();
  }

  void _initAuthListener() {
    try {
      final initialUser = _authService.currentUser;
      if (initialUser != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          profile: UserProfile.fromFirebaseUser(initialUser),
        );
      }

      _authSubscription = _authService.authStateChanges.listen((user) {
        if (user != null) {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            profile: UserProfile.fromFirebaseUser(user),
            clearError: true,
          );
        } else {
          // If signed out of Firebase
          state = const AuthState(
            status: AuthStatus.guest,
            profile: UserProfile.guestDefault,
          );
        }
      }, onError: (err) {
        debugPrint('Auth listener error: $err');
      });
    } catch (e) {
      debugPrint('AuthNotifier init error: $e');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Sign up with Email, Password, and Display Name via Firebase Auth.
  Future<bool> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final credential = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: name,
      );

      final user = credential?.user;
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          profile: UserProfile.fromFirebaseUser(user),
          isLoading: false,
          pendingGatedActionName: null,
        );
        return true;
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }

    state = state.copyWith(isLoading: false);
    return false;
  }

  /// Log in with Email and Password via Firebase Auth.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential?.user;
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          profile: UserProfile.fromFirebaseUser(user),
          isLoading: false,
          pendingGatedActionName: null,
        );
        return true;
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }

    state = state.copyWith(isLoading: false);
    return false;
  }

  /// Send password reset email via Firebase Auth.
  Future<bool> sendPasswordReset({required String email}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authService.sendPasswordResetEmail(email: email);
      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Sign out via Firebase Auth.
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _authService.signOut();
    state = const AuthState(
      status: AuthStatus.guest,
      profile: UserProfile.guestDefault,
    );
  }

  void setPendingGatedAction(String? actionName) {
    state = state.copyWith(pendingGatedActionName: actionName);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return AuthNotifier(authService);
});

// Alias for backward compatibility with existing mock references
typedef MockAuthState = AuthState;
typedef MockAuthNotifier = AuthNotifier;
final mockAuthNotifierProvider = authNotifierProvider;

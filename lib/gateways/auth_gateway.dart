import 'package:supabase_flutter/supabase_flutter.dart' show Session, User, AuthChangeEvent;

/// Result wrapper for auth operations.
class AuthResult {
  final User? user;
  final Session? session;
  final String? error;

  const AuthResult({this.user, this.session, this.error});

  bool get isSuccess => error == null && user != null;
}

/// Abstraction over Supabase Auth so the provider is testable
/// without a live backend.
abstract class AuthGateway {
  /// Returns the persisted session if one exists, null otherwise.
  Future<Session?> recoverSession();

  /// Email + password sign-up.
  Future<AuthResult> signUp({required String email, required String password});

  /// Email + password log-in.
  Future<AuthResult> signIn({required String email, required String password});

  /// Sign out the current user.
  Future<void> signOut();

  /// Stream of auth state changes (sign-in, sign-out, token refresh, etc.).
  Stream<AuthChangeEvent> onAuthStateChange();

  /// The currently authenticated user, if any.
  User? get currentUser;

  /// The current session, if any.
  Session? get currentSession;

  /// Sends a password-reset email.
  Future<void> resetPassword(String email);

  /// Sign in with Apple.
  Future<AuthResult> signInWithApple();

  /// Sign in with Google.
  Future<AuthResult> signInWithGoogle();
}

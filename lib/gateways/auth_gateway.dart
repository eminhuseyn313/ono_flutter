import 'package:supabase_flutter/supabase_flutter.dart'
    show Session, User, AuthChangeEvent;

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

  /// Whether Google sign-in is set up (else only email shows).
  bool get offersSocialSignIn;

  /// Whether "Continue with Apple" shows (on an iPhone).
  bool get offersAppleSignIn;

  /// The currently authenticated user, if any.
  User? get currentUser;

  /// The current session, if any.
  Session? get currentSession;

  /// Sends a password-reset email (throws when it can't be sent).
  Future<void> resetPassword(String email);

  /// Sets a new password for the signed-in user (after a reset link);
  /// returns an error message, or null when it worked.
  Future<String?> updatePassword(String password);

  /// Sign in with Apple.
  Future<AuthResult> signInWithApple();

  /// Sign in with Google.
  Future<AuthResult> signInWithGoogle();
}

/// What a person sees when sign-in fails for a reason that isn't theirs:
/// never a raw exception with an address in it.
String friendlyAuthError(Object e) {
  final t = '$e'.toLowerCase();
  const offline = [
    'socketexception',
    'clientexception',
    'failed host lookup',
    'xmlhttprequest',
    'connection',
    'network',
    'timeout',
    'timed out'
  ];
  if (offline.any(t.contains)) {
    return 'Couldn\'t reach ONO. Check your connection and try again.';
  }
  return 'Something went wrong. Try again in a moment.';
}

/// A Supabase Auth error in words a person can act on. Server-side
/// failures (a database waking up after a pause, a restart) never show
/// their raw text; a wrong password points to the reset.
String authExceptionMessage(
    {String? code,
    String? statusCode,
    required String message,
    bool signUp = false}) {
  final c = (code ?? '').toLowerCase();
  final m = message.toLowerCase();
  final status = int.tryParse(statusCode ?? '') ?? 0;
  if (c == 'user_already_exists' ||
      c == 'email_exists' ||
      m.contains('already registered')) {
    return 'You already have an account with this email — sign in instead. Forgot the password? Reset it from the sign-in screen.';
  }
  if (c == 'invalid_credentials' || m.contains('invalid login credentials')) {
    return 'That email and password don\'t match. If you made the account a while ago, tap "Forgot password?" to set a new one.';
  }
  if (c == 'provider_disabled' || m.contains('provider is not enabled') || m.contains('unsupported provider')) {
    return 'Sign in with Apple isn\'t switched on for ONO\'s server yet. Use your email for now.';
  }
    if (c == 'email_not_confirmed' || m.contains('email not confirmed')) {
    return 'Confirm your email first: tap the link we sent, then sign in.';
  }
  if (c == 'weak_password' || m.contains('password should be')) {
    return 'Choose a longer password: at least 6 characters.';
  }
  if (c == 'over_email_send_rate_limit' ||
      c == 'over_request_rate_limit' ||
      status == 429) {
    return 'Too many tries in a short time. Wait a few minutes, then try again.';
  }
  if (c == 'unexpected_failure' ||
      status >= 500 ||
      m.contains('database error')) {
    return 'ONO\'s server is waking up or busy. Wait a minute and try again${signUp ? ' — nothing was created' : ''}.';
  }
  return message;
}


import 'package:google_sign_in/google_sign_in.dart';
// TODO: re-add sign_in_with_apple when a compatible version is available
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_gateway.dart';

/// Production implementation that delegates to [SupabaseClient.auth].
class SupabaseAuthGateway implements AuthGateway {
  final SupabaseClient _client;

  SupabaseAuthGateway(this._client);

  GoTrueClient get _auth => _client.auth;

  // -- Session restore ----------------------------------------------------

  @override
  Future<Session?> recoverSession() async {
    return _auth.currentSession;
  }

  // -- Sign up ------------------------------------------------------------

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signUp(email: email, password: password);
      return AuthResult(user: response.user, session: response.session);
    } on AuthException catch (e) {
      return AuthResult(error: e.message);
    } catch (e) {
      return AuthResult(error: e.toString());
    }
  }

  // -- Sign in ------------------------------------------------------------

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      return AuthResult(user: response.user, session: response.session);
    } on AuthException catch (e) {
      return AuthResult(error: e.message);
    } catch (e) {
      return AuthResult(error: e.toString());
    }
  }

  // -- Sign in with Apple -------------------------------------------------

  @override
  Future<AuthResult> signInWithApple() async {
    // TODO: re-add when sign_in_with_apple package is updated
    return const AuthResult(error: 'Apple Sign In is temporarily unavailable.');
  }

  // -- Sign in with Google ------------------------------------------------

  @override
  Future<AuthResult> signInWithGoogle() async {
    try {
      /// Web client ID from Google Cloud Console for Supabase
      const webClientId = ''; // TODO: Add your Google web client ID
      const iosClientId = ''; // TODO: Add your iOS client ID

      final googleSignIn = GoogleSignIn(
        clientId: iosClientId.isNotEmpty ? iosClientId : null,
        serverClientId: webClientId.isNotEmpty ? webClientId : null,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return const AuthResult(error: null); // User cancelled
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        return const AuthResult(error: 'Google Sign In failed — no ID token received.');
      }

      final response = await _auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return AuthResult(user: response.user, session: response.session);
    } on AuthException catch (e) {
      return AuthResult(error: e.message);
    } catch (e) {
      return AuthResult(error: e.toString());
    }
  }

  // -- Sign out -----------------------------------------------------------

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // -- Auth state stream --------------------------------------------------

  @override
  Stream<AuthChangeEvent> onAuthStateChange() {
    return _auth.onAuthStateChange.map((state) => state.event);
  }

  // -- Accessors ----------------------------------------------------------

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Session? get currentSession => _auth.currentSession;

  // -- Password reset -----------------------------------------------------

  @override
  Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(email);
  }

  // -- Helpers ------------------------------------------------------------
}

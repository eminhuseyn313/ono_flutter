import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_gateway.dart';

/// Production implementation that delegates to [SupabaseClient.auth].
class SupabaseAuthGateway implements AuthGateway {
  final SupabaseClient _client;

  /// Where reset links land: the web app, which has a page to set the new
  /// password (the phone app has no deep link yet).
  final String? webAppUrl;

  SupabaseAuthGateway(this._client, {this.webAppUrl});

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
      if (response.session == null) {
        // An email that already has an account comes back with no
        // identities (and no email is sent): say so instead of waiting.
        if (response.user?.identities?.isEmpty ?? false) {
          return AuthResult(
              error: authExceptionMessage(
                  code: 'user_already_exists', message: ''));
        }
        // The project asks new accounts to confirm their email first.
        return const AuthResult(
            error:
                'Check your email and tap the link to confirm, then come back here and sign in.');
      }
      return AuthResult(user: response.user, session: response.session);
    } on AuthException catch (e) {
      return AuthResult(
          error: authExceptionMessage(
              code: e.code,
              statusCode: e.statusCode,
              message: e.message,
              signUp: true));
    } catch (e) {
      return AuthResult(error: friendlyAuthError(e));
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
      return AuthResult(
          error: authExceptionMessage(
              code: e.code, statusCode: e.statusCode, message: e.message));
    } catch (e) {
      return AuthResult(error: friendlyAuthError(e));
    }
  }

  // -- Sign in with Apple -------------------------------------------------

  /// Native Sign in with Apple, handed to Supabase as an ID token. Needs
  /// the Apple provider switched on in Supabase (Authentication →
  /// Providers → Apple, Client IDs: the app's bundle ID) and the
  /// "Sign in with Apple" capability (scripts/capabilities.sh apple on).
  /// An Apple ID with the same verified email joins the existing account.
  @override
  Future<AuthResult> signInWithApple() async {
    try {
      final rawNonce = _auth.generateRawNonce();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
      );
      final idToken = credential.identityToken;
      if (idToken == null) {
        return const AuthResult(error: 'Apple didn\'t send a sign-in token. Try again.');
      }
      final response = await _auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
      return AuthResult(user: response.user, session: response.session);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return const AuthResult(); // They closed the sheet.
      }
      return const AuthResult(error: 'Sign in with Apple didn\'t finish. Try again, or use your email.');
    } on AuthException catch (e) {
      return AuthResult(
          error: authExceptionMessage(
              code: e.code, statusCode: e.statusCode, message: e.message));
    } catch (e) {
      return AuthResult(error: friendlyAuthError(e));
    }
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
        return const AuthResult(
            error: 'Google Sign In failed — no ID token received.');
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
      return AuthResult(error: friendlyAuthError(e));
    }
  }

  // -- Sign out -----------------------------------------------------------

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // -- Auth state stream --------------------------------------------------

  @override
  bool get offersSocialSignIn => false; // Needs a Google client ID.

  @override
  bool get offersAppleSignIn =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

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
    // On the web, back to this same site; elsewhere, to the web app.
    final here = kIsWeb ? '${Uri.base.origin}${Uri.base.path}' : null;
    await _auth.resetPasswordForEmail(email, redirectTo: here ?? webAppUrl);
  }

  @override
  Future<String?> updatePassword(String password) async {
    try {
      await _auth.updateUser(UserAttributes(password: password));
      return null;
    } on AuthException catch (e) {
      if (e.code == 'same_password') {
        return 'That\'s your current password — choose a new one.';
      }
      return authExceptionMessage(
          code: e.code, statusCode: e.statusCode, message: e.message);
    } catch (e) {
      return friendlyAuthError(e);
    }
  }

  // -- Helpers ------------------------------------------------------------
}

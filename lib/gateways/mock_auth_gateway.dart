import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session, User, AuthChangeEvent;

import 'auth_gateway.dart';

/// Offline gateway for development — no Supabase needed. Remembers the
/// signed-in email on the device so the app reopens signed in.
class MockAuthGateway implements AuthGateway {
  User? _user;
  Session? _session;
  final _controller = StreamController<AuthChangeEvent>.broadcast();

  static const _key = 'mock_auth_email';

  @override
  Future<Session?> recoverSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_key);
    if (email == null) return null;
    return (await _start(email, persist: false)).session;
  }

  Future<AuthResult> _start(String email, {bool persist = true}) async {
    _user = User(
      id: 'mock-user-001',
      appMetadata: {},
      userMetadata: {'email': email},
      email: email,
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );
    _session = Session(
      accessToken: 'mock-token',
      tokenType: 'bearer',
      user: _user!,
    );
    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, email);
    }
    return AuthResult(user: _user, session: _session);
  }

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    return _start(email);
  }

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    return _start(email);
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _session = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  @override
  Stream<AuthChangeEvent> onAuthStateChange() => _controller.stream;

  @override
  bool get offersSocialSignIn => true;

  @override
  User? get currentUser => _user;

  @override
  Session? get currentSession => _session;

  @override
  Future<void> resetPassword(String email) async {
    // No-op in mock mode
  }

  @override
  Future<AuthResult> signInWithApple() async {
    return signUp(email: 'apple@mock.com', password: 'mock');
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    return signUp(email: 'google@mock.com', password: 'mock');
  }
}

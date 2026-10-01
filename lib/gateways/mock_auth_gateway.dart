import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' show Session, User, AuthChangeEvent;

import 'auth_gateway.dart';

/// Offline mock gateway for development — no Supabase needed.
/// Always starts unauthenticated so you see the onboarding flow.
class MockAuthGateway implements AuthGateway {
  User? _user;
  Session? _session;
  final _controller = StreamController<AuthChangeEvent>.broadcast();

  @override
  Future<Session?> recoverSession() async {
    // No persisted session — show onboarding
    return null;
  }

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    _user = User(
      id: 'mock-user-001',
      appMetadata: {},
      userMetadata: {'email': email},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );
    _session = Session(
      accessToken: 'mock-token',
      tokenType: 'bearer',
      user: _user!,
    );
    return AuthResult(user: _user, session: _session);
  }

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    _user = User(
      id: 'mock-user-001',
      appMetadata: {},
      userMetadata: {'email': email},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );
    _session = Session(
      accessToken: 'mock-token',
      tokenType: 'bearer',
      user: _user!,
    );
    return AuthResult(user: _user, session: _session);
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _session = null;
  }

  @override
  Stream<AuthChangeEvent> onAuthStateChange() => _controller.stream;

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

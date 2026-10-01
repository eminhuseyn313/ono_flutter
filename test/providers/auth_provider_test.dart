import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ono/gateways/auth_gateway.dart';
import 'package:ono/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, Session, User;

void main() {
  group('AuthProvider', () {
    test('starts uninitialized when no session is restored', () async {
      final gateway = FakeAuthGateway();
      final provider = AuthProvider(gateway: gateway);

      expect(provider.status, AuthStatus.uninitialized);
      expect(provider.user, isNull);

      provider.dispose();
    });

    test('restores authenticated session when available', () async {
      final gateway = FakeAuthGateway(session: _fakeSession());
      final provider = AuthProvider(gateway: gateway);

      await provider.init();

      expect(provider.status, AuthStatus.authenticated);
      expect(provider.user, isNotNull);

      provider.dispose();
    });
  });
}

class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({Session? session}) : _session = session;

  final Session? _session;
  final _controller = StreamController<AuthChangeEvent>.broadcast();

  @override
  Future<Session?> recoverSession() async => _session;

  @override
  Future<AuthResult> signUp(
      {required String email, required String password}) async {
    return const AuthResult(error: 'not implemented');
  }

  @override
  Future<AuthResult> signIn(
      {required String email, required String password}) async {
    return const AuthResult(error: 'not implemented');
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Stream<AuthChangeEvent> onAuthStateChange() => _controller.stream;

  @override
  User? get currentUser => _session?.user;

  @override
  Session? get currentSession => _session;
}

Session _fakeSession() {
  final user = User(
    id: 'user-123',
    appMetadata: {},
    userMetadata: {'email': 'ono@example.com'},
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
  );

  return Session(
    accessToken: 'token',
    tokenType: 'bearer',
    user: user,
  );
}

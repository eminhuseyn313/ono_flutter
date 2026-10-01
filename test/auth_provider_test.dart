import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session, User, AuthChangeEvent;

import 'package:ono/gateways/auth_gateway.dart';
import 'package:ono/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Hand-rolled mock — no codegen needed
// ---------------------------------------------------------------------------
class MockAuthGateway implements AuthGateway {

  @override
  Future<AuthResult> signInWithApple() async =>
      const AuthResult(error: 'not implemented');

  @override
  Future<AuthResult> signInWithGoogle() async =>
      const AuthResult(error: 'not implemented');
  // Stubs ----------------------------------------------------------------
  Session? sessionToRecover;
  AuthResult? signUpResult;
  AuthResult? signInResult;
  Exception? signOutError;
  User? _currentUser;
  Session? _currentSession;

  final _authEvents = StreamController<AuthChangeEvent>.broadcast();

  // Spy counters ---------------------------------------------------------
  int recoverSessionCalls = 0;
  int signOutCalls = 0;

  // Interface ------------------------------------------------------------
  @override
  Future<Session?> recoverSession() async {
    recoverSessionCalls++;
    if (sessionToRecover != null) {
      _currentUser = _fakeUser();
      _currentSession = sessionToRecover;
    }
    return sessionToRecover;
  }

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    final r = signUpResult ?? const AuthResult(error: 'not stubbed');
    if (r.isSuccess) {
      _currentUser = r.user;
      _currentSession = r.session;
    }
    return r;
  }

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final r = signInResult ?? const AuthResult(error: 'not stubbed');
    if (r.isSuccess) {
      _currentUser = r.user;
      _currentSession = r.session;
    }
    return r;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (signOutError != null) throw signOutError!;
    _currentUser = null;
    _currentSession = null;
  }

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Stream<AuthChangeEvent> onAuthStateChange() => _authEvents.stream;

  @override
  User? get currentUser => _currentUser;

  @override
  Session? get currentSession => _currentSession;

  // Helpers --------------------------------------------------------------
  void emitAuthEvent(AuthChangeEvent event) => _authEvents.add(event);

  void dispose() => _authEvents.close();
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------
User _fakeUser({String id = 'user-123'}) {
  return User(
    id: id,
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
  );
}

Session _fakeSession({String accessToken = 'tok-abc'}) {
  return Session(
    accessToken: accessToken,
    tokenType: 'bearer',
    user: _fakeUser(),
  );
}

AuthResult _successResult() {
  final user = _fakeUser();
  final session = _fakeSession();
  return AuthResult(user: user, session: session);
}

AuthResult _errorResult(String msg) => AuthResult(error: msg);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late MockAuthGateway gateway;
  late AuthProvider provider;

  setUp(() {
    gateway = MockAuthGateway();
    provider = AuthProvider(gateway: gateway);
  });

  tearDown(() {
    gateway.dispose();
    provider.dispose();
  });

  // -- Initial state ------------------------------------------------------

  group('initial state', () {
    test('status is uninitialized before init()', () {
      expect(provider.status, AuthStatus.uninitialized);
      expect(provider.user, isNull);
      expect(provider.errorMessage, isNull);
    });
  });

  // -- Session restoration ------------------------------------------------

  group('session restoration (init)', () {
    test('restores session → authenticated', () async {
      gateway.sessionToRecover = _fakeSession();

      await provider.init();

      expect(provider.status, AuthStatus.authenticated);
      expect(provider.user, isNotNull);
      expect(gateway.recoverSessionCalls, 1);
    });

    test('no session → unauthenticated', () async {
      gateway.sessionToRecover = null;

      await provider.init();

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.user, isNull);
    });

    test('recovery error → unauthenticated with error', () async {
      // Simulate recoverSession throwing
      gateway.sessionToRecover = null;
      // Override to throw
      final badGateway = _ThrowingRecoverGateway();
      final p = AuthProvider(gateway: badGateway);

      await p.init();

      expect(p.status, AuthStatus.unauthenticated);
      expect(p.errorMessage, isNotNull);
      p.dispose();
    });
  });

  // -- Sign up ------------------------------------------------------------

  group('signUp', () {
    test('successful sign-up → authenticated', () async {
      gateway.signUpResult = _successResult();

      await provider.signUp(email: 'a@b.com', password: 'pass1234');

      expect(provider.status, AuthStatus.authenticated);
      expect(provider.user, isNotNull);
      expect(provider.errorMessage, isNull);
    });

    test('failed sign-up → unauthenticated with error', () async {
      gateway.signUpResult = _errorResult('Email taken');

      await provider.signUp(email: 'a@b.com', password: 'pass1234');

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.errorMessage, 'Email taken');
    });

    test('shows loading during sign-up', () async {
      final states = <AuthStatus>[];
      provider.addListener(() => states.add(provider.status));

      gateway.signUpResult = _successResult();
      await provider.signUp(email: 'a@b.com', password: 'pass1234');

      expect(states, contains(AuthStatus.loading));
    });
  });

  // -- Sign in ------------------------------------------------------------

  group('signIn', () {
    test('successful sign-in → authenticated', () async {
      gateway.signInResult = _successResult();

      await provider.signIn(email: 'a@b.com', password: 'pass1234');

      expect(provider.status, AuthStatus.authenticated);
      expect(provider.user, isNotNull);
      expect(provider.errorMessage, isNull);
    });

    test('failed sign-in → unauthenticated with error', () async {
      gateway.signInResult = _errorResult('Invalid credentials');

      await provider.signIn(email: 'a@b.com', password: 'pass1234');

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.errorMessage, 'Invalid credentials');
    });

    test('shows loading during sign-in', () async {
      final states = <AuthStatus>[];
      provider.addListener(() => states.add(provider.status));

      gateway.signInResult = _successResult();
      await provider.signIn(email: 'a@b.com', password: 'pass1234');

      expect(states, contains(AuthStatus.loading));
    });
  });

  // -- Sign out -----------------------------------------------------------

  group('signOut', () {
    test('successful sign-out → unauthenticated', () async {
      // First sign in
      gateway.signInResult = _successResult();
      await provider.signIn(email: 'a@b.com', password: 'pass1234');
      expect(provider.status, AuthStatus.authenticated);

      await provider.signOut();

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.user, isNull);
      expect(gateway.signOutCalls, 1);
    });

    test('sign-out error → keeps authenticated, sets error', () async {
      gateway.signInResult = _successResult();
      await provider.signIn(email: 'a@b.com', password: 'pass1234');

      gateway.signOutError = Exception('network down');

      await provider.signOut();

      // Should still be authenticated since sign-out failed
      expect(provider.status, AuthStatus.authenticated);
      expect(provider.errorMessage, isNotNull);
    });
  });

  // -- Reset password -----------------------------------------------------

  group('resetPassword', () {
    test('successful reset returns true', () async {
      final result = await provider.resetPassword('a@b.com');
      expect(result, true);
    });
  });

  // -- clearError ---------------------------------------------------------

  group('clearError', () {
    test('clears the error message', () async {
      gateway.signInResult = _errorResult('bad');
      await provider.signIn(email: 'a@b.com', password: 'pass1234');
      expect(provider.errorMessage, 'bad');

      provider.clearError();

      expect(provider.errorMessage, isNull);
    });
  });

  // -- Auth state stream --------------------------------------------------

  group('auth state stream', () {
    test('signedOut event → unauthenticated', () async {
      // Start authenticated
      gateway.signInResult = _successResult();
      await provider.signIn(email: 'a@b.com', password: 'pass1234');
      expect(provider.status, AuthStatus.authenticated);

      // Listen and init the stream subscription
      provider.listenToAuthChanges();

      // Simulate external sign-out (e.g. token revoked server-side)
      gateway.emitAuthEvent(AuthChangeEvent.signedOut);

      // Give the stream a tick to propagate
      await Future.delayed(Duration.zero);

      expect(provider.status, AuthStatus.unauthenticated);
    });

    test('signedIn event → authenticated', () async {
      provider.listenToAuthChanges();

      // Pre-set a user on the gateway so provider can read it
      gateway.signInResult = _successResult();
      // Simulate the gateway setting internal state
      await gateway.signIn(email: '', password: '');

      gateway.emitAuthEvent(AuthChangeEvent.signedIn);

      await Future.delayed(Duration.zero);

      expect(provider.status, AuthStatus.authenticated);
    });
  });
}

// ---------------------------------------------------------------------------
// Helper gateway that throws on recoverSession
// ---------------------------------------------------------------------------
class _ThrowingRecoverGateway implements AuthGateway {

  @override
  Future<AuthResult> signInWithApple() async =>
      const AuthResult(error: 'not implemented');

  @override
  Future<AuthResult> signInWithGoogle() async =>
      const AuthResult(error: 'not implemented');
  @override
  Future<Session?> recoverSession() async {
    throw Exception('Storage corrupted');
  }

  @override
  Future<AuthResult> signUp({required String email, required String password}) async =>
      const AuthResult(error: 'nope');

  @override
  Future<AuthResult> signIn({required String email, required String password}) async =>
      const AuthResult(error: 'nope');

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Stream<AuthChangeEvent> onAuthStateChange() => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Session? get currentSession => null;
}

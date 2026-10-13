import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show User, AuthChangeEvent;

import '../gateways/auth_gateway.dart';

enum AuthStatus { uninitialized, loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthGateway _gateway;

  AuthStatus _status = AuthStatus.uninitialized;
  User? _user;
  String? _errorMessage;
  StreamSubscription<AuthChangeEvent>? _authSub;

  AuthProvider({required AuthGateway gateway}) : _gateway = gateway;

  bool get offersSocialSignIn => _gateway.offersSocialSignIn;

  // -- Public getters -----------------------------------------------------

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Convenience getter for the current user's ID (null if not signed in).
  String? get userId => _user?.id;

  // -- Initialisation (session restore) -----------------------------------

  /// Call once at app start to restore a persisted session.
  Future<void> init() async {
    try {
      final session = await _gateway.recoverSession();
      if (session != null) {
        _user = _gateway.currentUser;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  // -- Auth actions -------------------------------------------------------

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      final result = await _gateway.signUp(email: email, password: password);
      if (result.isSuccess) {
        _user = result.user;
        _status = AuthStatus.authenticated;
        _errorMessage = null;
      } else {
        _status = AuthStatus.unauthenticated;
        _errorMessage = result.error;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      final result = await _gateway.signIn(email: email, password: password);
      if (result.isSuccess) {
        _user = result.user;
        _status = AuthStatus.authenticated;
        _errorMessage = null;
      } else {
        _status = AuthStatus.unauthenticated;
        _errorMessage = result.error;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await _gateway.signOut();
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
    } catch (e) {
      // Sign-out failed — keep user authenticated, surface the error.
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  // -- Social sign-in -----------------------------------------------------

  Future<void> signInWithApple() async {
    _setLoading();
    try {
      final result = await _gateway.signInWithApple();
      if (result.error == null && result.user == null) {
        // User cancelled
        _status = AuthStatus.unauthenticated;
      } else if (result.isSuccess) {
        _user = result.user;
        _status = AuthStatus.authenticated;
        _errorMessage = null;
      } else {
        _status = AuthStatus.unauthenticated;
        _errorMessage = result.error;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    _setLoading();
    try {
      final result = await _gateway.signInWithGoogle();
      if (result.error == null && result.user == null) {
        // User cancelled
        _status = AuthStatus.unauthenticated;
      } else if (result.isSuccess) {
        _user = result.user;
        _status = AuthStatus.authenticated;
        _errorMessage = null;
      } else {
        _status = AuthStatus.unauthenticated;
        _errorMessage = result.error;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  // -- Password reset -----------------------------------------------------

  /// Signed in through a reset link: the router sends them to set a new
  /// password before anything else.
  bool _passwordRecovery = false;
  bool get passwordRecovery => _passwordRecovery;

  /// Sets the new password; returns an error message or null.
  Future<String?> updatePassword(String password) async {
    final error = await _gateway.updatePassword(password);
    if (error == null) {
      _passwordRecovery = false;
      notifyListeners();
    }
    return error;
  }

  Future<bool> resetPassword(String email) async {
    _setLoading();
    try {
      await _gateway.resetPassword(email);
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // -- Error management ---------------------------------------------------

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // -- Auth state stream --------------------------------------------------

  /// Subscribe to external auth-state changes (token refresh, remote sign-out).
  void listenToAuthChanges() {
    _authSub?.cancel();
    _authSub = _gateway.onAuthStateChange().listen(_handleAuthEvent);
  }

  void _handleAuthEvent(AuthChangeEvent event) {
    switch (event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
        _user = _gateway.currentUser;
        _status = AuthStatus.authenticated;
        notifyListeners();
        break;
      case AuthChangeEvent.passwordRecovery:
        _user = _gateway.currentUser;
        _status = AuthStatus.authenticated;
        _passwordRecovery = true;
        notifyListeners();
        break;
      case AuthChangeEvent.signedOut:
        _user = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        break;
      default:
        break;
    }
  }

  // -- Helpers ------------------------------------------------------------

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

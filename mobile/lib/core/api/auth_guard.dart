import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'auth_storage.dart';

/// Global callback for auth-related navigation (e.g. redirect to login on 401).
/// Set once when the app starts so API layer can trigger navigation without context.
class AuthGuard {
  AuthGuard._();

  static GoRouter? router;
  static final ValueNotifier<int> authVersion = ValueNotifier<int>(0);
  static bool isAuthenticated = false;
  static bool isProvider = false;
  static bool isAdmin = false;
  static String? _pendingLoginMessage;

  static void setAuthState({
    required bool authenticated,
    bool provider = false,
    bool admin = false,
  }) {
    isAuthenticated = authenticated;
    isProvider = provider;
    isAdmin = admin;
    authVersion.value++;
  }

  static String? consumePendingLoginMessage() {
    final msg = _pendingLoginMessage;
    _pendingLoginMessage = null;
    return msg;
  }

  /// Call when the user must re-authenticate (e.g. 401). Clears auth and navigates to login.
  static Future<void> requireLogin({
    bool clearSession = false,
    String? message,
  }) async {
    if (clearSession) {
      await clearAuth();
    }
    setAuthState(authenticated: false);
    _pendingLoginMessage = message;
    router?.go('/login');
  }
}

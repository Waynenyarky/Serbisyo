import 'package:go_router/go_router.dart';

/// Global callback for auth-related navigation (e.g. redirect to login on 401).
/// Set once when the app starts so API layer can trigger navigation without context.
class AuthGuard {
  AuthGuard._();

  static GoRouter? router;

  /// Call when the user must re-authenticate (e.g. 401). Clears auth and navigates to login.
  static void requireLogin() {
    router?.go('/login');
  }
}

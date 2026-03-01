import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/api/auth_guard.dart';
import 'core/api/auth_storage.dart';
import 'core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // If user has a stored token, start on Home; otherwise start on login.
  final token = await getToken();
  final isLoggedIn = token != null && token.trim().isNotEmpty;
  final initialLocation = isLoggedIn ? '/' : '/login';

  final router = createAppRouter(initialLocation: initialLocation);
  AuthGuard.router = router;

  runApp(
    ProviderScope(
      child: SerbisyoApp(router: router),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/booking/presentation/bookings_screen.dart';
import '../../features/booking/presentation/booking_detail_screen.dart';
import '../../features/booking/presentation/booking_flow_screen.dart';
import '../../features/home/presentation/explore_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/service_detail_screen.dart';
import '../../features/messages/presentation/chat_screen.dart';
import '../../features/messages/presentation/messages_screen.dart';
import '../../features/profile/presentation/profile_detail_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/notifications_screen.dart';
import '../../features/provider/presentation/provider_onboarding_screen.dart';
import '../../features/provider/presentation/my_services_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../core/models/service_model.dart';
import 'shell_scaffold.dart';

/// Premium entrance transition for Search: fade + slide up + subtle scale.
Page<void> _buildSearchTransitionPage({required LocalKey key, required Widget child}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const curve = Curves.easeOutCubic;
      const reverseCurve = Curves.easeInCubic;
      final t = animation.drive(CurveTween(curve: curve));
      final reverseT = secondaryAnimation.drive(CurveTween(curve: reverseCurve));

      return AnimatedBuilder(
        animation: Listenable.merge([animation, secondaryAnimation]),
        builder: (context, _) {
          final fade = t.value * (1 - reverseT.value * 0.6);
          const slideOffset = 28.0;
          final dy = slideOffset * (1 - t.value) + 12 * reverseT.value;
          const scaleStart = 0.96;
          final scale = scaleStart + (1 - scaleStart) * t.value - 0.04 * reverseT.value;
          return Opacity(
            opacity: fade.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
          );
        },
      );
    },
  );
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKeyHome = GlobalKey<NavigatorState>();
final _shellNavigatorKeyFavorites = GlobalKey<NavigatorState>();
final _shellNavigatorKeyBookings = GlobalKey<NavigatorState>();
final _shellNavigatorKeyMessages = GlobalKey<NavigatorState>();
final _shellNavigatorKeyProfile = GlobalKey<NavigatorState>();

/// Creates the app router. [initialLocation] defaults to [defaultInitialLocation].
/// Pass '/' when user has a stored token so they stay on Home; pass '/login' when not logged in.
GoRouter createAppRouter({String initialLocation = '/login'}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final role = state.uri.queryParameters['role'];
          return SignUpScreen(initialRole: role);
        },
      ),
      GoRoute(
        path: '/service/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ServiceDetailScreen(serviceId: id);
        },
      ),
      GoRoute(
        path: '/booking/flow',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final service = state.extra as ServiceModel?;
          if (service == null) {
            return const Scaffold(
              body: Center(child: Text('Missing service')),
            );
          }
          final bookNearest = state.uri.queryParameters['nearest'] == 'true';
          return BookingFlowScreen(service: service, bookNearest: bookNearest);
        },
      ),
      GoRoute(
        path: '/booking/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return BookingDetailScreen(bookingId: id);
        },
      ),
      GoRoute(
        path: '/messages/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ChatScreen(threadId: id);
        },
      ),
      GoRoute(
        path: '/profile/detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileDetailScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/search',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _buildSearchTransitionPage(
          key: state.pageKey,
          child: SearchScreen(
            initialQuery: state.uri.queryParameters['q'],
          ),
        ),
      ),
      GoRoute(
        path: '/explore',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExploreScreen(),
      ),
      GoRoute(
        path: '/provider/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as ServiceModel?;
          return ProviderOnboardingScreen(existingDraft: extra);
        },
      ),
      GoRoute(
        path: '/provider/services',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MyServicesScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => ShellScaffold(
          navigationShell: navigationShell,
        ),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyHome,
            routes: [
              GoRoute(
                path: '/',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyFavorites,
            routes: [
              GoRoute(
                path: '/favorites',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ShellFavoritesOrMyServices(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyBookings,
            routes: [
              GoRoute(
                path: '/bookings',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: BookingsScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyMessages,
            routes: [
              GoRoute(
                path: '/messages',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: MessagesScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyProfile,
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

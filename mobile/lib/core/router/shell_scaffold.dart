import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/api_providers.dart';
import '../theme/app_colors.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/provider/presentation/my_services_screen.dart';

class ShellScaffold extends ConsumerWidget {
  const ShellScaffold({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final isProvider = userAsync.valueOrNull?.isProviderRole ?? false;
    final favoritesAsync = ref.watch(favoritesIdsProvider);
    final favoriteCount = favoritesAsync.valueOrNull?.length ?? 0;
    final threadsAsync = ref.watch(threadsProvider);
    final unreadMessages = threadsAsync.valueOrNull?.fold<int>(0, (sum, t) => sum + t.unreadCount) ?? 0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  index: 0,
                  currentIndex: navigationShell.currentIndex,
                  onTap: () => _onTap(context, 0),
                ),
                _NavItem(
                  icon: isProvider ? Icons.work_outline_rounded : Icons.favorite_border_rounded,
                  activeIcon: isProvider ? Icons.work_rounded : Icons.favorite_rounded,
                  label: isProvider ? 'My services' : 'Favorites',
                  index: 1,
                  currentIndex: navigationShell.currentIndex,
                  onTap: () => _onTap(context, 1),
                  badgeCount: isProvider ? null : (favoriteCount > 0 ? favoriteCount : null),
                ),
                _NavItem(
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_today_rounded,
                  label: 'Bookings',
                  index: 2,
                  currentIndex: navigationShell.currentIndex,
                  onTap: () => _onTap(context, 2),
                ),
                _NavItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: 'Messages',
                  index: 3,
                  currentIndex: navigationShell.currentIndex,
                  onTap: () => _onTap(context, 3),
                  badgeCount: unreadMessages > 0 ? unreadMessages : null,
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  index: 4,
                  currentIndex: navigationShell.currentIndex,
                  onTap: () => _onTap(context, 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

/// Shows Favorites for customers and My services for providers (shell tab 1).
class ShellFavoritesOrMyServices extends ConsumerWidget {
  const ShellFavoritesOrMyServices({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProvider = ref.watch(currentUserProvider).valueOrNull?.isProviderRole ?? false;
    if (isProvider) {
      return const MyServicesScreen(showBackButton: false);
    }
    return const FavoritesScreen();
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;
  /// When non-null and > 0, shows a red bubble with count on the icon.
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    final showBadge = badgeCount != null && badgeCount! > 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 24,
                  color: isSelected ? AppColors.primary : AppColors.textTertiary,
                ),
                if (showBadge) _buildBadge(context),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context) {
    final count = badgeCount!;
    final isSingleDigit = count <= 9;
    final label = count > 99 ? '99+' : '$count';
    return Positioned(
      right: -6,
      top: -4,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSingleDigit ? 4 : 5,
          vertical: 2,
        ),
        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.surface, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.4),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                height: 1.1,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/profile_storage.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/repository/api_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled = true;
  final int _unreadCount = 0; // Could be from API later

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final providerStatusAsync = ref.watch(providerStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        actions: [
          _NotificationBellButton(
            notificationsEnabled: _notificationsEnabled,
            unreadCount: _unreadCount,
            onTap: _onNotificationsTap,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sm),
              _PremiumProfileCard(userAsync: userAsync),
              const SizedBox(height: AppSpacing.lg),
              _SectionLabel(label: 'Explore'),
              const SizedBox(height: AppSpacing.sm),
              _ProviderExploreCard(
                userAsync: userAsync,
                providerStatusAsync: providerStatusAsync,
                onBecomeHost: () => context.push('/signup?role=provider'),
                onCompleteService: () => context.push('/provider/onboarding'),
                onMyServices: () => context.push('/provider/services'),
              ),
              const SizedBox(height: AppSpacing.xl),
              _SectionLabel(label: 'Account'),
              const SizedBox(height: AppSpacing.sm),
              _SectionCard(
                children: [
                  _PremiumMenuTile(
                    icon: Icons.favorite_border_rounded,
                    activeIcon: Icons.favorite_rounded,
                    label: 'Favorites',
                    subtitle: 'Saved services & wishlist',
                    onTap: () => context.go('/favorites'),
                  ),
                  _PremiumDivider(),
                  _PremiumMenuTile(
                    icon: Icons.payment_outlined,
                    activeIcon: Icons.payment_rounded,
                    label: 'Payment methods',
                    subtitle: 'Cards, e-wallets',
                    onTap: () {},
                  ),
                  _PremiumDivider(),
                  _NotificationTile(
                    icon: Icons.notifications_outlined,
                    activeIcon: Icons.notifications_rounded,
                    label: 'Notifications',
                    subtitle: 'Booking reminders, messages',
                    value: _notificationsEnabled,
                    onChanged: (v) => setState(() => _notificationsEnabled = v),
                  ),
                  _PremiumDivider(),
                  _PremiumMenuTile(
                    icon: Icons.help_outline_rounded,
                    activeIcon: Icons.help_rounded,
                    label: 'Help',
                    subtitle: 'FAQs & support',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionCard(
                children: [
                  _PremiumMenuTile(
                    icon: Icons.logout_rounded,
                    label: 'Log out',
                    subtitle: 'Sign out of your account',
                    onTap: () => _showLogoutConfirmation(context),
                    iconColor: AppColors.error,
                    textColor: AppColors.error,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  void _onNotificationsTap() {
    context.push('/notifications');
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text(
          'Are you sure you want to log out? You will need to sign in again to access your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Log out'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true || !context.mounted) return;
      await ref.read(apiRepositoryProvider).logout();
      await clearProfileExtended();
      ref.invalidate(currentUserProvider);
      ref.invalidate(profileExtendedProvider);
      if (!context.mounted) return;
      context.go('/login');
    });
  }
}

/// App bar notification bell: professional container, badge, tooltip, and tap feedback.
class _NotificationBellButton extends StatelessWidget {
  const _NotificationBellButton({
    required this.notificationsEnabled,
    required this.unreadCount,
    required this.onTap,
  });

  final bool notificationsEnabled;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Notifications',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          splashColor: AppColors.primary.withValues(alpha: 0.12),
          highlightColor: AppColors.primary.withValues(alpha: 0.06),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    notificationsEnabled
                        ? Icons.notifications_rounded
                        : Icons.notifications_outlined,
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                  if (unreadCount > 0) _buildBadge(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context) {
    final isSingleDigit = unreadCount <= 9;
    final label = unreadCount > 99 ? '99+' : '$unreadCount';
    return Positioned(
      right: -4,
      top: -2,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSingleDigit ? 5 : 6,
          vertical: 3,
        ),
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: AppColors.surface, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                height: 1.1,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

class _PremiumProfileCard extends StatelessWidget {
  const _PremiumProfileCard({required this.userAsync});

  final AsyncValue<CurrentUser?> userAsync;

  static String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/profile/detail'),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.1),
                AppColors.primaryLight.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              userAsync.when(
                data: (user) => _buildContent(context, user?.name, user?.email),
                loading: () => _buildContent(context, '...', '...'),
                error: (e, s) => _buildContent(context, 'Guest', 'Not signed in'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View profile',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, String? name, String? email) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: name != null && name != '...' && name != 'Guest'
                ? Text(
                    _initials(name),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                  )
                : Icon(
                    Icons.person_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          name ?? 'Guest',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          email ?? 'Not signed in',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Explore card: Become a host (customer) | Complete your first service (provider, no service) | My services (provider, has service).
class _ProviderExploreCard extends StatelessWidget {
  const _ProviderExploreCard({
    required this.userAsync,
    required this.providerStatusAsync,
    required this.onBecomeHost,
    required this.onCompleteService,
    required this.onMyServices,
  });

  final AsyncValue<CurrentUser?> userAsync;
  final AsyncValue<ProviderStatus?> providerStatusAsync;
  final VoidCallback onBecomeHost;
  final VoidCallback onCompleteService;
  final VoidCallback onMyServices;

  @override
  Widget build(BuildContext context) {
    final role = userAsync.valueOrNull?.role;
    final isProvider = role == 'provider';
    if (!isProvider) return _BecomeHostCard(onTap: onBecomeHost);

    final status = providerStatusAsync.valueOrNull;
    final hasActiveService = status?.hasActiveService ?? false;

    if (hasActiveService) {
      return _ExploreCard(
        title: 'My services',
        subtitle: 'Manage your offerings and bookings',
        icon: Icons.work_rounded,
        onTap: onMyServices,
      );
    }
    return _ExploreCard(
      title: 'Complete your first service',
      subtitle: 'Add a service to start receiving bookings',
      icon: Icons.add_business_rounded,
      onTap: onCompleteService,
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.18),
                      AppColors.primaryLight.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _BecomeHostCard extends StatelessWidget {
  const _BecomeHostCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.18),
                      AppColors.primaryLight.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(Icons.home_work_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Become a host',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Offer your services and get booked',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _PremiumDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: AppSpacing.md,
      color: AppColors.divider,
    );
  }
}

class _PremiumMenuTile extends StatelessWidget {
  const _PremiumMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.activeIcon,
    this.subtitle,
    this.iconColor,
    this.textColor,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? AppColors.textPrimary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.textSecondary).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Icon(
          activeIcon ?? icon,
          size: 22,
          color: iconColor ?? AppColors.textSecondary,
        ),
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
      ),
      subtitle: subtitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor?.withValues(alpha: 0.8) ?? AppColors.textTertiary,
                    ),
              ),
            )
          : null,
      trailing: Icon(Icons.chevron_right_rounded, color: textColor ?? AppColors.textTertiary, size: 22),
      onTap: onTap,
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Icon(
          value ? activeIcon : icon,
          size: 22,
          color: AppColors.primary,
        ),
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
      ),
    );
  }
}

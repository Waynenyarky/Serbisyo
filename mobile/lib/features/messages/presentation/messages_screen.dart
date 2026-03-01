import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/api_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/models/message_thread_model.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  int _selectedFilterIndex = 0; // 0: All, 1: Unread, 2: Support

  static const List<String> _filterLabels = ['All', 'Unread', 'Support'];

  @override
  Widget build(BuildContext context) {
    final threadsAsync = ref.watch(threadsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Messages',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        actions: [
          _AppBarAction(
            icon: Icons.search_rounded,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _AppBarAction(
            icon: Icons.settings_outlined,
            onTap: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FilterTabs(
            labels: _filterLabels,
            selectedIndex: _selectedFilterIndex,
            onSelected: (index) => setState(() => _selectedFilterIndex = index),
          ),
          Expanded(
            child: threadsAsync.when(
              data: (threads) {
                final filtered = _filterThreads(threads, _selectedFilterIndex);
                if (filtered.isEmpty) {
                  return _EmptyState(
                    onShowAll: _selectedFilterIndex != 0
                        ? () => setState(() => _selectedFilterIndex = 0)
                        : null,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final thread = filtered[index];
                    return _MessageTile(
                      thread: thread,
                      onTap: () => context.push('/messages/${thread.id}'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => _EmptyState(onShowAll: null),
            ),
          ),
        ],
      ),
    );
  }

  List<MessageThreadModel> _filterThreads(List<MessageThreadModel> threads, int index) {
    switch (index) {
      case 1:
        return threads.where((t) => t.unreadCount > 0).toList();
      case 2:
        return []; // Support: no threads for now
      default:
        return threads;
    }
  }
}

class _AppBarAction extends StatelessWidget {
  const _AppBarAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.background,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isSelected = index == selectedIndex;
          return Padding(
            padding: EdgeInsets.only(right: index < labels.length - 1 ? 10 : 0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelected(index),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.textPrimary : AppColors.background,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(
                      color: isSelected ? AppColors.textPrimary : AppColors.divider,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    labels[index],
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.surface : AppColors.textSecondary,
                        ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.onShowAll});

  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 64,
                color: AppColors.textTertiary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'You don\'t have any messages',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'When you receive a message about a booking, it will appear here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            if (onShowAll != null) ...[
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton(
                onPressed: onShowAll,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                  side: BorderSide(color: AppColors.textSecondary),
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: const Text('Show all messages'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.thread, required this.onTap});

  final MessageThreadModel thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasUnread = thread.unreadCount > 0;

    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.providerName,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          thread.lastMessageAt,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textTertiary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            thread.lastMessage,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
                                  fontWeight: hasUnread ? FontWeight.w500 : null,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (thread.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                            ),
                            child: Text(
                              thread.unreadCount > 99 ? '99+' : '${thread.unreadCount}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

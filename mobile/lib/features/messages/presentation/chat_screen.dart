import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/api_providers.dart';
import '../../../core/repository/api_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    required this.threadId,
    super.key,
  });

  final String threadId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    final repo = ref.read(apiRepositoryProvider);
    await repo.sendMessage(widget.threadId, text);
    if (mounted) ref.invalidate(threadByIdProvider(widget.threadId));
  }

  @override
  Widget build(BuildContext context) {
    final asyncThread = ref.watch(threadByIdProvider(widget.threadId));

    return asyncThread.when(
      data: (data) {
        final thread = data as MessageThreadWithMessages?;
        if (thread == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chat')),
            body: const Center(child: Text('Conversation not found')),
          );
        }
        final messages = thread.messages;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(thread.providerName),
                Text(thread.serviceTitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            backgroundColor: AppColors.surface,
            leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final bubble = messages[messages.length - 1 - index];
                    return _Bubble(text: bubble.text, isMe: bubble.isMe, time: bubble.time);
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                color: AppColors.surface,
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _sendMessage,
                        icon: const Icon(Icons.send_rounded),
                        style: IconButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Chat'), backgroundColor: AppColors.surface),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: Center(child: Text('Could not load conversation: $e')),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.isMe, required this.time});

  final String text;
  final bool isMe;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isMe ? Colors.white : AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isMe ? Colors.white70 : AppColors.textTertiary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

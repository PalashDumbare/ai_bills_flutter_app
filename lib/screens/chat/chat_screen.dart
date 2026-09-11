import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(chatProvider.notifier).sendMessage(text);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) _scrollController.animateTo(_scrollController.position.maxScrollExtent + 200, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          if (state.messages.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => ref.read(chatProvider.notifier).clear()),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: state.messages.isEmpty ? _buildEmptyState() : _buildMessages(state),
          ),
          if (state.isLoading) const LinearProgressIndicator(minHeight: 2),
          if (state.error != null)
            Container(
              width: double.infinity,
              color: AppColors.error.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(state.error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
            ),
          _buildInputBar(state.isLoading),
        ],
      ),
    );
  }

  Widget _buildMessages(ChatState state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.messages.length,
      itemBuilder: (context, i) {
        final m = state.messages[i];
        return Align(
          alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
            decoration: BoxDecoration(
              color: m.isUser ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: m.isUser ? null : Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.text, style: TextStyle(fontSize: 14, color: m.isUser ? Colors.white : AppColors.textPrimary)),
                if (m.sources.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  const Text('Sources', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  ...m.sources.take(3).map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                          child: Text(s['text']?.toString().substring(0, (s['text']?.toString().length ?? 0).clamp(0, 120)) ?? '-', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ),
                      )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 20),
            const Text('Ask about your bills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            const Text('Upload & index documents first, then ask like "When does my LG warranty expire?"', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(bool loading) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)))),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !loading,
                decoration: const InputDecoration(hintText: 'Ask about your bills...', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false, contentPadding: EdgeInsets.symmetric(horizontal: 4)),
                maxLines: null,
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(onPressed: loading ? null : _send, icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}

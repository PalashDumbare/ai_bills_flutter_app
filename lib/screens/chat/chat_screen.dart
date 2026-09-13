import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
  int? _highlightedSourceGlobalIndex; // for highlight feedback

  String _linkifyCitations(String text) {
    // Convert [1] -> [1](source:1) so markdown makes it tappable, keep plain [1] visible anyway
    return text.replaceAllMapped(RegExp(r'\[(\d+)\]'), (m) => '[${m[1]}](source:${m[1]})');
  }

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
        final isUser = m.isUser;
        // For bot messages, render Markdown with linked citations; for user plain text
        final linkedText = isUser ? m.text : _linkifyCitations(m.text);

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
            decoration: BoxDecoration(
              color: isUser ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: isUser ? null : Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isUser)
                  Text(m.text, style: const TextStyle(fontSize: 14, color: Colors.white))
                else ...[
                  if (m.text.contains('(from web search)'))
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF0EA5E9).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.3))),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.language, size: 14, color: Color(0xFF0EA5E9)), SizedBox(width: 6), Text('Answer from web search', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0EA5E9)))]),
                    ),
                  MarkdownBody(
                    data: linkedText.replaceAll(' (from web search)', '').replaceAll('_(from web search)_', '').replaceAll('(from web search)', '').trim(),
                    selectable: true,
                    onTapLink: (text, href, title) {
                      if (href != null && href.startsWith('source:')) {
                        final idx = int.tryParse(href.split(':').last);
                        if (idx != null && idx > 0 && idx <= m.sources.length) {
                          setState(() => _highlightedSourceGlobalIndex = i * 100 + idx);
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) setState(() => _highlightedSourceGlobalIndex = null);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Source [$idx]'), duration: const Duration(milliseconds: 800)),
                          );
                        }
                      }
                    },
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
                      listBullet: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      strong: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      a: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                      blockquoteDecoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: const Border(left: BorderSide(color: AppColors.primary, width: 3)),
                      ),
                      blockquotePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    // extensionSet defaults to gitHubFlavored
                  ),
                ],
                if (m.sources.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Sources', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                      const SizedBox(width: 6),
                      if (m.sources.any((s) => s['document_id'] == 'web'))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF0EA5E9).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.language, size: 10, color: Color(0xFF0EA5E9)), SizedBox(width: 4), Text('Web search', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF0EA5E9)))]),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...m.sources.take(3).toList().asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final s = entry.value;
                    final isHighlighted = _highlightedSourceGlobalIndex == i * 100 + idx;
                    final isWeb = s['document_id'] == 'web';
                    final txt = s['text']?.toString() ?? '-';
                    // Extract URL for web sources: text ends with (https://...)
                    final urlMatch = RegExp(r'\((https?://[^)]+)\)').firstMatch(txt);
                    final url = urlMatch?.group(1);
                    final cleanTxt = txt.replaceAll(RegExp(r'\s*\(https?://[^)]+\)\s*$'), '').trim();
                    final preview = cleanTxt.length > 140 ? '${cleanTxt.substring(0, 140)}…' : cleanTxt;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isWeb ? const Color(0xFF0EA5E9).withValues(alpha: 0.06) : (isHighlighted ? AppColors.primary.withValues(alpha: 0.08) : AppColors.background),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isWeb ? const Color(0xFF0EA5E9).withValues(alpha: 0.3) : (isHighlighted ? AppColors.primary : Colors.transparent), width: (isWeb || isHighlighted) ? 1.2 : 0),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isWeb ? const Color(0xFF0EA5E9) : (isHighlighted ? AppColors.primary : AppColors.primary.withValues(alpha: 0.12)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                if (isWeb) const Icon(Icons.language, size: 10, color: Colors.white),
                                if (isWeb) const SizedBox(width: 3),
                                Text(isWeb ? 'Web [$idx]' : '[$idx]', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isWeb || isHighlighted ? Colors.white : AppColors.primary)),
                              ]),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(preview, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3)),
                                if (isWeb && url != null) ...[
                                  const SizedBox(height: 4),
                                  Text(url, style: const TextStyle(fontSize: 10, color: Color(0xFF0EA5E9), decoration: TextDecoration.underline, height: 1.2)),
                                ],
                                if (isWeb)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Text('Verified from web search', style: TextStyle(fontSize: 9, color: Color(0xFF0EA5E9), fontStyle: FontStyle.italic)),
                                  ),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
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

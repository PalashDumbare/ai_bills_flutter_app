import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'upload_provider.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final List<Map<String, dynamic>> sources;
  ChatMessage({required this.text, required this.isUser, this.sources = const []});
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  const ChatState({this.messages = const [], this.isLoading = false, this.error});

  ChatState copyWith({List<ChatMessage>? messages, bool? isLoading, String? error}) {
    return ChatState(messages: messages ?? this.messages, isLoading: isLoading ?? this.isLoading, error: error);
  }
}

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState();

  Future<void> sendMessage(String question, {String? documentId}) async {
    if (question.trim().isEmpty) return;
    final userMsg = ChatMessage(text: question, isUser: true);
    state = state.copyWith(messages: [...state.messages, userMsg], isLoading: true, error: null);

    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.chat(question: question, documentId: documentId);
      final answer = res['answer'] as String? ?? 'No answer';
      final rawSources = (res['sources'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      // Dedup sources by document_id:chunk_index + text hash (backend now does this, keep client safety)
      final seenKeys = <String>{};
      final seenText = <String>{};
      final sources = <Map<String, dynamic>>[];
      for (final s in rawSources) {
        final key = '${s['document_id']}:${s['chunk_index']}';
        final norm = (s['text']?.toString().split(RegExp(r'\s+')).take(30).join(' ').toLowerCase() ?? '');
        if (seenKeys.contains(key) || seenText.contains(norm)) continue;
        seenKeys.add(key);
        seenText.add(norm);
        sources.add(s);
      }
      final botMsg = ChatMessage(text: answer, isUser: false, sources: sources);
      state = state.copyWith(messages: [...state.messages, botMsg], isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() => state = const ChatState();
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);

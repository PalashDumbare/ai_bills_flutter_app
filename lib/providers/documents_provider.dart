import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/document.dart';
import 'upload_provider.dart';

final documentsProvider = AsyncNotifierProvider<DocumentsNotifier, List<Document>>(
  DocumentsNotifier.new,
);

class DocumentsNotifier extends AsyncNotifier<List<Document>> {
  static const String _userId = 'default-user';

  @override
  Future<List<Document>> build() async {
    final api = ref.read(apiServiceProvider);
    final raw = await api.fetchDocuments(userId: _userId);
    return raw.map((e) => Document.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiServiceProvider);
      final raw = await api.fetchDocuments(userId: _userId);
      return raw.map((e) => Document.fromJson(e as Map<String, dynamic>)).toList();
    });
  }
}

final documentDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final api = ref.read(apiServiceProvider);
  return api.fetchDocumentDetail(id);
});

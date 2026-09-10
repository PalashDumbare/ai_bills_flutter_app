import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/document.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

enum UploadStatus { idle, uploading, extracting, structuring, indexing, done, error }

class UploadState {
  final UploadStatus status;
  final double progress;
  final String? error;
  final Document? document;
  final dynamic structuredData;

  const UploadState({
    this.status = UploadStatus.idle,
    this.progress = 0,
    this.error,
    this.document,
    this.structuredData,
  });

  UploadState copyWith({
    UploadStatus? status,
    double? progress,
    String? error,
    Document? document,
    dynamic structuredData,
  }) {
    return UploadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error,
      document: document ?? this.document,
      structuredData: structuredData ?? this.structuredData,
    );
  }
}

class UploadNotifier extends Notifier<UploadState> {
  late final ApiService _api;
  static const String _userId = 'default-user';

  @override
  UploadState build() {
    _api = ref.read(apiServiceProvider);
    return const UploadState();
  }

  Future<void> uploadAndProcess(File file) async {
    state = state.copyWith(status: UploadStatus.uploading, progress: 0, error: null);

    try {
      final uploadResult = await _api.uploadDocument(
        file: file,
        userId: _userId,
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );

      final documentId = uploadResult['document_id'] as String;
      final document = Document.fromJson({
        ...uploadResult,
        'created_at': DateTime.now().toIso8601String(),
      });

      state = state.copyWith(
        status: UploadStatus.extracting,
        document: document,
        progress: 1.0,
      );

      await _api.extractDocument(documentId);

      state = state.copyWith(status: UploadStatus.structuring);

      final structureResult = await _api.structureDocument(
        documentId: documentId,
        userId: _userId,
      );

      state = state.copyWith(
        status: UploadStatus.indexing,
        structuredData: structureResult['structured_data'],
      );

      await _api.indexDocument(documentId);

      state = state.copyWith(status: UploadStatus.done);
    } catch (e) {
      state = state.copyWith(
        status: UploadStatus.error,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = const UploadState();
  }
}

final uploadProvider = NotifierProvider<UploadNotifier, UploadState>(() {
  return UploadNotifier();
});

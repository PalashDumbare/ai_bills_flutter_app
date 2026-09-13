import 'dart:io';
import 'package:flutter/foundation.dart';
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

  Future<void> uploadAndProcess({
    required String fileName,
    File? file,
    Uint8List? fileBytes,
  }) async {
    state = state.copyWith(status: UploadStatus.uploading, progress: 0, error: null);

    try {
      // Single-call upload: backend now does extract→structure→index inline (backend/app/main.py:102)
      // Old 4-call flow kept for backward compat but no longer needed.
      final uploadResult = await _api.uploadDocument(
        fileName: fileName,
        userId: _userId,
        file: file,
        fileBytes: fileBytes,
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );

      final documentId = uploadResult['document_id'] as String;
      final document = Document.fromJson({
        ...uploadResult,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Backend already processed (extracted + structured + indexed) during upload.
      // Fetch structured data for UI, fallback to legacy flow if not yet ready.
      state = state.copyWith(status: UploadStatus.structuring, document: document, progress: 1.0);

      dynamic structuredData;
      try {
        // Try fetching structured data (poll once, backend should be done)
        final detail = await _api.fetchDocumentDetail(documentId);
        structuredData = detail['structured_data'];
        // If backend was still processing (e.g. large PDF), fallback to legacy explicit calls (idempotent)
        if (detail['document_type'] == null) {
          state = state.copyWith(status: UploadStatus.extracting);
          await _api.extractDocument(documentId);
          state = state.copyWith(status: UploadStatus.structuring);
          final structureResult = await _api.structureDocument(documentId: documentId, userId: _userId);
          structuredData = structureResult['structured_data'];
          state = state.copyWith(status: UploadStatus.indexing, structuredData: structuredData);
          await _api.indexDocument(documentId);
        }
      } catch (_) {
        // Legacy fallback if fetch fails
        structuredData = null;
      }

      state = state.copyWith(status: UploadStatus.done, structuredData: structuredData);
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

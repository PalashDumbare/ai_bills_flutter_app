import 'dart:io';
import 'package:dio/dio.dart';
import '../config/api.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  Future<Map<String, dynamic>> uploadDocument({
    required File file,
    required String userId,
    void Function(double progress)? onProgress,
  }) async {
    final fileName = file.path.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      ),
      'user_id': userId,
    });

    final response = await _dio.post(
      ApiConfig.upload,
      data: formData,
      onSendProgress: onProgress != null
          ? (sent, total) => onProgress(sent / total)
          : null,
    );

    return response.data;
  }

  Future<Map<String, dynamic>> extractDocument(String documentId) async {
    final response = await _dio.post(ApiConfig.extract(documentId));
    return response.data;
  }

  Future<Map<String, dynamic>> structureDocument({
    required String documentId,
    required String userId,
  }) async {
    final response = await _dio.post(
      ApiConfig.structure(documentId),
      data: {'user_id': userId},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> indexDocument(String documentId) async {
    final response = await _dio.post(ApiConfig.index(documentId));
    return response.data;
  }

  Future<Map<String, dynamic>> chat({
    required String question,
    String? documentId,
  }) async {
    final response = await _dio.post(
      ApiConfig.chat,
      data: {
        'question': question,
        'document_id': documentId,
      },
    );
    return response.data;
  }
}

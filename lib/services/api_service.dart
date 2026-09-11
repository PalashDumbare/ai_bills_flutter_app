import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
    required String fileName,
    required String userId,
    Uint8List? fileBytes,
    File? file,
    void Function(double progress)? onProgress,
  }) async {
    late MultipartFile multipartFile;

    if (kIsWeb && fileBytes != null) {
      multipartFile = MultipartFile.fromBytes(
        fileBytes,
        filename: fileName,
      );
    } else if (file != null) {
      multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      );
    } else {
      throw Exception('No file data provided');
    }

    final formData = FormData.fromMap({
      'file': multipartFile,
      'user_id': userId,
    });

    final response = await _dio.post(
      ApiConfig.upload,
      data: formData,
      // onSendProgress forces a CORS preflight on Web (XMLHttpRequest + upload
      // listener) -> fails if server doesn't handle OPTIONS. Disable on Web.
      onSendProgress: !kIsWeb && onProgress != null
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

  Future<List<dynamic>> fetchDocuments({String? userId}) async {
    final response = await _dio.get(
      ApiConfig.documents,
      queryParameters: userId != null ? {'user_id': userId} : null,
    );
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> fetchDocumentDetail(String documentId) async {
    final response = await _dio.get(ApiConfig.documentDetail(documentId));
    return response.data as Map<String, dynamic>;
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

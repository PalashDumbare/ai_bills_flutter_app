class ApiConfig {
  static const String baseUrl = 'http://localhost:8000';
  
  static const String documents = '/documents';
  static const String upload = '/documents/upload';
  static String extract(String id) => '/documents/$id/extract';
  static String structure(String id) => '/documents/$id/structure';
  static String index(String id) => '/documents/$id/index';
  static const String chat = '/chat';
}

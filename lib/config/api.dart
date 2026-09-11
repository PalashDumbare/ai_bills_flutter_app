class ApiConfig {
  // Use --dart-define=API_BASE_URL=http://<your-ip>:8000 for device/web.
  // For Android emulator use http://10.0.2.2:8000, for iOS sim/web use http://localhost:8000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
  
  static const String documents = '/documents';
  static const String upload = '/documents/upload';
  static String extract(String id) => '/documents/$id/extract';
  static String structure(String id) => '/documents/$id/structure';
  static String index(String id) => '/documents/$id/index';
  static const String chat = '/chat';
}

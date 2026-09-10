class Document {
  final String id;
  final String userId;
  final String filename;
  final String? documentType;
  final DateTime createdAt;

  Document({
    required this.id,
    required this.userId,
    required this.filename,
    this.documentType,
    required this.createdAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['document_id'] ?? json['id'],
      userId: json['user_id'] ?? '',
      filename: json['filename'] ?? '',
      documentType: json['document_type'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

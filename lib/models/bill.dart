class Bill {
  final String id;
  final String documentId;
  final String? provider;
  final String? billType;
  final double? amount;
  final DateTime? dueDate;
  final String? billingPeriod;

  Bill({
    required this.id,
    required this.documentId,
    this.provider,
    this.billType,
    this.amount,
    this.dueDate,
    this.billingPeriod,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'],
      documentId: json['document_id'],
      provider: json['provider'],
      billType: json['bill_type'],
      amount: json['amount'] != null
          ? double.parse(json['amount'].toString())
          : null,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      billingPeriod: json['billing_period'],
    );
  }
}

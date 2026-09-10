class Appliance {
  final String id;
  final String documentId;
  final String? brand;
  final String? product;
  final String? model;
  final DateTime? purchaseDate;
  final double? amount;
  final int? warrantyMonths;
  final DateTime? warrantyExpiry;

  Appliance({
    required this.id,
    required this.documentId,
    this.brand,
    this.product,
    this.model,
    this.purchaseDate,
    this.amount,
    this.warrantyMonths,
    this.warrantyExpiry,
  });

  factory Appliance.fromJson(Map<String, dynamic> json) {
    return Appliance(
      id: json['id'],
      documentId: json['document_id'],
      brand: json['brand'],
      product: json['product'],
      model: json['model'],
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'])
          : null,
      amount: json['amount'] != null
          ? double.parse(json['amount'].toString())
          : null,
      warrantyMonths: json['warranty_months'],
      warrantyExpiry: json['warranty_expiry'] != null
          ? DateTime.parse(json['warranty_expiry'])
          : null,
    );
  }
}

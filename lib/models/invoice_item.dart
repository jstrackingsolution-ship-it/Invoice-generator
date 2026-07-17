import 'package:uuid/uuid.dart';

class InvoiceItem {
  final String id;
  String description;
  double quantity;
  double unitPrice;

  InvoiceItem({
    String? id,
    this.description = '',
    this.quantity = 1,
    this.unitPrice = 0,
  }) : id = id ?? const Uuid().v4();

  double get total => quantity * unitPrice;

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
        id: json['id'],
        description: json['description'] ?? '',
        quantity: (json['quantity'] ?? 1).toDouble(),
        unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      );
}

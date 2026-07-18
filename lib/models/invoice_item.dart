import 'package:uuid/uuid.dart';

class InvoiceItem {
  final String id;
  String description;
  double quantity;
  double unitPrice;

  /// Number of months this line item covers (e.g. a recurring GPS service
  /// charge). Defaults to 1 so existing behaviour (qty × unit price) is
  /// unchanged for one-off items.
  int months;

  InvoiceItem({
    String? id,
    this.description = '',
    this.quantity = 1,
    this.unitPrice = 0,
    this.months = 1,
  }) : id = id ?? const Uuid().v4();

  double get total => quantity * unitPrice * months;

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'months': months,
      };

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
        id: json['id'],
        description: json['description'] ?? '',
        quantity: (json['quantity'] ?? 1).toDouble(),
        unitPrice: (json['unitPrice'] ?? 0).toDouble(),
        months: json['months'] ?? 1,
      );
}

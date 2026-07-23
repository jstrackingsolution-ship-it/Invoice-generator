import 'package:uuid/uuid.dart';
import 'invoice_item.dart';

enum PaymentMethod {
  cash,
  bankTransfer,
  mobileMoney,
  cheque,
  other,
}

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.cheque:
        return 'Cheque';
      case PaymentMethod.other:
        return 'Other';
    }
  }
}

class Receipt {
  final String id;
  String receiptNumber;
  final String invoiceId;
  final String invoiceNumber;

  final String companyName;
  final String? companyLogoBase64;
  final String? companyTin;
  final String? companyVrn;

  final String clientName;
  final String? clientTin;
  final String? clientVrn;
  final double amountPaid;
  final DateTime datePaid;
  final PaymentMethod method;

  /// Snapshot of the invoice's line items and tax breakdown, so the receipt
  /// can show an itemized "Purchased Items" section independent of any
  /// later edits to the original invoice.
  final List<InvoiceItem> items;
  final double subtotal;
  final double taxRate;
  final double taxAmount;

  /// Only used for GPS service invoices
  final int? monthsPaid;
  final DateTime? serviceExpiry;

  Receipt({
    String? id,
    required this.receiptNumber,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.companyName,
    this.companyLogoBase64,
    this.companyTin,
    this.companyVrn,
    required this.clientName,
    this.clientTin,
    this.clientVrn,
    required this.amountPaid,
    required this.datePaid,
    this.method = PaymentMethod.cash,
    List<InvoiceItem>? items,
    this.subtotal = 0,
    this.taxRate = 0,
    this.taxAmount = 0,
    this.monthsPaid,
    this.serviceExpiry,
  })  : items = items ?? const [],
        id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receiptNumber': receiptNumber,
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'companyName': companyName,
      'companyLogoBase64': companyLogoBase64,
      'companyTin': companyTin,
      'companyVrn': companyVrn,
      'clientName': clientName,
      'clientTin': clientTin,
      'clientVrn': clientVrn,
      'amountPaid': amountPaid,
      'datePaid': datePaid.toIso8601String(),
      'method': method.name,
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'monthsPaid': monthsPaid,
      'serviceExpiry': serviceExpiry?.toIso8601String(),
    };
  }

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id']?.toString(),
      receiptNumber: json['receiptNumber']?.toString() ?? '',
      invoiceId: json['invoiceId']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? '',
      companyName:
          json['companyName']?.toString() ?? 'SJ TRACKING SOLUTION',
      companyLogoBase64: json['companyLogoBase64']?.toString(),
      companyTin: json['companyTin']?.toString(),
      companyVrn: json['companyVrn']?.toString(),
      clientName: json['clientName']?.toString() ?? '',
      clientTin: json['clientTin']?.toString(),
      clientVrn: json['clientVrn']?.toString(),
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0.0,
      datePaid:
          DateTime.tryParse(json['datePaid']?.toString() ?? '') ??
              DateTime.now(),
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => PaymentMethod.cash,
      ),
      items: ((json['items'] as List<dynamic>?) ?? [])
          .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      monthsPaid: json['monthsPaid'] as int?,
      serviceExpiry: json['serviceExpiry'] != null
          ? DateTime.tryParse(json['serviceExpiry'].toString())
          : null,
    );
  }
}
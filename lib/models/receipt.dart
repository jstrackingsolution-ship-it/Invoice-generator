import 'package:uuid/uuid.dart';
import '../models/receipt.dart';

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
  final double amountPaid;
  final DateTime datePaid;
  final PaymentMethod method;

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
    required this.amountPaid,
    required this.datePaid,
    this.method = PaymentMethod.cash,
    this.monthsPaid,
    this.serviceExpiry,
  }) : id = id ?? const Uuid().v4();

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
      'amountPaid': amountPaid,
      'datePaid': datePaid.toIso8601String(),
      'method': method.name,
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
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0.0,
      datePaid:
          DateTime.tryParse(json['datePaid']?.toString() ?? '') ??
              DateTime.now(),
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => PaymentMethod.cash,
      ),
      monthsPaid: json['monthsPaid'] as int?,
      serviceExpiry: json['serviceExpiry'] != null
          ? DateTime.tryParse(json['serviceExpiry'].toString())
          : null,
    );
  }
}
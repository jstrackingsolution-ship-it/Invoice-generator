import 'package:uuid/uuid.dart';
import 'client.dart';
import 'invoice_item.dart';
import '../utils/month_utils.dart';

enum InvoiceTemplate { classic, modern, minimal }

enum InvoiceStatus { draft, unpaid, paid, overdue }

/// A GPS Service Charge invoice is a subscription-style invoice for GPS
/// tracking service, paid for a number of months, with a computed expiry.
enum ServiceType { standard, gpsService }

extension ServiceTypeLabel on ServiceType {
  String get label {
    switch (this) {
      case ServiceType.standard:
        return 'Standard Invoice';
      case ServiceType.gpsService:
        return 'GPS Service Charge';
    }
  }
}

extension InvoiceTemplateLabel on InvoiceTemplate {
  String get label {
    switch (this) {
      case InvoiceTemplate.classic:
        return 'Classic';
      case InvoiceTemplate.modern:
        return 'Modern';
      case InvoiceTemplate.minimal:
        return 'Minimal';
    }
  }
}

extension InvoiceStatusLabel on InvoiceStatus {
  String get label {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.unpaid:
        return 'Unpaid';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.overdue:
        return 'Overdue';
    }
  }
}

class Invoice {
  final String id;
  String invoiceNumber;

  // Issuer / company details
  String companyName;
  String companyAddress;
  String companyEmail;
  String companyPhone;

  Client client;
  List<InvoiceItem> items;

  DateTime issueDate;
  DateTime dueDate;

  String notes;
  double taxRate; // percentage e.g. 18 for 18%
  double discount; // percentage e.g. 5 for 5%

  InvoiceTemplate template;
  InvoiceStatus status;

  /// Company logo snapshot (base64) at the time this invoice was created,
  /// so historical invoices always show the logo that was current then.
  String? companyLogoBase64;

  /// When the invoice was marked as paid (set automatically by the
  /// "Mark as Paid" flow, which also generates a Receipt).
  DateTime? paidDate;

  // --- GPS Service Charge specific fields -------------------------------
  ServiceType serviceType;

  /// Number of months this GPS service charge covers (only meaningful
  /// when [serviceType] is [ServiceType.gpsService]).
  int monthsPaid;

  Invoice({
    String? id,
    required this.invoiceNumber,
    this.companyName = 'SJ TRACKING SOLUTION',
    this.companyAddress = '',
    this.companyEmail = '',
    this.companyPhone = '',
    this.companyLogoBase64,
    Client? client,
    List<InvoiceItem>? items,
    DateTime? issueDate,
    DateTime? dueDate,
    this.notes = '',
    this.taxRate = 0,
    this.discount = 0,
    this.template = InvoiceTemplate.classic,
    this.status = InvoiceStatus.draft,
    this.paidDate,
    this.serviceType = ServiceType.standard,
    this.monthsPaid = 1,
  })  : id = id ?? const Uuid().v4(),
        client = client ?? Client(),
        items = items ?? [InvoiceItem()],
        issueDate = issueDate ?? DateTime.now(),
        dueDate = dueDate ?? DateTime.now().add(const Duration(days: 14));

  bool get isGpsService => serviceType == ServiceType.gpsService;

  /// The date the GPS service expires (issue date + [monthsPaid] months).
  /// Null for standard invoices.
  DateTime? get serviceExpiry =>
      isGpsService ? addMonths(issueDate, monthsPaid) : null;

  bool get isServiceExpired =>
      serviceExpiry != null && serviceExpiry!.isBefore(DateTime.now());

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);

  double get discountAmount => subtotal * (discount / 100);

  double get taxableAmount => subtotal - discountAmount;

  double get taxAmount => taxableAmount * (taxRate / 100);

  double get total => taxableAmount + taxAmount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'invoiceNumber': invoiceNumber,
        'companyName': companyName,
        'companyAddress': companyAddress,
        'companyEmail': companyEmail,
        'companyPhone': companyPhone,
        'companyLogoBase64': companyLogoBase64,
        'client': client.toJson(),
        'items': items.map((e) => e.toJson()).toList(),
        'issueDate': issueDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'notes': notes,
        'taxRate': taxRate,
        'discount': discount,
        'template': template.name,
        'status': status.name,
        'paidDate': paidDate?.toIso8601String(),
        'serviceType': serviceType.name,
        'monthsPaid': monthsPaid,
      };

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['id'],
        invoiceNumber: json['invoiceNumber'] ?? '',
        companyName: json['companyName'] ?? 'SJ TRACKING SOLUTION',
        companyAddress: json['companyAddress'] ?? '',
        companyEmail: json['companyEmail'] ?? '',
        companyPhone: json['companyPhone'] ?? '',
        companyLogoBase64: json['companyLogoBase64'],
        client: Client.fromJson(json['client'] ?? {}),
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => InvoiceItem.fromJson(e))
            .toList(),
        issueDate: DateTime.tryParse(json['issueDate'] ?? '') ?? DateTime.now(),
        dueDate: DateTime.tryParse(json['dueDate'] ?? '') ??
            DateTime.now().add(const Duration(days: 14)),
        notes: json['notes'] ?? '',
        taxRate: (json['taxRate'] ?? 0).toDouble(),
        discount: (json['discount'] ?? 0).toDouble(),
        template: InvoiceTemplate.values.firstWhere(
          (e) => e.name == json['template'],
          orElse: () => InvoiceTemplate.classic,
        ),
        status: InvoiceStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => InvoiceStatus.draft,
        ),
        paidDate: json['paidDate'] != null ? DateTime.tryParse(json['paidDate']) : null,
        serviceType: ServiceType.values.firstWhere(
          (e) => e.name == json['serviceType'],
          orElse: () => ServiceType.standard,
        ),
        monthsPaid: json['monthsPaid'] ?? 1,
      );
}

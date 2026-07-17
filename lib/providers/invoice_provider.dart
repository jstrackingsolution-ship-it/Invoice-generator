import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice.dart';
import '../utils/month_utils.dart';

/// Snapshot of a single month's totals: what was invoiced, what has been
/// collected (paid), and what is still remaining (outstanding).
class MonthlyStats {
  final DateTime month;
  final double totalInvoiced;
  final double totalPaid;
  final double totalRemaining;

  MonthlyStats({
    required this.month,
    required this.totalInvoiced,
    required this.totalPaid,
    required this.totalRemaining,
  });
}

class InvoiceProvider extends ChangeNotifier {
  static const _storageKey = 'sj_tracking_invoices_v1';

  List<Invoice> _invoices = [];
  bool _loading = true;

  List<Invoice> get invoices => List.unmodifiable(_invoices);
  bool get isLoading => _loading;

  double get totalRevenue => _invoices
      .where((inv) => inv.status == InvoiceStatus.paid)
      .fold(0.0, (sum, inv) => sum + inv.total);

  double get totalOutstanding => _invoices
      .where((inv) =>
          inv.status == InvoiceStatus.unpaid || inv.status == InvoiceStatus.overdue)
      .fold(0.0, (sum, inv) => sum + inv.total);

  int get invoiceCount => _invoices.length;

  InvoiceProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _invoices = list
            .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _invoices = [];
      }
    }
    _invoices.sort((a, b) => b.issueDate.compareTo(a.issueDate));
    _loading = false;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_invoices.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }

  String generateNextInvoiceNumber() {
    final nextIndex = _invoices.length + 1;
    return 'INV-${nextIndex.toString().padLeft(4, '0')}';
  }

  Future<void> addInvoice(Invoice invoice) async {
    _invoices.insert(0, invoice);
    notifyListeners();
    await _persist();
  }

  Future<void> updateInvoice(Invoice invoice) async {
    final index = _invoices.indexWhere((e) => e.id == invoice.id);
    if (index != -1) {
      _invoices[index] = invoice;
      notifyListeners();
      await _persist();
    }
  }

  Future<void> deleteInvoice(String id) async {
    _invoices.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> setStatus(String id, InvoiceStatus status) async {
    final index = _invoices.indexWhere((e) => e.id == id);
    if (index != -1) {
      _invoices[index].status = status;
      notifyListeners();
      await _persist();
    }
  }

  /// Marks an invoice as paid and stamps the paid date (used right before
  /// generating a Receipt for it).
  Future<void> markPaid(String id, {DateTime? paidDate}) async {
    final index = _invoices.indexWhere((e) => e.id == id);
    if (index != -1) {
      _invoices[index].status = InvoiceStatus.paid;
      _invoices[index].paidDate = paidDate ?? DateTime.now();
      notifyListeners();
      await _persist();
    }
  }

  /// Computes total invoiced, total paid (collected), and total remaining
  /// (outstanding) for invoices issued in the given [month].
  MonthlyStats monthlyStats(DateTime month) {
    final inMonth = _invoices.where((inv) => isSameMonth(inv.issueDate, month));
    final totalInvoiced = inMonth.fold(0.0, (sum, inv) => sum + inv.total);
    final totalPaid = inMonth
        .where((inv) => inv.status == InvoiceStatus.paid)
        .fold(0.0, (sum, inv) => sum + inv.total);
    final totalRemaining = totalInvoiced - totalPaid;
    return MonthlyStats(
      month: month,
      totalInvoiced: totalInvoiced,
      totalPaid: totalPaid,
      totalRemaining: totalRemaining,
    );
  }

  /// GPS service invoices whose coverage period has expired (or is about to).
  List<Invoice> get expiringGpsServices => _invoices
      .where((inv) => inv.isGpsService && inv.serviceExpiry != null)
      .toList()
    ..sort((a, b) => a.serviceExpiry!.compareTo(b.serviceExpiry!));
}

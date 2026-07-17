import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/receipt.dart';

class ReceiptProvider extends ChangeNotifier {
  static const _storageKey = 'sj_tracking_receipts_v1';

  List<Receipt> _receipts = [];
  bool _loading = true;

  List<Receipt> get receipts => List.unmodifiable(_receipts);
  bool get isLoading => _loading;

  ReceiptProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _receipts = list.map((e) => Receipt.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        _receipts = [];
      }
    }
    _receipts.sort((a, b) => b.datePaid.compareTo(a.datePaid));
    _loading = false;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_receipts.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }

  String generateNextReceiptNumber() {
    final nextIndex = _receipts.length + 1;
    return 'RCPT-${nextIndex.toString().padLeft(4, '0')}';
  }

  Future<void> addReceipt(Receipt receipt) async {
    _receipts.insert(0, receipt);
    notifyListeners();
    await _persist();
  }

  Receipt? receiptForInvoice(String invoiceId) {
    try {
      return _receipts.firstWhere((r) => r.invoiceId == invoiceId);
    } catch (_) {
      return null;
    }
  }
}

import '../models/invoice.dart';
import '../providers/invoice_provider.dart';
import '../providers/receipt_provider.dart';
import 'formatters.dart';

/// A single deterministic, no-AI-required insight shown as a card at the
/// top of the AI Accountant screen (works even without an API key).
class Insight {
  final String title;
  final String detail;
  final InsightLevel level;

  Insight({required this.title, required this.detail, this.level = InsightLevel.info});
}

enum InsightLevel { info, warning, good }

class FinanceInsights {
  /// Computes a handful of at-a-glance insights purely from local data —
  /// no API key or network call required.
  static List<Insight> quickInsights(InvoiceProvider invoices) {
    final now = DateTime.now();
    final stats = invoices.monthlyStats(DateTime(now.year, now.month, 1));
    final list = <Insight>[];

    list.add(Insight(
      title: 'This Month',
      detail: 'Invoiced ${Formatters.money(stats.totalInvoiced)} · '
          'Collected ${Formatters.money(stats.totalPaid)} · '
          'Remaining ${Formatters.money(stats.totalRemaining)}',
      level: stats.totalRemaining > 0 ? InsightLevel.warning : InsightLevel.good,
    ));

    final overdue = invoices.invoices
        .where((inv) =>
            inv.status != InvoiceStatus.paid &&
            inv.status != InvoiceStatus.draft &&
            inv.dueDate.isBefore(now))
        .toList();
    if (overdue.isNotEmpty) {
      final total = overdue.fold(0.0, (sum, inv) => sum + inv.total);
      list.add(Insight(
        title: '${overdue.length} Overdue Invoice${overdue.length == 1 ? '' : 's'}',
        detail: '${Formatters.money(total)} total past due',
        level: InsightLevel.warning,
      ));
    }

    final expiringSoon = invoices.expiringGpsServices
        .where((inv) =>
            inv.serviceExpiry != null &&
            inv.serviceExpiry!.isAfter(now) &&
            inv.serviceExpiry!.difference(now).inDays <= 7)
        .toList();
    final alreadyExpired = invoices.expiringGpsServices.where((inv) => inv.isServiceExpired).toList();
    if (alreadyExpired.isNotEmpty) {
      list.add(Insight(
        title: '${alreadyExpired.length} GPS Service${alreadyExpired.length == 1 ? '' : 's'} Expired',
        detail: alreadyExpired.take(3).map((inv) => inv.client.name).join(', ') +
            (alreadyExpired.length > 3 ? ', +${alreadyExpired.length - 3} more' : ''),
        level: InsightLevel.warning,
      ));
    }
    if (expiringSoon.isNotEmpty) {
      list.add(Insight(
        title: '${expiringSoon.length} GPS Service${expiringSoon.length == 1 ? '' : 's'} Expiring Soon',
        detail: 'Within the next 7 days',
        level: InsightLevel.info,
      ));
    }

    list.add(Insight(
      title: 'All-Time Revenue',
      detail: '${Formatters.money(invoices.totalRevenue)} collected · '
          '${Formatters.money(invoices.totalOutstanding)} outstanding',
      level: InsightLevel.info,
    ));

    return list;
  }

  /// Builds a compact text summary of the business's current financial
  /// state, fed to the AI as grounding context so it answers from real
  /// numbers instead of guessing.
  static String buildContextSummary(InvoiceProvider invoices, ReceiptProvider receipts) {
    final now = DateTime.now();
    final stats = invoices.monthlyStats(DateTime(now.year, now.month, 1));
    final buffer = StringBuffer();

    buffer.writeln('Business: SJ TRACKING SOLUTION (GPS tracking service provider)');
    buffer.writeln('Currency: ${Formatters.currencySymbol.trim()}');
    buffer.writeln('Today: ${Formatters.date(now)}');
    buffer.writeln();
    buffer.writeln('--- This Month (${Formatters.date(DateTime(now.year, now.month, 1))} onward) ---');
    buffer.writeln('Invoiced: ${Formatters.money(stats.totalInvoiced)}');
    buffer.writeln('Collected: ${Formatters.money(stats.totalPaid)}');
    buffer.writeln('Remaining: ${Formatters.money(stats.totalRemaining)}');
    buffer.writeln();
    buffer.writeln('--- All-Time ---');
    buffer.writeln('Total invoices: ${invoices.invoiceCount}');
    buffer.writeln('Total revenue collected: ${Formatters.money(invoices.totalRevenue)}');
    buffer.writeln('Total outstanding: ${Formatters.money(invoices.totalOutstanding)}');
    buffer.writeln('Total receipts issued: ${receipts.receipts.length}');
    buffer.writeln();

    final unpaid = invoices.invoices
        .where((inv) => inv.status == InvoiceStatus.unpaid || inv.status == InvoiceStatus.overdue)
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    if (unpaid.isNotEmpty) {
      buffer.writeln('--- Unpaid / Overdue Invoices (up to 15, largest first) ---');
      for (final inv in unpaid.take(15)) {
        buffer.writeln(
            '${inv.invoiceNumber} | ${inv.client.name} | ${Formatters.money(inv.total)} | '
            'due ${Formatters.date(inv.dueDate)} | ${inv.status.label}');
      }
      buffer.writeln();
    }

    final gpsInvoices = invoices.expiringGpsServices;
    if (gpsInvoices.isNotEmpty) {
      buffer.writeln('--- GPS Service Charges (expiry status) ---');
      for (final inv in gpsInvoices.take(20)) {
        final expiry = inv.serviceExpiry!;
        final status = inv.isServiceExpired ? 'EXPIRED' : 'active';
        buffer.writeln(
            '${inv.client.name} | paid ${inv.monthsPaid} month(s) | expires ${Formatters.date(expiry)} | $status');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}

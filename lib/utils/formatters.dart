import 'package:intl/intl.dart';

class Formatters {
  // Tanzanian Shillings. TZS amounts are conventionally shown as whole
  // numbers (no cents), symbol before the amount, e.g. "TZS 150,000".
  static const String currencySymbol = 'TZS ';

  static final NumberFormat _currency =
      NumberFormat.currency(symbol: currencySymbol, decimalDigits: 0);

  static final DateFormat _date = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, HH:mm');

  static String money(double value) => _currency.format(value);

  static String date(DateTime value) => _date.format(value);

  static String dateTime(DateTime value) => _dateTime.format(value);
}

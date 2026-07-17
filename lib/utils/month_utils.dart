import 'package:intl/intl.dart';

/// Adds [months] calendar months to [date], clamping the day if the target
/// month is shorter (e.g. 31 Jan + 1 month -> 28/29 Feb, not 3 Mar).
DateTime addMonths(DateTime date, int months) {
  final totalMonths = date.month - 1 + months;
  final year = date.year + totalMonths ~/ 12;
  final month = totalMonths % 12 + 1;
  final lastDayOfTargetMonth = DateTime(year, month + 1, 0).day;
  final day = date.day > lastDayOfTargetMonth ? lastDayOfTargetMonth : date.day;
  return DateTime(year, month, day, date.hour, date.minute, date.second);
}

/// True if [date] is before "now" (i.e. the subscription/service has expired).
bool isExpired(DateTime date) => date.isBefore(DateTime.now());

final DateFormat monthYearFormat = DateFormat('MMMM yyyy');

String monthKey(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}';

bool isSameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

/// Returns the most recent [count] months (including the current month),
/// newest first — handy for a month-picker dropdown.
List<DateTime> recentMonths(int count) {
  final now = DateTime.now();
  final base = now.year * 12 + (now.month - 1);
  return List.generate(count, (i) {
    final total = base - i;
    final year = total ~/ 12;
    final month = total % 12 + 1;
    return DateTime(year, month, 1);
  });
}

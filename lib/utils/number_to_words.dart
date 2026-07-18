const List<String> _ones = [
  'Zero', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
  'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
  'Seventeen', 'Eighteen', 'Nineteen',
];

const List<String> _tens = [
  '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety',
];

/// Converts a non-negative integer (up to ~999,999,999,999) into English words.
String numberToWords(int number) {
  if (number == 0) return 'Zero';
  if (number < 0) return 'Negative ${numberToWords(-number)}';

  String threeDigits(int n) {
    final parts = <String>[];
    if (n >= 100) {
      parts.add('${_ones[n ~/ 100]} Hundred');
      n %= 100;
    }
    if (n >= 20) {
      final tensWord = _tens[n ~/ 10];
      final remainder = n % 10;
      parts.add(remainder > 0 ? '$tensWord-${_ones[remainder]}' : tensWord);
    } else if (n > 0) {
      parts.add(_ones[n]);
    }
    return parts.join(' ');
  }

  const scales = [
    [1000000000, 'Billion'],
    [1000000, 'Million'],
    [1000, 'Thousand'],
  ];

  final segments = <String>[];
  var remaining = number;
  for (final scale in scales) {
    final divisor = scale[0] as int;
    final label = scale[1] as String;
    if (remaining >= divisor) {
      final count = remaining ~/ divisor;
      segments.add('${threeDigits(count)} $label');
      remaining %= divisor;
    }
  }
  if (remaining > 0) {
    segments.add(threeDigits(remaining));
  }

  return segments.join(' ');
}

/// Maps a currency symbol (as configured in Settings) to a spoken currency
/// name for the "amount in words" line. Falls back to the trimmed symbol
/// itself if it isn't one of the well-known ones.
String _currencyNameFor(String symbol) {
  final s = symbol.trim().toUpperCase();
  switch (s) {
    case 'TZS':
      return 'Tanzania Shillings';
    case 'KES':
      return 'Kenyan Shillings';
    case 'UGX':
      return 'Ugandan Shillings';
    case 'USD':
    case '\$':
      return 'US Dollars';
    case 'GBP':
    case '£':
      return 'British Pounds';
    case 'EUR':
    case '€':
      return 'Euros';
    default:
      return symbol.trim();
  }
}

/// Renders a monetary amount as words, e.g. "One Hundred Fifty Thousand
/// Tanzania Shillings Only". Whole-currency only (no decimals is standard
/// for TZS); any fractional part is rounded into the whole amount.
String amountInWords(double amount, {required String currencySymbol}) {
  final whole = amount.round();
  final currencyName = _currencyNameFor(currencySymbol);
  return '${numberToWords(whole)} $currencyName Only';
}

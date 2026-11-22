/// How numbers and dates are written in the app.
library;

/// A whole number the Indian way: 1,200 and 13,000, then 1,00,000.
String formatWhole(int n) {
  final digits = n.abs().toString();
  final sign = n < 0 ? '−' : '';
  if (digits.length <= 3) return '$sign$digits';
  final last3 = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  return '$sign${groups.join(',')},$last3';
}

/// A measurement with no trailing zeros: 155, 62.5, 1.75.
String formatDecimal(double x, {int places = 2}) {
  final fixed = x.toStringAsFixed(places);
  if (!fixed.contains('.')) return fixed;
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

/// Litres from millilitres: 2,450 ml is "2.45 L".
String formatLitres(int ml) => '${formatDecimal(ml / 1000)} L';

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// A date in words: "14 March 1998".
String formatDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

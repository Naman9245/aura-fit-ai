import 'dart:typed_data';

/// Rounds [x] to [places] decimal places the way Python's `round()` does:
/// from the exact value the double holds, with a tie going to the even
/// digit.
///
/// The old FastAPI backend rounded every target with `round()`, and the
/// port must give the same numbers. `(x * 100).round() / 100` doesn't: it
/// sends ties away from zero (2303.125 becomes 2303.13, where Python gives
/// 2303.12), and the multiplication itself can round a value onto the other
/// side of a tie.
double roundHalfEven(double x, int places) {
  RangeError.checkValueInInterval(places, 0, 15, 'places');
  if (!x.isFinite || x == 0) return x;

  // The exact value is mantissa × 2^exponent.
  final bits = (ByteData(8)..setFloat64(0, x.abs())).getInt64(0);
  final biasedExponent = bits >> 52;
  final fraction = bits & 0xFFFFFFFFFFFFF;
  final mantissa = biasedExponent == 0 ? fraction : fraction | (1 << 52);
  final exponent = (biasedExponent == 0 ? 1 : biasedExponent) - 1075;
  // A double this large is a whole number already.
  if (exponent >= 0) return x;

  // scaled = x × 10^places exactly, as whole / 2^shift.
  final shift = -exponent;
  final scaled = BigInt.from(mantissa) * BigInt.from(10).pow(places);
  var whole = scaled >> shift;
  final rest = scaled - (whole << shift);
  final half = BigInt.one << (shift - 1);
  if (rest > half || (rest == half && whole.isOdd)) whole += BigInt.one;

  // Both operands are exact, so the division gives the double nearest the
  // rounded decimal, as Python's does.
  final rounded = whole.toDouble() / _powersOfTen[places];
  return x.isNegative ? -rounded : rounded;
}

const _powersOfTen = [
  1.0, 1e1, 1e2, 1e3, 1e4, 1e5, 1e6, 1e7, //
  1e8, 1e9, 1e10, 1e11, 1e12, 1e13, 1e14, 1e15,
];

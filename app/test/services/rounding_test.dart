import 'package:aurafit/services/rounding.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Each expected value is what Python's round() returned for the same
  // double.
  const pythonRounds = [
    // Exact ties go to the even digit.
    (2303.125, 2, 2303.12),
    (2303.375, 2, 2303.38),
    (0.125, 2, 0.12),
    (0.375, 2, 0.38),
    (0.25, 1, 0.2),
    (2.5, 0, 2.0),
    (3.5, 0, 4.0),
    (-2.5, 0, -2.0),
    (-0.125, 2, -0.12),
    // These look like ties, but the double is just below or above one.
    (2.675, 2, 2.67),
    (1.005, 2, 1.0),
    (0.15, 1, 0.1),
    (0.35, 1, 0.3),
    (0.05, 1, 0.1),
    (123.45, 1, 123.5),
    // Ordinary values.
    (889.3000000000002, 2, 889.3),
    (1234.5678, 3, 1234.568),
    (2008.5, 2, 2008.5),
    // Extremes.
    (1e20, 2, 1e20),
    (5e-324, 2, 0.0),
  ];

  for (final (x, places, expected) in pythonRounds) {
    test('rounds $x to $places places as Python does: $expected', () {
      expect(roundHalfEven(x, places), expected);
    });
  }

  test('passes zero, infinity and NaN through', () {
    expect(roundHalfEven(0, 2), 0);
    expect(roundHalfEven(double.infinity, 2), double.infinity);
    expect(roundHalfEven(double.nan, 2).isNaN, isTrue);
  });

  test('refuses a negative number of places', () {
    expect(() => roundHalfEven(1.5, -1), throwsRangeError);
  });
}

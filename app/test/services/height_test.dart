import 'package:aurafit/services/height.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feet and inches become centimetres', () {
    expect(cmFromFeetInches(5, 7), 170.2);
    expect(cmFromFeetInches(5, 0), 152.4);
    expect(cmFromFeetInches(6, 2.5), 189.2);
  });

  test('centimetres become the nearest whole inch', () {
    expect(feetInchesFromCm(170.2), (feet: 5, inches: 7));
    expect(feetInchesFromCm(155), (feet: 5, inches: 1));
    // 182.6 cm is 71.9 in: the nearest inch carries over to 6 ft.
    expect(feetInchesFromCm(182.6), (feet: 6, inches: 0));
  });

  test('the allowed range reads sensibly in feet', () {
    expect(feetInchesFromCm(120), (feet: 3, inches: 11));
    expect(feetInchesFromCm(230), (feet: 7, inches: 7));
  });
}

import 'package:aurafit/services/rounding.dart';

/// How someone gives their height. It's stored in centimetres either way.
enum HeightUnit { feetInches, cm }

/// Centimetres from feet and inches, to one decimal place as stored.
double cmFromFeetInches(int feet, double inches) =>
    roundHalfEven((feet * 12 + inches) * 2.54, 1);

/// Centimetres as whole feet and inches, to the nearest inch.
({int feet, int inches}) feetInchesFromCm(double cm) {
  final totalInches = (cm / 2.54).round();
  return (feet: totalInches ~/ 12, inches: totalInches % 12);
}

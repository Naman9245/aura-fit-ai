import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:flutter/material.dart';

/// The backdrop behind the setup screens: the design's flat near-black,
/// the same as the tabs.
class AuraBackground extends StatelessWidget {
  const AuraBackground({super.key, required this.child});

  final Widget child;

  @override
  // A Material, not a plain colour, so list rows' ripples show on it.
  Widget build(BuildContext context) =>
      Material(color: AuraColors.black, child: child);
}

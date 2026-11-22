import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:flutter/material.dart';

/// The website's backdrop behind a screen: a blue glow from the upper left
/// and an orange one from the top, over the scaffold's near-black. Plain
/// gradients, no blur, so it costs nothing on a low-end phone.
class AuraBackground extends StatelessWidget {
  const AuraBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.6, -0.7),
          radius: 0.9,
          colors: [AuraColors.blueGlow, Color(0x00587AFF)],
        ),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1.2),
            radius: 1.1,
            colors: [AuraColors.orangeGlow, Color(0x00FF7A00)],
          ),
        ),
        child: child,
      ),
    );
  }
}

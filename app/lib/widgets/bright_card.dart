import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:aurafit/widgets/motion.dart';
import 'package:flutter/material.dart';

/// A rounded card in one of the design's colours. Text and icons inside take
/// [AuraColors.ink] on a bright card and [AuraColors.foreground] on a dark
/// one, so they always pass contrast.
class BrightCard extends StatelessWidget {
  const BrightCard({
    super.key,
    required this.color,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.onTap,
  });

  final Color color;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  /// The text colour that goes on [color].
  static Color textOn(Color color) =>
      color.computeLuminance() > 0.3 ? AuraColors.ink : AuraColors.foreground;

  @override
  Widget build(BuildContext context) {
    final fg = textOn(color);
    final inner = Padding(
      padding: padding,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: fg),
        child: IconTheme.merge(
          data: IconThemeData(color: fg),
          child: child,
        ),
      ),
    );
    final card = Material(
      color: color,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(radius)),
      ),
      child: onTap == null ? inner : InkWell(onTap: onTap, child: inner),
    );
    return onTap == null ? card : Pressable(child: card);
  }
}

/// A pill button in [AuraColors.ink], for the main action on a bright card.
class InkPillButton extends StatelessWidget {
  const InkPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 44,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: AuraColors.ink,
      foregroundColor: AuraColors.paper,
      minimumSize: Size(48, height),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      shape: const StadiumBorder(),
      textStyle: Theme.of(context).textTheme.labelLarge
          ?.copyWith(fontWeight: FontWeight.w700),
    );
    return Pressable(
      enabled: onPressed != null,
      child: switch (icon) {
        final icon? => FilledButton.icon(
          style: style,
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
        ),
        null => FilledButton(
          style: style,
          onPressed: onPressed,
          child: Text(label),
        ),
      },
    );
  }
}

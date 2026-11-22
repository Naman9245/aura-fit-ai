import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:flutter/material.dart';

/// One answer to pick from a list, like a radio button the size of a card.
/// The chosen one has an orange edge and a tick, so it doesn't rely on
/// colour alone.
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected
            ? AuraColors.accent.withValues(alpha: 0.12)
            : AuraColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          side: BorderSide(
            color: selected ? AuraColors.accent : AuraColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.titleMedium),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: text.bodyMedium?.copyWith(
                            color: AuraColors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? AuraColors.accent : AuraColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

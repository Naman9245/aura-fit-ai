import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/food_repository.dart';
import 'package:aurafit/data/log_repository.dart';
import 'package:aurafit/data/providers.dart';
import 'package:aurafit/widgets/portion_wheel_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The sheets for water, steps and weight (PRD N5, D3), shared by Today,
// Train and Progress. Each one hands what it saved to `onUndo`. They open
// over the tab bar, so an Undo bar never covers their buttons.

/// Water in one tap per container, and the glasses logged on [day].
Future<void> showWaterSheet(
  BuildContext context,
  WidgetRef ref, {
  required DateTime day,
  required List<HealthSampleRow> samples,
  required ValueChanged<UndoAction> onUndo,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: AuraColors.surface,
  builder: (sheetCtx) {
    final text = Theme.of(sheetCtx).textTheme;
    const presets = <(int, String, IconData)>[
      (150, 'Chai cup', Icons.local_cafe_outlined),
      (250, 'Glass', Icons.local_drink_outlined),
      (350, 'Mug', Icons.coffee_outlined),
      (500, 'Bottle', Icons.water_drop_outlined),
      (750, 'Shaker', Icons.fitness_center_outlined),
      (1000, '1 L bottle', Icons.sports_bar_outlined),
    ];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Log water', style: text.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Tap a container size to add at once.',
              style: text.bodySmall?.copyWith(color: AuraColors.muted),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (ml, label, icon) in presets)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(16),
                        ),
                        onTap: () async {
                          final nav = Navigator.of(sheetCtx);
                          final undo = await ref
                              .read(logRepositoryProvider)
                              .addWater(day: day, ml: ml);
                          nav.pop();
                          onUndo(undo);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: const BoxDecoration(
                            color: AuraColors.surfaceStrong,
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, color: AuraColors.yellow, size: 22),
                              const SizedBox(height: 6),
                              Text('+$ml ml', style: text.labelLarge),
                              Text(
                                label,
                                style: text.bodySmall?.copyWith(
                                  color: AuraColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (samples.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Logged today', style: text.titleMedium),
              const SizedBox(height: 8),
              for (final sample in samples)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.water_drop_outlined,
                    color: AuraColors.yellow,
                  ),
                  title: Text('${sample.value.round()} ml'),
                  trailing: IconButton(
                    tooltip: 'Remove glass',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final nav = Navigator.of(sheetCtx);
                      final undo = await ref
                          .read(logRepositoryProvider)
                          .deleteHealthSample(sample);
                      nav.pop();
                      onUndo(undo);
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  },
);

/// Steps walked on [day], on a wheel, so no keyboard is needed.
Future<void> showStepsSheet(
  BuildContext context,
  WidgetRef ref, {
  required DateTime day,
  required DaySummary summary,
  required ValueChanged<UndoAction> onUndo,
}) async {
  var currentSteps = summary.steps > 0 ? summary.steps.toDouble() : 6000.0;
  final stepTicks = <double>[
    for (var s = 500; s <= 30000; s += 500) s.toDouble(),
  ];
  final action = await showModalBottomSheet<UndoAction>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AuraColors.surface,
    builder: (sheetCtx) => StatefulBuilder(
      builder: (sheetCtx, setSheetState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Steps walked',
                style: Theme.of(sheetCtx).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _SimpleNumberWheel(
                unitLabel: 'steps',
                steps: stepTicks,
                value: currentSteps,
                maxExact: 100000,
                onChanged: (v) => setSheetState(() => currentSteps = v),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () async {
                  final nav = Navigator.of(sheetCtx);
                  final undo = await ref
                      .read(logRepositoryProvider)
                      .setStepsForDay(day: day, steps: currentSteps.round());
                  nav.pop(undo);
                },
                child: const Text('Save steps'),
              ),
              if (summary.stepsSamples.isNotEmpty) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    final nav = Navigator.of(sheetCtx);
                    final undo = await ref
                        .read(logRepositoryProvider)
                        .deleteHealthSample(summary.stepsSamples.first);
                    nav.pop(undo);
                  },
                  child: const Text('Remove steps'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
  if (action != null) onUndo(action);
}

/// The weigh-in for [day], on a wheel. Starts from [existing], or from
/// [startKg] when there's none yet.
Future<void> showWeightSheet(
  BuildContext context,
  WidgetRef ref, {
  required DateTime day,
  required WeightLogRow? existing,
  required double startKg,
  required ValueChanged<UndoAction> onUndo,
}) async {
  var currentKg = existing?.weightKg ?? startKg;
  final weightTicks = <double>[
    for (var tenths = 350; tenths <= 1600; tenths += 5) tenths / 10.0,
  ];
  final action = await showModalBottomSheet<UndoAction>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AuraColors.surface,
    builder: (sheetCtx) => StatefulBuilder(
      builder: (sheetCtx, setSheetState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Weigh-in', style: Theme.of(sheetCtx).textTheme.titleLarge),
              const SizedBox(height: 12),
              _SimpleNumberWheel(
                unitLabel: 'kg',
                steps: weightTicks,
                value: currentKg,
                minExact: 20,
                maxExact: 400,
                onChanged: (v) => setSheetState(() => currentKg = v),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () async {
                  final nav = Navigator.of(sheetCtx);
                  final undo = await ref
                      .read(logRepositoryProvider)
                      .saveWeightForDay(day: day, weightKg: currentKg);
                  nav.pop(undo);
                },
                child: const Text('Save weight'),
              ),
              if (existing != null) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    final nav = Navigator.of(sheetCtx);
                    final undo = await ref
                        .read(logRepositoryProvider)
                        .deleteWeightLog(existing);
                    nav.pop(undo);
                  },
                  child: const Text('Remove weigh-in'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
  if (action != null) onUndo(action);
}

class _SimpleNumberWheel extends StatelessWidget {
  const _SimpleNumberWheel({
    required this.unitLabel,
    required this.steps,
    required this.value,
    this.minExact = 0,
    required this.maxExact,
    required this.onChanged,
  });

  final String unitLabel;
  final List<double> steps;
  final double value;
  final double minExact;
  final double maxExact;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return PortionWheelPicker(
      portions: [FoodPortion(unit: unitLabel, grams: 1)],
      selectedUnit: unitLabel,
      count: value.clamp(minExact > 0 ? minExact : steps.first, maxExact),
      customSteps: steps,
      showGramsSubtitle: false,
      maxExactValue: maxExact,
      onUnitChanged: (_) {},
      onCountChanged: onChanged,
    );
  }
}

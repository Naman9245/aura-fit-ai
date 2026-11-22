import 'package:aurafit/core/format.dart';
import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/providers.dart';
import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/targets.dart';
import 'package:aurafit/widgets/aura_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every step from the person's details to their targets, with their own
/// numbers in it (PRD A3).
class HowWeCalculatedScreen extends ConsumerWidget {
  const HowWeCalculatedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final explained = ref.watch(explainedGoalProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('How we calculated this')),
      extendBodyBehindAppBar: true,
      body: AuraBackground(
        child: SafeArea(
          child: switch (explained) {
            AsyncData(value: final e?) => _Working(goal: e.goal, t: e.targets),
            AsyncData() => const Center(child: Text('No targets yet.')),
            AsyncError(:final error) => Center(child: Text('$error')),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}

class _Working extends StatelessWidget {
  const _Working({required this.goal, required this.t});

  final GoalRow goal;
  final Targets t;

  @override
  Widget build(BuildContext context) {
    final inputs = t.inputs;
    final weight = formatDecimal(inputs.weightKg, places: 1);
    final height = formatDecimal(inputs.heightCm, places: 1);
    final offset = sexOffsetKcal(inputs.sex);
    final offsetText = offset < 0 ? '− ${-offset}' : '+ $offset';
    final adjustment = goalAdjustmentKcal(inputs.goal);
    final active =
        inputs.activity == ActivityLevel.active ||
        inputs.activity == ActivityLevel.athlete;
    final sexName = switch (inputs.sex) {
      Sex.female => 'women',
      Sex.male => 'men',
      null => 'anyone who doesn\'t give their sex',
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        _Section(
          title: 'Your details',
          lines: [
            '${inputs.age} years old · ${inputs.sex?.label ?? 'Sex not given'}',
            '$height cm · $weight kg',
            inputs.activity.label,
          ],
        ),
        _Section(
          title: '1. Energy at rest',
          lines: [
            'What your body uses doing nothing at all, by the Mifflin–St Jeor '
                'equation:',
            '10 × $weight kg + 6.25 × $height cm − 5 × ${inputs.age} years '
                '$offsetText',
          ],
          result: '${_kcal(t.bmrKcal)} kcal',
        ),
        _Section(
          title: '2. A normal day',
          lines: [
            'Energy at rest × ${activityMultiplier(inputs.activity)}, for '
                '"${inputs.activity.label.toLowerCase()}"',
          ],
          result: '${_kcal(t.maintenanceKcal)} kcal',
        ),
        _Section(
          title: '3. Your goal',
          lines: [
            adjustment == 0
                ? 'To ${inputs.goal.label.toLowerCase()}: no change'
                : 'To ${inputs.goal.label.toLowerCase()}: '
                      '${adjustment < 0 ? '−' : '+'} ${adjustment.abs()} kcal',
          ],
          result: '${_kcal(t.unflooredKcal)} kcal',
        ),
        _Section(
          title: '4. The safe minimum',
          lines: [
            t.floorApplied
                ? '${_kcal(t.unflooredKcal)} kcal is below '
                      '${formatWhole(t.floorKcal)} kcal, the least that\'s safe '
                      'for $sexName without a doctor\'s care. So your target is '
                      'the minimum.'
                : 'Never below ${formatWhole(t.floorKcal)} kcal for $sexName. '
                      'Yours is above it, so it stays.',
          ],
          result: '${formatWhole(goal.caloriesKcal)} kcal a day',
          highlight: true,
        ),
        _Section(
          title: 'Protein',
          lines: [
            '${proteinPerKg(inputs.goal)} g for each kg you weigh, for your goal',
            if (t.carbRuleApplied && t.fatG == 0)
              'Cut to fit your calories, which can\'t hold that much protein',
          ],
          result: '${goal.proteinG} g',
        ),
        _Section(
          title: 'Fat',
          lines: [
            t.carbRuleApplied
                ? 'What\'s left after protein, at 9 kcal a gram. Usually a '
                      'quarter of your calories, but that would leave no room '
                      'for carbs'
                : 'A quarter of your calories, at 9 kcal a gram',
          ],
          result: '${goal.fatG} g',
        ),
        _Section(
          title: 'Carbs',
          lines: ['The rest of your calories, at 4 kcal a gram'],
          result: '${goal.carbsG} g',
        ),
        _Section(
          title: 'Water',
          lines: [
            '$waterMlPerKg ml for each kg you weigh'
                '${active ? ', plus ${formatDecimal(activeExtraWaterL)} L because you\'re active' : ''}',
          ],
          result: formatLitres(goal.waterMl),
        ),
        _Section(
          title: 'Steps',
          lines: [
            'For "${inputs.activity.label.toLowerCase()}". More active levels '
                'aim higher.',
          ],
          result: formatWhole(goal.steps),
        ),
        const SizedBox(height: 8),
        Text(
          'Formula ${goal.formulaVersion}, worked out on your phone on '
          '${formatDate(goal.startedAt)}. For reference, your BMI is '
          '${formatDecimal(t.bmi, places: 1)}; it can\'t tell muscle from fat, '
          'so AURA doesn\'t set targets from it.',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AuraColors.muted),
        ),
      ],
    );
  }

  static String _kcal(double kcal) => formatWhole(kcal.round());
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.lines,
    this.result,
    this.highlight = false,
  });

  final String title;
  final List<String> lines;
  final String? result;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        shape: highlight
            ? const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)),
                side: BorderSide(color: AuraColors.accent),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: text.titleMedium),
                ),
                const SizedBox(height: 8),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      line,
                      style: text.bodyMedium?.copyWith(color: AuraColors.muted),
                    ),
                  ),
                if (result != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '= $result',
                    style: text.titleLarge?.copyWith(
                      color: highlight ? AuraColors.accent : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

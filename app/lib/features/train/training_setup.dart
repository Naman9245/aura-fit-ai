import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:aurafit/core/theme/aura_type.dart';
import 'package:aurafit/data/providers.dart';
import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/workouts.dart';
import 'package:aurafit/widgets/bright_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where to train, how many days a week (Sunday is always rest), and for how
/// long you've been training.
class TrainingSetupForm extends StatefulWidget {
  const TrainingSetupForm({
    super.key,
    required this.initialPlace,
    required this.initialDays,
    required this.initialExperience,
    required this.onSave,
    this.onBright = false,
    this.saveLabel = 'Build my plan',
  });

  final TrainingPlace? initialPlace;
  final int? initialDays;
  final Experience? initialExperience;
  final Future<void> Function(TrainingPlace place, int days, Experience? exp)
  onSave;

  /// On a bright card: text in ink.
  final bool onBright;
  final String saveLabel;

  @override
  State<TrainingSetupForm> createState() => _TrainingSetupFormState();
}

class _TrainingSetupFormState extends State<TrainingSetupForm> {
  late TrainingPlace? _place = widget.initialPlace;
  late Experience? _experience = widget.initialExperience;
  late int? _days = widget.initialDays;
  bool _saving = false;

  int get _shownDays => _days ?? suggestedDays(_experience);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = widget.onBright ? AuraColors.ink : AuraColors.muted;
    Widget label(String words) => Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(words, style: AuraType.kicker(color: ink)),
    );
    Widget chips<T>(
      List<(T, String)> options,
      T? selected,
      ValueChanged<T> onPick,
    ) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (value, words) in options)
          ChoiceChip(
            label: Text(words),
            selected: value == selected,
            onSelected: (_) => setState(() => onPick(value)),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        label('WHERE'),
        chips<TrainingPlace>(
          const [
            (TrainingPlace.gym, 'At a gym'),
            (TrainingPlace.dumbbells, 'Home, with dumbbells'),
            (TrainingPlace.home, 'Home, no equipment'),
          ],
          _place,
          (place) => _place = place,
        ),
        const SizedBox(height: 10),
        label('HOW LONG YOU\'VE TRAINED'),
        chips<Experience>(
          const [
            (Experience.beginner, 'New to it'),
            (Experience.intermediate, 'A year or more'),
            (Experience.advanced, 'Several years'),
          ],
          _experience,
          (experience) => _experience = experience,
        ),
        const SizedBox(height: 10),
        label('DAYS A WEEK · SUNDAY IS REST'),
        chips<int>(
          const [(3, '3 days'), (4, '4 days'), (5, '5 days'), (6, '6 days')],
          _shownDays,
          (days) => _days = days,
        ),
        const SizedBox(height: 16),
        if (widget.onBright)
          InkPillButton(
            label: widget.saveLabel,
            height: 48,
            onPressed: _place == null || _saving ? null : _save,
          )
        else
          FilledButton(
            onPressed: _place == null || _saving ? null : _save,
            child: Text(widget.saveLabel),
          ),
        if (_place == null) ...[
          const SizedBox(height: 6),
          Text(
            'Pick where you train first.',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: ink),
          ),
        ],
      ],
    );
  }

  Future<void> _save() async {
    final place = _place;
    if (place == null) return;
    setState(() => _saving = true);
    await widget.onSave(place, _shownDays, _experience);
    if (mounted) setState(() => _saving = false);
  }
}

/// Changes where, how long and how often, for when the gym starts or stops.
Future<void> showTrainingSetupSheet(BuildContext context, WidgetRef ref) {
  final profile = ref.read(profileProvider).value;
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your training',
              style: Theme.of(sheetContext).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Josh rebuilds your week from these. Workouts you\'ve done stay.',
              style: Theme.of(sheetContext).textTheme.bodyMedium
                  ?.copyWith(color: AuraColors.muted),
            ),
            const SizedBox(height: 12),
            TrainingSetupForm(
              initialPlace: profile?.trainingPlace,
              initialDays: profile?.trainingDays,
              initialExperience: profile?.experience,
              saveLabel: 'Save',
              onSave: (place, days, experience) async {
                final navigator = Navigator.of(sheetContext);
                await ref
                    .read(profileRepositoryProvider)
                    .saveTraining(
                      place: place,
                      days: days,
                      experience: experience,
                    );
                navigator.pop();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

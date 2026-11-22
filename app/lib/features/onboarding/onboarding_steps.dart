import 'package:aurafit/core/format.dart';
import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:aurafit/features/onboarding/onboarding_controller.dart';
import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/targets.dart';
import 'package:aurafit/widgets/choice_card.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The question at the top of every step.
class StepHeading extends StatelessWidget {
  const StepHeading({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: text.headlineSmall),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: text.bodyLarge?.copyWith(color: AuraColors.muted),
          ),
        ],
      ),
    );
  }
}

/// A list of [ChoiceCard]s, one per option.
class _Choices<T extends StoredOption> extends StatelessWidget {
  const _Choices({
    required this.options,
    required this.selected,
    required this.onChoose,
    this.describe,
  });

  final List<T> options;
  final T? selected;
  final ValueChanged<T> onChoose;
  final String Function(T)? describe;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ChoiceCard(
              title: option.label,
              subtitle: describe?.call(option),
              selected: option == selected,
              onTap: () => onChoose(option),
            ),
          ),
      ],
    );
  }
}

class GoalStep extends ConsumerWidget {
  const GoalStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider.select((d) => d.goal));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeading(
          title: 'What\'s your main goal?',
          subtitle:
              'Your daily targets are built around it. You can change it '
              'later.',
        ),
        _Choices(
          options: GoalType.values,
          selected: selected,
          describe: (goal) => goal.description,
          onChoose: ref.read(onboardingProvider.notifier).chooseGoal,
        ),
      ],
    );
  }
}

/// Day, month and year as three small fields, which is quicker for a
/// birthday than scrolling a calendar back decades.
class BirthDateStep extends ConsumerStatefulWidget {
  const BirthDateStep({super.key});

  @override
  ConsumerState<BirthDateStep> createState() => _BirthDateStepState();
}

class _BirthDateStepState extends ConsumerState<BirthDateStep> {
  late final TextEditingController _day;
  late final TextEditingController _month;
  late final TextEditingController _year;
  final _monthFocus = FocusNode();
  final _yearFocus = FocusNode();
  String? _problem;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(onboardingProvider).birthDate;
    _day = TextEditingController(text: saved?.day.toString() ?? '');
    _month = TextEditingController(text: saved?.month.toString() ?? '');
    _year = TextEditingController(text: saved?.year.toString() ?? '');
  }

  @override
  void dispose() {
    _day.dispose();
    _month.dispose();
    _year.dispose();
    _monthFocus.dispose();
    _yearFocus.dispose();
    super.dispose();
  }

  void _changed() {
    final day = int.tryParse(_day.text);
    final month = int.tryParse(_month.text);
    final year = int.tryParse(_year.text);
    final controller = ref.read(onboardingProvider.notifier);
    if (day == null || month == null || year == null || _year.text.length < 4) {
      controller.setBirthDate(null);
      setState(() => _problem = null);
      return;
    }
    final date = DateTime(year, month, day);
    // DateTime rolls 31 February over into March; a real date doesn't.
    final real = date.year == year && date.month == month && date.day == day;
    final problem = real ? birthDateProblem(date) : 'That date doesn\'t exist';
    controller.setBirthDate(problem == null ? date : null);
    setState(() => _problem = problem);
  }

  @override
  Widget build(BuildContext context) {
    final birthDate = ref.watch(onboardingProvider.select((d) => d.birthDate));
    final now = clock.now();
    final text = Theme.of(context).textTheme;

    Widget field(
      String label,
      String hint,
      TextEditingController controller,
      int length, {
      FocusNode? focus,
      FocusNode? nextFocus,
      int flex = 1,
    }) => Expanded(
      flex: flex,
      child: TextField(
        controller: controller,
        focusNode: focus,
        decoration: InputDecoration(labelText: label, hintText: hint),
        keyboardType: TextInputType.number,
        textInputAction: nextFocus == null
            ? TextInputAction.done
            : TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(length),
        ],
        onChanged: (value) {
          if (value.length == length) nextFocus?.requestFocus();
          _changed();
        },
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeading(
          title: 'When were you born?',
          subtitle:
              'Your age changes how much energy your body uses. AURA is for '
              'adults, $minAge and over.',
        ),
        Row(
          children: [
            field('Day', 'DD', _day, 2, nextFocus: _monthFocus),
            const SizedBox(width: 12),
            field(
              'Month',
              'MM',
              _month,
              2,
              focus: _monthFocus,
              nextFocus: _yearFocus,
            ),
            const SizedBox(width: 12),
            field('Year', 'YYYY', _year, 4, focus: _yearFocus, flex: 2),
          ],
        ),
        const SizedBox(height: 16),
        if (_problem != null)
          Text(
            _problem!,
            style: text.bodyLarge?.copyWith(color: AuraColors.error),
          )
        else if (birthDate != null)
          Text(
            '${formatDate(birthDate)}: you\'re '
            '${ageOn(birthDate, DateTime(now.year, now.month, now.day))}.',
            style: text.bodyLarge?.copyWith(color: AuraColors.muted),
          ),
      ],
    );
  }
}

class SexStep extends ConsumerWidget {
  const SexStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeading(
          title: 'What\'s your sex?',
          subtitle:
              'Only the calorie formula uses this: bodies of the same size use '
              'a little more energy if male.',
        ),
        for (final sex in Sex.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ChoiceCard(
              title: sex.label,
              selected: draft.sexAnswered && draft.sex == sex,
              onTap: () => controller.chooseSex(sex),
            ),
          ),
        ChoiceCard(
          title: 'I\'d rather not say',
          subtitle:
              'We\'ll use the middle of the two, and the higher safe minimum.',
          selected: draft.sexAnswered && draft.sex == null,
          onTap: () => controller.chooseSex(null),
        ),
      ],
    );
  }
}

/// Accepts up to three digits and one decimal place, with either a dot or
/// a comma, as a phone keyboard may offer either.
class _MeasurementFormatter extends TextInputFormatter {
  static final _pattern = RegExp(r'^\d{0,3}(\.\d?)?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(',', '.');
    if (!_pattern.hasMatch(text)) return oldValue;
    return newValue.copyWith(text: text);
  }
}

class BodyStep extends ConsumerStatefulWidget {
  const BodyStep({super.key});

  @override
  ConsumerState<BodyStep> createState() => _BodyStepState();
}

class _BodyStepState extends ConsumerState<BodyStep> {
  late final TextEditingController _height;
  late final TextEditingController _weight;
  final _weightFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingProvider);
    _height = TextEditingController(text: _show(draft.heightCm));
    _weight = TextEditingController(text: _show(draft.weightKg));
  }

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    _weightFocus.dispose();
    super.dispose();
  }

  static String _show(double? x) =>
      x == null ? '' : formatDecimal(x, places: 1);

  /// The value typed, if it's in range.
  static double? _inRange(String text, double min, double max) {
    final value = double.tryParse(text);
    return value != null && value >= min && value <= max ? value : null;
  }

  static String? _problem(String text, double min, double max, String unit) {
    if (text.isEmpty || _inRange(text, min, max) != null) return null;
    return 'Between ${formatDecimal(min)} and ${formatDecimal(max)} $unit';
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(onboardingProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeading(
          title: 'Your height and weight',
          subtitle:
              'Your weight sets your protein and water as well as calories.',
        ),
        TextField(
          controller: _height,
          decoration: InputDecoration(
            labelText: 'Height',
            suffixText: 'cm',
            errorText: _problem(_height.text, minHeightCm, maxHeightCm, 'cm'),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          inputFormatters: [_MeasurementFormatter()],
          onChanged: (text) {
            controller.setHeight(_inRange(text, minHeightCm, maxHeightCm));
            setState(() {});
          },
          onSubmitted: (_) => _weightFocus.requestFocus(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _weight,
          focusNode: _weightFocus,
          decoration: InputDecoration(
            labelText: 'Weight',
            suffixText: 'kg',
            errorText: _problem(_weight.text, minWeightKg, maxWeightKg, 'kg'),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          inputFormatters: [_MeasurementFormatter()],
          onChanged: (text) {
            controller.setWeight(_inRange(text, minWeightKg, maxWeightKg));
            setState(() {});
          },
        ),
      ],
    );
  }
}

class ActivityStep extends ConsumerWidget {
  const ActivityStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider.select((d) => d.activity));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeading(
          title: 'How active is a normal week?',
          subtitle: 'Count exercise and how much you move at work.',
        ),
        _Choices(
          options: ActivityLevel.values,
          selected: selected,
          describe: (level) => level.description,
          onChoose: ref.read(onboardingProvider.notifier).chooseActivity,
        ),
      ],
    );
  }
}

class DietStep extends ConsumerWidget {
  const DietStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider.select((d) => d.diet));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeading(
          title: 'What do you eat?',
          subtitle: 'So food suggestions fit your diet. You can skip this.',
        ),
        _Choices(
          options: DietType.values,
          selected: selected,
          onChoose: ref.read(onboardingProvider.notifier).chooseDiet,
        ),
      ],
    );
  }
}

class TrainingStep extends ConsumerWidget {
  const TrainingStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeading(
          title: 'How do you train?',
          subtitle:
              'For your workout plan, which is coming. You can skip this.',
        ),
        Text('Where', style: text.titleMedium),
        const SizedBox(height: 12),
        _Choices(
          options: TrainingPlace.values,
          selected: draft.trainingPlace,
          onChoose: controller.chooseTrainingPlace,
        ),
        const SizedBox(height: 12),
        Text('For how long', style: text.titleMedium),
        const SizedBox(height: 12),
        _Choices(
          options: Experience.values,
          selected: draft.experience,
          onChoose: controller.chooseExperience,
        ),
      ],
    );
  }
}

import 'package:aurafit/core/format.dart';
import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/profile_repository.dart';
import 'package:aurafit/data/providers.dart';
import 'package:aurafit/features/account/account_sheet.dart';
import 'package:aurafit/features/onboarding/onboarding_controller.dart';
import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/height.dart';
import 'package:aurafit/services/targets.dart';
import 'package:aurafit/widgets/aura_background.dart';
import 'package:aurafit/widgets/choice_card.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Edit any profile detail or goal on one screen (PRD A4). Tapping a row
/// edits only that detail and recalculates targets at once, keeping old
/// goals with the formula version they were worked out with.
class EditDetailsScreen extends ConsumerStatefulWidget {
  const EditDetailsScreen({super.key});

  @override
  ConsumerState<EditDetailsScreen> createState() => _EditDetailsScreenState();
}

class _EditDetailsScreenState extends ConsumerState<EditDetailsScreen> {
  ProfileRow? _profile;
  GoalRow? _goal;
  double? _weightKg;
  var _loading = true;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final repo = ref.read(profileRepositoryProvider);
    final profile = await repo.profile();
    final goal = await repo.activeGoal();
    final weight = await repo.latestWeight();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _goal = goal;
      _weightKg = weight?.weightKg ?? goal?.basisWeightKg;
      _loading = false;
    });
  }

  Future<void> _save({
    GoalType? goal,
    DateTime? birthDate,
    bool updateSex = false,
    Sex? sex,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activity,
    bool updateDiet = false,
    DietType? diet,
  }) async {
    final p = _profile;
    final g = _goal;
    final w = _weightKg;
    if (p == null || g == null || w == null || _saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .saveProfile(
            ProfileAnswers(
              goal: goal ?? g.goalType,
              birthDate: birthDate ?? p.birthDate,
              sex: updateSex ? sex : p.sex,
              heightCm: heightCm ?? p.heightCm,
              weightKg: weightKg ?? w,
              activity: activity ?? p.activityLevel,
              diet: updateDiet ? diet : p.dietType,
              trainingPlace: p.trainingPlace,
              experience: p.experience,
            ),
          );
      await _reload();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final profile = _profile;
    final goal = _goal;
    final weightKg = _weightKg;

    return Scaffold(
      appBar: AppBar(title: const Text('My details')),
      extendBodyBehindAppBar: true,
      body: AuraBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : profile == null || goal == null || weightKg == null
              ? const Center(child: Text('No profile saved yet.'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Active daily target',
                                    style: text.labelLarge?.copyWith(
                                      color: AuraColors.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${formatWhole(goal.caloriesKcal)} kcal · '
                                    '${goal.proteinG} g protein',
                                    style: text.titleLarge?.copyWith(
                                      color: AuraColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_saving)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      label: 'Goal',
                      value: goal.goalType.label,
                      onTap: () => _pickOption<GoalType>(
                        context,
                        title: 'Main goal',
                        options: GoalType.values,
                        selected: goal.goalType,
                        describe: (o) => o.description,
                        onPick: (picked) => _save(goal: picked),
                      ),
                    ),
                    _DetailRow(
                      label: 'Weight',
                      value: '${formatDecimal(weightKg, places: 1)} kg',
                      onTap: () => _editWeight(context, weightKg),
                    ),
                    _DetailRow(
                      label: 'Height',
                      value: _heightSummary(profile.heightCm),
                      onTap: () => _editHeight(context, profile.heightCm),
                    ),
                    _DetailRow(
                      label: 'Birth date',
                      value: _birthSummary(profile.birthDate),
                      onTap: () => _editBirthDate(context, profile.birthDate),
                    ),
                    _DetailRow(
                      label: 'Sex',
                      value: profile.sex?.label ?? 'Not given',
                      onTap: () => _editSex(context, profile.sex),
                    ),
                    _DetailRow(
                      label: 'Activity level',
                      value: profile.activityLevel.label,
                      onTap: () => _pickOption<ActivityLevel>(
                        context,
                        title: 'Activity level',
                        options: ActivityLevel.values,
                        selected: profile.activityLevel,
                        describe: (o) => o.description,
                        onPick: (picked) => _save(activity: picked),
                      ),
                    ),
                    _DetailRow(
                      label: 'Diet',
                      value: profile.dietType?.label ?? 'Not set',
                      onTap: () => _editDiet(context, profile.dietType),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => exportMyData(context, ref),
                      child: const Text('Export my data'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  static String _heightSummary(double cm) {
    final f = feetInchesFromCm(cm);
    return '${f.feet} ft ${f.inches} in (${formatDecimal(cm, places: 1)} cm)';
  }

  static String _birthSummary(DateTime date) {
    final now = clock.now();
    final age = ageOn(date, DateTime(now.year, now.month, now.day));
    return '${formatDate(date)} ($age)';
  }

  Future<void> _pickOption<T extends StoredOption>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required T selected,
    String Function(T)? describe,
    required Future<void> Function(T) onPick,
  }) async {
    final chosen = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AuraColors.surface,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              for (final option in options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ChoiceCard(
                    title: option.label,
                    subtitle: describe?.call(option),
                    selected: option == selected,
                    onTap: () => Navigator.of(context).pop(option),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (chosen != null) await onPick(chosen);
  }

  Future<void> _editSex(BuildContext context, Sex? current) async {
    final result = await showModalBottomSheet<({bool picked, Sex? sex})>(
      context: context,
      showDragHandle: true,
      backgroundColor: AuraColors.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sex', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              for (final sex in Sex.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ChoiceCard(
                    title: sex.label,
                    selected: current == sex,
                    onTap: () =>
                        Navigator.of(context).pop((picked: true, sex: sex)),
                  ),
                ),
              ChoiceCard(
                title: 'I\'d rather not say',
                selected: current == null,
                onTap: () =>
                    Navigator.of(context).pop((picked: true, sex: null)),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null && result.picked) {
      await _save(updateSex: true, sex: result.sex);
    }
  }

  Future<void> _editDiet(BuildContext context, DietType? current) async {
    final result = await showModalBottomSheet<({bool picked, DietType? diet})>(
      context: context,
      showDragHandle: true,
      backgroundColor: AuraColors.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Diet', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              for (final diet in DietType.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ChoiceCard(
                    title: diet.label,
                    selected: current == diet,
                    onTap: () =>
                        Navigator.of(context).pop((picked: true, diet: diet)),
                  ),
                ),
              if (current != null)
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop((picked: true, diet: null)),
                    child: const Text('Clear choice'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (result != null && result.picked) {
      await _save(updateDiet: true, diet: result.diet);
    }
  }

  Future<void> _editWeight(BuildContext context, double currentKg) async {
    final saved = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AuraColors.surface,
      builder: (context) => _WeightSheet(initialKg: currentKg),
    );
    if (saved != null) await _save(weightKg: saved);
  }

  Future<void> _editHeight(BuildContext context, double currentCm) async {
    final saved = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AuraColors.surface,
      builder: (context) => _HeightSheet(initialCm: currentCm),
    );
    if (saved != null) await _save(heightCm: saved);
  }

  Future<void> _editBirthDate(BuildContext context, DateTime current) async {
    final saved = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AuraColors.surface,
      builder: (context) => _BirthDateSheet(initial: current),
    );
    if (saved != null) await _save(birthDate: saved);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: text.labelLarge?.copyWith(
                          color: AuraColors.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(value, style: text.titleMedium),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AuraColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DecimalInputFormatter extends TextInputFormatter {
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

class _WeightSheet extends StatefulWidget {
  const _WeightSheet({required this.initialKg});

  final double initialKg;

  @override
  State<_WeightSheet> createState() => _WeightSheetState();
}

class _WeightSheetState extends State<_WeightSheet> {
  late final _controller = TextEditingController(
    text: formatDecimal(widget.initialKg, places: 1),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _valid {
    final v = double.tryParse(_controller.text);
    return v != null && v >= minWeightKg && v <= maxWeightKg ? v : null;
  }

  @override
  Widget build(BuildContext context) {
    final valid = _valid;
    final problem = _controller.text.isNotEmpty && valid == null
        ? 'Between ${formatDecimal(minWeightKg)} and ${formatDecimal(maxWeightKg)} kg'
        : null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Weight', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_DecimalInputFormatter()],
            decoration: InputDecoration(
              labelText: 'Weight',
              suffixText: 'kg',
              errorText: problem,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) =>
                valid == null ? null : Navigator.of(context).pop(valid),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: valid == null
                ? null
                : () => Navigator.of(context).pop(valid),
            child: const Text('Save weight'),
          ),
        ],
      ),
    );
  }
}

class _HeightSheet extends StatefulWidget {
  const _HeightSheet({required this.initialCm});

  final double initialCm;

  @override
  State<_HeightSheet> createState() => _HeightSheetState();
}

class _HeightSheetState extends State<_HeightSheet> {
  var _unit = HeightUnit.feetInches;
  late final TextEditingController _cm;
  late final TextEditingController _feet;
  late final TextEditingController _inches;
  late double? _valueCm = widget.initialCm;

  @override
  void initState() {
    super.initState();
    final f = feetInchesFromCm(widget.initialCm);
    _cm = TextEditingController(
      text: formatDecimal(widget.initialCm, places: 1),
    );
    _feet = TextEditingController(text: f.feet.toString());
    _inches = TextEditingController(text: f.inches.toString());
  }

  @override
  void dispose() {
    _cm.dispose();
    _feet.dispose();
    _inches.dispose();
    super.dispose();
  }

  void _recompute() {
    double? cm;
    if (_unit == HeightUnit.cm) {
      final v = double.tryParse(_cm.text);
      if (v != null && v >= minHeightCm && v <= maxHeightCm) cm = v;
    } else {
      final ft = int.tryParse(_feet.text);
      final inch = _inches.text.isEmpty ? 0.0 : double.tryParse(_inches.text);
      if (ft != null && inch != null && inch < 12) {
        final v = cmFromFeetInches(ft, inch);
        if (v >= minHeightCm && v <= maxHeightCm) cm = v;
      }
    }
    setState(() => _valueCm = cm);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Height', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SegmentedButton<HeightUnit>(
            segments: const [
              ButtonSegment(
                value: HeightUnit.feetInches,
                label: Text('ft + in'),
              ),
              ButtonSegment(value: HeightUnit.cm, label: Text('cm')),
            ],
            selected: {_unit},
            showSelectedIcon: false,
            onSelectionChanged: (s) {
              final next = s.single;
              final current = _valueCm;
              if (current != null) {
                _cm.text = formatDecimal(current, places: 1);
                final f = feetInchesFromCm(current);
                _feet.text = f.feet.toString();
                _inches.text = f.inches.toString();
              }
              setState(() => _unit = next);
            },
          ),
          const SizedBox(height: 16),
          if (_unit == HeightUnit.cm)
            TextField(
              controller: _cm,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [_DecimalInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Height',
                suffixText: 'cm',
              ),
              onChanged: (_) => _recompute(),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _feet,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Feet',
                      suffixText: 'ft',
                    ),
                    onChanged: (_) => _recompute(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _inches,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [_DecimalInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Inches',
                      suffixText: 'in',
                    ),
                    onChanged: (_) => _recompute(),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _valueCm == null
                ? null
                : () => Navigator.of(context).pop(_valueCm),
            child: const Text('Save height'),
          ),
        ],
      ),
    );
  }
}

class _BirthDateSheet extends StatefulWidget {
  const _BirthDateSheet({required this.initial});

  final DateTime initial;

  @override
  State<_BirthDateSheet> createState() => _BirthDateSheetState();
}

class _BirthDateSheetState extends State<_BirthDateSheet> {
  late final _day = TextEditingController(text: widget.initial.day.toString());
  late final _month = TextEditingController(
    text: widget.initial.month.toString(),
  );
  late final _year = TextEditingController(
    text: widget.initial.year.toString(),
  );
  late DateTime? _date = widget.initial;
  String? _problem;

  @override
  void dispose() {
    _day.dispose();
    _month.dispose();
    _year.dispose();
    super.dispose();
  }

  void _changed() {
    final d = int.tryParse(_day.text);
    final m = int.tryParse(_month.text);
    final y = int.tryParse(_year.text);
    if (d == null || m == null || y == null || _year.text.length < 4) {
      setState(() {
        _date = null;
        _problem = null;
      });
      return;
    }
    final date = DateTime(y, m, d);
    final real = date.year == y && date.month == m && date.day == d;
    final problem = real ? birthDateProblem(date) : 'That date doesn\'t exist';
    setState(() {
      _problem = problem;
      _date = problem == null ? date : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Birth date', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _day,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  decoration: const InputDecoration(labelText: 'Day'),
                  onChanged: (_) => _changed(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _month,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  decoration: const InputDecoration(labelText: 'Month'),
                  onChanged: (_) => _changed(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _year,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(labelText: 'Year'),
                  onChanged: (_) => _changed(),
                ),
              ),
            ],
          ),
          if (_problem != null) ...[
            const SizedBox(height: 8),
            Text(
              _problem!,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AuraColors.error),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _date == null
                ? null
                : () => Navigator.of(context).pop(_date),
            child: const Text('Save birth date'),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:aurafit/core/error_reporter.dart';
import 'package:aurafit/core/format.dart';
import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/food_repository.dart';
import 'package:aurafit/data/log_repository.dart';
import 'package:aurafit/data/providers.dart';
import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/meal_text_parser.dart';
import 'package:aurafit/services/oil.dart';
import 'package:aurafit/widgets/aura_background.dart';
import 'package:aurafit/widgets/portion_wheel_picker.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LogMealMode { search, text, saved, manual }

@immutable
class LogMealArgs {
  const LogMealArgs({
    this.day,
    this.meal,
    this.mode = LogMealMode.search,
    this.initialQuery = '',
    this.readNow = false,
  });

  final DateTime? day;
  final Meal? meal;
  final LogMealMode mode;

  /// What's searched for, or in [LogMealMode.text], the meal as typed.
  final String initialQuery;

  /// In [LogMealMode.text], read [initialQuery] straight away: it was typed
  /// on the Food tab already.
  final bool readNow;
}

Meal defaultMealForHour(int hour) {
  if (hour < 11) return Meal.breakfast;
  if (hour < 16) return Meal.lunch;
  if (hour < 19) return Meal.snack;
  return Meal.dinner;
}

/// Full meal logging screen supporting offline verified search (N1, N9),
/// AI text logging with edit-before-save & fallback (N2, N8), saved meals and
/// yesterday repeats (N3), and offline manual quick-add (N12).
class LogMealScreen extends ConsumerStatefulWidget {
  const LogMealScreen({super.key, this.args = const LogMealArgs()});

  final LogMealArgs args;

  @override
  ConsumerState<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends ConsumerState<LogMealScreen> {
  late Meal _meal;
  late DateTime _day;
  late LogMealMode _mode;

  late final TextEditingController _searchCtrl;
  late final TextEditingController _textCtrl;
  final _manualNameCtrl = TextEditingController();
  final _manualKcalCtrl = TextEditingController();
  final _manualProteinCtrl = TextEditingController();
  final _manualCarbsCtrl = TextEditingController();
  final _manualFatCtrl = TextEditingController();
  final _manualGramsCtrl = TextEditingController(text: '100');

  List<FoodItem> _results = const [];
  bool _loadingFoods = true;

  bool _parsingText = false;
  MealParseFallbackReason? _fallbackReason;
  List<ParsedMealDraft>? _drafts;
  String? _manualError;
  bool _saveManualAsFavourite = false;

  @override
  void initState() {
    super.initState();
    final now = clock.now();
    _day = diaryDay(widget.args.day ?? now);
    _meal = widget.args.meal ?? defaultMealForHour(now.hour);
    _mode = widget.args.mode;
    _searchCtrl = TextEditingController(text: widget.args.initialQuery);
    _textCtrl = TextEditingController(
      text: widget.args.mode == LogMealMode.text
          ? widget.args.initialQuery
          : '',
    );
    unawaited(_runSearch(widget.args.initialQuery));
    if (widget.args.readNow && _mode == LogMealMode.text) {
      // After the first frame: reading starts with a setState.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_parseTextMeal());
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _textCtrl.dispose();
    _manualNameCtrl.dispose();
    _manualKcalCtrl.dispose();
    _manualProteinCtrl.dispose();
    _manualCarbsCtrl.dispose();
    _manualFatCtrl.dispose();
    _manualGramsCtrl.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    try {
      final results = await ref
          .read(foodRepositoryProvider)
          .search(query, limit: 40);
      if (mounted) {
        setState(() {
          _results = results;
          _loadingFoods = false;
        });
      }
    } catch (error, stack) {
      reportAuraError(error, stack, where: 'log_meal.search');
      if (mounted) setState(() => _loadingFoods = false);
    }
  }

  Future<void> _openFoodSheet(FoodItem food) async {
    final nav = Navigator.of(context);
    final action = await showModalBottomSheet<UndoAction>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AuraColors.surface,
      builder: (context) =>
          _FoodPortionSheet(food: food, meal: _meal, day: _day),
    );
    if (action != null && mounted) {
      nav.pop(action);
    }
  }

  Future<void> _parseTextMeal() async {
    final raw = _textCtrl.text.trim();
    if (raw.isEmpty || _parsingText) return;
    setState(() {
      _parsingText = true;
      _fallbackReason = null;
      _drafts = null;
    });
    try {
      final drafts = await ref.read(mealTextParserProvider).parse(raw);
      if (!mounted) return;
      setState(() {
        _drafts = drafts;
        _parsingText = false;
      });
    } on MealParseFallbackException catch (error) {
      if (!mounted) return;
      setState(() {
        _fallbackReason = error.reason;
        _parsingText = false;
      });
    } catch (error, stack) {
      reportAuraError(error, stack, where: 'log_meal.parse');
      if (!mounted) return;
      setState(() {
        _fallbackReason = MealParseFallbackReason.aiUnavailable;
        _parsingText = false;
      });
    }
  }

  Future<void> _saveDrafts() async {
    final drafts = _drafts;
    if (drafts == null || drafts.isEmpty) return;
    final nav = Navigator.of(context);
    final logs = ref.read(logRepositoryProvider);
    final entries = [
      for (final d in drafts)
        NewMealEntry(
          foodId: d.matchedFood?.id,
          name: d.name,
          meal: _meal,
          day: _day,
          portionUnit: d.portionUnit,
          portionCount: d.portionCount,
          oilLevel: d.oilLevel,
          grams: d.grams,
          kcal: d.kcal,
          proteinG: d.proteinG,
          carbsG: d.carbsG,
          fatG: d.fatG,
          source: EntrySource.text,
        ),
    ];
    final undo = await logs.logEntries(
      entries,
      summaryLabel:
          'Logged ${entries.length} ${entries.length == 1 ? 'item' : 'items'}',
    );
    if (mounted) nav.pop(undo);
  }

  Future<void> _saveManual() async {
    final name = _manualNameCtrl.text.trim();
    final kcal = double.tryParse(_manualKcalCtrl.text.trim());
    if (name.isEmpty) {
      setState(() => _manualError = 'Enter the dish name.');
      return;
    }
    if (kcal == null || kcal < 0 || kcal > 10000) {
      setState(
        () => _manualError = 'Enter calories between 0 and 10,000 kcal.',
      );
      return;
    }
    final protein = double.tryParse(_manualProteinCtrl.text.trim()) ?? 0;
    final carbs = double.tryParse(_manualCarbsCtrl.text.trim()) ?? 0;
    final fat = double.tryParse(_manualFatCtrl.text.trim()) ?? 0;
    final grams = double.tryParse(_manualGramsCtrl.text.trim()) ?? 100;
    if (protein < 0 || carbs < 0 || fat < 0 || grams <= 0 || grams > 5000) {
      setState(() => _manualError = 'Check the gram numbers entered.');
      return;
    }

    final nav = Navigator.of(context);
    final logs = ref.read(logRepositoryProvider);
    if (_saveManualAsFavourite) {
      await logs.saveMealTemplate(
        name: name,
        items: [
          SavedMealDraftItem(
            name: name,
            portionUnit: 'serving',
            portionCount: 1,
            grams: grams,
            kcal: kcal,
            proteinG: protein,
            carbsG: carbs,
            fatG: fat,
          ),
        ],
      );
    }
    final undo = await logs.logEntry(
      NewMealEntry(
        name: name,
        meal: _meal,
        day: _day,
        portionUnit: 'serving',
        portionCount: 1,
        grams: grams,
        kcal: kcal,
        proteinG: protein,
        carbsG: carbs,
        fatG: fat,
        source: EntrySource.manual,
      ),
    );
    if (mounted) nav.pop(undo);
  }

  void _jumpToFallbackSearch() {
    final seed = _textCtrl.text.trim();
    final firstPart = seed.split(RegExp(r'[,\n]+')).first.trim();
    _searchCtrl.text = firstPart;
    setState(() => _mode = LogMealMode.search);
    unawaited(_runSearch(firstPart));
  }

  void _jumpToFallbackManual() {
    final seed = _textCtrl.text.trim();
    if (_manualNameCtrl.text.isEmpty && seed.isNotEmpty) {
      _manualNameCtrl.text = seed.length > 80 ? seed.substring(0, 80) : seed;
    }
    setState(() => _mode = LogMealMode.manual);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('Log ${_meal.label.toLowerCase()}')),
      body: AuraBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final m in Meal.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(m.label),
                            selected: _meal == m,
                            onSelected: (_) => setState(() => _meal = m),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<LogMealMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: LogMealMode.search,
                      label: Text('Search'),
                    ),
                    ButtonSegment(value: LogMealMode.text, label: Text('AI')),
                    ButtonSegment(
                      value: LogMealMode.saved,
                      label: Text('Saved'),
                    ),
                    ButtonSegment(
                      value: LogMealMode.manual,
                      label: Text('Quick add'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => setState(() => _mode = s.first),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: switch (_mode) {
                  LogMealMode.search => _buildSearchTab(text),
                  LogMealMode.text => _buildTextTab(text),
                  LogMealMode.saved => _buildSavedTab(text),
                  LogMealMode.manual => _buildManualTab(text),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchTab(TextTheme text) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchCtrl,
            autofocus: widget.args.initialQuery.isEmpty,
            textInputAction: TextInputAction.search,
            onChanged: _runSearch,
            decoration: InputDecoration(
              labelText: 'Search Indian foods & staples',
              hintText: 'roti, moong dal, poha, anda, paneer…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        unawaited(_runSearch(''));
                      },
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loadingFoods
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty
              ? _EmptySearch(
                  query: _searchCtrl.text.trim(),
                  onQuickAdd: () {
                    _manualNameCtrl.text = _searchCtrl.text.trim();
                    setState(() => _mode = LogMealMode.manual);
                  },
                  onTypeWithAi: () {
                    _textCtrl.text = _searchCtrl.text.trim();
                    setState(() => _mode = LogMealMode.text);
                  },
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: _results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final food = _results[index];
                    final defaultPortion = food.portions.first;
                    final preview = food.calculate(
                      unit: defaultPortion.unit,
                      count: 1,
                      oilLevel: food.defaultOil,
                    );
                    return Card(
                      child: InkWell(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(24),
                        ),
                        onTap: () => _openFoodSheet(food),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AuraColors.surfaceStrong,
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  border: Border.all(color: AuraColors.border),
                                ),
                                child: Icon(
                                  iconForPortionUnit(defaultPortion.unit),
                                  size: 20,
                                  color: AuraColors.accentSoft,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(food.name, style: text.titleMedium),
                                    const SizedBox(height: 2),
                                    Text(
                                      '1 ${defaultPortion.unit} '
                                      '(${formatDecimal(preview.grams, places: 0)} g) · '
                                      '${formatDecimal(preview.proteinG, places: 1)} g protein',
                                      style: text.bodySmall?.copyWith(
                                        color: AuraColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${formatWhole(preview.kcal.round())} kcal',
                                style: text.titleMedium?.copyWith(
                                  color: AuraColors.accentSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTextTab(TextTheme text) {
    final drafts = _drafts;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text(
          'Type or dictate your meal in English or Hinglish, and AI reads it. '
          'Our food database supplies the numbers whenever a dish matches, '
          'and you check everything before it\'s saved.',
          style: text.bodyMedium?.copyWith(color: AuraColors.muted),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _textCtrl,
          maxLines: 3,
          maxLength: maxMealTextLength,
          enabled: !_parsingText,
          decoration: const InputDecoration(
            labelText: 'What did you eat?',
            hintText: '2 roti without ghee, 1 katori moong dal, salad',
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _parsingText ? null : _parseTextMeal,
          child: Text(_parsingText ? 'Reading meal…' : 'Read meal'),
        ),
        if (_fallbackReason case final reason?) ...[
          const SizedBox(height: 16),
          Card(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)),
              side: BorderSide(color: AuraColors.accentSoft),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    switch (reason) {
                      MealParseFallbackReason.offline =>
                        'You\'re offline right now.',
                      MealParseFallbackReason.dailyLimitReached =>
                        'Today\'s AI text allowance is used.',
                      MealParseFallbackReason.signedOut =>
                        'Sign in to use AI text parsing.',
                      MealParseFallbackReason.aiUnavailable =>
                        'AI meal reading isn\'t reachable right now.',
                    },
                    style: text.titleMedium?.copyWith(
                      color: AuraColors.accentSoft,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Search and manual quick-add work offline at full speed.',
                    style: text.bodyMedium?.copyWith(color: AuraColors.muted),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _jumpToFallbackSearch,
                          child: const Text('Search foods'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _jumpToFallbackManual,
                          child: const Text('Quick add'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        if (drafts != null) ...[
          const SizedBox(height: 16),
          if (drafts.isEmpty)
            Text(
              'No food or drink items were spotted in that note. Try searching '
              'or quick-adding instead.',
              style: text.bodyMedium?.copyWith(color: AuraColors.accentSoft),
            )
          else ...[
            Text('Check and adjust before saving', style: text.titleMedium),
            const SizedBox(height: 8),
            for (var i = 0; i < drafts.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DraftItemCard(
                  draft: drafts[i],
                  onChanged: (updated) => setState(() {
                    final next = [...drafts];
                    next[i] = updated;
                    _drafts = next;
                  }),
                  onRemove: () => setState(() {
                    final next = [...drafts]..removeAt(i);
                    _drafts = next;
                  }),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _saveDrafts,
              child: Text(
                'Save ${drafts.length} '
                '${drafts.length == 1 ? 'item' : 'items'} '
                '(${formatWhole(drafts.fold<double>(0, (s, d) => s + d.kcal).round())} kcal)',
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildSavedTab(TextTheme text) {
    final savedAsync = ref.watch(savedMealsProvider);
    final prevDay = DateTime(_day.year, _day.month, _day.day - 1);
    final prev =
        ref.watch(daySummaryProvider(prevDay)).value?.entriesFor(_meal) ??
        const <MealEntryRow>[];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        if (prev.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Yesterday\'s ${_meal.label.toLowerCase()}',
                      style: text.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${prev.map((e) => e.name).join(', ')} · '
                      '${formatWhole(prev.fold<double>(0, (s, e) => s + e.kcal).round())} kcal',
                      style: text.bodySmall?.copyWith(color: AuraColors.muted),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () async {
                        final nav = Navigator.of(context);
                        final undo = await ref
                            .read(logRepositoryProvider)
                            .repeatYesterdayMeal(day: _day, meal: _meal);
                        if (undo != null && mounted) nav.pop(undo);
                      },
                      child: const Text('Repeat in one tap'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Text('Saved meals & favourites', style: text.titleMedium),
        const SizedBox(height: 8),
        switch (savedAsync) {
          AsyncData(value: final bundles) when bundles.isEmpty => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No saved meals yet. Save any dish from Search, or tap "Save '
              'meal" on a meal card on Today.',
              style: text.bodyMedium?.copyWith(color: AuraColors.muted),
            ),
          ),
          AsyncData(value: final bundles) => Column(
            children: [
              for (final bundle in bundles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(bundle.meal.name, style: text.titleMedium),
                                const SizedBox(height: 2),
                                Text(
                                  '${formatWhole(bundle.totalKcal.round())} kcal · '
                                  '${formatDecimal(bundle.totalProteinG, places: 1)} g protein',
                                  style: text.bodySmall?.copyWith(
                                    color: AuraColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove saved meal',
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final undo = await ref
                                  .read(logRepositoryProvider)
                                  .deleteSavedMeal(bundle);
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(undo.message),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    onPressed: undo.undo,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                          const SizedBox(width: 4),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(84, 44),
                            ),
                            onPressed: () async {
                              final nav = Navigator.of(context);
                              final undo = await ref
                                  .read(logRepositoryProvider)
                                  .logSavedMeal(
                                    bundle: bundle,
                                    day: _day,
                                    meal: _meal,
                                  );
                              if (mounted) nav.pop(undo);
                            },
                            child: const Text('Log'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ],
    );
  }

  Widget _buildManualTab(TextTheme text) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text(
          'Add a dish by hand when it isn\'t in the catalogue. Saved only to '
          'your own log, and works offline.',
          style: text.bodyMedium?.copyWith(color: AuraColors.muted),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _manualNameCtrl,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Dish name'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _manualKcalCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Calories',
                  suffixText: 'kcal',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _manualGramsCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  suffixText: 'g',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _manualProteinCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Protein (opt)',
                  suffixText: 'g',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _manualCarbsCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Carbs (opt)',
                  suffixText: 'g',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _manualFatCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Fat (opt)',
                  suffixText: 'g',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _saveManualAsFavourite,
          onChanged: (v) => setState(() => _saveManualAsFavourite = v ?? false),
          title: const Text('Also save to my favourites'),
        ),
        if (_manualError case final err?) ...[
          const SizedBox(height: 8),
          Text(err, style: text.bodyMedium?.copyWith(color: AuraColors.error)),
        ],
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _saveManual,
          child: Text('Add to ${_meal.label.toLowerCase()}'),
        ),
      ],
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({
    required this.query,
    required this.onQuickAdd,
    required this.onTypeWithAi,
  });

  final String query;
  final VoidCallback onQuickAdd;
  final VoidCallback onTypeWithAi;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('No verified match for "$query".', style: text.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Add it by hand in seconds, or describe the meal to AI.',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: AuraColors.muted),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onQuickAdd,
            child: const Text('Quick add by hand'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onTypeWithAi,
            child: const Text('Describe it to AI instead'),
          ),
        ],
      ),
    );
  }
}

class _DraftItemCard extends StatelessWidget {
  const _DraftItemCard({
    required this.draft,
    required this.onChanged,
    required this.onRemove,
  });

  final ParsedMealDraft draft;
  final ValueChanged<ParsedMealDraft> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final needsAttention =
        !draft.isVerifiedMatch || draft.confidence == ParseConfidence.low;
    final portions =
        draft.matchedFood?.portions ??
        [
          FoodPortion(
            unit: draft.portionUnit,
            grams: draft.portionCount > 0
                ? draft.grams / draft.portionCount
                : draft.grams,
          ),
          if (draft.portionUnit != 'g') const FoodPortion(unit: 'g', grams: 1),
        ];
    final showOil =
        draft.matchedFood == null || draft.matchedFood!.source == 'recipe';

    return Card(
      shape: needsAttention
          ? const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)),
              side: BorderSide(color: AuraColors.accentSoft),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(draft.name, style: text.titleMedium)),
                IconButton(
                  tooltip: 'Remove item',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              draft.isVerifiedMatch
                  ? 'Verified food match · about '
                        '${formatWhole(draft.kcal.round())} kcal · '
                        '${formatDecimal(draft.proteinG, places: 1)} g protein'
                  : 'AI estimate, tap to adjust · about '
                        '${formatWhole(draft.kcal.round())} kcal · '
                        '${formatDecimal(draft.proteinG, places: 1)} g protein',
              style: text.bodySmall?.copyWith(
                color: draft.isVerifiedMatch
                    ? AuraColors.muted
                    : AuraColors.accentSoft,
              ),
            ),
            if (draft.confidence == ParseConfidence.low)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Low confidence — check portion and oil below.',
                  style: text.bodySmall?.copyWith(color: AuraColors.accentSoft),
                ),
              ),
            const SizedBox(height: 12),
            PortionWheelPicker(
              portions: portions,
              selectedUnit: draft.portionUnit,
              count: draft.portionCount,
              onUnitChanged: (p) {
                final nextCount = p.unit == 'g' ? 100.0 : 1.0;
                final food = draft.matchedFood;
                if (food != null) {
                  final calc = food.calculate(
                    unit: p.unit,
                    count: nextCount,
                    oilLevel: draft.oilLevel,
                  );
                  onChanged(
                    ParsedMealDraft(
                      matchedFood: food,
                      name: draft.name,
                      portionUnit: p.unit,
                      portionCount: nextCount,
                      oilLevel: draft.oilLevel,
                      grams: calc.grams,
                      kcal: calc.kcal,
                      proteinG: calc.proteinG,
                      carbsG: calc.carbsG,
                      fatG: calc.fatG,
                      confidence: draft.confidence,
                    ),
                  );
                } else {
                  final nextGrams = (p.grams * nextCount).clamp(1.0, 5000.0);
                  final ratio = draft.grams > 0 ? nextGrams / draft.grams : 1.0;
                  onChanged(
                    ParsedMealDraft(
                      matchedFood: null,
                      name: draft.name,
                      portionUnit: p.unit,
                      portionCount: nextCount,
                      oilLevel: draft.oilLevel,
                      grams: nextGrams,
                      kcal: draft.kcal * ratio,
                      proteinG: draft.proteinG * ratio,
                      carbsG: draft.carbsG * ratio,
                      fatG: draft.fatG * ratio,
                      confidence: draft.confidence,
                    ),
                  );
                }
              },
              onCountChanged: (c) => onChanged(draft.adjust(count: c)),
            ),
            if (showOil) ...[
              const SizedBox(height: 12),
              OilSelectorBar(
                selected: draft.oilLevel,
                onChanged: (level) => onChanged(draft.adjust(oil: level)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FoodPortionSheet extends ConsumerStatefulWidget {
  const _FoodPortionSheet({
    required this.food,
    required this.meal,
    required this.day,
  });

  final FoodItem food;
  final Meal meal;
  final DateTime day;

  @override
  ConsumerState<_FoodPortionSheet> createState() => _FoodPortionSheetState();
}

class _FoodPortionSheetState extends ConsumerState<_FoodPortionSheet> {
  late String _unit;
  late OilLevel _oil;
  double _count = 1;

  bool get _hasCookingOil => widget.food.source == 'recipe';

  @override
  void initState() {
    super.initState();
    _unit = widget.food.portions.first.unit;
    _oil = widget.food.defaultOil;
    _count = _unit == 'g' ? 100 : 1;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final effectiveOil = _hasCookingOil ? _oil : null;
    final calc = widget.food.calculate(
      unit: _unit,
      count: _count,
      oilLevel: effectiveOil,
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.food.name, style: text.titleLarge),
            if (widget.food.assumption.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Assumes: ${widget.food.assumption}',
                style: text.bodySmall?.copyWith(color: AuraColors.muted),
              ),
            ],
            const SizedBox(height: 12),
            Card(
              color: AuraColors.surfaceStrong,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    _MacroPill(
                      label: 'Calories',
                      value: '${formatWhole(calc.kcal.round())} kcal',
                      highlight: true,
                    ),
                    _MacroPill(
                      label: 'Protein',
                      value: '${formatDecimal(calc.proteinG, places: 1)} g',
                    ),
                    _MacroPill(
                      label: 'Carbs',
                      value: '${formatDecimal(calc.carbsG, places: 1)} g',
                    ),
                    _MacroPill(
                      label: 'Fat',
                      value: '${formatDecimal(calc.fatG, places: 1)} g',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PortionWheelPicker(
                      portions: widget.food.portions,
                      selectedUnit: _unit,
                      count: _count,
                      onUnitChanged: (p) {
                        setState(() {
                          _unit = p.unit;
                          _count = p.unit == 'g' ? 100 : 1;
                        });
                      },
                      onCountChanged: (next) => setState(() => _count = next),
                    ),
                    if (_hasCookingOil) ...[
                      const SizedBox(height: 14),
                      Text('Oil & ghee', style: text.labelLarge),
                      const SizedBox(height: 8),
                      OilSelectorBar(
                        selected: _oil,
                        onChanged: (level) => setState(() => _oil = level),
                      ),
                    ],
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: () async {
                        final nav = Navigator.of(context);
                        final undo = await ref
                            .read(logRepositoryProvider)
                            .logEntry(
                              NewMealEntry(
                                foodId: widget.food.id,
                                name: widget.food.name,
                                meal: widget.meal,
                                day: widget.day,
                                portionUnit: _unit,
                                portionCount: _count,
                                oilLevel: effectiveOil,
                                grams: calc.grams,
                                kcal: calc.kcal,
                                proteinG: calc.proteinG,
                                carbsG: calc.carbsG,
                                fatG: calc.fatG,
                                source: EntrySource.search,
                              ),
                            );
                        if (mounted) nav.pop(undo);
                      },
                      child: Text('Add to ${widget.meal.label.toLowerCase()}'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await ref
                            .read(logRepositoryProvider)
                            .saveMealTemplate(
                              name: widget.food.name,
                              items: [
                                SavedMealDraftItem(
                                  foodId: widget.food.id,
                                  name: widget.food.name,
                                  portionUnit: _unit,
                                  portionCount: _count,
                                  oilLevel: effectiveOil,
                                  grams: calc.grams,
                                  kcal: calc.kcal,
                                  proteinG: calc.proteinG,
                                  carbsG: calc.carbsG,
                                  fatG: calc.fatG,
                                ),
                              ],
                            );
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Saved ${widget.food.name} to favourites.',
                            ),
                          ),
                        );
                      },
                      child: const Text('Save to favourites'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  const _MacroPill({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Flexible and scaled down, so four values fit a 320 dp phone even at
    // large system text sizes.
    return Expanded(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: text.bodySmall?.copyWith(color: AuraColors.muted),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: text.titleSmall?.copyWith(
                color: highlight ? AuraColors.accent : AuraColors.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet opened when tapping any logged meal entry on Today, allowing instant
/// portion, oil, or meal changes, or soft-deletion with Undo (PRD N11).
Future<UndoAction?> showEditMealEntrySheet(
  BuildContext context,
  MealEntryRow entry,
) => showModalBottomSheet<UndoAction>(
  context: context,
  // Over the tabs and their snackbars, not inside the Food tab.
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: AuraColors.surface,
  builder: (context) => _EditMealEntrySheet(entry: entry),
);

class _EditMealEntrySheet extends ConsumerStatefulWidget {
  const _EditMealEntrySheet({required this.entry});

  final MealEntryRow entry;

  @override
  ConsumerState<_EditMealEntrySheet> createState() =>
      _EditMealEntrySheetState();
}

class _EditMealEntrySheetState extends ConsumerState<_EditMealEntrySheet> {
  late Meal _meal;
  late String _unit;
  late OilLevel _oil;
  late double _count;
  FoodItem? _food;

  @override
  void initState() {
    super.initState();
    _meal = widget.entry.meal;
    _unit = widget.entry.portionUnit ?? 'g';
    _oil = widget.entry.oilLevel ?? OilLevel.home;
    _count = widget.entry.portionCount ?? widget.entry.grams;
    final foodId = widget.entry.foodId;
    if (foodId != null) {
      unawaited(
        ref.read(foodRepositoryProvider).byId(foodId).then((found) {
          if (mounted && found != null) setState(() => _food = found);
        }),
      );
    }
  }

  bool get _hasCookingOil {
    final food = _food;
    if (food != null) return food.source == 'recipe';
    return widget.entry.oilLevel != null;
  }

  List<FoodPortion> get _portions {
    final food = _food;
    if (food != null) return food.portions;
    final origUnit = widget.entry.portionUnit;
    final origCount = widget.entry.portionCount ?? 1.0;
    final unitGrams = origUnit == null || origUnit == 'g'
        ? 1.0
        : (origCount > 0 ? widget.entry.grams / origCount : widget.entry.grams);
    return [
      if (origUnit != null && origUnit != 'g')
        FoodPortion(unit: origUnit, grams: unitGrams),
      const FoodPortion(unit: 'g', grams: 1),
    ];
  }

  CalculatedNutrients _recalculate() {
    final effectiveOil = _hasCookingOil ? _oil : null;
    final food = _food;
    if (food != null) {
      return food.calculate(unit: _unit, count: _count, oilLevel: effectiveOil);
    }
    final chosenPortion = _portions.firstWhere(
      (p) => p.unit == _unit,
      orElse: () => const FoodPortion(unit: 'g', grams: 1),
    );
    final grams = (chosenPortion.grams * _count).clamp(0.5, 5000.0);
    final ratio = widget.entry.grams > 0 ? grams / widget.entry.grams : 1.0;
    final protein = widget.entry.proteinG * ratio;
    final carbs = widget.entry.carbsG * ratio;
    var fat = widget.entry.fatG * ratio;
    var kcal = widget.entry.kcal * ratio;

    final origOil = widget.entry.oilLevel ?? OilLevel.home;
    if (_hasCookingOil && _oil != origOil) {
      final deltaPer100g = _stepFor(_oil) - _stepFor(origOil);
      final newFat = (fat + deltaPer100g * (grams / 100.0)).clamp(0.0, 500.0);
      kcal = (kcal + (newFat - fat) * 9.0).clamp(0.0, 10000.0);
      fat = newFat;
    }
    return CalculatedNutrients(
      grams: grams,
      kcal: kcal,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
    );
  }

  static double _stepFor(OilLevel level) => switch (level) {
    OilLevel.low => 0.0,
    OilLevel.home => 3.5,
    OilLevel.extra => 7.5,
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final calc = _recalculate();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.entry.name, style: text.titleLarge),
            const SizedBox(height: 10),
            Card(
              color: AuraColors.surfaceStrong,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    _MacroPill(
                      label: 'Calories',
                      value: '${formatWhole(calc.kcal.round())} kcal',
                      highlight: true,
                    ),
                    _MacroPill(
                      label: 'Protein',
                      value: '${formatDecimal(calc.proteinG, places: 1)} g',
                    ),
                    _MacroPill(
                      label: 'Carbs',
                      value: '${formatDecimal(calc.carbsG, places: 1)} g',
                    ),
                    _MacroPill(
                      label: 'Fat',
                      value: '${formatDecimal(calc.fatG, places: 1)} g',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final m in Meal.values)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(m.label),
                                selected: _meal == m,
                                onSelected: (_) => setState(() => _meal = m),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    PortionWheelPicker(
                      portions: _portions,
                      selectedUnit: _unit,
                      count: _count,
                      onUnitChanged: (p) {
                        setState(() {
                          _unit = p.unit;
                          _count = p.unit == 'g' ? 100 : 1;
                        });
                      },
                      onCountChanged: (next) => setState(() => _count = next),
                    ),
                    if (_hasCookingOil) ...[
                      const SizedBox(height: 14),
                      Text('Oil & ghee', style: text.labelLarge),
                      const SizedBox(height: 8),
                      OilSelectorBar(
                        selected: _oil,
                        onChanged: (level) => setState(() => _oil = level),
                      ),
                    ],
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: () async {
                        final nav = Navigator.of(context);
                        await ref
                            .read(logRepositoryProvider)
                            .updateMealEntry(
                              id: widget.entry.id,
                              meal: _meal,
                              portionUnit: _unit,
                              portionCount: _count,
                              oilLevel: _hasCookingOil ? _oil : null,
                              grams: calc.grams,
                              kcal: calc.kcal,
                              proteinG: calc.proteinG,
                              carbsG: calc.carbsG,
                              fatG: calc.fatG,
                            );
                        if (mounted) nav.pop();
                      },
                      child: const Text('Save changes'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () async {
                        final nav = Navigator.of(context);
                        final undo = await ref
                            .read(logRepositoryProvider)
                            .deleteMealEntry(widget.entry);
                        if (mounted) nav.pop(undo);
                      },
                      child: const Text('Remove entry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:aurafit/core/format.dart';
import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:aurafit/core/theme/aura_type.dart';
import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/log_repository.dart';
import 'package:aurafit/data/providers.dart';
import 'package:aurafit/features/nutrition/log_meal_screen.dart';
import 'package:aurafit/features/progress/streak.dart';
import 'package:aurafit/features/shell/diary.dart';
import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/meal_text_parser.dart';
import 'package:aurafit/widgets/bright_card.dart';
import 'package:aurafit/widgets/josh.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The meals in the order they're eaten.
const _mealsInOrder = [Meal.breakfast, Meal.lunch, Meal.snack, Meal.dinner];

/// Logging food (PRD N1, N2, N3, N11, N12): type a meal for AI to read,
/// search the food list, saved meals and quick add, the last few dishes in
/// one tap, and the day's meals to edit, repeat or save.
class FoodScreen extends ConsumerStatefulWidget {
  const FoodScreen({super.key});

  @override
  ConsumerState<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends ConsumerState<FoodScreen> {
  final _typed = TextEditingController();

  /// The meal new food goes to. Until one is picked, it follows the clock.
  Meal? _picked;

  Meal get _meal => _picked ?? defaultMealForHour(clock.now().hour);

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  Future<void> _open(DateTime day, LogMealMode mode) async {
    final typed = _typed.text.trim();
    final reading = mode == LogMealMode.text && typed.isNotEmpty;
    final saved = await openMealLogger(
      context,
      LogMealArgs(
        day: day,
        meal: _meal,
        mode: mode,
        initialQuery: reading ? typed : '',
        readNow: reading,
      ),
    );
    if (saved && reading) _typed.clear();
  }

  Future<void> _logAgain(DateTime day, MealEntryRow recent) async {
    final undo = await ref
        .read(logRepositoryProvider)
        .logEntry(
          NewMealEntry(
            foodId: recent.foodId,
            name: recent.name,
            meal: _meal,
            day: day,
            portionUnit: recent.portionUnit,
            portionCount: recent.portionCount,
            oilLevel: recent.oilLevel,
            grams: recent.grams,
            kcal: recent.kcal,
            proteinG: recent.proteinG,
            carbsG: recent.carbsG,
            fatG: recent.fatG,
            source: EntrySource.repeat,
          ),
        );
    if (mounted) showUndo(context, undo);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final yesterday = ref.watch(viewingYesterdayProvider);
    final day = viewedDay(yesterday: yesterday);
    final summary = ref.watch(daySummaryProvider(day)).value;
    final entries = summary?.entries ?? const <MealEntryRow>[];
    final recents = ref.watch(recentFoodsProvider).value ?? const [];
    final streak = streakDays(
      ref.watch(loggedDaysProvider).value ?? const {},
      diaryDay(clock.now()),
    );

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            formatDate(day),
            style: text.bodyMedium?.copyWith(color: AuraColors.muted),
          ),
          Semantics(
            header: true,
            child: Text('FOOD', style: AuraType.display(40)),
          ),
          const SizedBox(height: 12),
          DaySwitch(isToday: !yesterday),
          const SizedBox(height: 12),
          _MealPicker(
            meal: _meal,
            onPick: (meal) => setState(() => _picked = meal),
          ),
          const SizedBox(height: 12),
          _TypeItCard(
            controller: _typed,
            stage: JoshStage.forStreak(streak),
            onRead: () => _open(day, LogMealMode.text),
          ),
          const SizedBox(height: 12),
          _SearchPill(onTap: () => _open(day, LogMealMode.search)),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Tile(
                    color: AuraColors.lilac,
                    icon: Icons.bookmark_rounded,
                    title: 'Saved meals',
                    line: 'Your usual thali in one tap',
                    onTap: () => _open(day, LogMealMode.saved),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Tile(
                    color: AuraColors.yellow,
                    icon: Icons.add_rounded,
                    title: 'Quick add',
                    line: 'Just the calories, from a label',
                    onTap: () => _open(day, LogMealMode.manual),
                  ),
                ),
              ],
            ),
          ),
          if (recents.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'AGAIN, IN ONE TAP',
              style: AuraType.kicker(color: AuraColors.muted),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final item in recents)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: const Icon(Icons.add_rounded, size: 16),
                        label: Text(item.name),
                        tooltip: 'Add ${item.name} to ${_meal.label}',
                        onPressed: () => _logAgain(day, item),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  yesterday ? 'EATEN YESTERDAY' : 'EATEN TODAY',
                  style: AuraType.kicker(color: AuraColors.muted),
                ),
              ),
              Text(
                '${formatWhole(entries.fold<double>(0, (s, e) => s + e.kcal).round())} KCAL',
                style: AuraType.display(22),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final meal in _mealsInOrder)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MealSectionCard(
                meal: meal,
                day: day,
                entries: summary?.entriesFor(meal) ?? const [],
                onAdd: () =>
                    openMealLogger(context, LogMealArgs(day: day, meal: meal)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Which meal new food goes to.
class _MealPicker extends StatelessWidget {
  const _MealPicker({required this.meal, required this.onPick});

  final Meal meal;
  final ValueChanged<Meal> onPick;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in _mealsInOrder)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(option.label),
                selected: option == meal,
                onSelected: (_) => onPick(option),
              ),
            ),
        ],
      ),
    );
  }
}

/// Type a meal and AI reads it; the food list supplies the numbers wherever
/// a dish matches (PRD N2, N8).
class _TypeItCard extends StatelessWidget {
  const _TypeItCard({
    required this.controller,
    required this.stage,
    required this.onRead,
  });

  final TextEditingController controller;
  final JoshStage stage;
  final VoidCallback onRead;

  static const _cream = Color(0xFFFFF6E6);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const field = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(18)),
      borderSide: BorderSide.none,
    );
    return BrightCard(
      color: AuraColors.sky,
      radius: 28,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('WHAT DID YOU EAT?', style: AuraType.display(28)),
                    const SizedBox(height: 6),
                    Text(
                      'Type it in English or Hinglish, or use your '
                      'keyboard\'s mic. AI reads it, and the food list '
                      'counts it.',
                      style: text.bodyMedium?.copyWith(color: AuraColors.ink),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Josh(
                mood: JoshMood.happy,
                stage: stage,
                width: 80,
                playFor: joshPlayFor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: 2,
            maxLines: 3,
            maxLength: maxMealTextLength,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onRead(),
            style: text.bodyLarge?.copyWith(color: AuraColors.ink),
            cursorColor: AuraColors.ink,
            decoration: InputDecoration(
              hintText: '2 roti, 1 katori rajma, salad',
              hintStyle: text.bodyLarge?.copyWith(
                color: const Color(0xFF5A5468),
              ),
              filled: true,
              fillColor: _cream,
              counterText: '',
              border: field,
              enabledBorder: field,
              focusedBorder: field.copyWith(
                borderSide: const BorderSide(color: AuraColors.ink, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          InkPillButton(label: 'Read it', height: 48, onPressed: onRead),
        ],
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AuraColors.surface,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AuraColors.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Search Indian foods',
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: AuraColors.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.color,
    required this.icon,
    required this.title,
    required this.line,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String line;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return BrightCard(
      color: color,
      radius: 22,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: text.titleSmall?.copyWith(
              color: AuraColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(line, style: text.bodySmall?.copyWith(color: AuraColors.ink)),
        ],
      ),
    );
  }
}

/// One meal of the day: what's in it to edit or delete, yesterday's in one
/// tap when it's empty, and saving it as a favourite (PRD N3, N11).
class _MealSectionCard extends ConsumerWidget {
  const _MealSectionCard({
    required this.meal,
    required this.day,
    required this.entries,
    required this.onAdd,
  });

  final Meal meal;
  final DateTime day;
  final List<MealEntryRow> entries;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final mealKcal = entries.fold<double>(0, (s, e) => s + e.kcal).round();
    final mealProtein = entries.fold<double>(0, (s, e) => s + e.proteinG);
    final prevDay = DateTime(day.year, day.month, day.day - 1);
    final prevEntries = entries.isEmpty
        ? (ref.watch(daySummaryProvider(prevDay)).value?.entriesFor(meal) ??
              const <MealEntryRow>[])
        : const <MealEntryRow>[];

    return BrightCard(
      color: AuraColors.surface,
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meal.label, style: text.titleMedium),
                    if (entries.isNotEmpty)
                      Text(
                        '${formatWhole(mealKcal)} kcal · '
                        '${formatDecimal(mealProtein, places: 1)} g protein',
                        style: text.bodySmall?.copyWith(
                          color: AuraColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              if (entries.isNotEmpty)
                IconButton(
                  tooltip: 'Save ${meal.label.toLowerCase()} as favourite',
                  icon: const Icon(Icons.bookmark_add_outlined, size: 20),
                  onPressed: () => _saveMealDialog(context, ref),
                ),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          if (entries.isEmpty)
            if (prevEntries.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Nothing logged yet.',
                  style: text.bodySmall?.copyWith(color: AuraColors.muted),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final undo = await ref
                        .read(logRepositoryProvider)
                        .repeatYesterdayMeal(day: day, meal: meal);
                    if (undo != null && context.mounted) {
                      showUndo(context, undo);
                    }
                  },
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: Text(
                    'Repeat yesterday (${prevEntries.length} '
                    '${prevEntries.length == 1 ? 'item' : 'items'} · '
                    '${formatWhole(prevEntries.fold<double>(0, (s, e) => s + e.kcal).round())} kcal)',
                  ),
                ),
              )
          else ...[
            const Divider(height: 16, color: AuraColors.surfaceStrong),
            for (final entry in entries)
              InkWell(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                onTap: () async {
                  final undo = await showEditMealEntrySheet(context, entry);
                  if (undo != null && context.mounted) showUndo(context, undo);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.name, style: text.bodyLarge),
                            Text(
                              entrySubtitle(entry),
                              style: text.bodySmall?.copyWith(
                                color: AuraColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${formatWhole(entry.kcal.round())} kcal',
                        style: text.bodyMedium?.copyWith(
                          color: AuraColors.accentSoft,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveMealDialog(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(text: 'My ${meal.label.toLowerCase()}');
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Save meal combo'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Name (e.g. Hostel breakfast)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              final nav = Navigator.of(dlgCtx);
              await ref
                  .read(logRepositoryProvider)
                  .saveMealTemplate(
                    name: name,
                    items: [
                      for (final e in entries)
                        SavedMealDraftItem(
                          foodId: e.foodId,
                          name: e.name,
                          portionUnit: e.portionUnit,
                          portionCount: e.portionCount,
                          oilLevel: e.oilLevel,
                          grams: e.grams,
                          kcal: e.kcal,
                          proteinG: e.proteinG,
                          carbsG: e.carbsG,
                          fatG: e.fatG,
                        ),
                    ],
                  );
              nav.pop(true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (saved == true) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Saved to your meals.')),
      );
    }
  }
}

/// An entry's portion, oil, where its numbers came from, and its protein:
/// "2 piece · Home style · 6.9 g P".
String entrySubtitle(MealEntryRow e) {
  final parts = <String>[];
  if (e.portionUnit != null && e.portionCount != null) {
    parts.add('${formatDecimal(e.portionCount!)} ${e.portionUnit}');
  } else {
    parts.add('${formatDecimal(e.grams, places: 0)} g');
  }
  if (e.oilLevel case final oil?) {
    parts.add(switch (oil) {
      OilLevel.low => 'No ghee / low oil',
      OilLevel.home => 'Home style',
      OilLevel.extra => 'Extra ghee',
    });
  }
  if (e.source == EntrySource.text && e.foodId == null) {
    parts.add('AI estimate');
  }
  parts.add('${formatDecimal(e.proteinG, places: 1)} g P');
  return parts.join(' · ');
}

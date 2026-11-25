import 'dart:async';
import 'dart:math' as math;

import 'package:aurafit/core/format.dart';
import 'package:aurafit/core/router.dart';
import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:aurafit/data/account.dart';
import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/log_repository.dart';
import 'package:aurafit/data/providers.dart';
import 'package:aurafit/features/account/account_sheet.dart';
import 'package:aurafit/features/nutrition/log_meal_screen.dart';
import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/coach_rules.dart';
import 'package:aurafit/services/targets.dart';
import 'package:aurafit/widgets/aura_background.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Daily home dashboard (PRD D1, D2, D4, C5, N3, N5, N11):
/// * Yesterday / Today switcher
/// * Real-log calorie ring & macro bars (amber when over, never red)
/// * 7-day rolling calorie & protein average
/// * Calm feedback & deterministic diet-matched protein ideas
/// * 1-tap +250 ml water, manual steps & weigh-in, tap-to-edit/delete with Undo
/// * Bottom thumb-reach bar for Search, Type meal, Saved & Recent foods.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  bool _viewingYesterday = false;

  void _showUndo(UndoAction action) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(action.message),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => unawaited(action.undo()),
          ),
        ),
      );
  }

  Future<void> _openLogger(LogMealArgs args) async {
    final result = await context.push<UndoAction>(Routes.logMeal, extra: args);
    if (result != null) _showUndo(result);
  }

  @override
  Widget build(BuildContext context) {
    final now = clock.now();
    final today = diaryDay(now);
    final viewedDay = _viewingYesterday
        ? DateTime(today.year, today.month, today.day - 1)
        : today;

    final explained = ref.watch(explainedGoalProvider);
    final profile = ref.watch(profileProvider).value;
    final summaryAsync = ref.watch(daySummaryProvider(viewedDay));
    final avgAsync = ref.watch(sevenDayAverageProvider(viewedDay));
    final recentAsync = ref.watch(recentFoodsProvider);
    final inAccount =
        ref.watch(accountProvider).value != null ||
        ref.watch(phoneOwnerProvider).value != null;

    return switch (explained) {
      AsyncData(value: final e?) => Scaffold(
        body: AuraBackground(
          child: SafeArea(
            bottom: false,
            child: _TodayBody(
              goal: e.goal,
              targets: e.targets,
              profile: profile,
              viewedDay: viewedDay,
              isToday: !_viewingYesterday,
              now: now,
              inAccount: inAccount,
              summary:
                  summaryAsync.value ??
                  DaySummary(
                    day: viewedDay,
                    entries: const [],
                    waterSamples: const [],
                    stepsSamples: const [],
                    weightLog: null,
                  ),
              sevenDay:
                  avgAsync.value ??
                  const SevenDayAverage(
                    avgKcal: 0,
                    avgProteinG: 0,
                    daysLogged: 0,
                  ),
              onSwitchDay: (yesterday) =>
                  setState(() => _viewingYesterday = yesterday),
              onOpenLogger: _openLogger,
              onUndo: _showUndo,
            ),
          ),
        ),
        bottomNavigationBar: _ThumbReachBar(
          day: viewedDay,
          nowHour: now.hour,
          recents: recentAsync.value ?? const [],
          onOpenLogger: _openLogger,
          onQuickLogRecent: (recent) async {
            final undo = await ref
                .read(logRepositoryProvider)
                .logEntry(
                  NewMealEntry(
                    foodId: recent.foodId,
                    name: recent.name,
                    meal: defaultMealForHour(clock.now().hour),
                    day: viewedDay,
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
            _showUndo(undo);
          },
        ),
      ),
      AsyncData() => Scaffold(
        body: AuraBackground(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('You don\'t have targets yet.'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go(Routes.onboarding),
                      child: const Text('Set up my targets'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      AsyncError() => const Scaffold(
        body: AuraBackground(
          child: Center(child: Text('Your diary couldn\'t be loaded.')),
        ),
      ),
      _ => const Scaffold(
        body: AuraBackground(child: Center(child: CircularProgressIndicator())),
      ),
    };
  }
}

class _TodayBody extends ConsumerWidget {
  const _TodayBody({
    required this.goal,
    required this.targets,
    required this.profile,
    required this.viewedDay,
    required this.isToday,
    required this.now,
    required this.inAccount,
    required this.summary,
    required this.sevenDay,
    required this.onSwitchDay,
    required this.onOpenLogger,
    required this.onUndo,
  });

  final GoalRow goal;
  final Targets? targets;
  final ProfileRow? profile;
  final DateTime viewedDay;
  final bool isToday;
  final DateTime now;
  final bool inAccount;
  final DaySummary summary;
  final SevenDayAverage sevenDay;
  final ValueChanged<bool> onSwitchDay;
  final Future<void> Function(LogMealArgs args) onOpenLogger;
  final ValueChanged<UndoAction> onUndo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final feedback = evaluateDayFeedback(
      eatenKcal: summary.totalKcal,
      targetKcal: goal.caloriesKcal,
      maintenanceKcal: targets?.maintenanceKcal,
      sex: profile?.sex,
      isToday: isToday,
      currentHour: now.hour,
      mealCount: summary.entries.length,
    );
    final proteinGuidance = buildProteinGuidance(
      dietType: profile?.dietType,
      targetProteinG: goal.proteinG,
      eatenProteinG: summary.totalProteinG,
      targetKcal: goal.caloriesKcal,
      eatenKcal: summary.totalKcal,
      sex: profile?.sex,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      isToday ? 'Today' : 'Yesterday',
                      style: text.headlineSmall,
                    ),
                  ),
                  Text(
                    formatDate(viewedDay),
                    style: text.bodySmall?.copyWith(color: AuraColors.muted),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push(Routes.targets),
              icon: const Icon(Icons.tune_outlined, size: 18),
              label: const Text('Targets'),
            ),
            if (inAccount)
              IconButton(
                onPressed: () => showAccountSheet(context),
                tooltip: 'Account',
                icon: const Icon(Icons.account_circle_outlined),
              )
            else
              TextButton(
                onPressed: () => context.push(Routes.signIn),
                child: const Text('Save plan'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: true, label: Text('Yesterday')),
            ButtonSegment(value: false, label: Text('Today')),
          ],
          selected: {!isToday},
          onSelectionChanged: (s) => onSwitchDay(s.first),
        ),
        const SizedBox(height: 16),
        _RingsAndMacrosCard(
          summary: summary,
          goal: goal,
          sevenDay: sevenDay,
          feedback: feedback,
        ),
        if (proteinGuidance.ideas.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ProteinIdeasCard(
            guidance: proteinGuidance,
            diet: profile?.dietType,
            onTapIdea: (idea) => onOpenLogger(
              LogMealArgs(
                day: viewedDay,
                meal: defaultMealForHour(now.hour),
                mode: LogMealMode.search,
                initialQuery: idea.searchQuery,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        _WaterStepsWeightSection(
          summary: summary,
          goal: goal,
          day: viewedDay,
          onUndo: onUndo,
        ),
        const SizedBox(height: 16),
        for (final meal in Meal.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MealSectionCard(
              meal: meal,
              day: viewedDay,
              entries: summary.entriesFor(meal),
              onAdd: () =>
                  onOpenLogger(LogMealArgs(day: viewedDay, meal: meal)),
              onUndo: onUndo,
            ),
          ),
      ],
    );
  }
}

class _RingsAndMacrosCard extends StatelessWidget {
  const _RingsAndMacrosCard({
    required this.summary,
    required this.goal,
    required this.sevenDay,
    required this.feedback,
  });

  final DaySummary summary;
  final GoalRow goal;
  final SevenDayAverage sevenDay;
  final CalmFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final eatenKcal = summary.totalKcal.round();
    final isOver = eatenKcal > goal.caloriesKcal;
    final progress = goal.caloriesKcal > 0
        ? (summary.totalKcal / goal.caloriesKcal).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Semantics(
                  label:
                      '${formatWhole(eatenKcal)} of '
                      '${formatWhole(goal.caloriesKcal)} kilocalories eaten',
                  child: SizedBox(
                    width: 112,
                    height: 112,
                    child: CustomPaint(
                      painter: _CalorieRingPainter(
                        progress: progress,
                        isOver: isOver,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  formatWhole(eatenKcal),
                                  style: text.titleLarge?.copyWith(
                                    color: isOver
                                        ? AuraColors.accentSoft
                                        : AuraColors.foreground,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                '/ ${formatWhole(goal.caloriesKcal)}',
                                style: text.bodySmall?.copyWith(
                                  color: AuraColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      _MacroBar(
                        label: 'Protein',
                        eatenG: summary.totalProteinG,
                        targetG: goal.proteinG,
                      ),
                      const SizedBox(height: 10),
                      _MacroBar(
                        label: 'Carbs',
                        eatenG: summary.totalCarbsG,
                        targetG: goal.carbsG,
                      ),
                      const SizedBox(height: 10),
                      _MacroBar(
                        label: 'Fat',
                        eatenG: summary.totalFatG,
                        targetG: goal.fatG,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AuraColors.surfaceStrong,
                borderRadius: const BorderRadius.all(Radius.circular(14)),
                border: Border.all(
                  color: feedback.isAmber
                      ? AuraColors.accentSoft
                      : AuraColors.border,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    feedback.isAmber
                        ? Icons.wb_sunny_outlined
                        : Icons.insights_outlined,
                    size: 18,
                    color: AuraColors.accentSoft,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feedback.message,
                      style: text.bodyMedium?.copyWith(
                        color: feedback.isAmber
                            ? AuraColors.accentSoft
                            : AuraColors.foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.calendar_view_week_outlined,
                  size: 16,
                  color: AuraColors.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sevenDay.daysLogged == 0
                        ? '7-day average: log meals to see your weekly trend'
                        : '7-day average: '
                              '${formatWhole(sevenDay.avgKcal.round())} kcal · '
                              '${formatWhole(sevenDay.avgProteinG.round())} g protein '
                              '(${sevenDay.daysLogged} ${sevenDay.daysLogged == 1 ? 'day' : 'days'} logged)',
                    style: text.bodySmall?.copyWith(color: AuraColors.muted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalorieRingPainter extends CustomPainter {
  const _CalorieRingPainter({required this.progress, required this.isOver});

  final double progress;
  final bool isOver;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - stroke) / 2;

    final trackPaint = Paint()
      ..color = AuraColors.surfaceStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;
    final arcPaint = Paint()
      ..color = isOver ? AuraColors.accentSoft : AuraColors.accent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_CalorieRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isOver != isOver;
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.eatenG,
    required this.targetG,
  });

  final String label;
  final double eatenG;
  final int targetG;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final eatenRound = eatenG.round();
    final isOver = targetG > 0 && eatenRound > targetG;
    final ratio = targetG > 0 ? (eatenG / targetG).clamp(0.0, 1.0) : 0.0;

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: text.labelMedium?.copyWith(color: AuraColors.muted),
                ),
              ),
              Text(
                '$eatenRound / $targetG g',
                style: text.labelMedium?.copyWith(
                  color: isOver ? AuraColors.accentSoft : AuraColors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(6)),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              color: isOver ? AuraColors.accentSoft : AuraColors.accent,
              backgroundColor: AuraColors.surfaceStrong,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProteinIdeasCard extends StatelessWidget {
  const _ProteinIdeasCard({
    required this.guidance,
    required this.diet,
    required this.onTapIdea,
  });

  final ProteinGuidance guidance;
  final DietType? diet;
  final ValueChanged<ProteinIdea> onTapIdea;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${guidance.proteinLeftG} g protein left today',
                    style: text.titleMedium,
                  ),
                ),
                Text(
                  diet?.label ?? 'Vegetarian ideas',
                  style: text.bodySmall?.copyWith(color: AuraColors.muted),
                ),
              ],
            ),
            if (guidance.floorNote case final note?) ...[
              const SizedBox(height: 4),
              Text(
                note,
                style: text.bodySmall?.copyWith(color: AuraColors.muted),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final idea in guidance.ideas)
                  ActionChip(
                    label: Text('${idea.dish} (+${idea.proteinG} g)'),
                    onPressed: () => onTapIdea(idea),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterStepsWeightSection extends ConsumerWidget {
  const _WaterStepsWeightSection({
    required this.summary,
    required this.goal,
    required this.day,
    required this.onUndo,
  });

  final DaySummary summary;
  final GoalRow goal;
  final DateTime day;
  final ValueChanged<UndoAction> onUndo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Card(
          child: InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            onTap: summary.waterSamples.isEmpty
                ? null
                : () => _showWaterHistorySheet(context, ref),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.water_drop_outlined,
                    color: AuraColors.accentSoft,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Water', style: text.labelLarge),
                        Text(
                          '${formatLitres(summary.waterMl)} / '
                          '${formatLitres(goal.waterMl)}',
                          style: text.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    onPressed: () async {
                      final undo = await ref
                          .read(logRepositoryProvider)
                          .addWater(day: day);
                      onUndo(undo);
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('250 ml'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Card(
                child: InkWell(
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  onTap: () => _editStepsDialog(context, ref),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.directions_walk,
                              size: 18,
                              color: AuraColors.muted,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Steps',
                                style: text.labelLarge?.copyWith(
                                  color: AuraColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${formatWhole(summary.steps)} / '
                          '${formatWhole(goal.steps)}',
                          style: text.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Card(
                child: InkWell(
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  onTap: () => _editWeightDialog(context, ref),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.monitor_weight_outlined,
                              size: 18,
                              color: AuraColors.muted,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Weight',
                                style: text.labelLarge?.copyWith(
                                  color: AuraColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          summary.weightLog == null
                              ? 'Log kg'
                              : '${formatDecimal(summary.weightLog!.weightKg, places: 1)} kg',
                          style: text.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showWaterHistorySheet(BuildContext context, WidgetRef ref) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        backgroundColor: AuraColors.surface,
        builder: (sheetCtx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Water entries',
                  style: Theme.of(sheetCtx).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final sample in summary.waterSamples)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
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
            ),
          ),
        ),
      );

  Future<void> _editStepsDialog(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(
      text: summary.steps > 0 ? '${summary.steps}' : '',
    );
    final action = await showDialog<UndoAction>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Steps walked'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Steps',
            helperText: 'Up to 1,00,000 steps',
          ),
        ),
        actions: [
          if (summary.stepsSamples.isNotEmpty)
            TextButton(
              onPressed: () async {
                final nav = Navigator.of(dlgCtx);
                final undo = await ref
                    .read(logRepositoryProvider)
                    .deleteHealthSample(summary.stepsSamples.first);
                nav.pop(undo);
              },
              child: const Text('Remove'),
            ),
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final val = int.tryParse(ctrl.text.trim());
              if (val == null || val < 0 || val > 100000) return;
              final nav = Navigator.of(dlgCtx);
              final undo = await ref
                  .read(logRepositoryProvider)
                  .setStepsForDay(day: day, steps: val);
              nav.pop(undo);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (action != null) onUndo(action);
  }

  Future<void> _editWeightDialog(BuildContext context, WidgetRef ref) async {
    final existing = summary.weightLog;
    final ctrl = TextEditingController(
      text: existing != null ? formatDecimal(existing.weightKg, places: 1) : '',
    );
    final action = await showDialog<UndoAction>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Weigh-in'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
          ],
          decoration: const InputDecoration(
            labelText: 'Weight',
            suffixText: 'kg',
            helperText: 'Between 20 and 400 kg',
          ),
        ),
        actions: [
          if (existing != null)
            TextButton(
              onPressed: () async {
                final nav = Navigator.of(dlgCtx);
                final undo = await ref
                    .read(logRepositoryProvider)
                    .deleteWeightLog(existing);
                nav.pop(undo);
              },
              child: const Text('Remove'),
            ),
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final val = double.tryParse(ctrl.text.trim());
              if (val == null || val < 20 || val > 400) return;
              final nav = Navigator.of(dlgCtx);
              final undo = await ref
                  .read(logRepositoryProvider)
                  .saveWeightForDay(day: day, weightKg: val);
              nav.pop(undo);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (action != null) onUndo(action);
  }
}

class _MealSectionCard extends ConsumerWidget {
  const _MealSectionCard({
    required this.meal,
    required this.day,
    required this.entries,
    required this.onAdd,
    required this.onUndo,
  });

  final Meal meal;
  final DateTime day;
  final List<MealEntryRow> entries;
  final VoidCallback onAdd;
  final ValueChanged<UndoAction> onUndo;

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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  icon: const Icon(Icons.add, size: 18),
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
                      if (undo != null) onUndo(undo);
                    },
                    icon: const Icon(Icons.replay, size: 18),
                    label: Text(
                      'Repeat yesterday (${prevEntries.length} '
                      '${prevEntries.length == 1 ? 'item' : 'items'} · '
                      '${formatWhole(prevEntries.fold<double>(0, (s, e) => s + e.kcal).round())} kcal)',
                    ),
                  ),
                )
            else ...[
              const Divider(height: 16, color: AuraColors.border),
              for (final entry in entries)
                InkWell(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  onTap: () async {
                    final undo = await showEditMealEntrySheet(context, entry);
                    if (undo != null) onUndo(undo);
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
                                _entrySubtitle(entry),
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  static String _entrySubtitle(MealEntryRow e) {
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

/// Bottom thumb-zone bar: recent foods and primary logging actions sit right
/// under the thumb for one-handed kitchen or mess-hall logging (PRD Page 11).
class _ThumbReachBar extends StatelessWidget {
  const _ThumbReachBar({
    required this.day,
    required this.nowHour,
    required this.recents,
    required this.onOpenLogger,
    required this.onQuickLogRecent,
  });

  final DateTime day;
  final int nowHour;
  final List<MealEntryRow> recents;
  final Future<void> Function(LogMealArgs args) onOpenLogger;
  final ValueChanged<MealEntryRow> onQuickLogRecent;

  @override
  Widget build(BuildContext context) {
    final meal = defaultMealForHour(nowHour);
    return Material(
      color: AuraColors.surface,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AuraColors.border)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (recents.isNotEmpty) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final item in recents)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            avatar: const Icon(Icons.add, size: 16),
                            label: Text(item.name),
                            onPressed: () => onQuickLogRecent(item),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () => onOpenLogger(
                        LogMealArgs(
                          day: day,
                          meal: meal,
                          mode: LogMealMode.search,
                        ),
                      ),
                      icon: const Icon(Icons.search, size: 20),
                      label: const Text('Log food'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () => onOpenLogger(
                        LogMealArgs(
                          day: day,
                          meal: meal,
                          mode: LogMealMode.text,
                        ),
                      ),
                      icon: const Icon(Icons.edit_note, size: 20),
                      label: const Text('Type'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    tooltip: 'Saved meals',
                    onPressed: () => onOpenLogger(
                      LogMealArgs(
                        day: day,
                        meal: meal,
                        mode: LogMealMode.saved,
                      ),
                    ),
                    icon: const Icon(Icons.bookmarks_outlined),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

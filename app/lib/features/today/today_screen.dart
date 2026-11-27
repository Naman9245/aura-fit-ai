import 'dart:math' as math;

import 'package:aurafit/core/format.dart';
import 'package:aurafit/core/router.dart';
import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:aurafit/core/theme/aura_type.dart';
import 'package:aurafit/data/account.dart';
import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/log_repository.dart';
import 'package:aurafit/data/providers.dart';
import 'package:aurafit/features/account/account_sheet.dart';
import 'package:aurafit/features/nutrition/log_meal_screen.dart';
import 'package:aurafit/features/progress/streak.dart';
import 'package:aurafit/features/shell/diary.dart';
import 'package:aurafit/features/today/health_sheets.dart';
import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/coach_rules.dart';
import 'package:aurafit/services/goals.dart';
import 'package:aurafit/services/targets.dart';
import 'package:aurafit/widgets/bright_card.dart';
import 'package:aurafit/widgets/josh.dart';
import 'package:aurafit/widgets/motion.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The daily dashboard (PRD D1, D2, D4, C5, N5): Josh with the day's calm
/// coaching line, then calories, protein, water, steps and the weigh-in,
/// for today or yesterday. Meals are listed and edited on the Food tab.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yesterday = ref.watch(viewingYesterdayProvider);
    return switch (ref.watch(explainedGoalProvider)) {
      AsyncData(value: final e?) => _TodayBody(
        goal: e.goal,
        targets: e.targets,
        day: viewedDay(yesterday: yesterday),
        isToday: !yesterday,
      ),
      AsyncData() => Center(
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
      AsyncError() => const Center(
        child: Text('Your diary couldn\'t be loaded.'),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _TodayBody extends ConsumerWidget {
  const _TodayBody({
    required this.goal,
    required this.targets,
    required this.day,
    required this.isToday,
  });

  final GoalRow goal;
  final Targets? targets;
  final DateTime day;
  final bool isToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = clock.now();
    final profile = ref.watch(profileProvider).value;
    final summary =
        ref.watch(daySummaryProvider(day)).value ??
        DaySummary(
          day: day,
          entries: const [],
          waterSamples: const [],
          stepsSamples: const [],
          weightLog: null,
        );
    final sevenDay =
        ref.watch(sevenDayAverageProvider(day)).value ??
        const SevenDayAverage(avgKcal: 0, avgProteinG: 0, daysLogged: 0);
    final streak = streakDays(
      ref.watch(loggedDaysProvider).value ?? const {},
      diaryDay(now),
    );

    final feedback = evaluateDayFeedback(
      eatenKcal: summary.totalKcal,
      targetKcal: goal.caloriesKcal,
      maintenanceKcal: targets?.maintenanceKcal,
      sex: profile?.sex,
      isToday: isToday,
      currentHour: now.hour,
      mealCount: summary.entries.length,
    );
    final trained =
        ref
            .watch(weekWorkoutsProvider(day))
            .value
            ?.any((session) => session.day == day) ??
        false;
    final goals = dailyGoals(
      summary: summary,
      goal: goal,
      sex: profile?.sex,
      planDay: ref.watch(trainingPlanProvider)?.dayOf(day.weekday),
      trained: trained,
    );
    final allDone = goals.every((g) => g.done);
    final proteinGuidance = buildProteinGuidance(
      dietType: profile?.dietType,
      targetProteinG: goal.proteinG,
      eatenProteinG: summary.totalProteinG,
      targetKcal: goal.caloriesKcal,
      eatenKcal: summary.totalKcal,
      sex: profile?.sex,
    );
    void undo(UndoAction action) => showUndo(context, action);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: staggered([
          _Header(day: day, isToday: isToday),
          DaySwitch(isToday: isToday),
          _JoshCard(
            // He moves again whenever something is logged.
            wakeKey: (summary.entries.length, summary.waterMl, summary.steps),
            streak: streak,
            greeting: todayGreeting(isToday: isToday, hour: now.hour),
            feedback: feedback,
            // A day that needs a second look says so calmly; otherwise
            // Josh cheers on the next goal.
            line: feedback.isAmber
                ? feedback.message
                : goalsLine(goals, isToday: isToday),
            mood: allDone && isToday
                ? JoshMood.proud
                : todayMood(
                    feedback: feedback,
                    isToday: isToday,
                    hour: now.hour,
                    mealCount: summary.entries.length,
                    proteinEatenG: summary.totalProteinG,
                    proteinTargetG: goal.proteinG,
                  ),
          ),
          GoalsCard(goals: goals, isToday: isToday),
          _CaloriesCard(
            summary: summary,
            goal: goal,
            sevenDay: sevenDay,
            onLog: () => openMealLogger(
              context,
              LogMealArgs(day: day, meal: defaultMealForHour(now.hour)),
            ),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ProteinCard(
                    eatenG: summary.totalProteinG,
                    targetG: goal.proteinG,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WaterCard(
                    summary: summary,
                    goal: goal,
                    onAdd: () async => undo(
                      await ref.read(logRepositoryProvider).addWater(day: day),
                    ),
                    onOpen: () => showWaterSheet(
                      context,
                      ref,
                      day: day,
                      samples: summary.waterSamples,
                      onUndo: undo,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _DarkStat(
                    kicker: 'STEPS',
                    icon: Icons.directions_walk_rounded,
                    value: summary.steps.toDouble(),
                    format: (v) =>
                        '${formatWhole(v.round())} / '
                        '${formatWhole(goal.steps)}',
                    onTap: () => showStepsSheet(
                      context,
                      ref,
                      day: day,
                      summary: summary,
                      onUndo: undo,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DarkStat(
                    kicker: 'WEIGHT',
                    icon: Icons.monitor_weight_outlined,
                    value: summary.weightLog?.weightKg,
                    fromZero: false,
                    format: (v) => '${formatDecimal(v, places: 1)} KG',
                    empty: 'LOG KG',
                    onTap: () => showWeightSheet(
                      context,
                      ref,
                      day: day,
                      existing: summary.weightLog,
                      startKg: goal.basisWeightKg,
                      onUndo: undo,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (proteinGuidance.ideas.isNotEmpty)
            _ProteinIdeasCard(
              guidance: proteinGuidance,
              diet: profile?.dietType,
              onTapIdea: (idea) => openMealLogger(
                context,
                LogMealArgs(
                  day: day,
                  meal: defaultMealForHour(now.hour),
                  initialQuery: idea.searchQuery,
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

/// The date, the day's name, and the way to the targets and the account.
class _Header extends ConsumerWidget {
  const _Header({required this.day, required this.isToday});

  final DateTime day;
  final bool isToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountProvider).value;
    final owner = ref.watch(phoneOwnerProvider).value;
    final email = account?.email ?? owner?.email;
    final inAccount = account != null || owner != null;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatDate(day),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AuraColors.muted),
              ),
              Semantics(
                header: true,
                child: Text(
                  isToday ? 'TODAY' : 'YESTERDAY',
                  style: AuraType.display(40),
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () => context.push(Routes.targets),
          icon: const Icon(Icons.tune_rounded, size: 18),
          label: const Text('Targets'),
        ),
        if (inAccount)
          IconButton(
            onPressed: () => showAccountSheet(context),
            tooltip: 'Account',
            style: IconButton.styleFrom(
              backgroundColor: AuraColors.yellow,
              foregroundColor: AuraColors.ink,
              fixedSize: const Size(44, 44),
            ),
            icon: email == null || email.isEmpty
                ? const Icon(Icons.person_rounded)
                : Text(
                    email.characters.first.toUpperCase(),
                    style: AuraType.display(22, color: AuraColors.ink),
                  ),
          )
        else
          TextButton(
            onPressed: () => context.push(Routes.signIn),
            child: const Text('Save plan'),
          ),
      ],
    );
  }
}

/// Josh, his streak, and the day's calm line (PRD D4). The card turns warm
/// yellow, never red, when the line asks for a second look.
class _JoshCard extends StatelessWidget {
  const _JoshCard({
    required this.streak,
    required this.greeting,
    required this.feedback,
    required this.line,
    required this.mood,
    required this.wakeKey,
  });

  /// What Josh says.
  final String line;

  final Object wakeKey;
  final int streak;
  final String greeting;
  final CalmFeedback feedback;
  final JoshMood mood;

  @override
  Widget build(BuildContext context) {
    const joshWidth = 120.0;
    return BrightCard(
      color: feedback.isAmber ? AuraColors.yellow : AuraColors.lilacLight,
      radius: 28,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 150),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, joshWidth + 4, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(streakTitle(streak), style: AuraType.kicker()),
                  const SizedBox(height: 6),
                  Text(greeting, style: AuraType.display(32)),
                  const SizedBox(height: 8),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      line,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AuraColors.ink, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -10,
            child: Josh(
              mood: mood,
              stage: JoshStage.forStreak(streak),
              width: joshWidth,
              playFor: joshPlayFor,
              wakeKey: wakeKey,
            ),
          ),
        ],
      ),
    );
  }
}

class _CaloriesCard extends StatelessWidget {
  const _CaloriesCard({
    required this.summary,
    required this.goal,
    required this.sevenDay,
    required this.onLog,
  });

  final DaySummary summary;
  final GoalRow goal;
  final SevenDayAverage sevenDay;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final eaten = summary.totalKcal.round();
    final target = goal.caloriesKcal;
    final over = eaten > target;
    final progress = target > 0
        ? (summary.totalKcal / target).clamp(0.0, 1.0)
        : 0.0;
    final days = sevenDay.daysLogged;

    return BrightCard(
      color: AuraColors.accent,
      radius: 28,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Semantics(
                label:
                    '${formatWhole(eaten)} of ${formatWhole(target)} '
                    'kilocalories eaten',
                excludeSemantics: true,
                child: SizedBox.square(
                  dimension: 104,
                  child: FillUp(
                    value: progress,
                    builder: (context, fill, child) => CustomPaint(
                      painter: _RingPainter(progress: fill),
                      child: child,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CountUp(
                                value: (target - eaten).abs().toDouble(),
                                format: (v) => formatWhole(v.round()),
                                style: AuraType.display(26),
                              ),
                              Text(
                                over ? 'kcal over' : 'kcal left',
                                style: text.labelSmall?.copyWith(
                                  color: AuraColors.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: CountUp(
                        value: eaten.toDouble(),
                        format: (v) =>
                            '${formatWhole(v.round())} / '
                            '${formatWhole(target)} KCAL',
                        style: AuraType.display(26),
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MacroChip(
                          'Carbs ${summary.totalCarbsG.round()} / '
                          '${goal.carbsG} g',
                        ),
                        _MacroChip(
                          'Fat ${summary.totalFatG.round()} / ${goal.fatG} g',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    InkPillButton(
                      label: 'Log food',
                      icon: Icons.add_rounded,
                      height: 40,
                      onPressed: onLog,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.calendar_view_week_rounded, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  days == 0
                      ? '7-day average: log meals to see your weekly trend'
                      : '7-day average: '
                            '${formatWhole(sevenDay.avgKcal.round())} kcal · '
                            '${formatWhole(sevenDay.avgProteinG.round())} g '
                            'protein ($days ${days == 1 ? 'day' : 'days'} '
                            'logged)',
                  style: text.bodySmall?.copyWith(
                    color: AuraColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0x1F17151F),
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: AuraColors.ink, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// The calorie ring, in ink on the orange card.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 11.0;
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0x2617151F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (progress <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = AuraColors.ink
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

/// A bar in ink on a bright card.
class _InkBar extends StatelessWidget {
  const _InkBar({required this.ratio});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(5)),
      child: LinearProgressIndicator(
        value: ratio.clamp(0.0, 1.0),
        minHeight: 10,
        color: AuraColors.ink,
        backgroundColor: const Color(0x2617151F),
      ),
    );
  }
}

class _ProteinCard extends StatelessWidget {
  const _ProteinCard({required this.eatenG, required this.targetG});

  final double eatenG;
  final int targetG;

  @override
  Widget build(BuildContext context) {
    return BrightCard(
      color: AuraColors.mint,
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PROTEIN', style: AuraType.kicker()),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: CountUp(
                value: eatenG,
                format: (v) => '${v.round()} / $targetG G',
                style: AuraType.display(30),
                maxLines: 1,
                softWrap: false,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              eatenG.round() >= targetG
                  ? 'Target reached'
                  : '${targetG - eatenG.round()} g to go',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AuraColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const SizedBox(height: 10),
            FillUp(
              value: targetG > 0 ? (eatenG / targetG).clamp(0.0, 1.0) : 0,
              builder: (context, fill, _) => _InkBar(ratio: fill),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterCard extends StatelessWidget {
  const _WaterCard({
    required this.summary,
    required this.goal,
    required this.onAdd,
    required this.onOpen,
  });

  final DaySummary summary;
  final GoalRow goal;
  final VoidCallback onAdd;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return BrightCard(
      color: AuraColors.yellow,
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WATER', style: AuraType.kicker()),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CountUp(
              value: summary.waterMl.toDouble(),
              format: (v) =>
                  '${formatLitres(v.round())} / '
                  '${formatLitres(goal.waterMl)}',
              style: AuraType.display(30),
              maxLines: 1,
              softWrap: false,
            ),
          ),
          const Spacer(),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: InkPillButton(
              label: '250 ml',
              icon: Icons.add_rounded,
              height: 36,
              onPressed: onAdd,
            ),
          ),
        ],
      ),
    );
  }
}

/// Steps or the weigh-in, on a dark card that opens its wheel.
class _DarkStat extends StatelessWidget {
  const _DarkStat({
    required this.kicker,
    required this.icon,
    required this.value,
    required this.format,
    required this.onTap,
    this.fromZero = true,
    this.empty = '',
  });

  final String kicker;
  final IconData icon;

  /// Null shows [empty] instead.
  final double? value;
  final String Function(double value) format;
  final bool fromZero;
  final String empty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BrightCard(
      color: AuraColors.surface,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AuraColors.muted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  kicker,
                  style: AuraType.kicker(color: AuraColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: switch (value) {
              final value? => CountUp(
                value: value,
                format: format,
                fromZero: fromZero,
                style: AuraType.display(26),
                maxLines: 1,
                softWrap: false,
              ),
              null => Text(
                empty,
                style: AuraType.display(26),
                maxLines: 1,
                softWrap: false,
              ),
            },
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
    return BrightCard(
      color: AuraColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PROTEIN IDEAS', style: AuraType.kicker(color: AuraColors.mint)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${guidance.proteinLeftG} g protein left today',
                  style: text.titleMedium,
                ),
              ),
              const SizedBox(width: 8),
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
                  backgroundColor: AuraColors.surfaceStrong,
                  label: Text('${idea.dish} (+${idea.proteinG} g)'),
                  onPressed: () => onTapIdea(idea),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The day's goals, ticked off as they're done.
class GoalsCard extends StatelessWidget {
  const GoalsCard({super.key, required this.goals, required this.isToday});

  final List<DailyGoal> goals;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final done = goals.where((g) => g.done).length;
    return BrightCard(
      color: AuraColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isToday ? 'TODAY\'S GOALS' : 'THAT DAY\'S GOALS',
                  style: AuraType.kicker(color: AuraColors.mint),
                ),
              ),
              CountUp(
                value: done.toDouble(),
                fromZero: false,
                format: (v) => '${v.round()} / ${goals.length}',
                style: AuraType.display(24),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final goal in goals) GoalLine(goal: goal, text: text),
        ],
      ),
    );
  }
}

/// One goal: a ring filling up, or a tick once it's done.
class GoalLine extends StatelessWidget {
  const GoalLine({super.key, required this.goal, required this.text});

  final DailyGoal goal;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final colour = switch (goal.kind) {
      GoalKind.calories => AuraColors.accent,
      GoalKind.protein => AuraColors.mint,
      GoalKind.water => AuraColors.sky,
      GoalKind.steps => AuraColors.yellow,
      GoalKind.training => AuraColors.lilac,
    };
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 34,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: goal.done
                    ? DecoratedBox(
                        key: const ValueKey('done'),
                        decoration: BoxDecoration(
                          color: colour,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AuraColors.ink,
                          size: 22,
                        ),
                      )
                    : FillUp(
                        key: const ValueKey('ring'),
                        value: goal.progress,
                        builder: (context, fill, _) =>
                            CircularProgressIndicator(
                              value: fill,
                              strokeWidth: 4,
                              color: colour,
                              backgroundColor: AuraColors.surfaceStrong,
                            ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                goal.title,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                goal.detail,
                textAlign: TextAlign.end,
                style: text.bodySmall?.copyWith(
                  color: goal.done ? colour : AuraColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Semantics(label: goal.done ? 'done' : 'not done yet'),
          ],
        ),
      ),
    );
  }
}

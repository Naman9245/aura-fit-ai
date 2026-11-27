import 'package:aurafit/core/format.dart';
import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:aurafit/core/theme/aura_type.dart';
import 'package:aurafit/data/log_repository.dart';
import 'package:aurafit/data/providers.dart';
import 'package:aurafit/features/progress/streak.dart';
import 'package:aurafit/features/shell/diary.dart';
import 'package:aurafit/features/today/health_sheets.dart';
import 'package:aurafit/widgets/bright_card.dart';
import 'package:aurafit/widgets/josh.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Training. Workout plans aren't built yet (PRD T1–T3), so for now Josh
/// says they're on the way, and today's steps count.
class TrainScreen extends ConsumerWidget {
  const TrainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final today = diaryDay(clock.now());
    final summary = ref.watch(daySummaryProvider(today)).value;
    final goalSteps = ref.watch(explainedGoalProvider).value?.goal.steps ?? 0;
    final steps = summary?.steps ?? 0;
    final streak = streakDays(
      ref.watch(loggedDaysProvider).value ?? const {},
      today,
    );

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Semantics(
            header: true,
            child: Text('TRAIN', style: AuraType.display(40)),
          ),
          const SizedBox(height: 14),
          BrightCard(
            color: AuraColors.mint,
            radius: 28,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Josh(
                    mood: JoshMood.sweaty,
                    stage: JoshStage.forStreak(streak),
                    width: 150,
                    playFor: joshPlayFor,
                  ),
                ),
                const SizedBox(height: 8),
                Text('ON THE WAY', style: AuraType.kicker()),
                const SizedBox(height: 6),
                Text('YOUR PLAN,\nBUILT BY JOSH', style: AuraType.display(34)),
                const SizedBox(height: 8),
                Text(
                  'Workouts for the gym or for home, every set coached, and '
                  'food that fits your training. Josh is getting them '
                  'ready. Until then, walking counts.',
                  style: text.bodyMedium?.copyWith(
                    color: AuraColors.ink,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          BrightCard(
            color: AuraColors.surface,
            onTap: summary == null
                ? null
                : () => showStepsSheet(
                    context,
                    ref,
                    day: today,
                    summary: summary,
                    onUndo: (action) => showUndo(context, action),
                  ),
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STEPS TODAY',
                    style: AuraType.kicker(color: AuraColors.mint),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${formatWhole(steps)} / ${formatWhole(goalSteps)}',
                      style: AuraType.display(30),
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                    child: LinearProgressIndicator(
                      value: goalSteps > 0
                          ? (steps / goalSteps).clamp(0.0, 1.0)
                          : 0,
                      minHeight: 10,
                      color: AuraColors.mint,
                      backgroundColor: AuraColors.surfaceStrong,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tap to log today\'s steps.',
                    style: text.bodySmall?.copyWith(color: AuraColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:aurafit/core/format.dart';
import 'package:aurafit/core/router.dart';
import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:aurafit/core/theme/aura_type.dart';
import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/log_repository.dart';
import 'package:aurafit/data/providers.dart';
import 'package:aurafit/features/progress/streak.dart';
import 'package:aurafit/features/shell/diary.dart';
import 'package:aurafit/features/today/health_sheets.dart';
import 'package:aurafit/features/train/training_setup.dart';
import 'package:aurafit/features/train/workout_screen.dart';
import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/step_counter.dart';
import 'package:aurafit/services/workouts.dart';
import 'package:aurafit/widgets/bright_card.dart';
import 'package:aurafit/widgets/josh.dart';
import 'package:aurafit/widgets/motion.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _weekdayNames = [
  'MONDAY',
  'TUESDAY',
  'WEDNESDAY',
  'THURSDAY',
  'FRIDAY',
  'SATURDAY',
  'SUNDAY',
];

/// Training (PRD T1-T3): a week's plan for the gym, dumbbells or home, with
/// Sunday always rest, today's workout to start, and today's steps.
class TrainScreen extends ConsumerStatefulWidget {
  const TrainScreen({super.key});

  @override
  ConsumerState<TrainScreen> createState() => _TrainScreenState();
}

class _TrainScreenState extends ConsumerState<TrainScreen> {
  /// The weekday on show, 1 = Monday. Today until another is picked.
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final today = diaryDay(clock.now());
    final plan = ref.watch(trainingPlanProvider);
    final profile = ref.watch(profileProvider).value;
    final weekday = _picked ?? today.weekday;
    final shown = DateTime(
      today.year,
      today.month,
      today.day + (weekday - today.weekday),
    );
    final week = ref.watch(weekWorkoutsProvider(today)).value ?? const [];
    final stage = JoshStage.forStreak(
      streakDays(ref.watch(loggedDaysProvider).value ?? const {}, today),
    );

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: staggered([
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text('TRAIN', style: AuraType.display(40)),
                ),
              ),
              if (plan != null)
                TextButton.icon(
                  onPressed: () => showTrainingSetupSheet(context, ref),
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: Text('${placeShort(plan.place)} · ${plan.days} days'),
                ),
            ],
          ),
          if (plan == null)
            _SetUpCard(profile: profile, stage: stage)
          else ...[
            _WeekStrip(
              plan: plan,
              today: today,
              shown: weekday,
              doneDays: {for (final s in week) s.day.weekday},
              onPick: (day) => setState(() => _picked = day),
            ),
            _DayCard(
              plan: plan,
              day: shown,
              isToday: shown == today,
              done: [
                for (final s in week)
                  if (s.day == shown) s,
              ],
              stage: stage,
            ),
            if (plan.dayOf(weekday) case TrainingDay(:final workout))
              _ExerciseList(workout: workout),
          ],
          _StepsCard(today: today),
          Text(
            'Stop if anything hurts beyond normal effort, and see a '
            'physiotherapist. These plans are general guidance, not '
            'medical advice.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AuraColors.muted),
          ),
        ]),
      ),
    );
  }
}

/// "Gym", "Dumbbells" or "Home".
String placeShort(TrainingPlace place) => switch (place) {
  TrainingPlace.gym => 'Gym',
  TrainingPlace.dumbbells => 'Dumbbells',
  TrainingPlace.home => 'Home',
};

class _SetUpCard extends ConsumerWidget {
  const _SetUpCard({required this.profile, required this.stage});

  final ProfileRow? profile;
  final JoshStage stage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BrightCard(
      color: AuraColors.mint,
      radius: 28,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('YOUR PLAN', style: AuraType.kicker()),
                    const SizedBox(height: 6),
                    Text('WHERE DO YOU TRAIN?', style: AuraType.display(32)),
                  ],
                ),
              ),
              Josh(
                mood: JoshMood.fired,
                stage: stage,
                width: 90,
                playFor: joshPlayFor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Josh builds your week from it: the gym, dumbbells at home, or '
            'just your body. Change it any time.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AuraColors.ink),
          ),
          const SizedBox(height: 14),
          TrainingSetupForm(
            initialPlace: profile?.trainingPlace,
            initialDays: profile?.trainingDays,
            initialExperience: profile?.experience,
            onBright: true,
            onSave: (place, days, experience) => ref
                .read(profileRepositoryProvider)
                .saveTraining(place: place, days: days, experience: experience),
          ),
        ],
      ),
    );
  }
}

/// Monday to Sunday: what each day holds, which are done, and the one on
/// show.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.plan,
    required this.today,
    required this.shown,
    required this.doneDays,
    required this.onPick,
  });

  final TrainingPlan plan;
  final DateTime today;
  final int shown;
  final Set<int> doneDays;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      children: [
        for (var weekday = 1; weekday <= 7; weekday++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _DayChip(
                letter: letters[weekday - 1],
                name: _weekdayNames[weekday - 1],
                day: plan.dayOf(weekday),
                done: doneDays.contains(weekday),
                selected: weekday == shown,
                isToday: weekday == today.weekday,
                onTap: () => onPick(weekday),
              ),
            ),
          ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.letter,
    required this.name,
    required this.day,
    required this.done,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final String letter;
  final String name;
  final PlanDay day;
  final bool done;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AuraColors.ink : AuraColors.foreground;
    final (icon, what) = switch (day) {
      _ when done => (Icons.check_circle_rounded, 'done'),
      TrainingDay(:final workout) => (
        Icons.fitness_center_rounded,
        workout.title.toLowerCase(),
      ),
      RestDay() => (Icons.bedtime_rounded, 'rest day'),
      ActiveRestDay() => (Icons.directions_walk_rounded, 'active rest'),
    };
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: '${name.toLowerCase()}, $what${isToday ? ', today' : ''}',
      excludeSemantics: true,
      child: Pressable(
        child: Material(
          color: selected ? AuraColors.paper : AuraColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            side: isToday && !selected
                ? const BorderSide(color: AuraColors.accent, width: 2)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  Text(
                    letter,
                    style: AuraType.kicker(color: fg)
                        .copyWith(letterSpacing: 0),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    icon,
                    size: 18,
                    color: done
                        ? (selected ? AuraColors.ink : AuraColors.mint)
                        : (day is TrainingDay ? fg : AuraColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The day on show: its workout to start, or rest.
class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.plan,
    required this.day,
    required this.isToday,
    required this.done,
    required this.stage,
  });

  final TrainingPlan plan;
  final DateTime day;
  final bool isToday;
  final List<WorkoutSessionRow> done;
  final JoshStage stage;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final when = isToday ? 'TODAY' : _weekdayNames[day.weekday - 1];
    Widget card({
      required Color colour,
      required JoshMood mood,
      required String kicker,
      required String title,
      required String line,
      Widget? action,
    }) => BrightCard(
      color: colour,
      radius: 28,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 170),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 124, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kicker, style: AuraType.kicker()),
                  const SizedBox(height: 6),
                  Text(title, style: AuraType.display(34)),
                  const SizedBox(height: 6),
                  Text(
                    line,
                    style: text.bodyMedium?.copyWith(color: AuraColors.ink),
                  ),
                  if (action != null) ...[const SizedBox(height: 14), action],
                ],
              ),
            ),
          ),
          Positioned(
            right: -4,
            bottom: -10,
            child: Josh(
              mood: mood,
              stage: stage,
              width: 120,
              playFor: joshPlayFor,
            ),
          ),
        ],
      ),
    );

    void start(PlannedWorkout workout) =>
        context.push(Routes.workout, extra: WorkoutArgs(workout: workout));

    return switch (plan.dayOf(day.weekday)) {
      TrainingDay(:final workout, :final number, :final of) when done.isEmpty =>
        card(
          colour: AuraColors.lilacLight,
          mood: JoshMood.fired,
          kicker: '$when · DAY $number OF $of',
          title: workout.title,
          line:
              '${workout.exercises.length} exercises · about '
              '${workout.minutes} min',
          action: InkPillButton(
            label: isToday ? 'Start workout' : 'Do it today',
            icon: Icons.play_arrow_rounded,
            onPressed: () => start(workout),
          ),
        ),
      TrainingDay(:final workout) => card(
        colour: AuraColors.mint,
        mood: JoshMood.proud,
        kicker: '$when · DONE',
        title: workout.title,
        line:
            '${done.last.setsDone} of ${done.last.setsPlanned} sets in '
            '${done.last.durationMin ?? 0} min. Proud of you.',
        action: InkPillButton(
          label: 'Do it again',
          icon: Icons.replay_rounded,
          onPressed: () => start(workout),
        ),
      ),
      RestDay() => card(
        colour: AuraColors.sky,
        mood: JoshMood.sleepy,
        kicker: when,
        title: 'REST DAY',
        line:
            'Muscles grow while you rest. Sleep well, eat your protein, '
            'and an easy walk is plenty.',
      ),
      ActiveRestDay() => card(
        colour: AuraColors.yellow,
        mood: JoshMood.happy,
        kicker: '$when · NO WORKOUT',
        title: 'ACTIVE REST',
        line:
            'A 30-minute walk and a stretch keep you moving. Your steps '
            'count towards today\'s goals.',
      ),
    };
  }
}

/// The day's exercises, each with how to do it.
class _ExerciseList extends StatelessWidget {
  const _ExerciseList({required this.workout});

  final PlannedWorkout workout;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return BrightCard(
      color: AuraColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THE EXERCISES', style: AuraType.kicker(color: AuraColors.mint)),
          const SizedBox(height: 4),
          for (final (index, planned) in workout.exercises.indexed)
            InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              onTap: () => showExerciseSheet(context, planned.exercise),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tileColour(index),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: AuraType.display(18, color: AuraColors.ink),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(planned.exercise.name, style: text.titleSmall),
                          Text(
                            '${planned.target} · ${planned.exercise.muscles}',
                            style: text.bodySmall?.copyWith(
                              color: AuraColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AuraColors.muted,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The bright colours list items take in turn.
Color tileColour(int index) => const [
  AuraColors.mint,
  AuraColors.sky,
  AuraColors.yellow,
  AuraColors.lilacLight,
][index % 4];

/// How to do an exercise, in a few lines.
Future<void> showExerciseSheet(BuildContext context, Exercise exercise) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) {
        final text = Theme.of(context).textTheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name, style: text.headlineSmall),
                const SizedBox(height: 2),
                Text(
                  exercise.muscles,
                  style: text.bodyMedium?.copyWith(color: AuraColors.muted),
                ),
                const SizedBox(height: 16),
                for (final (index, cue) in exercise.cues.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${index + 1}',
                          style: AuraType.display(22, color: AuraColors.accent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(cue, style: text.bodyLarge)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

class _StepsCard extends ConsumerWidget {
  const _StepsCard({required this.today});

  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final summary = ref.watch(daySummaryProvider(today)).value;
    final status = ref.watch(stepStatusProvider).value ?? StepStatus.none;
    final byPhone =
        summary?.stepsSamples.any((s) => s.source == SampleSource.phone) ??
        false;
    final goalSteps = ref.watch(explainedGoalProvider).value?.goal.steps ?? 0;
    final steps = summary?.steps ?? 0;
    return BrightCard(
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
            Text('STEPS TODAY', style: AuraType.kicker(color: AuraColors.mint)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: CountUp(
                value: steps.toDouble(),
                format: (v) =>
                    '${formatWhole(v.round())} / ${formatWhole(goalSteps)}',
                style: AuraType.display(30),
                maxLines: 1,
                softWrap: false,
              ),
            ),
            const SizedBox(height: 10),
            FillUp(
              value: goalSteps > 0 ? (steps / goalSteps).clamp(0.0, 1.0) : 0,
              builder: (context, fill, _) => ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(5)),
                child: LinearProgressIndicator(
                  value: fill,
                  minHeight: 10,
                  color: AuraColors.mint,
                  backgroundColor: AuraColors.surfaceStrong,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              status.counting
                  ? (byPhone
                        ? 'Counted by your phone. Tap to correct it.'
                        : 'Your phone counts them from now. Tap to add more.')
                  : 'Tap to log today\'s steps.',
              style: text.bodySmall?.copyWith(color: AuraColors.muted),
            ),
            if (status.available && !status.allowed) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final counter = ref.read(stepCounterProvider);
                  if (await counter.requestPermission()) {
                    await counter.start();
                    ref.invalidate(stepStatusProvider);
                    ref.invalidate(phoneStepsProvider);
                  }
                },
                icon: const Icon(Icons.directions_walk_rounded),
                label: const Text('Count my steps'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

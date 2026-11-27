import 'package:aurafit/core/format.dart';
import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:aurafit/core/theme/aura_type.dart';
import 'package:aurafit/data/providers.dart';
import 'package:aurafit/data/workout_repository.dart';
import 'package:aurafit/features/progress/streak.dart';
import 'package:aurafit/features/train/train_screen.dart';
import 'package:aurafit/services/workouts.dart';
import 'package:aurafit/widgets/bright_card.dart';
import 'package:aurafit/widgets/josh.dart';
import 'package:aurafit/widgets/motion.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which workout to do.
@immutable
class WorkoutArgs {
  const WorkoutArgs({required this.workout});

  final PlannedWorkout workout;
}

/// Doing a workout (PRD T2): every set with its reps or seconds and weight,
/// started from last time's numbers, a rest timer after each set, and Josh
/// cheering. Finishing saves it to today.
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key, required this.args});

  final WorkoutArgs args;

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen>
    with SingleTickerProviderStateMixin {
  late final DateTime _started = clock.now();
  PlannedWorkout get _workout => widget.args.workout;

  /// The sets of each exercise, in order.
  late final List<List<LoggedSet>> _sets = [
    for (final planned in _workout.exercises)
      List.generate(
        planned.sets,
        (_) => LoggedSet(
          exercise: planned.exercise.id,
          reps: planned.exercise.seconds == null
              ? planned.exercise.reps.$1
              : null,
          seconds: planned.exercise.seconds,
          kg: planned.exercise.weighted ? 0 : null,
        ),
      ),
  ];

  /// Last time's sets of each exercise, once loaded.
  List<List<LoggedSet>> _last = const [];

  /// Exercises where every set reached the top of the range last time, so
  /// the weight goes up a step.
  final Set<int> _goUp = {};

  late final AnimationController _rest = AnimationController(vsync: this);
  bool _saving = false;

  /// Saved or dropped: leaving no longer asks.
  bool _finished = false;

  int get _done =>
      _sets.fold(0, (sum, sets) => sum + sets.where((s) => s.done).length);
  int get _total => _sets.fold(0, (sum, sets) => sum + sets.length);

  @override
  void initState() {
    super.initState();
    _startFromLastTime();
  }

  @override
  void dispose() {
    _rest.dispose();
    super.dispose();
  }

  /// Fills each exercise from the last time it was done. When every set
  /// reached the top of the range, the weight goes up a step (double
  /// progression).
  Future<void> _startFromLastTime() async {
    final repo = ref.read(workoutRepositoryProvider);
    final last = [
      for (final planned in _workout.exercises)
        await repo.lastSets(planned.exercise.id),
    ];
    if (!mounted) return;
    setState(() {
      _last = last;
      for (final (index, previous) in last.indexed) {
        if (previous.isEmpty) continue;
        final exercise = _workout.exercises[index].exercise;
        final top = exercise.reps.$2;
        final reachedTop =
            exercise.weighted &&
            exercise.seconds == null &&
            previous.every((s) => (s.reps ?? 0) >= top);
        if (reachedTop) _goUp.add(index);
        _sets[index] = [
          for (final (n, set) in _sets[index].indexed)
            () {
              final before = previous[n.clamp(0, previous.length - 1)];
              return set.copyWith(
                reps: reachedTop ? exercise.reps.$1 : before.reps,
                seconds: before.seconds,
                kg: before.kg == null
                    ? null
                    : before.kg! + (reachedTop ? exercise.kgStep : 0),
              );
            }(),
        ];
      }
    });
  }

  void _change(int exercise, int set, LoggedSet next) =>
      setState(() => _sets[exercise][set] = next);

  void _toggleDone(int exercise, int set) {
    final current = _sets[exercise][set];
    _change(exercise, set, current.copyWith(done: !current.done));
    if (!current.done) {
      HapticFeedback.mediumImpact().ignore();
      // Rest before the next set, unless that was the last of the workout.
      if (_done < _total && !motionOff(context)) {
        _rest
          ..duration = Duration(
            seconds: _workout.exercises[exercise].restSeconds,
          )
          ..forward(from: 0).then((_) {
            if (mounted) HapticFeedback.heavyImpact().ignore();
          });
      }
    }
  }

  String get _joshLine {
    final left = _total - _done;
    if (_done == 0) return 'Warm up for five minutes, then let\'s go!';
    if (left == 0) return 'All done! Finish to save it.';
    if (left <= 3) return 'Last few. You\'ve got this!';
    return 'Nice work. $left sets to go.';
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _finished = true;
    });
    final sets = [for (final exercise in _sets) ...exercise];
    await ref
        .read(workoutRepositoryProvider)
        .saveSession(
          day: clock.now(),
          workoutKey: _workout.key,
          title: _workout.title,
          sets: sets,
          startedAt: _started,
        );
    if (!mounted) return;
    final minutes = clock.now().difference(_started).inMinutes;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Josh(
          mood: JoshMood.proud,
          width: 110,
          playFor: joshPlayFor,
        ),
        title: const Text('WORKOUT DONE', textAlign: TextAlign.center),
        content: Text(
          '$_done of $_total sets in $minutes min. Josh is proud of you. '
          'Eat your protein and rest well.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (mounted) _close();
  }

  /// Closes the workout once the leave guard is down.
  void _close() {
    setState(() => _finished = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  /// Leaving with sets done: keep going, save them, or drop them.
  Future<void> _leave() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave the workout?'),
        content: Text('You\'ve done $_done of $_total sets.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('drop'),
            child: const Text('Don\'t save'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('save'),
            child: const Text('Save and leave'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep going'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'save') {
      await _finish();
    } else if (choice == 'drop') {
      _close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = clock.now();
    final stage = JoshStage.forStreak(
      streakDays(ref.watch(loggedDaysProvider).value ?? const {}, today),
    );
    return PopScope(
      canPop: _done == 0 || _finished,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_finished) _leave();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_workout.title)),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              _ProgressHeader(
                done: _done,
                total: _total,
                line: _joshLine,
                stage: stage,
                rest: _rest,
                onSkipRest: () {
                  _rest
                    ..stop()
                    ..value = 1;
                },
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: staggered([
                    for (final (index, planned) in _workout.exercises.indexed)
                      _ExerciseCard(
                        index: index,
                        planned: planned,
                        sets: _sets[index],
                        last: index < _last.length ? _last[index] : const [],
                        goUp: _goUp.contains(index),
                        onChange: (set, next) => _change(index, set, next),
                        onToggle: (set) => _toggleDone(index, set),
                      ),
                    FilledButton.icon(
                      onPressed: _done == 0 || _saving ? null : _finish,
                      icon: const Icon(Icons.flag_rounded),
                      label: Text(
                        _done == _total ? 'Finish workout' : 'Finish early',
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Josh, how far through, and the rest timer.
class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.done,
    required this.total,
    required this.line,
    required this.stage,
    required this.rest,
    required this.onSkipRest,
  });

  final int done;
  final int total;
  final String line;
  final JoshStage stage;
  final AnimationController rest;
  final VoidCallback onSkipRest;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: BrightCard(
        color: AuraColors.mint,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Column(
          children: [
            Row(
              children: [
                Josh(
                  mood: done == total ? JoshMood.proud : JoshMood.sweaty,
                  stage: stage,
                  width: 64,
                  playFor: joshPlayFor,
                  wakeKey: done,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CountUp(
                        value: done.toDouble(),
                        fromZero: false,
                        format: (v) => '${v.round()} / $total SETS',
                        style: AuraType.display(26),
                      ),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          line,
                          style: text.bodyMedium?.copyWith(
                            color: AuraColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(5)),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: total == 0 ? 0 : done / total),
                duration: const Duration(milliseconds: 400),
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  color: AuraColors.ink,
                  backgroundColor: const Color(0x2617151F),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: rest,
              builder: (context, _) {
                if (!rest.isAnimating) return const SizedBox.shrink();
                final left = (rest.duration!.inSeconds * (1 - rest.value))
                    .ceil();
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'REST ${left ~/ 60}:${(left % 60).toString().padLeft(2, '0')}',
                          style: AuraType.display(22),
                        ),
                      ),
                      InkPillButton(
                        label: 'Skip rest',
                        height: 36,
                        onPressed: onSkipRest,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.index,
    required this.planned,
    required this.sets,
    required this.last,
    required this.goUp,
    required this.onChange,
    required this.onToggle,
  });

  final int index;
  final PlannedExercise planned;
  final List<LoggedSet> sets;
  final List<LoggedSet> last;
  final bool goUp;
  final void Function(int set, LoggedSet next) onChange;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final exercise = planned.exercise;
    return BrightCard(
      color: AuraColors.surface,
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tileColour(index),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                child: Text(
                  '${index + 1}',
                  style: AuraType.display(20, color: AuraColors.ink),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name, style: text.titleMedium),
                    Text(
                      '${planned.target} · rest ${planned.restSeconds} s',
                      style: text.bodySmall?.copyWith(color: AuraColors.muted),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'How to do ${exercise.name}',
                onPressed: () => showExerciseSheet(context, exercise),
                icon: const Icon(Icons.info_outline_rounded),
              ),
            ],
          ),
          if (last.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: Text(
                goUp
                    ? 'You hit the top of the range last time: go up to '
                          '${formatDecimal(sets.first.kg ?? 0, places: 1)} kg.'
                    : 'Last time: ${_summary(last)}',
                style: text.bodySmall?.copyWith(
                  color: goUp ? AuraColors.accentSoft : AuraColors.mint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (exercise.weighted)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: Text(
                'First time: pick a weight you can lift '
                '${exercise.reps.$2} times with good form.',
                style: text.bodySmall?.copyWith(color: AuraColors.muted),
              ),
            ),
          const SizedBox(height: 6),
          for (final (n, set) in sets.indexed)
            _SetRow(
              number: n + 1,
              exercise: exercise,
              set: set,
              onChange: (next) => onChange(n, next),
              onToggle: () => onToggle(n),
            ),
        ],
      ),
    );
  }

  static String _summary(List<LoggedSet> sets) {
    final first = sets.first;
    final amount = first.seconds != null
        ? '${first.seconds} s'
        : '${first.reps ?? 0}';
    final weight = first.kg != null && first.kg! > 0
        ? ' at ${formatDecimal(first.kg!, places: 1)} kg'
        : '';
    return '${sets.length} × $amount$weight';
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.number,
    required this.exercise,
    required this.set,
    required this.onChange,
    required this.onToggle,
  });

  final int number;
  final Exercise exercise;
  final LoggedSet set;
  final ValueChanged<LoggedSet> onChange;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final timed = exercise.seconds != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(top: 6, right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: set.done ? const Color(0x337EE0C3) : Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              'SET $number',
              style: AuraType.kicker(color: AuraColors.muted)
                  .copyWith(fontSize: 11, letterSpacing: 0.5),
            ),
          ),
          Expanded(
            child: timed
                ? _Stepper(
                    label: 'seconds, set $number',
                    value: '${set.seconds ?? 0} s',
                    onMinus: () => onChange(
                      set.copyWith(
                        seconds: ((set.seconds ?? 0) - 5).clamp(5, 600),
                      ),
                    ),
                    onPlus: () => onChange(
                      set.copyWith(
                        seconds: ((set.seconds ?? 0) + 5).clamp(5, 600),
                      ),
                    ),
                  )
                : _Stepper(
                    label: 'reps, set $number',
                    value: '${set.reps ?? 0}',
                    onMinus: () => onChange(
                      set.copyWith(reps: ((set.reps ?? 0) - 1).clamp(1, 100)),
                    ),
                    onPlus: () => onChange(
                      set.copyWith(reps: ((set.reps ?? 0) + 1).clamp(1, 100)),
                    ),
                  ),
          ),
          if (exercise.weighted) ...[
            const SizedBox(width: 6),
            Expanded(
              child: _Stepper(
                label: 'kilos, set $number',
                value: (set.kg ?? 0) == 0
                    ? '– kg'
                    : '${formatDecimal(set.kg!, places: 1)} kg',
                onMinus: () => onChange(
                  set.copyWith(
                    kg: ((set.kg ?? 0) - exercise.kgStep).clamp(0, 500),
                  ),
                ),
                onPlus: () => onChange(
                  set.copyWith(
                    kg: ((set.kg ?? 0) + exercise.kgStep).clamp(0, 500),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: 6),
          Semantics(
            button: true,
            checked: set.done,
            label: set.done ? 'Set $number done' : 'Mark set $number done',
            excludeSemantics: true,
            child: Pressable(
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: set.done
                        ? AuraColors.mint
                        : AuraColors.surfaceStrong,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: set.done ? AuraColors.ink : AuraColors.muted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// − value +, for reps, seconds or kilos.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    const tight = BoxConstraints(minWidth: 36, minHeight: 40);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AuraColors.surfaceStrong,
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Fewer $label',
            constraints: tight,
            padding: EdgeInsets.zero,
            iconSize: 18,
            onPressed: onMinus,
            icon: const Icon(Icons.remove_rounded),
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, style: AuraType.display(20)),
              ),
            ),
          ),
          IconButton(
            tooltip: 'More $label',
            constraints: tight,
            padding: EdgeInsets.zero,
            iconSize: 18,
            onPressed: onPlus,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:aurafit/core/format.dart';
import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:aurafit/core/theme/aura_type.dart';
import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/log_repository.dart';
import 'package:aurafit/data/providers.dart';
import 'package:aurafit/features/progress/streak.dart';
import 'package:aurafit/features/shell/diary.dart';
import 'package:aurafit/features/today/health_sheets.dart';
import 'package:aurafit/features/today/today_screen.dart' show GoalsCard;
import 'package:aurafit/services/goals.dart';
import 'package:aurafit/widgets/bright_card.dart';
import 'package:aurafit/widgets/josh.dart';
import 'package:aurafit/widgets/motion.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How it's going: Josh's streak, a calendar of the days logged, and the
/// weight trend with its 7-day average (PRD D3).
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  /// The first of the month the calendar shows.
  late DateTime _month = _firstOfMonth(clock.now());

  static DateTime _firstOfMonth(DateTime date) =>
      DateTime(date.year, date.month);

  @override
  Widget build(BuildContext context) {
    final today = diaryDay(clock.now());
    final logged = ref.watch(loggedDaysProvider).value ?? const <DateTime>{};
    final profile = ref.watch(profileProvider).value;
    final streak = streakDays(logged, today);

    // The calendar starts the day the plan did, or the first day logged if
    // that's earlier (a restored account), so nothing before reads as
    // missed.
    var start = profile == null ? today : diaryDay(profile.createdAt.toLocal());
    for (final day in logged) {
      if (day.isBefore(start)) start = day;
    }
    final firstMonth = _firstOfMonth(start);
    final thisMonth = _firstOfMonth(today);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: staggered([
          Semantics(
            header: true,
            child: Text('PROGRESS', style: AuraType.display(40)),
          ),
          _StreakCard(streak: streak),
          _MonthCalendar(
            month: _month,
            today: today,
            start: start,
            logged: logged,
            onPick: (day) => showDaySheet(context, day),
            onPrevious: _month.isAfter(firstMonth)
                ? () => setState(
                    () => _month = DateTime(_month.year, _month.month - 1),
                  )
                : null,
            onNext: _month.isBefore(thisMonth)
                ? () => setState(
                    () => _month = DateTime(_month.year, _month.month + 1),
                  )
                : null,
          ),
          const _Legend(),
          const _WeightCard(),
        ]),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return BrightCard(
      color: AuraColors.yellow,
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 12),
      child: Row(
        children: [
          Josh(
            mood: streak == 0 ? JoshMood.happy : JoshMood.proud,
            stage: JoshStage.forStreak(streak),
            width: 88,
            playFor: joshPlayFor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CountUp(
                  value: streak.toDouble(),
                  format: (v) => streakTitle(v.round()),
                  style: AuraType.display(28),
                ),
                const SizedBox(height: 4),
                Text(
                  streakLine(streak),
                  style: text.bodyMedium?.copyWith(
                    color: AuraColors.ink,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A day counts when you log a meal or a workout. Missing one '
                  'only pauses it.',
                  style: text.bodySmall?.copyWith(color: AuraColors.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// What one day on the calendar shows.
enum _DayKind { logged, today, missed, idle }

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.today,
    required this.start,
    required this.logged,
    required this.onPick,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final DateTime today;
  final DateTime start;
  final Set<DateTime> logged;

  /// Opens a day that has been, to see its goals.
  final ValueChanged<DateTime> onPick;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  _DayKind _kind(DateTime day) {
    if (logged.contains(day)) return _DayKind.logged;
    if (day == today) return _DayKind.today;
    if (day.isBefore(today) && !day.isBefore(start)) return _DayKind.missed;
    return _DayKind.idle;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final lead = month.weekday - 1; // The weeks start on Monday.
    final rows = ((lead + daysInMonth) / 7).ceil();
    final cellHeight = math.max(
      50.0,
      MediaQuery.textScalerOf(context).scale(13) + 34,
    );
    final previous = DateTime(month.year, month.month - 1);
    final next = DateTime(month.year, month.month + 1);

    return BrightCard(
      color: AuraColors.surface,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: monthName(previous.month),
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  '${monthName(month.month)} ${month.year}',
                  textAlign: TextAlign.center,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: monthName(next.month),
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ExcludeSemantics(
            child: Row(
              children: [
                for (final letter in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                  Expanded(
                    child: Text(
                      letter,
                      textAlign: TextAlign.center,
                      style: AuraType.kicker(color: AuraColors.muted)
                          .copyWith(fontSize: 11, letterSpacing: 1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          for (var row = 0; row < rows; row++)
            Padding(
              // A new month's days pop in afresh.
              key: ValueKey((month, row)),
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  for (var col = 0; col < 7; col++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: SizedBox(
                          height: cellHeight,
                          child: switch (row * 7 + col - lead + 1) {
                            final n when n >= 1 && n <= daysInMonth => Entrance(
                              index: n,
                              step: const Duration(milliseconds: 16),
                              maxIndex: 31,
                              rise: 8,
                              grow: true,
                              child: _DayCell(
                                day: DateTime(month.year, month.month, n),
                                kind: _kind(
                                  DateTime(month.year, month.month, n),
                                ),
                                isToday:
                                    DateTime(month.year, month.month, n) ==
                                    today,
                                onTap:
                                    DateTime(
                                      month.year,
                                      month.month,
                                      n,
                                    ).isAfter(today)
                                    ? null
                                    : () => onPick(
                                        DateTime(month.year, month.month, n),
                                      ),
                              ),
                            ),
                            _ => const SizedBox.shrink(),
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.kind,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final _DayKind kind;
  final bool isToday;

  /// Null for days still to come.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final number = '${day.day}';
    final date = formatDayMonth(day);
    final label = switch (kind) {
      _DayKind.logged when isToday => '$date, today: logged',
      _DayKind.logged => '$date: logged',
      _DayKind.today => '$date, today: nothing logged yet',
      _DayKind.missed => '$date: no log',
      _DayKind.idle => date,
    };
    const radius = BorderRadius.all(Radius.circular(14));
    const numberStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w700);

    final Widget cell = switch (kind) {
      _DayKind.logged => DecoratedBox(
        decoration: BoxDecoration(
          color: AuraColors.accent,
          borderRadius: radius,
          border: isToday
              ? Border.all(color: AuraColors.paper, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(number, style: numberStyle.copyWith(color: AuraColors.ink)),
            const SizedBox(height: 3),
            const CustomPaint(size: Size(26, 15), painter: FieryEyesPainter()),
          ],
        ),
      ),
      _DayKind.today => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: AuraColors.accent, width: 2),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  number,
                  style: numberStyle.copyWith(
                    color: AuraColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'TODAY',
                  style: numberStyle.copyWith(
                    color: AuraColors.accent,
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      _DayKind.missed => DecoratedBox(
        decoration: const BoxDecoration(
          color: AuraColors.surfaceStrong,
          borderRadius: radius,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(number, style: numberStyle.copyWith(color: AuraColors.muted)),
            const SizedBox(height: 6),
            const _Dot(),
          ],
        ),
      ),
      _DayKind.idle => Center(
        child: Text(
          number,
          style: numberStyle.copyWith(color: AuraColors.faint),
        ),
      ),
    };
    // Its own stop for a screen reader, not one long read of the month.
    return Semantics(
      container: true,
      button: onTap != null,
      label: label,
      excludeSemantics: true,
      child: onTap == null
          ? cell
          : Pressable(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: cell,
              ),
            ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 6,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFF8A849B),
        shape: BoxShape.circle,
      ),
    ),
  );
}

/// Josh's eyes with fire in them, for a day logged on the calendar.
class FieryEyesPainter extends CustomPainter {
  const FieryEyesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on a 28 by 16 grid.
    canvas.scale(size.width / 28, size.height / 16);
    final white = Paint()..color = const Color(0xFFFFFFFF);
    final flame = Paint()..color = const Color(0xFFFF4D2E);
    for (final x in [8.0, 20.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 8), width: 12, height: 14),
        white,
      );
      canvas.drawPath(
        Path()
          ..moveTo(x, 3)
          ..cubicTo(x + 3, 6, x + 3, 10, x + 1, 12)
          ..cubicTo(x, 13, x - 1, 13, x - 1, 12)
          ..cubicTo(x - 3, 10, x - 2, 7, x, 3)
          ..close(),
        flame,
      );
    }
  }

  @override
  bool shouldRepaint(FieryEyesPainter old) => false;
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: AuraColors.muted);
    Widget item(Widget mark, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 6),
        Text(label, style: style),
      ],
    );
    const square = BorderRadius.all(Radius.circular(4));
    return ExcludeSemantics(
      child: Wrap(
        spacing: 14,
        runSpacing: 8,
        children: [
          item(
            const SizedBox.square(
              dimension: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AuraColors.accent,
                  borderRadius: square,
                ),
              ),
            ),
            'Logged',
          ),
          item(const _Dot(), 'No log, no guilt'),
          item(
            SizedBox.square(
              dimension: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: square,
                  border: Border.all(color: AuraColors.accent, width: 2),
                ),
              ),
            ),
            'Today',
          ),
        ],
      ),
    );
  }
}

/// Each weigh-in's 7-day average: the mean of the weigh-ins in the week up
/// to and including it, which smooths out water and salt (PRD D3).
List<double> sevenDayAverages(List<WeightLogRow> weighIns) => [
  for (final row in weighIns)
    () {
      final from = DateTime(row.day.year, row.day.month, row.day.day - 6);
      final week = [
        for (final other in weighIns)
          if (!other.day.isBefore(from) && !other.day.isAfter(row.day))
            other.weightKg,
      ];
      return week.reduce((a, b) => a + b) / week.length;
    }(),
];

/// How the latest weigh-in compares with the first one in the trend, in
/// plain words: up, down or the same, never good or bad.
String weightChangeLine(List<WeightLogRow> weighIns) {
  if (weighIns.length < 2) {
    return 'Your first weigh-in. Josh draws the trend from the next one.';
  }
  final first = weighIns.first;
  final change = weighIns.last.weightKg - first.weightKg;
  final since = formatDayMonth(first.day);
  final kg = formatDecimal(change.abs(), places: 1);
  if (kg == '0') return 'The same as on $since';
  return '$kg kg ${change < 0 ? 'down' : 'up'} since $since';
}

class _WeightCard extends ConsumerWidget {
  const _WeightCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final weighIns = ref.watch(weighInsProvider).value ?? const [];
    final today = diaryDay(clock.now());
    final todays = ref.watch(daySummaryProvider(today)).value?.weightLog;
    final basis = ref.watch(explainedGoalProvider).value?.goal.basisWeightKg;

    void logWeight() => showWeightSheet(
      context,
      ref,
      day: today,
      existing: todays,
      startKg: weighIns.isEmpty ? (basis ?? 60) : weighIns.last.weightKg,
      onUndo: (action) => showUndo(context, action),
    );

    return BrightCard(
      color: AuraColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'WEIGHT, LAST 12 WEEKS',
                  style: AuraType.kicker(color: AuraColors.mint),
                ),
              ),
              TextButton(onPressed: logWeight, child: const Text('Log weight')),
            ],
          ),
          if (weighIns.isEmpty)
            Text(
              'Weigh in once a week, at the same time of day, and Josh draws '
              'your trend here.',
              style: text.bodyMedium?.copyWith(color: AuraColors.muted),
            )
          else ...[
            Text(
              '${formatDecimal(weighIns.last.weightKg, places: 1)} KG',
              style: AuraType.display(34),
            ),
            const SizedBox(height: 4),
            Text(
              weightChangeLine(weighIns),
              style: text.bodyMedium?.copyWith(color: AuraColors.muted),
            ),
            if (weighIns.length >= 2) ...[
              const SizedBox(height: 14),
              _WeightChart(weighIns: weighIns, end: today),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    formatDayMonth(weighIns.first.day),
                    style: text.bodySmall?.copyWith(color: AuraColors.muted),
                  ),
                  const Spacer(),
                  Text(
                    formatDayMonth(today),
                    style: text.bodySmall?.copyWith(color: AuraColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Line: your 7-day average. Dots: each weigh-in.',
                style: text.bodySmall?.copyWith(color: AuraColors.muted),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.weighIns, required this.end});

  final List<WeightLogRow> weighIns;
  final DateTime end;

  @override
  Widget build(BuildContext context) {
    final kg = [for (final row in weighIns) row.weightKg];
    final low = kg.reduce(math.min);
    final high = kg.reduce(math.max);
    final summary =
        'Weight trend: lowest ${formatDecimal(low, places: 1)} kg, '
        'highest ${formatDecimal(high, places: 1)} kg, latest '
        '${formatDecimal(kg.last, places: 1)} kg.';
    return Semantics(
      container: true,
      label: summary,
      child: SizedBox(
        height: 140,
        width: double.infinity,
        child: FillUp(
          value: 1,
          builder: (context, drawn, _) => CustomPaint(
            painter: _WeightChartPainter(
              days: [for (final row in weighIns) row.day],
              kg: kg,
              average: sevenDayAverages(weighIns),
              end: end,
              drawn: drawn,
            ),
          ),
        ),
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  _WeightChartPainter({
    required this.days,
    required this.kg,
    required this.average,
    required this.end,
    this.drawn = 1,
  });

  final List<DateTime> days;
  final List<double> kg;
  final List<double> average;
  final DateTime end;

  /// How much of the line is drawn yet, from 0 to 1.
  final double drawn;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 8.0;
    final first = days.first;
    final span = math.max(1, end.difference(first).inDays);
    var low = [...kg, ...average].reduce(math.min);
    var high = [...kg, ...average].reduce(math.max);
    // Half a kilo either side at least, so small changes don't look huge.
    final mid = (low + high) / 2;
    low = math.min(low, mid - 0.5);
    high = math.max(high, mid + 0.5);

    Offset at(DateTime day, double value) => Offset(
      pad + (size.width - 2 * pad) * day.difference(first).inDays / span,
      pad + (size.height - 2 * pad) * (high - value) / (high - low),
    );

    final grid = Paint()
      ..color = AuraColors.surfaceStrong
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = pad + (size.height - 2 * pad) * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Dots appear as the line reaches them, left to right.
    final reached = pad + (size.width - 2 * pad) * drawn;
    final dot = Paint()..color = AuraColors.lilac;
    for (var i = 0; i < days.length; i++) {
      final point = at(days[i], kg[i]);
      if (point.dx <= reached + 0.5) canvas.drawCircle(point, 3.5, dot);
    }

    final line = Path();
    for (var i = 0; i < days.length; i++) {
      final point = at(days[i], average[i]);
      i == 0
          ? line.moveTo(point.dx, point.dy)
          : line.lineTo(point.dx, point.dy);
    }
    final pen = Paint()
      ..color = AuraColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (drawn >= 1) {
      canvas.drawPath(line, pen);
      return;
    }
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, reached + 2, size.height));
    canvas.drawPath(line, pen);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WeightChartPainter old) =>
      old.kg != kg || old.days != days || old.end != end || old.drawn != drawn;
}

const _weekdays = [
  'MONDAY',
  'TUESDAY',
  'WEDNESDAY',
  'THURSDAY',
  'FRIDAY',
  'SATURDAY',
  'SUNDAY',
];

/// A day that has been: Josh says how it went, over its goals.
Future<void> showDaySheet(BuildContext context, DateTime day) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _DaySheet(day: day),
    );

class _DaySheet extends ConsumerWidget {
  const _DaySheet({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final today = diaryDay(clock.now());
    final isToday = day == today;
    final summary = ref.watch(daySummaryProvider(day)).value;
    final goal = ref.watch(explainedGoalProvider).value?.goal;
    final trained =
        ref
            .watch(weekWorkoutsProvider(day))
            .value
            ?.any((session) => session.day == day) ??
        false;
    final streak = streakDays(
      ref.watch(loggedDaysProvider).value ?? const {},
      today,
    );
    final goals = summary == null || goal == null
        ? const <DailyGoal>[]
        : dailyGoals(
            summary: summary,
            goal: goal,
            sex: ref.watch(profileProvider).value?.sex,
            planDay: ref.watch(trainingPlanProvider)?.dayOf(day.weekday),
            trained: trained,
          );
    final nothing =
        summary != null &&
        summary.entries.isEmpty &&
        summary.waterMl == 0 &&
        summary.steps == 0 &&
        !trained;
    final done = goals.where((g) => g.done).length;
    final line = nothing
        ? 'Nothing logged this day. No guilt: every day is a fresh start.'
        : goalsLine(goals, isToday: isToday);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isToday
                  ? 'TODAY'
                  : '${_weekdays[day.weekday - 1]} ${formatDayMonth(day).toUpperCase()}',
              style: AuraType.display(30),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Josh(
                  mood: nothing
                      ? JoshMood.calm
                      : (goals.isNotEmpty && done == goals.length
                            ? JoshMood.proud
                            : JoshMood.happy),
                  stage: JoshStage.forStreak(streak),
                  width: 84,
                  playFor: joshPlayFor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Bubble(text: line, style: text),
                ),
              ],
            ),
            if (!nothing && goals.isNotEmpty) ...[
              const SizedBox(height: 16),
              GoalsCard(goals: goals, isToday: isToday),
            ],
          ],
        ),
      ),
    );
  }
}

/// Josh's speech bubble, its tail pointing at him.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.style});

  final String text;
  final TextTheme style;

  @override
  Widget build(BuildContext context) {
    return Entrance(
      index: 1,
      grow: true,
      rise: 8,
      child: CustomPaint(
        painter: const _BubblePainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 16, 14),
          child: Semantics(
            liveRegion: true,
            child: Text(
              text,
              style: style.bodyLarge?.copyWith(
                color: AuraColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AuraColors.paper;
    canvas.drawRRect(
      RRect.fromLTRBR(8, 0, size.width, size.height, const Radius.circular(20)),
      paint,
    );
    // The tail, low on the left, towards Josh.
    final y = size.height - 22;
    canvas.drawPath(
      Path()
        ..moveTo(10, y - 8)
        ..lineTo(0, y + 6)
        ..lineTo(14, y + 4)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(_BubblePainter old) => false;
}

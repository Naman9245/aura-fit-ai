import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/features/progress/progress_screen.dart';
import 'package:aurafit/features/progress/streak.dart';
import 'package:aurafit/services/coach_rules.dart';
import 'package:aurafit/widgets/josh.dart';
import 'package:flutter_test/flutter_test.dart';

WeightLogRow _weighIn(DateTime day, double kg) => WeightLogRow(
  dirty: false,
  id: '$day',
  day: day,
  weightKg: kg,
  createdAt: day,
  updatedAt: day,
);

void main() {
  final today = DateTime(2026, 11, 22);

  test('the streak counts days logged, never days to come', () {
    expect(streakDays({}, today), 0);
    expect(
      streakDays({
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 20),
        today,
        // A meal logged ahead, for tomorrow, doesn't count yet.
        DateTime(2026, 11, 23),
      }, today),
      3,
    );
  });

  test('Josh says how far his next stage is, and never resets', () {
    expect(streakTitle(0), 'DAY 1');
    expect(streakTitle(24), '24-DAY STREAK');
    expect(streakLine(0), startsWith('Log a meal and Josh starts growing'));
    expect(
      streakLine(6),
      'Josh is a cub. 1 more day logged and he gets going.',
    );
    expect(streakLine(7), 'Josh is getting going. 23 more days and he\'s fit.');
    expect(streakLine(30), 'Josh is fit. 30 more days to beast mode.');
    expect(streakLine(60), startsWith('Beast mode.'));
    expect(nextStageAt(59), 60);
    expect(nextStageAt(60), isNull);
  });

  test('Josh is never cross: calm when the day needs a second look', () {
    const fine = CalmFeedback(tone: CalmTone.neutral, message: '');
    const amber = CalmFeedback(tone: CalmTone.amber, message: '');
    JoshMood mood({
      CalmFeedback feedback = fine,
      bool isToday = true,
      int hour = 13,
      int meals = 2,
      double protein = 40,
    }) => todayMood(
      feedback: feedback,
      isToday: isToday,
      hour: hour,
      mealCount: meals,
      proteinEatenG: protein,
      proteinTargetG: 100,
    );

    expect(mood(), JoshMood.fired);
    expect(mood(meals: 0, protein: 0), JoshMood.happy);
    expect(mood(protein: 100), JoshMood.proud);
    expect(mood(feedback: amber), JoshMood.calm);
    expect(mood(isToday: false), JoshMood.calm);
    expect(mood(hour: 23), JoshMood.sleepy);
    expect(todayGreeting(isToday: true, hour: 9), 'GOOD MORNING');
    expect(todayGreeting(isToday: true, hour: 19), 'GOOD EVENING');
    expect(todayGreeting(isToday: false, hour: 9), 'YESTERDAY');
  });

  test('the weight trend averages each week, in plain words', () {
    final rows = [
      _weighIn(DateTime(2026, 11, 1), 66),
      _weighIn(DateTime(2026, 11, 5), 65),
      _weighIn(DateTime(2026, 11, 8), 64),
      _weighIn(DateTime(2026, 11, 20), 64.6),
    ];
    // 8 Nov's week runs from 2 Nov, so it holds 5 and 8 Nov.
    expect(sevenDayAverages(rows), [66, 65.5, 64.5, 64.6]);
    expect(weightChangeLine(rows), '1.4 kg down since 1 November');
    expect(
      weightChangeLine([rows.first, _weighIn(DateTime(2026, 11, 9), 66.3)]),
      '0.3 kg up since 1 November',
    );
    expect(
      weightChangeLine([rows.first, _weighIn(DateTime(2026, 11, 9), 66.02)]),
      'The same as on 1 November',
    );
    expect(weightChangeLine([rows.first]), startsWith('Your first weigh-in'));
  });
}

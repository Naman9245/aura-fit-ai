import 'package:aurafit/services/coach_rules.dart';
import 'package:aurafit/widgets/josh.dart';

// Josh's streak until workouts arrive: a day counts once a meal is logged
// on it. Missing a day only pauses the streak. It never resets, and Josh
// never shrinks.

/// The days logged up to and including [today].
int streakDays(Set<DateTime> loggedDays, DateTime today) =>
    loggedDays.where((day) => !day.isAfter(today)).length;

/// The streak Josh reaches his next stage at, or null in beast mode.
int? nextStageAt(int days) => switch (JoshStage.forStreak(days)) {
  JoshStage.cub => 7,
  JoshStage.gettingGoing => 30,
  JoshStage.fit => 60,
  JoshStage.beastMode => null,
};

/// The streak's headline, like "24-DAY STREAK".
String streakTitle(int days) => days == 0 ? 'DAY 1' : '$days-DAY STREAK';

/// What Josh says about his streak, and how far his next stage is.
String streakLine(int days) {
  final next = nextStageAt(days);
  final left = next == null ? 0 : next - days;
  final more = left == 1 ? '1 more day' : '$left more days';
  return switch (JoshStage.forStreak(days)) {
    _ when days == 0 =>
      'Log a meal and Josh starts growing. He gets fitter every week you '
          'keep at it.',
    JoshStage.cub => 'Josh is a cub. $more logged and he gets going.',
    JoshStage.gettingGoing => 'Josh is getting going. $more and he\'s fit.',
    JoshStage.fit => 'Josh is fit. $more to beast mode.',
    JoshStage.beastMode =>
      'Beast mode. Josh can\'t get any stronger, and he\'ll keep showing up '
          'with you.',
  };
}

/// Josh's mood on Today: never sad or cross, whatever the numbers say.
JoshMood todayMood({
  required CalmFeedback feedback,
  required bool isToday,
  required int hour,
  required int mealCount,
  required double proteinEatenG,
  required int proteinTargetG,
}) {
  if (!isToday || feedback.isAmber) return JoshMood.calm;
  if (hour >= 22) return JoshMood.sleepy;
  if (proteinTargetG > 0 && proteinEatenG.round() >= proteinTargetG) {
    return JoshMood.proud;
  }
  if (mealCount == 0) return JoshMood.happy;
  return JoshMood.fired;
}

/// Josh's hello on Today, by the time of day.
String todayGreeting({required bool isToday, required int hour}) {
  if (!isToday) return 'YESTERDAY';
  if (hour < 12) return 'GOOD MORNING';
  if (hour < 17) return 'GOOD AFTERNOON';
  return 'GOOD EVENING';
}

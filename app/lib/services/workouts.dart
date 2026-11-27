import 'package:aurafit/models/options.dart';
import 'package:flutter/foundation.dart';

// Workout plans worked out on the phone from simple, well-known rules
// (PRD T1-T3), never by AI: where you train (gym, dumbbells or home), how
// many days a week (3 to 6, Sunday always rest) and how long you've been
// training. Every exercise is a standard one, with a few plain cues.

/// One exercise, with how to do it.
@immutable
class Exercise {
  const Exercise(
    this.id,
    this.name,
    this.muscles,
    this.cues, {
    this.reps = (8, 12),
    this.seconds,
    this.weighted = false,
    this.eachSide = false,
    this.kgStep = 1,
  });

  final String id;
  final String name;

  /// What it works, for the screen: "Chest, shoulders, triceps".
  final String muscles;

  /// Two or three short how-to lines.
  final List<String> cues;

  /// The rep range to aim for, when it's counted in reps.
  final (int, int) reps;

  /// Held for this many seconds instead, like a plank.
  final int? seconds;

  /// Done with a weight, so its kilos are logged.
  final bool weighted;

  /// Reps or seconds are for each leg, arm or side.
  final bool eachSide;

  /// How much the weight goes up or down by: 2.5 kg on a barbell.
  final double kgStep;
}

Exercise _bw(
  String id,
  String name,
  String muscles,
  List<String> cues, {
  (int, int) reps = (8, 12),
  int? seconds,
  bool eachSide = false,
}) => Exercise(
  id,
  name,
  muscles,
  cues,
  reps: reps,
  seconds: seconds,
  eachSide: eachSide,
);

Exercise _kg(
  String id,
  String name,
  String muscles,
  List<String> cues, {
  (int, int) reps = (8, 12),
  bool eachSide = false,
  double kgStep = 1,
}) => Exercise(
  id,
  name,
  muscles,
  cues,
  reps: reps,
  weighted: true,
  eachSide: eachSide,
  kgStep: kgStep,
);

/// Every exercise the plans use, by id.
final Map<String, Exercise> exerciseLibrary = {
  for (final e in <Exercise>[
    // At home, no equipment.
    _bw(
      'chair_squat',
      'Chair Squat',
      'Legs, glutes',
      [
        'Stand in front of a chair, feet shoulder-width apart',
        'Sit back until you just touch the chair, chest up',
        'Push through your heels to stand',
      ],
      reps: (10, 15),
    ),
    _bw(
      'bw_squat',
      'Bodyweight Squat',
      'Legs, glutes',
      [
        'Feet shoulder-width apart, toes slightly out',
        'Sit back and down until thighs are level, chest up',
        'Push the floor away to stand',
      ],
      reps: (12, 20),
    ),
    _bw('reverse_lunge', 'Reverse Lunge', 'Legs, glutes', [
      'Step one foot back and lower until both knees bend to 90°',
      'Front knee stays over the ankle',
      'Push through the front heel to come back',
    ], eachSide: true),
    _bw('split_squat', 'Bulgarian Split Squat', 'Legs, glutes', [
      'Back foot on a chair or bed, front foot a stride ahead',
      'Lower straight down, torso tall',
      'Drive up through the front heel',
    ], eachSide: true),
    _bw(
      'glute_bridge',
      'Glute Bridge',
      'Glutes, hamstrings',
      [
        'Lie on your back, knees bent, feet flat',
        'Squeeze your glutes and lift your hips in a straight line',
        'Pause at the top, lower slowly',
      ],
      reps: (12, 20),
    ),
    _bw('single_leg_bridge', 'Single-Leg Glute Bridge', 'Glutes, hamstrings', [
      'Like a glute bridge, with one leg straight in the air',
      'Lift through the heel on the floor',
      'Keep the hips level',
    ], eachSide: true),
    _bw(
      'incline_pushup',
      'Incline Push-up',
      'Chest, shoulders, triceps',
      [
        'Hands on a bed, table or wall, a little wider than shoulders',
        'Body in one straight line, lower your chest to the edge',
        'Push back up without letting the hips sag',
      ],
      reps: (8, 15),
    ),
    _bw(
      'pushup',
      'Push-up',
      'Chest, shoulders, triceps',
      [
        'Hands under the shoulders, body in one straight line',
        'Lower until your chest is a fist from the floor',
        'Push up; on your knees if the last reps get hard',
      ],
      reps: (6, 15),
    ),
    _bw(
      'pike_pushup',
      'Pike Push-up',
      'Shoulders, triceps',
      [
        'Hips high in an upside-down V, hands shoulder-width',
        'Bend the elbows to bring your head towards the floor',
        'Push back up',
      ],
      reps: (5, 10),
    ),
    _bw(
      'superman',
      'Superman',
      'Lower back, glutes',
      [
        'Lie face down, arms forward',
        'Lift arms, chest and legs a little off the floor',
        'Hold for two seconds, lower slowly',
      ],
      reps: (10, 15),
    ),
    _bw(
      'reverse_snow_angel',
      'Reverse Snow Angel',
      'Upper back, shoulders',
      [
        'Lie face down, arms by your sides, lifted off the floor',
        'Sweep the arms overhead in a wide arc, and back',
        'Keep them off the floor the whole time',
      ],
      reps: (8, 12),
    ),
    _bw(
      'door_row',
      'Doorframe Row',
      'Back, biceps',
      [
        'Hold both sides of a sturdy doorframe, toes near the frame',
        'Lean back with straight arms, body in one line',
        'Pull your chest to the frame, then lower slowly',
      ],
      reps: (8, 15),
    ),
    _bw(
      'towel_curl',
      'Towel Curl',
      'Biceps',
      [
        'Stand on the middle of a towel, an end in each hand',
        'Curl the ends up while the foot holds the towel down',
        'Make it harder by pressing down harder with the foot',
      ],
      reps: (10, 15),
    ),
    _bw(
      'chair_dip',
      'Chair Dip',
      'Triceps, chest',
      [
        'Hands on the edge of a steady chair behind you',
        'Bend the elbows to lower, shoulders away from the ears',
        'Push back up; bend the knees to make it easier',
      ],
      reps: (8, 15),
    ),
    _bw('plank', 'Plank', 'Core', [
      'Elbows under shoulders, body in one straight line',
      'Squeeze the glutes and brace the stomach',
      'Breathe steadily',
    ], seconds: 30),
    _bw(
      'side_plank',
      'Side Plank',
      'Core, obliques',
      [
        'On one elbow, feet stacked, hips lifted',
        'Body in one straight line',
        'On the knees to make it easier',
      ],
      seconds: 20,
      eachSide: true,
    ),
    _bw('dead_bug', 'Dead Bug', 'Core', [
      'On your back, arms up, knees bent over the hips',
      'Lower the opposite arm and leg slowly, back pressed down',
      'Return, then the other side',
    ], eachSide: true),
    _bw('mountain_climber', 'Mountain Climbers', 'Core, cardio', [
      'Push-up position, hands under shoulders',
      'Drive the knees in turn towards the chest',
      'Keep the hips low and steady',
    ], seconds: 30),
    _bw(
      'calf_raise',
      'Calf Raise',
      'Calves',
      [
        'Balls of the feet on a step, hold something for balance',
        'Rise as high as you can',
        'Lower the heels below the step, slowly',
      ],
      reps: (15, 25),
    ),
    _bw('wall_sit', 'Wall Sit', 'Legs', [
      'Back flat on a wall, slide down until knees are at 90°',
      'Feet flat, knees over ankles',
      'Hold and breathe',
    ], seconds: 30),

    // With dumbbells.
    _kg('goblet_squat', 'Goblet Squat', 'Legs, glutes', [
      'Hold one dumbbell at the chest, elbows down',
      'Sit down between the heels, chest up',
      'Drive up through the whole foot',
    ]),
    _kg('db_rdl', 'Dumbbell Romanian Deadlift', 'Hamstrings, glutes', [
      'Dumbbells in front of the thighs, knees soft',
      'Push the hips back, sliding the weights down the legs',
      'Stop when you feel the hamstrings stretch, then stand tall',
    ]),
    _kg('db_split_squat', 'Dumbbell Split Squat', 'Legs, glutes', [
      'A dumbbell in each hand, one foot a stride ahead',
      'Lower straight down until the back knee nearly touches',
      'Drive up through the front heel',
    ], eachSide: true),
    _kg('db_floor_press', 'Dumbbell Floor Press', 'Chest, triceps', [
      'Lie on the floor or a bench, dumbbells over the chest',
      'Lower until the upper arms touch the floor',
      'Press back up, wrists straight',
    ]),
    _kg('db_ohp', 'Dumbbell Shoulder Press', 'Shoulders, triceps', [
      'Dumbbells at shoulder height, palms forward',
      'Press overhead without arching the back',
      'Lower with control',
    ]),
    _kg('db_row', 'One-Arm Dumbbell Row', 'Back, biceps', [
      'One hand and knee on a bench or chair, back flat',
      'Pull the dumbbell to the hip',
      'Lower it all the way, slowly',
    ], eachSide: true),
    _kg(
      'db_pullover',
      'Dumbbell Pullover',
      'Back, chest',
      [
        'Lie on a bench or floor, one dumbbell held over the chest',
        'Lower it behind the head with arms slightly bent',
        'Pull it back over the chest',
      ],
      reps: (10, 12),
    ),
    _kg(
      'db_curl',
      'Dumbbell Curl',
      'Biceps',
      [
        'Elbows at your sides',
        'Curl the weights up, palms facing up',
        'Lower slowly, no swinging',
      ],
      reps: (10, 15),
    ),
    _kg(
      'db_hammer_curl',
      'Hammer Curl',
      'Biceps, forearms',
      [
        'Palms facing each other',
        'Curl up keeping the elbows still',
        'Lower slowly',
      ],
      reps: (10, 15),
    ),
    _kg(
      'db_oh_extension',
      'Overhead Triceps Extension',
      'Triceps',
      [
        'Hold one dumbbell overhead with both hands',
        'Lower it behind the head, elbows pointing up',
        'Straighten the arms',
      ],
      reps: (10, 15),
    ),
    _kg(
      'db_lateral_raise',
      'Lateral Raise',
      'Shoulders',
      [
        'Dumbbells at the sides, elbows slightly bent',
        'Raise them out to shoulder height',
        'Lower slowly; light weights are enough',
      ],
      reps: (12, 15),
    ),
    _kg(
      'db_reverse_fly',
      'Bent-Over Reverse Fly',
      'Upper back, rear shoulders',
      [
        'Hinge forward with a flat back, dumbbells hanging',
        'Raise them out to the sides, squeezing the shoulder blades',
        'Lower slowly',
      ],
      reps: (12, 15),
    ),
    _kg(
      'db_calf_raise',
      'Dumbbell Calf Raise',
      'Calves',
      [
        'A dumbbell in each hand, balls of the feet on a step',
        'Rise high, pause',
        'Lower the heels below the step',
      ],
      reps: (12, 20),
    ),

    // At the gym.
    _kg(
      'leg_press',
      'Leg Press',
      'Legs, glutes',
      [
        'Feet shoulder-width on the plate',
        'Lower until the knees are at about 90°',
        'Press up without locking the knees',
      ],
      reps: (10, 12),
      kgStep: 5,
    ),
    _kg(
      'back_squat',
      'Barbell Back Squat',
      'Legs, glutes, core',
      [
        'Bar on the upper back, feet shoulder-width',
        'Brace, then sit down until thighs are level',
        'Drive up, knees in line with the toes',
      ],
      reps: (6, 10),
      kgStep: 2.5,
    ),
    _kg(
      'rdl',
      'Barbell Romanian Deadlift',
      'Hamstrings, glutes, back',
      [
        'Bar at the hips, knees soft, back flat',
        'Push the hips back, bar close to the legs',
        'Stand tall by squeezing the glutes',
      ],
      reps: (8, 10),
      kgStep: 2.5,
    ),
    _kg(
      'walking_lunge',
      'Walking Lunge',
      'Legs, glutes',
      [
        'A dumbbell in each hand',
        'Step forward and lower the back knee towards the floor',
        'Drive up and step through',
      ],
      reps: (10, 12),
      eachSide: true,
    ),
    _kg(
      'machine_chest_press',
      'Machine Chest Press',
      'Chest, triceps',
      [
        'Handles at mid-chest, back against the pad',
        'Press out until the arms are nearly straight',
        'Return slowly',
      ],
      reps: (10, 12),
      kgStep: 2.5,
    ),
    _kg(
      'bench_press',
      'Barbell Bench Press',
      'Chest, shoulders, triceps',
      [
        'Eyes under the bar, feet flat, shoulder blades squeezed',
        'Lower the bar to the middle of the chest',
        'Press up; use a spotter or safety pins',
      ],
      reps: (6, 10),
      kgStep: 2.5,
    ),
    _kg(
      'incline_db_press',
      'Incline Dumbbell Press',
      'Upper chest, shoulders',
      [
        'Bench at about 30°, dumbbells at the chest',
        'Press up and slightly in',
        'Lower with control',
      ],
    ),
    _kg(
      'seated_db_press',
      'Seated Dumbbell Shoulder Press',
      'Shoulders, triceps',
      [
        'Back against an upright bench',
        'Press the dumbbells overhead',
        'Lower to shoulder height',
      ],
    ),
    _kg(
      'lat_pulldown',
      'Lat Pulldown',
      'Back, biceps',
      [
        'Grip a little wider than shoulders, thighs under the pad',
        'Pull the bar to the upper chest, chest up',
        'Let it rise slowly',
      ],
      reps: (8, 12),
      kgStep: 2.5,
    ),
    _bw(
      'pull_up',
      'Pull-up',
      'Back, biceps',
      [
        'Hang with hands shoulder-width, palms away',
        'Pull until the chin clears the bar',
        'Use the assisted machine or a band if needed',
      ],
      reps: (5, 10),
    ),
    _kg(
      'cable_row',
      'Seated Cable Row',
      'Back, biceps',
      [
        'Sit tall, feet on the platform, knees soft',
        'Pull the handle to the stomach, shoulder blades together',
        'Let the arms straighten slowly',
      ],
      reps: (8, 12),
      kgStep: 2.5,
    ),
    _kg(
      'ez_curl',
      'EZ-Bar Curl',
      'Biceps',
      [
        'Hold the angled grips, elbows at your sides',
        'Curl up without swinging',
        'Lower slowly',
      ],
      reps: (10, 12),
      kgStep: 2.5,
    ),
    _kg(
      'triceps_pushdown',
      'Cable Triceps Pushdown',
      'Triceps',
      [
        'Elbows pinned to your sides',
        'Push the bar or rope down until the arms are straight',
        'Let it come up to about chest height',
      ],
      reps: (10, 15),
      kgStep: 2.5,
    ),
    _kg(
      'face_pull',
      'Face Pull',
      'Rear shoulders, upper back',
      [
        'Rope at face height',
        'Pull towards the eyes, elbows high and wide',
        'Squeeze, then return slowly',
      ],
      reps: (12, 15),
      kgStep: 2.5,
    ),
    _kg(
      'leg_curl',
      'Leg Curl',
      'Hamstrings',
      [
        'Pad just above the heels',
        'Curl the heels towards you',
        'Lower slowly',
      ],
      reps: (10, 15),
      kgStep: 2.5,
    ),
    _kg(
      'leg_extension',
      'Leg Extension',
      'Quads',
      [
        'Pad on the front of the ankles',
        'Straighten the legs, pause',
        'Lower slowly',
      ],
      reps: (10, 15),
      kgStep: 2.5,
    ),
    _kg(
      'calf_machine',
      'Standing Calf Raise',
      'Calves',
      [
        'Shoulders under the pads, balls of the feet on the edge',
        'Rise high, pause',
        'Lower the heels fully',
      ],
      reps: (10, 15),
      kgStep: 2.5,
    ),
    _kg(
      'cable_crunch',
      'Cable Crunch',
      'Core',
      [
        'Kneel facing the cable, rope by your head',
        'Curl down, ribs towards hips',
        'Return slowly',
      ],
      reps: (10, 15),
      kgStep: 2.5,
    ),
  ])
    e.id: e,
};

/// The kinds of movement a workout is built from.
enum Move {
  squat,
  hinge,
  lunge,
  push,
  overheadPush,
  pull,
  pullDown,
  biceps,
  triceps,
  shoulders,
  rearShoulders,
  hamstrings,
  quads,
  calves,
  core,
  conditioning,
}

/// For each place, the exercise for each move: the easier one for people
/// new to training, then the one for everyone else. A move missing for a
/// place is left out of its workouts.
const Map<TrainingPlace, Map<Move, (String, String)>> _moves = {
  TrainingPlace.home: {
    Move.squat: ('chair_squat', 'bw_squat'),
    Move.hinge: ('glute_bridge', 'single_leg_bridge'),
    Move.lunge: ('reverse_lunge', 'split_squat'),
    Move.push: ('incline_pushup', 'pushup'),
    Move.overheadPush: ('pike_pushup', 'pike_pushup'),
    Move.pull: ('door_row', 'door_row'),
    Move.pullDown: ('reverse_snow_angel', 'reverse_snow_angel'),
    Move.rearShoulders: ('superman', 'superman'),
    Move.biceps: ('towel_curl', 'towel_curl'),
    Move.triceps: ('chair_dip', 'chair_dip'),
    Move.quads: ('wall_sit', 'wall_sit'),
    Move.calves: ('calf_raise', 'calf_raise'),
    Move.core: ('dead_bug', 'plank'),
    Move.conditioning: ('mountain_climber', 'mountain_climber'),
  },
  TrainingPlace.dumbbells: {
    Move.squat: ('goblet_squat', 'goblet_squat'),
    Move.hinge: ('db_rdl', 'db_rdl'),
    Move.lunge: ('reverse_lunge', 'db_split_squat'),
    Move.push: ('db_floor_press', 'db_floor_press'),
    Move.overheadPush: ('db_ohp', 'db_ohp'),
    Move.pull: ('db_row', 'db_row'),
    Move.pullDown: ('db_pullover', 'db_pullover'),
    Move.biceps: ('db_curl', 'db_hammer_curl'),
    Move.triceps: ('db_oh_extension', 'db_oh_extension'),
    Move.shoulders: ('db_lateral_raise', 'db_lateral_raise'),
    Move.rearShoulders: ('db_reverse_fly', 'db_reverse_fly'),
    Move.hamstrings: ('glute_bridge', 'single_leg_bridge'),
    Move.calves: ('db_calf_raise', 'db_calf_raise'),
    Move.core: ('dead_bug', 'plank'),
  },
  TrainingPlace.gym: {
    Move.squat: ('leg_press', 'back_squat'),
    Move.hinge: ('rdl', 'rdl'),
    Move.lunge: ('walking_lunge', 'walking_lunge'),
    Move.push: ('machine_chest_press', 'bench_press'),
    Move.overheadPush: ('seated_db_press', 'seated_db_press'),
    Move.pull: ('cable_row', 'cable_row'),
    Move.pullDown: ('lat_pulldown', 'pull_up'),
    Move.biceps: ('ez_curl', 'ez_curl'),
    Move.triceps: ('triceps_pushdown', 'triceps_pushdown'),
    Move.shoulders: ('db_lateral_raise', 'db_lateral_raise'),
    Move.rearShoulders: ('face_pull', 'face_pull'),
    Move.hamstrings: ('leg_curl', 'leg_curl'),
    Move.quads: ('leg_extension', 'leg_extension'),
    Move.calves: ('calf_machine', 'calf_machine'),
    Move.core: ('plank', 'cable_crunch'),
  },
};

/// The workouts plans are made of: a key, a title and its moves in order.
/// Big moves come first, while you're fresh.
const Map<String, (String, List<Move>)> _templates = {
  'full_a': (
    'FULL BODY A',
    [Move.squat, Move.push, Move.pull, Move.hinge, Move.shoulders, Move.core],
  ),
  'full_b': (
    'FULL BODY B',
    [
      Move.lunge,
      Move.overheadPush,
      Move.pullDown,
      Move.hinge,
      Move.triceps,
      Move.core,
    ],
  ),
  'full_c': (
    'FULL BODY C',
    [
      Move.squat,
      Move.push,
      Move.pull,
      Move.lunge,
      Move.biceps,
      Move.calves,
      Move.conditioning,
    ],
  ),
  'upper_a': (
    'UPPER BODY A',
    [
      Move.push,
      Move.pull,
      Move.overheadPush,
      Move.pullDown,
      Move.biceps,
      Move.triceps,
    ],
  ),
  'upper_b': (
    'UPPER BODY B',
    [
      Move.overheadPush,
      Move.pullDown,
      Move.push,
      Move.pull,
      Move.shoulders,
      Move.rearShoulders,
    ],
  ),
  'lower_a': (
    'LOWER BODY A',
    [Move.squat, Move.hinge, Move.lunge, Move.quads, Move.calves, Move.core],
  ),
  'lower_b': (
    'LOWER BODY B',
    [
      Move.hinge,
      Move.squat,
      Move.lunge,
      Move.hamstrings,
      Move.calves,
      Move.core,
    ],
  ),
  'push': (
    'PUSH DAY',
    [Move.push, Move.overheadPush, Move.shoulders, Move.triceps, Move.core],
  ),
  'pull': (
    'PULL DAY',
    [Move.pullDown, Move.pull, Move.rearShoulders, Move.biceps, Move.core],
  ),
  'legs': (
    'LEG DAY',
    [
      Move.squat,
      Move.hinge,
      Move.lunge,
      Move.hamstrings,
      Move.quads,
      Move.calves,
    ],
  ),
};

/// The moves that work several joints at once: the big lifts.
const _compound = {
  Move.squat,
  Move.hinge,
  Move.lunge,
  Move.push,
  Move.overheadPush,
  Move.pull,
  Move.pullDown,
};

/// Which workout falls on which weekday (1 = Monday), by days a week.
/// Sunday (7) is never in it.
const Map<int, Map<int, String>> _weeks = {
  3: {1: 'full_a', 3: 'full_b', 5: 'full_c'},
  4: {1: 'upper_a', 2: 'lower_a', 4: 'upper_b', 5: 'lower_b'},
  5: {1: 'push', 2: 'pull', 3: 'legs', 4: 'upper_b', 5: 'lower_b'},
  6: {1: 'push', 2: 'pull', 3: 'legs', 4: 'push', 5: 'pull', 6: 'legs'},
};

/// Days a week to start from, by experience.
int suggestedDays(Experience? experience) => switch (experience) {
  Experience.advanced => 5,
  Experience.intermediate => 4,
  _ => 3,
};

/// One exercise in a workout, with what to aim for.
@immutable
class PlannedExercise {
  const PlannedExercise({
    required this.exercise,
    required this.sets,
    required this.restSeconds,
  });

  final Exercise exercise;
  final int sets;
  final int restSeconds;

  /// "3 × 8-12", "3 × 30 s", "3 × 10-12 each leg".
  String get target {
    final e = exercise;
    final side = e.eachSide ? ' each side' : '';
    final amount = switch (e.seconds) {
      final s? => '$s s',
      null => '${e.reps.$1}-${e.reps.$2}',
    };
    return '$sets × $amount$side';
  }
}

/// A day's workout.
@immutable
class PlannedWorkout {
  const PlannedWorkout({
    required this.key,
    required this.title,
    required this.exercises,
  });

  final String key;
  final String title;
  final List<PlannedExercise> exercises;

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets);

  /// About how long it takes, with warm-up: each set's work and rest.
  int get minutes {
    var seconds = 5 * 60;
    for (final e in exercises) {
      final work = (e.exercise.seconds ?? 40) * (e.exercise.eachSide ? 2 : 1);
      seconds += e.sets * (work + e.restSeconds);
    }
    return (seconds / 60 / 5).round() * 5;
  }
}

/// What a day of the week holds.
sealed class PlanDay {
  const PlanDay();
}

class TrainingDay extends PlanDay {
  const TrainingDay(this.workout, {required this.number, required this.of});

  final PlannedWorkout workout;

  /// The [number]-th training day of [of] this week.
  final int number;
  final int of;
}

/// Sunday: real rest.
class RestDay extends PlanDay {
  const RestDay();
}

/// Another day off: a walk and a stretch.
class ActiveRestDay extends PlanDay {
  const ActiveRestDay();
}

/// A week of training for a [place], [days] a week and [experience].
@immutable
class TrainingPlan {
  const TrainingPlan({
    required this.place,
    required this.days,
    required this.experience,
  });

  final TrainingPlace place;
  final int days;
  final Experience? experience;

  bool get _easier => experience == null || experience == Experience.beginner;

  /// What [weekday] (1 = Monday, 7 = Sunday) holds.
  PlanDay dayOf(int weekday) {
    if (weekday == DateTime.sunday) return const RestDay();
    final week = _weeks[days.clamp(3, 6)]!;
    final key = week[weekday];
    if (key == null) return const ActiveRestDay();
    final order = week.keys.toList()..sort();
    return TrainingDay(
      workout(key),
      number: order.indexOf(weekday) + 1,
      of: order.length,
    );
  }

  /// The workout for a template [key], with this plan's exercises, sets
  /// and rest.
  PlannedWorkout workout(String key) {
    final (title, moves) = _templates[key]!;
    final used = <String>{};
    final exercises = <PlannedExercise>[];
    for (final move in moves) {
      final pick = _moves[place]![move];
      if (pick == null) continue;
      final id = _easier ? pick.$1 : pick.$2;
      if (!used.add(id)) continue;
      final exercise = exerciseLibrary[id]!;
      // Big lifts that move several joints get more sets and longer rests.
      final big = _compound.contains(move) && exercise.seconds == null;
      final sets = switch (experience) {
        Experience.advanced => big ? 4 : 3,
        Experience.intermediate => 3,
        _ => big ? 3 : 2,
      };
      exercises.add(
        PlannedExercise(
          exercise: exercise,
          sets: sets,
          restSeconds: big ? 90 : 60,
        ),
      );
    }
    return PlannedWorkout(key: key, title: title, exercises: exercises);
  }
}

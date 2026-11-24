import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/profile_repository.dart';
import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/targets.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The questions, one screen each, in order.
enum OnboardingStep {
  goal,
  birthDate,
  sex,
  body,
  activity,
  diet(optional: true),
  training(optional: true);

  const OnboardingStep({this.optional = false});

  /// Whether the person can skip it.
  final bool optional;
}

/// The youngest age AURA is for. India's DPDP Act needs a parent's
/// consent for anyone younger, and the app doesn't ask for it.
const minAge = 18;
const maxAge = 100;
const minHeightCm = 120.0;
const maxHeightCm = 230.0;
const minWeightKg = 30.0;
const maxWeightKg = 250.0;

/// What onboarding has collected so far.
@immutable
class OnboardingDraft {
  const OnboardingDraft({
    this.step = OnboardingStep.goal,
    this.goal,
    this.birthDate,
    this.sexAnswered = false,
    this.sex,
    this.heightCm,
    this.weightKg,
    this.activity,
    this.diet,
    this.trainingPlace,
    this.experience,
  });

  final OnboardingStep step;
  final GoalType? goal;
  final DateTime? birthDate;

  /// Whether the sex question has an answer; "I'd rather not say" is one,
  /// and leaves [sex] null.
  final bool sexAnswered;
  final Sex? sex;
  final double? heightCm;
  final double? weightKg;
  final ActivityLevel? activity;
  final DietType? diet;
  final TrainingPlace? trainingPlace;
  final Experience? experience;

  /// Whether [step] has what it needs to move on.
  bool isAnswered(OnboardingStep step) => switch (step) {
    OnboardingStep.goal => goal != null,
    OnboardingStep.birthDate => birthDate != null,
    OnboardingStep.sex => sexAnswered,
    OnboardingStep.body => heightCm != null && weightKg != null,
    OnboardingStep.activity => activity != null,
    OnboardingStep.diet => diet != null,
    OnboardingStep.training => trainingPlace != null || experience != null,
  };

  /// Whether the main button can move on from [step]. An optional step
  /// never holds it back: editing details someone skipped the first time
  /// must still save without a hunt for "Skip".
  bool canContinue(OnboardingStep step) => step.optional || isAnswered(step);

  /// All the answers, once every required question has one.
  ProfileAnswers? toAnswers() {
    final goal = this.goal;
    final birthDate = this.birthDate;
    final heightCm = this.heightCm;
    final weightKg = this.weightKg;
    final activity = this.activity;
    if (goal == null ||
        birthDate == null ||
        !sexAnswered ||
        heightCm == null ||
        weightKg == null ||
        activity == null) {
      return null;
    }
    return ProfileAnswers(
      goal: goal,
      birthDate: birthDate,
      sex: sex,
      heightCm: heightCm,
      weightKg: weightKg,
      activity: activity,
      diet: diet,
      trainingPlace: trainingPlace,
      experience: experience,
    );
  }

  /// A copy with some answers changed. Answers that can be cleared take a
  /// function, so passing one that returns null clears it.
  OnboardingDraft copyWith({
    OnboardingStep? step,
    GoalType? goal,
    ValueGetter<DateTime?>? birthDate,
    bool? sexAnswered,
    ValueGetter<Sex?>? sex,
    ValueGetter<double?>? heightCm,
    ValueGetter<double?>? weightKg,
    ActivityLevel? activity,
    ValueGetter<DietType?>? diet,
    ValueGetter<TrainingPlace?>? trainingPlace,
    ValueGetter<Experience?>? experience,
  }) => OnboardingDraft(
    step: step ?? this.step,
    goal: goal ?? this.goal,
    birthDate: birthDate != null ? birthDate() : this.birthDate,
    sexAnswered: sexAnswered ?? this.sexAnswered,
    sex: sex != null ? sex() : this.sex,
    heightCm: heightCm != null ? heightCm() : this.heightCm,
    weightKg: weightKg != null ? weightKg() : this.weightKg,
    activity: activity ?? this.activity,
    diet: diet != null ? diet() : this.diet,
    trainingPlace: trainingPlace != null ? trainingPlace() : this.trainingPlace,
    experience: experience != null ? experience() : this.experience,
  );
}

/// Why a birth date can't be used, or null when it can.
String? birthDateProblem(DateTime date) {
  final now = clock.now();
  final age = ageOn(date, DateTime(now.year, now.month, now.day));
  if (age < 0 || date.year < 1900) return 'Check the year';
  if (age < minAge) return 'AURA is for adults, $minAge and over';
  if (age > maxAge) return 'Check the year: that would make you $age';
  return null;
}

/// Holds the answers while someone goes through onboarding, or edits them.
class OnboardingController extends Notifier<OnboardingDraft> {
  @override
  OnboardingDraft build() => const OnboardingDraft();

  /// Starts from what's saved, to edit it.
  void startFrom(ProfileRow profile, WeightLogRow? weight, GoalRow? goal) {
    state = OnboardingDraft(
      goal: goal?.goalType,
      birthDate: profile.birthDate,
      sexAnswered: true,
      sex: profile.sex,
      heightCm: profile.heightCm,
      weightKg: weight?.weightKg ?? goal?.basisWeightKg,
      activity: profile.activityLevel,
      diet: profile.dietType,
      trainingPlace: profile.trainingPlace,
      experience: profile.experience,
    );
  }

  void chooseGoal(GoalType goal) => state = state.copyWith(goal: goal);

  void setBirthDate(DateTime? date) =>
      state = state.copyWith(birthDate: () => date);

  void chooseSex(Sex? sex) =>
      state = state.copyWith(sexAnswered: true, sex: () => sex);

  void setHeight(double? cm) => state = state.copyWith(heightCm: () => cm);

  void setWeight(double? kg) => state = state.copyWith(weightKg: () => kg);

  void chooseActivity(ActivityLevel activity) =>
      state = state.copyWith(activity: activity);

  void chooseDiet(DietType diet) => state = state.copyWith(diet: () => diet);

  void chooseTrainingPlace(TrainingPlace place) =>
      state = state.copyWith(trainingPlace: () => place);

  void chooseExperience(Experience experience) =>
      state = state.copyWith(experience: () => experience);

  /// Skips an optional step, clearing anything picked on it, and moves on.
  /// Returns false on the last step, where there's nowhere to move to.
  bool skip() {
    state = switch (state.step) {
      OnboardingStep.diet => state.copyWith(diet: () => null),
      OnboardingStep.training => state.copyWith(
        trainingPlace: () => null,
        experience: () => null,
      ),
      _ => throw StateError('${state.step} can\'t be skipped'),
    };
    return next();
  }

  /// Moves on a step. Returns false on the last one.
  bool next() {
    final index = state.step.index;
    if (index == OnboardingStep.values.length - 1) return false;
    state = state.copyWith(step: OnboardingStep.values[index + 1]);
    return true;
  }

  /// Goes back a step. Returns false on the first one.
  bool back() {
    final index = state.step.index;
    if (index == 0) return false;
    state = state.copyWith(step: OnboardingStep.values[index - 1]);
    return true;
  }
}

final onboardingProvider =
    NotifierProvider.autoDispose<OnboardingController, OnboardingDraft>(
      OnboardingController.new,
    );

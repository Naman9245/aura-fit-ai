import 'package:aurafit/core/error_reporter.dart';
import 'package:aurafit/data/log_repository.dart';
import 'package:aurafit/data/providers.dart';
import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the phone can count steps, and whether it's allowed to.
@immutable
class StepStatus {
  const StepStatus({required this.available, required this.allowed});

  static const none = StepStatus(available: false, allowed: false);

  /// The phone has a step sensor.
  final bool available;

  /// The person allowed "Physical activity".
  final bool allowed;

  bool get counting => available && allowed;
}

/// The phone's own step sensor (StepCounter.kt on Android).
abstract class StepCounter {
  Future<StepStatus> status();

  /// Asks to use it. True once allowed.
  Future<bool> requestPermission();

  /// Starts the readings every 15 minutes, even with the app closed.
  Future<void> start();

  /// Steps between [from] and [to], or null if the sensor didn't answer.
  Future<int?> stepsBetween(DateTime from, DateTime to);
}

class PhoneStepCounter implements StepCounter {
  const PhoneStepCounter();

  static const _channel = MethodChannel('com.naman9245.aurafit/steps');

  @override
  Future<StepStatus> status() async {
    try {
      final status = await _channel.invokeMapMethod<String, Object?>('status');
      return StepStatus(
        available: status?['available'] == true,
        allowed: status?['allowed'] == true,
      );
    } on MissingPluginException {
      // Not on Android: there's nothing to count with.
      return StepStatus.none;
    }
  }

  @override
  Future<bool> requestPermission() async =>
      await _channel.invokeMethod<bool>('requestPermission') ?? false;

  @override
  Future<void> start() => _channel.invokeMethod<bool>('start');

  @override
  Future<int?> stepsBetween(DateTime from, DateTime to) async {
    final steps = await _channel.invokeMethod<int>('stepsBetween', {
      'start': from.millisecondsSinceEpoch,
      'end': to.millisecondsSinceEpoch,
    });
    return steps;
  }
}

final stepCounterProvider = Provider<StepCounter>(
  (ref) => const PhoneStepCounter(),
);

/// Whether steps are counted by the phone, checked again after asking.
final stepStatusProvider = FutureProvider<StepStatus>(
  (ref) => ref.watch(stepCounterProvider).status(),
);

/// Brings today's and yesterday's phone-counted steps into the diary. Never
/// lowers steps typed in by hand. Does nothing until allowed.
Future<void> syncPhoneSteps(Ref ref) async {
  try {
    final counter = ref.read(stepCounterProvider);
    final status = await counter.status();
    if (!status.counting) return;
    await counter.start();
    final now = clock.now();
    final today = diaryDay(now);
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final log = ref.read(logRepositoryProvider);
    // Yesterday's count is final once today starts; then today's so far.
    final before = await counter.stepsBetween(yesterday, today);
    if (before != null) {
      await log.savePhoneSteps(day: yesterday, steps: before);
    }
    final sofar = await counter.stepsBetween(today, now);
    if (sofar != null) await log.savePhoneSteps(day: today, steps: sofar);
  } catch (error, stack) {
    reportAuraError(error, stack, where: 'steps.sync');
  }
}

/// Keeps the phone's steps coming in: when the app opens and whenever it
/// comes back to the front.
final phoneStepsProvider = Provider<void>((ref) {
  syncPhoneSteps(ref).ignore();
  final listener = AppLifecycleListener(
    onResume: () => syncPhoneSteps(ref).ignore(),
  );
  ref.onDispose(listener.dispose);
});

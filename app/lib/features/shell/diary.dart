import 'dart:async';

import 'package:aurafit/core/router.dart';
import 'package:aurafit/data/log_repository.dart';
import 'package:aurafit/features/nutrition/log_meal_screen.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Whether Today and Food show yesterday. One switch for both tabs, so a
/// meal logged on Food lands on the day Today shows.
final viewingYesterdayProvider = NotifierProvider<ViewingYesterday, bool>(
  ViewingYesterday.new,
);

class ViewingYesterday extends Notifier<bool> {
  @override
  bool build() => false;

  void show({required bool yesterday}) => state = yesterday;
}

/// The diary day on show: today, or yesterday when [yesterday].
DateTime viewedDay({required bool yesterday}) {
  final today = diaryDay(clock.now());
  return yesterday ? DateTime(today.year, today.month, today.day - 1) : today;
}

/// Yesterday or Today, for Today and Food together.
class DaySwitch extends ConsumerWidget {
  const DaySwitch({super.key, required this.isToday});

  final bool isToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<bool>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: true, label: Text('Yesterday')),
        ButtonSegment(value: false, label: Text('Today')),
      ],
      selected: {!isToday},
      onSelectionChanged: (choice) => ref
          .read(viewingYesterdayProvider.notifier)
          .show(yesterday: choice.first),
    );
  }
}

/// Says what was just done, with a one-tap Undo (PRD N11).
void showUndo(BuildContext context, UndoAction action) =>
    _showUndoOn(ScaffoldMessenger.of(context), action);

void _showUndoOn(ScaffoldMessengerState messenger, UndoAction action) {
  // A small tap in the hand for every log, as well as the bar.
  HapticFeedback.lightImpact().ignore();
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(action.message),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => unawaited(action.undo()),
        ),
      ),
    );
}

/// Opens the meal logger, and offers Undo for whatever it saved. True when
/// something was saved.
Future<bool> openMealLogger(BuildContext context, LogMealArgs args) async {
  final messenger = ScaffoldMessenger.of(context);
  final result = await context.push<UndoAction>(Routes.logMeal, extra: args);
  if (result == null) return false;
  _showUndoOn(messenger, result);
  return true;
}

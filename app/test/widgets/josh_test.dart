import 'package:aurafit/widgets/josh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _frame(Widget child, {bool still = true}) => MediaQuery(
  data: MediaQueryData(disableAnimations: still),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: child),
  ),
);

void main() {
  test('Josh grows at 7, 30 and 60 days of streak', () {
    expect(JoshStage.forStreak(0), JoshStage.cub);
    expect(JoshStage.forStreak(6), JoshStage.cub);
    expect(JoshStage.forStreak(7), JoshStage.gettingGoing);
    expect(JoshStage.forStreak(29), JoshStage.gettingGoing);
    expect(JoshStage.forStreak(30), JoshStage.fit);
    expect(JoshStage.forStreak(59), JoshStage.fit);
    expect(JoshStage.forStreak(60), JoshStage.beastMode);
    expect(JoshStage.forStreak(400), JoshStage.beastMode);
  });

  testWidgets('every stage and mood draws, and says what it shows', (
    tester,
  ) async {
    for (final stage in JoshStage.values) {
      for (final mood in JoshMood.values) {
        await tester.pumpWidget(
          _frame(Josh(mood: mood, stage: stage, width: 120)),
        );
        expect(tester.takeException(), isNull);
        expect(find.bySemanticsLabel(joshLabel(mood, stage)), findsOneWidget);
      }
    }
    expect(
      joshLabel(JoshMood.fired, JoshStage.beastMode),
      'Josh the bear, in beast mode, with fire in his eyes, lifting a '
      'dumbbell',
    );
  });

  testWidgets('he stands still when the phone asks for less motion', (
    tester,
  ) async {
    await tester.pumpWidget(_frame(const Josh(mood: JoshMood.happy)));
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(
      _frame(const Josh(mood: JoshMood.happy), still: false),
    );
    expect(tester.hasRunningAnimations, isTrue);
    // Leave him still again so the test ends with nothing ticking.
    await tester.pumpWidget(_frame(const Josh(mood: JoshMood.happy)));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('on a tab he moves for a while, rests, and wakes when tapped', (
    tester,
  ) async {
    Widget josh(JoshMood mood) => _frame(
      Josh(mood: mood, playFor: const Duration(seconds: 2)),
      still: false,
    );
    await tester.pumpWidget(josh(JoshMood.happy));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(const Duration(milliseconds: 2100));
    expect(tester.hasRunningAnimations, isFalse);

    await tester.tap(find.byType(Josh));
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);

    // A new mood, like reaching the protein target, wakes him too.
    await tester.pumpWidget(josh(JoshMood.proud));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets('his height follows his width', (tester) async {
    await tester.pumpWidget(
      _frame(const Josh(mood: JoshMood.calm, width: 100)),
    );
    final size = tester.getSize(find.byType(CustomPaint).last);
    expect(size.width, 100);
    expect(size.height, closeTo(115, 0.001));
  });
}

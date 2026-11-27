import 'package:aurafit/widgets/motion.dart';
import 'package:aurafit/widgets/portion_wheel_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _frame(Widget child, {bool still = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: still),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: child),
  ),
);

void main() {
  testWidgets('numbers count up, and stand still with less motion', (
    tester,
  ) async {
    Widget count(double value, {bool still = false}) => _frame(
      CountUp(value: value, format: (v) => '${v.round()} kcal'),
      still: still,
    );
    await tester.pumpWidget(count(600));
    expect(find.text('0 kcal'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('600 kcal'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('600 kcal'), findsOneWidget);

    // A new value counts on from the last one.
    await tester.pumpWidget(count(700));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('0 kcal'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('700 kcal'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(count(450, still: true));
    expect(find.text('450 kcal'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('cards rise in once, and taps still reach them', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _frame(
        Entrance(
          index: 2,
          child: Pressable(
            child: TextButton(
              onPressed: () => taps++,
              child: const Text('Tap'),
            ),
          ),
        ),
      ),
    );
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tap'));
    await tester.pumpAndSettle();
    expect(taps, 1);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      _frame(const Entrance(index: 2, child: Text('Still')), still: true),
    );
    expect(tester.hasRunningAnimations, isFalse);
  });

  test('amounts read naturally', () {
    expect(portionLabel(1, 'katori'), '1 katori');
    expect(portionLabel(2, 'katori'), '2 katori');
    expect(portionLabel(2, 'piece'), '2 pieces');
    expect(portionLabel(2, 'egg + gravy'), '2 eggs + gravy');
    expect(portionLabel(3, 'potato + gravy'), '3 potatoes + gravy');
    expect(portionLabel(2, 'omelette (2 eggs)'), '2 omelettes (2 eggs)');
    expect(portionLabel(2, 'glass'), '2 glasses');
    expect(portionLabel(1.5, 'medium'), '1.5 medium');
    expect(portionLabel(150, 'g'), '150 g');
  });
}

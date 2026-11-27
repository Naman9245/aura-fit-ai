import 'package:aurafit/core/router.dart';
import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:aurafit/core/theme/aura_type.dart';
import 'package:aurafit/widgets/josh.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The first thing a new person sees: Josh says hello, shows what AURA does
/// in three screens, then hands over to the onboarding questions. He grows
/// from a cub to beast mode along the way, as he will with their streak.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, this.replay = false});

  /// Opened again from the account sheet: the last button goes back there
  /// instead of on to onboarding.
  final bool replay;

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _pages = PageController();
  int _page = 0;

  static const _count = 5;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    final still = MediaQuery.disableAnimationsOf(context);
    if (still) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(
        page,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _start() {
    if (widget.replay && context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _count - 1;
    final ink = last ? AuraColors.paper : AuraColors.ink;
    return Scaffold(
      backgroundColor: _background(_page),
      body: Stack(
        children: [
          PageView(
            controller: _pages,
            onPageChanged: (page) => setState(() => _page = page),
            children: [
              _Page(
                background: AuraColors.sky,
                josh: const Josh(mood: JoshMood.happy, width: 210),
                kicker: 'MEET JOSH',
                title: 'NAMASTE!\nI\'M JOSH.',
                body:
                    'Your trainer, in your pocket. I plan your workouts, keep '
                    'count of your food, and get stronger every day you stick '
                    'with me.',
                actions: [_Button.filled('Hi Josh', onPressed: () => _goTo(1))],
              ),
              _Page(
                background: AuraColors.lilacLight,
                josh: const Josh(
                  mood: JoshMood.happy,
                  stage: JoshStage.gettingGoing,
                  width: 170,
                ),
                kicker: '1 OF 3',
                title: 'I BUILD\nYOUR PLAN',
                body:
                    'Gym, dumbbells at home, or no equipment at all. Two days '
                    'a week or six. Tell me once and I plan every week.',
                card: const _PlanCard(),
                actions: _backNext(0, 2),
              ),
              _Page(
                background: AuraColors.mint,
                josh: const Josh(
                  mood: JoshMood.sweaty,
                  stage: JoshStage.gettingGoing,
                  width: 170,
                ),
                kicker: '2 OF 3',
                title: 'I COACH\nEVERY SET',
                body:
                    'Sets, reps and rest, with last time\'s numbers ready. '
                    'Beat them, and next time I\'ll ask for a little more.',
                card: const _SetCard(),
                actions: _backNext(1, 3),
              ),
              _Page(
                background: AuraColors.yellow,
                josh: const Josh(
                  mood: JoshMood.proud,
                  stage: JoshStage.fit,
                  width: 170,
                ),
                kicker: '3 OF 3',
                title: 'EAT LIKE\nYOU TRAIN',
                body:
                    'Dal, paneer, eggs, roti: I know Indian food by the '
                    'katori, and I tell you what to eat before and after the '
                    'gym.',
                card: const _FoodCard(),
                actions: _backNext(2, 4),
              ),
              _Page(
                background: AuraColors.ink,
                dark: true,
                josh: const Josh(
                  mood: JoshMood.fired,
                  stage: JoshStage.beastMode,
                  width: 220,
                ),
                kicker: 'READY?',
                title: 'WE\'LL DO THIS\nTOGETHER.',
                body:
                    'You don\'t have to figure it out alone. A few quick '
                    'questions first.',
                actions: [
                  _Button.outlined(
                    'Back',
                    color: AuraColors.paper,
                    onPressed: () => _goTo(3),
                  ),
                  _Button.filled(
                    'Let\'s go',
                    background: AuraColors.accent,
                    foreground: AuraColors.ink,
                    onPressed: _start,
                  ),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 16, 0),
              // As tall as the Skip button, so the dots stay put without it.
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    Semantics(
                      label: 'Screen ${_page + 1} of $_count',
                      child: ExcludeSemantics(
                        child: Row(
                          children: [
                            for (var i = 0; i < _count; i++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.only(right: 6),
                                width: i == _page ? 28 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: i == _page
                                      ? (last ? AuraColors.accent : ink)
                                      : ink.withValues(alpha: 0.3),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!last)
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: ink),
                        onPressed: () => _goTo(_count - 1),
                        child: const Text('Skip'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _backNext(int back, int next) => [
    _Button.outlined('Back', onPressed: () => _goTo(back)),
    _Button.filled('Next', onPressed: () => _goTo(next)),
  ];

  static Color _background(int page) => const [
    AuraColors.sky,
    AuraColors.lilacLight,
    AuraColors.mint,
    AuraColors.yellow,
    AuraColors.ink,
  ][page];
}

/// One screen of the intro: Josh, a heading, a line or two, an example of
/// the feature, and the buttons at the bottom within thumb reach.
class _Page extends StatelessWidget {
  const _Page({
    required this.background,
    required this.josh,
    required this.kicker,
    required this.title,
    required this.body,
    required this.actions,
    this.card,
    this.dark = false,
  });

  final Color background;
  final Widget josh;
  final String kicker;
  final String title;
  final String body;
  final Widget? card;
  final List<Widget> actions;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = dark ? AuraColors.paper : AuraColors.ink;
    final card = this.card;
    return ColoredBox(
      color: background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 48, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                // Centred when it fits, scrolling when the text is large.
                child: LayoutBuilder(
                  builder: (context, box) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: box.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(child: josh),
                          const SizedBox(height: 12),
                          Text(
                            kicker,
                            style: text.labelLarge?.copyWith(
                              color: dark ? AuraColors.mint : ink,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: AuraType.display(
                                52,
                                color: dark ? AuraColors.accent : ink,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            body,
                            style: text.bodyLarge?.copyWith(
                              color: ink,
                              fontSize: 17,
                              height: 1.45,
                            ),
                          ),
                          if (card != null) ...[
                            const SizedBox(height: 16),
                            card,
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final (i, action) in actions.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    i == actions.length - 1 ? Expanded(child: action) : action,
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A pill button in the intro's style: dark on the bright screens.
class _Button extends StatelessWidget {
  const _Button.filled(
    this.label, {
    required this.onPressed,
    this.background = AuraColors.ink,
    this.foreground = Colors.white,
  }) : outlined = false,
       color = foreground;

  const _Button.outlined(
    this.label, {
    required this.onPressed,
    this.color = AuraColors.ink,
  }) : outlined = true,
       background = Colors.transparent,
       foreground = color;

  final String label;
  final VoidCallback onPressed;
  final bool outlined;
  final Color background;
  final Color foreground;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const shape = StadiumBorder();
    const size = Size(0, 56);
    final textStyle = Theme.of(context).textTheme.titleMedium
        ?.copyWith(fontWeight: FontWeight.w700);
    if (outlined) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: size,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: shape,
          foregroundColor: color,
          side: BorderSide(color: color, width: 2),
          textStyle: textStyle,
        ),
        onPressed: onPressed,
        child: Text(label),
      );
    }
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: size,
        shape: shape,
        backgroundColor: background,
        foregroundColor: foreground,
        textStyle: textStyle,
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

/// An example weekly plan: four days, upper / lower, at a gym.
class _PlanCard extends StatelessWidget {
  const _PlanCard();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget chip(String label, {bool strong = false}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: strong ? AuraColors.ink : const Color(0xFFEDEAFF),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: text.labelLarge?.copyWith(
          color: strong ? Colors.white : AuraColors.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const training = {0, 1, 3, 4};
    return _CardBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              chip('Upper / lower', strong: true),
              chip('4 days'),
              chip('Gym'),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            label: 'Training on Monday, Tuesday, Thursday and Friday',
            child: ExcludeSemantics(
              child: Row(
                children: [
                  for (final (i, day) in days.indexed) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: training.contains(i)
                              ? AuraColors.accent
                              : const Color(0xFFEDEAFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          day,
                          style: text.labelLarge?.copyWith(
                            color: AuraColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// An example set in progress, with last time's numbers.
class _SetCard extends StatelessWidget {
  const _SetCard();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _CardBox(
      color: AuraColors.ink,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BENCH PRESS',
                  style: AuraType.display(24, color: AuraColors.paper),
                ),
                const SizedBox(height: 4),
                Text(
                  'Set 3 of 4',
                  style: text.bodyMedium?.copyWith(color: AuraColors.muted),
                ),
                Text(
                  'Last time 37.5 kg × 8',
                  style: text.bodyMedium?.copyWith(color: AuraColors.mint),
                ),
              ],
            ),
          ),
          Text('40 × 8', style: AuraType.display(34, color: AuraColors.accent)),
        ],
      ),
    );
  }
}

/// An example of food around training.
class _FoodCard extends StatelessWidget {
  const _FoodCard();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget row(String when, String what) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            when,
            style: text.bodyMedium?.copyWith(
              color: AuraColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              what,
              textAlign: TextAlign.end,
              style: text.bodyMedium?.copyWith(color: AuraColors.ink),
            ),
          ),
        ],
      ),
    );
    return _CardBox(
      color: Colors.white,
      child: Column(
        children: [
          row('Before training', 'Banana and curd'),
          const SizedBox(height: 8),
          row('After training', 'Paneer bhurji, 2 roti'),
        ],
      ),
    );
  }
}

class _CardBox extends StatelessWidget {
  const _CardBox({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
    ),
    child: child,
  );
}

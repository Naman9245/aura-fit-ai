import 'package:aurafit/features/account/code_screen.dart';
import 'package:aurafit/features/account/sign_in_screen.dart';
import 'package:aurafit/features/food/food_screen.dart';
import 'package:aurafit/features/intro/intro_screen.dart';
import 'package:aurafit/features/nutrition/log_meal_screen.dart';
import 'package:aurafit/features/onboarding/onboarding_screen.dart';
import 'package:aurafit/features/profile/edit_details_screen.dart';
import 'package:aurafit/features/progress/progress_screen.dart';
import 'package:aurafit/features/shell/app_shell.dart';
import 'package:aurafit/features/targets/how_we_calculated_screen.dart';
import 'package:aurafit/features/targets/targets_screen.dart';
import 'package:aurafit/features/today/today_screen.dart';
import 'package:aurafit/features/train/train_screen.dart';
import 'package:aurafit/data/log_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

abstract final class Routes {
  static const intro = '/intro';
  static const onboarding = '/onboarding';
  static const today = '/today';
  static const train = '/train';
  static const food = '/food';
  static const progress = '/progress';
  static const logMeal = '/log-meal';
  static const editDetails = '/edit-details';
  static const targets = '/targets';
  static const howWeCalculated = '/targets/how';
  static const signIn = '/sign-in';
  static const code = '/sign-in/code';
}

/// The app's screens, starting at [initialLocation]: Josh's intro and
/// onboarding until someone has targets, sign-in while they're kept only on
/// the phone, then the four tabs from Today. Everything else opens over the
/// tabs. [initialExtra] is the first screen's arguments.
GoRouter buildRouter({
  required String initialLocation,
  Object? initialExtra,
}) => GoRouter(
  initialLocation: initialLocation,
  initialExtra: initialExtra,
  routes: [
    GoRoute(
      path: Routes.intro,
      builder: (context, state) => IntroScreen(replay: state.extra == true),
    ),
    GoRoute(
      path: Routes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    StatefulShellRoute(
      builder: (context, state, shell) => AppShell(shell: shell),
      navigatorContainerBuilder: (context, shell, children) =>
          TabsContainer(currentIndex: shell.currentIndex, children: children),
      // In AppTab's order.
      branches: [
        _tab(Routes.today, const TodayScreen()),
        _tab(Routes.train, const TrainScreen()),
        _tab(Routes.food, const FoodScreen()),
        _tab(Routes.progress, const ProgressScreen()),
      ],
    ),
    GoRoute(
      path: Routes.logMeal,
      builder: (context, state) => LogMealScreen(
        args: state.extra as LogMealArgs? ?? const LogMealArgs(),
      ),
    ),
    GoRoute(
      path: Routes.editDetails,
      builder: (context, state) => const EditDetailsScreen(),
    ),
    GoRoute(
      path: Routes.targets,
      builder: (context, state) => const TargetsScreen(),
      routes: [
        GoRoute(
          path: 'how',
          builder: (context, state) => const HowWeCalculatedScreen(),
        ),
      ],
    ),
    GoRoute(
      path: Routes.signIn,
      builder: (context, state) =>
          SignInScreen(args: state.extra as SignInArgs? ?? const SignInArgs()),
      routes: [
        GoRoute(
          path: 'code',
          builder: (context, state) =>
              CodeScreen(args: state.extra! as CodeArgs),
        ),
      ],
    ),
  ],
);

StatefulShellBranch _tab(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (context, state) => screen)],
);

/// Helper type reference so GoRouter `push<UndoAction>` resolves cleanly.
typedef MealLogUndo = UndoAction;

import 'package:aurafit/features/onboarding/onboarding_screen.dart';
import 'package:aurafit/features/targets/how_we_calculated_screen.dart';
import 'package:aurafit/features/targets/targets_screen.dart';
import 'package:go_router/go_router.dart';

abstract final class Routes {
  static const onboarding = '/onboarding';
  static const editDetails = '/edit-details';
  static const targets = '/targets';
  static const howWeCalculated = '/targets/how';
}

/// The app's screens, starting at [initialLocation]: onboarding until
/// someone has targets, then the targets.
GoRouter buildRouter({required String initialLocation}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: Routes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: Routes.editDetails,
      builder: (context, state) => const OnboardingScreen(editing: true),
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
  ],
);

import 'package:aurafit/features/account/code_screen.dart';
import 'package:aurafit/features/account/sign_in_screen.dart';
import 'package:aurafit/features/onboarding/onboarding_screen.dart';
import 'package:aurafit/features/targets/how_we_calculated_screen.dart';
import 'package:aurafit/features/targets/targets_screen.dart';
import 'package:go_router/go_router.dart';

abstract final class Routes {
  static const onboarding = '/onboarding';
  static const editDetails = '/edit-details';
  static const targets = '/targets';
  static const howWeCalculated = '/targets/how';
  static const signIn = '/sign-in';
  static const code = '/sign-in/code';
}

/// The app's screens, starting at [initialLocation]: onboarding until
/// someone has targets, sign-in while they're kept only on the phone, then
/// the targets. [initialExtra] is the first screen's arguments.
GoRouter buildRouter({required String initialLocation, Object? initialExtra}) =>
    GoRouter(
      initialLocation: initialLocation,
      initialExtra: initialExtra,
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
        GoRoute(
          path: Routes.signIn,
          builder: (context, state) => SignInScreen(
            args: state.extra as SignInArgs? ?? const SignInArgs(),
          ),
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

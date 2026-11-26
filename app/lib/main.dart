import 'dart:async';

import 'package:aurafit/app.dart';
import 'package:aurafit/core/error_reporter.dart';
import 'package:aurafit/core/router.dart';
import 'package:aurafit/data/account.dart';
import 'package:aurafit/data/providers.dart';
import 'package:aurafit/features/account/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installErrorHooks();
  await startCrashReports();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Light status-bar icons on the dark background.
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  final container = ProviderContainer();
  final (location, extra) = await startingPoint(container);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: AuraApp(startAt: location, startExtra: extra),
    ),
  );
}

/// The first screen and its arguments, decided before the first frame from
/// the phone alone, so it never waits on the network: onboarding with no
/// plan yet, sign-in for a plan kept only here, else the targets.
Future<(String, Object?)> startingPoint(ProviderContainer container) async {
  final hasProfile = await container
      .read(profileRepositoryProvider)
      .hasProfile();
  final account = await _savedSignIn(container);
  if (account != null) {
    return (hasProfile ? Routes.today : Routes.onboarding, null);
  }
  if (!hasProfile) return (Routes.onboarding, null);
  if (!container.read(accountServiceProvider).canSignIn) {
    return (Routes.today, null);
  }
  final owner = await container.read(accountDataProvider).owner();
  return (
    Routes.signIn,
    SignInArgs(
      reason: owner == null ? SignInReason.savePlan : SignInReason.expired,
      email: owner?.email,
    ),
  );
}

/// The sign-in kept on the phone, if any. Reading it needs no network; if
/// it can't be read at all, the app starts signed out rather than not at
/// all.
Future<Account?> _savedSignIn(ProviderContainer container) async {
  try {
    return await container
        .read(accountServiceProvider)
        .watch()
        .first
        .timeout(const Duration(seconds: 3));
  } on Object catch (error) {
    debugPrint(
      'AURA: the saved sign-in couldn\'t be read (${error.runtimeType})',
    );
    return null;
  }
}

import 'package:aurafit/app.dart';
import 'package:aurafit/core/router.dart';
import 'package:aurafit/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Light status-bar icons on the dark background.
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  // Decide the first screen before the first frame, from the phone's own
  // database, so it never waits on the network.
  final container = ProviderContainer();
  final hasProfile = await container
      .read(profileRepositoryProvider)
      .hasProfile();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: AuraApp(startAt: hasProfile ? Routes.targets : Routes.onboarding),
    ),
  );
}

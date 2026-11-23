import 'package:aurafit/core/router.dart';
import 'package:aurafit/core/theme/aura_theme.dart';
import 'package:aurafit/data/sync/sync_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AuraApp extends ConsumerStatefulWidget {
  const AuraApp({super.key, required this.startAt, this.startExtra});

  /// The first screen, from [startingPoint] in main.dart.
  final String startAt;

  /// The first screen's arguments.
  final Object? startExtra;

  @override
  ConsumerState<AuraApp> createState() => _AuraAppState();
}

class _AuraAppState extends ConsumerState<AuraApp> {
  late final GoRouter _router = buildRouter(
    initialLocation: widget.startAt,
    initialExtra: widget.startExtra,
  );
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Sync runs for as long as the app does: as it opens, a few seconds
    // after each change, and on its own retries.
    ref.listenManual(syncControllerProvider, (_, _) {});
    // Phones kill apps in the background, so sync never relies on it: it
    // catches up whenever the app comes back.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(syncControllerProvider.notifier).syncNow(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AURA FIT AI',
      debugShowCheckedModeBanner: false,
      theme: buildAuraTheme(),
      routerConfig: _router,
    );
  }
}

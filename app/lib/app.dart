import 'package:aurafit/core/router.dart';
import 'package:aurafit/core/theme/aura_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuraApp extends StatefulWidget {
  const AuraApp({super.key, required this.startAt});

  /// The first screen: [Routes.onboarding] or [Routes.targets].
  final String startAt;

  @override
  State<AuraApp> createState() => _AuraAppState();
}

class _AuraAppState extends State<AuraApp> {
  late final GoRouter _router = buildRouter(initialLocation: widget.startAt);

  @override
  void dispose() {
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

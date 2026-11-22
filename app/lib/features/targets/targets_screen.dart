import 'package:aurafit/core/format.dart';
import 'package:aurafit/core/router.dart';
import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:aurafit/data/account.dart';
import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/providers.dart';
import 'package:aurafit/features/account/account_sheet.dart';
import 'package:aurafit/services/targets.dart';
import 'package:aurafit/widgets/aura_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The person's daily targets: calories, macros, water and steps.
class TargetsScreen extends ConsumerWidget {
  const TargetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final explained = ref.watch(explainedGoalProvider);
    // Signed in now, or the plan already belongs to an account.
    final inAccount =
        ref.watch(accountProvider).value != null ||
        ref.watch(phoneOwnerProvider).value != null;
    return Scaffold(
      body: AuraBackground(
        child: SafeArea(
          child: switch (explained) {
            AsyncData(value: final e?) => _Targets(
              goal: e.goal,
              targets: e.targets,
              inAccount: inAccount,
            ),
            AsyncData() => const _NoGoal(),
            AsyncError(:final error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Your targets couldn\'t be loaded: $error'),
              ),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}

class _Targets extends StatelessWidget {
  const _Targets({
    required this.goal,
    required this.targets,
    required this.inAccount,
  });

  final GoalRow goal;
  final Targets targets;

  /// Whether the plan is kept in an account, or so far only on this phone.
  final bool inAccount;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text('Your daily targets', style: text.headlineSmall),
              ),
            ),
            if (inAccount)
              IconButton(
                onPressed: () => showAccountSheet(context),
                tooltip: 'Account',
                icon: const Icon(Icons.account_circle_outlined),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'To ${goal.goalType.label.toLowerCase()}',
          style: text.bodyLarge?.copyWith(color: AuraColors.muted),
        ),
        const SizedBox(height: 24),
        _CaloriesCard(goal: goal, targets: targets),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Stat(label: 'Protein', value: '${goal.proteinG} g'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Stat(label: 'Carbs', value: '${goal.carbsG} g'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Stat(label: 'Fat', value: '${goal.fatG} g'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'Water',
                value: formatLitres(goal.waterMl),
                icon: Icons.water_drop_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Stat(
                label: 'Steps',
                value: formatWhole(goal.steps),
                icon: Icons.directions_walk,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (!inAccount) ...[
          FilledButton(
            onPressed: () => context.push(Routes.signIn),
            child: const Text('Save my plan'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.push(Routes.howWeCalculated),
            child: const Text('How we calculated this'),
          ),
        ] else
          FilledButton(
            onPressed: () => context.push(Routes.howWeCalculated),
            child: const Text('How we calculated this'),
          ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => context.push(Routes.editDetails),
          child: const Text('Change my details'),
        ),
        const SizedBox(height: 24),
        Text(
          'AURA isn\'t a medical device. If you\'re pregnant, under a doctor\'s '
          'care or have had an eating disorder, check these targets with a '
          'doctor first.',
          style: text.bodySmall?.copyWith(color: AuraColors.muted),
        ),
      ],
    );
  }
}

class _CaloriesCard extends StatelessWidget {
  const _CaloriesCard({required this.goal, required this.targets});

  final GoalRow goal;
  final Targets targets;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calories',
              style: text.titleMedium?.copyWith(color: AuraColors.muted),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: formatWhole(goal.caloriesKcal),
                    style: text.displayMedium?.copyWith(
                      color: AuraColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: ' kcal a day', style: text.titleMedium),
                ],
              ),
            ),
            if (targets.floorApplied) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: AuraColors.accentSoft,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Raised to the safe minimum. The formula gave '
                      '${formatWhole(targets.unflooredKcal.round())} kcal, and '
                      'eating that little isn\'t safe without a doctor.',
                      style: text.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: AuraColors.muted),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: text.labelLarge?.copyWith(color: AuraColors.muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(value, style: text.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown only if the goal is missing, which onboarding never leaves.
class _NoGoal extends StatelessWidget {
  const _NoGoal();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You don\'t have targets yet.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(Routes.onboarding),
              child: const Text('Set up my targets'),
            ),
          ],
        ),
      ),
    );
  }
}

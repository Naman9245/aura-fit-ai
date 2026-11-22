import 'package:aurafit/core/router.dart';
import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:aurafit/data/providers.dart';
import 'package:aurafit/features/onboarding/onboarding_controller.dart';
import 'package:aurafit/features/onboarding/onboarding_steps.dart';
import 'package:aurafit/widgets/aura_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The questions the targets are worked out from, one at a time. With
/// [editing], it starts from the saved answers and returns to the targets.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.editing = false});

  final bool editing;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late bool _loaded = !widget.editing;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.editing) _loadSaved();
  }

  Future<void> _loadSaved() async {
    final repo = ref.read(profileRepositoryProvider);
    final profile = await repo.profile();
    final weight = await repo.latestWeight();
    final goal = await repo.activeGoal();
    if (!mounted) return;
    if (profile != null) {
      ref.read(onboardingProvider.notifier).startFrom(profile, weight, goal);
    }
    setState(() => _loaded = true);
  }

  OnboardingController get _controller => ref.read(onboardingProvider.notifier);

  void _continue() {
    if (!_controller.next()) _save();
  }

  void _skip() {
    if (!_controller.skip()) _save();
  }

  void _back() {
    if (!_controller.back() && widget.editing) context.pop();
  }

  Future<void> _save() async {
    final answers = ref.read(onboardingProvider).toAnswers();
    if (answers == null || _saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).saveProfile(answers);
      if (mounted) context.go(Routes.targets);
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'onboarding',
        ),
      );
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your details couldn\'t be saved. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingProvider);
    final step = draft.step;
    final first = step.index == 0;
    final last = step.index == OnboardingStep.values.length - 1;

    return PopScope(
      // The phone's back button steps back through the questions.
      canPop: first,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _controller.back();
      },
      child: Scaffold(
        body: AuraBackground(
          child: SafeArea(
            child: !_loaded
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      _Progress(
                        step: step,
                        onBack: first && !widget.editing ? null : _back,
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          // Short steps start at the top, not the middle.
                          layoutBuilder: (current, previous) => Stack(
                            alignment: Alignment.topCenter,
                            children: [...previous, ?current],
                          ),
                          child: SingleChildScrollView(
                            key: ValueKey(step),
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                            child: _body(step),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                        child: Column(
                          children: [
                            FilledButton(
                              onPressed: draft.isAnswered(step) && !_saving
                                  ? _continue
                                  : null,
                              child: Text(last ? 'See my targets' : 'Continue'),
                            ),
                            if (step.optional)
                              TextButton(
                                onPressed: _saving ? null : _skip,
                                child: const Text('Skip'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _body(OnboardingStep step) => switch (step) {
    OnboardingStep.goal => const GoalStep(),
    OnboardingStep.birthDate => const BirthDateStep(),
    OnboardingStep.sex => const SexStep(),
    OnboardingStep.body => const BodyStep(),
    OnboardingStep.activity => const ActivityStep(),
    OnboardingStep.diet => const DietStep(),
    OnboardingStep.training => const TrainingStep(),
  };
}

/// The back button and how far through the questions this is.
class _Progress extends StatelessWidget {
  const _Progress({required this.step, required this.onBack});

  final OnboardingStep step;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final number = step.index + 1;
    final total = OnboardingStep.values.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 24, 8),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: onBack == null
                ? null
                : IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back',
                  ),
          ),
          Expanded(
            child: Semantics(
              label: 'Question $number of $total',
              child: ExcludeSemantics(
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                  child: LinearProgressIndicator(
                    value: number / total,
                    minHeight: 6,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ExcludeSemantics(
            child: Text(
              '$number of $total',
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: AuraColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

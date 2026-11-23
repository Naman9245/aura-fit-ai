import 'dart:async';

import 'package:aurafit/core/router.dart';
import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:aurafit/data/account.dart';
import 'package:aurafit/features/account/account_messages.dart';
import 'package:aurafit/features/account/code_screen.dart';
import 'package:aurafit/features/account/finish_sign_in.dart';
import 'package:aurafit/widgets/aura_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Why the sign-in screen is showing, which sets what it says first.
enum SignInReason {
  /// After the targets: keep the plan made on this phone.
  savePlan,

  /// "I already have an account", on a phone with no plan yet.
  returning,

  /// The session ended on a phone whose plan belongs to an account.
  expired,
}

@immutable
class SignInArgs {
  const SignInArgs({this.reason = SignInReason.savePlan, this.email});

  final SignInReason reason;

  /// Filled in for the person, when the phone knows it.
  final String? email;
}

/// Consent, under India's DPDP Act, before any account holds health data.
/// The box starts unticked and every way of signing in waits for it.
const consentText =
    'I agree that AURA FIT AI keeps my profile, targets and my food, water '
    'and steps logs in my account, to work out my targets and keep my '
    'phones in sync. Meals I type are sent to Google\'s Gemini to be read. '
    'AURA never sells my data, and I can delete my account and everything '
    'in it at any time.';

/// Signing in or creating an account, with Google or an email and password.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, this.args = const SignInArgs()});

  final SignInArgs args;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  late final _email = TextEditingController(text: widget.args.email);
  final _password = TextEditingController();
  late var _creating = widget.args.reason == SignInReason.savePlan;
  var _agreed = false;
  var _showPassword = false;
  var _busy = false;
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  AccountService get _service => ref.read(accountServiceProvider);

  /// Runs an account step, showing what went wrong in the screen's words.
  Future<void> _run(Future<void> Function() step) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await step();
    } on AccountException catch (error) {
      if (mounted) setState(() => _error = messageFor(error.failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish(Account account) async {
    setState(() => _saving = true);
    await finishSignIn(context, ref, account);
    if (mounted) setState(() => _saving = false);
  }

  void _google() => _run(() async {
    final account = await _service.signInWithGoogle();
    if (account != null && mounted) await _finish(account);
  });

  /// The email as typed, or null with the reason shown.
  String? _checkedEmail() {
    final email = tidyEmail(_email.text);
    if (looksLikeEmail(email)) return email;
    setState(() => _error = 'Enter your email address.');
    return null;
  }

  void _submit() {
    final email = _checkedEmail();
    if (email == null) return;
    final password = _password.text;
    if (_creating && password.length < minPasswordLength) {
      setState(() => _error = messageFor(AccountFailure.weakPassword));
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Enter your password.');
      return;
    }
    final service = _service;
    _run(() async {
      if (_creating) {
        final account = await service.createAccount(email, password);
        if (!mounted) return;
        if (account != null) return _finish(account);
        _enterCode(email, CodePurpose.confirm);
        return;
      }
      try {
        final account = await service.signIn(email, password);
        if (mounted) await _finish(account);
      } on AccountException catch (error) {
        if (error.failure != AccountFailure.notConfirmed) rethrow;
        await service.sendNewCode(email);
        if (mounted) _enterCode(email, CodePurpose.confirm);
      }
    });
  }

  void _forgot() {
    final email = _checkedEmail();
    if (email == null) return;
    _run(() async {
      await _service.sendResetCode(email);
      if (mounted) _enterCode(email, CodePurpose.reset);
    });
  }

  void _enterCode(String email, CodePurpose purpose) => unawaited(
    context.push(
      Routes.code,
      extra: CodeArgs(email: email, purpose: purpose),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final service = ref.watch(accountServiceProvider);
    final (title, subtitle) = switch (widget.args.reason) {
      SignInReason.savePlan => (
        'Save your plan',
        'Create an account to keep your targets safe, and on every phone.',
      ),
      SignInReason.returning => (
        'Welcome back',
        'Sign in to bring your plan to this phone.',
      ),
      SignInReason.expired => (
        'Sign in again',
        'Your session ended. Sign in to keep saving to your account.',
      ),
    };
    final ready = _agreed && !_busy && !_saving;

    return Scaffold(
      appBar: AppBar(),
      extendBodyBehindAppBar: true,
      body: AuraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            children: [
              Semantics(
                header: true,
                child: Text(title, style: text.headlineSmall),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: text.bodyLarge?.copyWith(color: AuraColors.muted),
              ),
              const SizedBox(height: 24),
              if (!service.canSignIn)
                Text(
                  'This build of AURA can\'t sign in: it was built without '
                  'the server\'s address (env/supabase.json).',
                  style: text.bodyLarge?.copyWith(color: AuraColors.error),
                )
              else ...[
                _Consent(
                  agreed: _agreed,
                  onChanged: _busy || _saving
                      ? null
                      : (value) => setState(() => _agreed = value),
                ),
                const SizedBox(height: 16),
                if (service.canUseGoogle) ...[
                  OutlinedButton(
                    onPressed: ready ? _google : null,
                    child: const Text('Continue with Google'),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'or',
                      style: text.bodyMedium?.copyWith(color: AuraColors.muted),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _email,
                  enabled: !_busy && !_saving,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  enabled: !_busy && !_saving,
                  obscureText: !_showPassword,
                  autofillHints: [
                    _creating
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => ready ? _submit() : null,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    helperText: _creating ? 'At least 8 characters' : null,
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                      tooltip: _showPassword
                          ? 'Hide password'
                          : 'Show password',
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                ),
                if (_error case final error?) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      error,
                      style: text.bodyMedium?.copyWith(color: AuraColors.error),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: ready ? _submit : null,
                  child: _saving
                      ? const Text('Saving your plan to your account…')
                      : Text(_creating ? 'Create account' : 'Sign in'),
                ),
                if (!_creating)
                  TextButton(
                    onPressed: _busy || _saving ? null : _forgot,
                    child: const Text('Forgot password?'),
                  ),
                TextButton(
                  onPressed: _busy || _saving
                      ? null
                      : () => setState(() {
                          _creating = !_creating;
                          _error = null;
                        }),
                  child: Text(
                    _creating ? 'I already have an account' : 'I\'m new here',
                  ),
                ),
              ],
              // Opened as the first screen, with a plan already on the
              // phone: the targets stay a tap away.
              if (!GoRouter.of(context).canPop())
                TextButton(
                  onPressed: _busy || _saving
                      ? null
                      : () => context.go(Routes.targets),
                  child: const Text('Not now'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The consent box and its words, all one tap target.
class _Consent extends StatelessWidget {
  const _Consent({required this.agreed, required this.onChanged});

  final bool agreed;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return MergeSemantics(
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        onTap: onChanged == null ? null : () => onChanged(!agreed),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: agreed,
                onChanged: onChanged == null
                    ? null
                    : (value) => onChanged(value ?? false),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    consentText,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:aurafit/data/account.dart';
import 'package:aurafit/features/account/account_messages.dart';
import 'package:aurafit/features/account/finish_sign_in.dart';
import 'package:aurafit/widgets/aura_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the emailed code is for.
enum CodePurpose {
  /// Confirming a new account's email.
  confirm,

  /// Choosing a new password.
  reset,
}

@immutable
class CodeArgs {
  const CodeArgs({required this.email, required this.purpose});

  final String email;
  final CodePurpose purpose;
}

/// How long before another code can be sent.
const resendWait = Duration(seconds: 60);

/// Typing the 6-digit code from the email: to confirm a new account, or to
/// reset a password. A code works across phones, unlike a link, which has
/// to open on the phone that asked for it.
class CodeScreen extends ConsumerStatefulWidget {
  const CodeScreen({super.key, required this.args});

  final CodeArgs args;

  @override
  ConsumerState<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends ConsumerState<CodeScreen> {
  final _code = TextEditingController();
  final _password = TextEditingController();
  var _busy = false;
  var _saving = false;
  String? _error;
  String? _note;
  Timer? _tick;
  var _secondsLeft = 0;

  bool get _resetting => widget.args.purpose == CodePurpose.reset;

  @override
  void initState() {
    super.initState();
    _startWait();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  void _startWait() {
    _tick?.cancel();
    setState(() => _secondsLeft = resendWait.inSeconds);
    _tick = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  Future<void> _run(Future<void> Function() step) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _note = null;
    });
    try {
      await step();
    } on AccountException catch (error) {
      if (mounted) setState(() => _error = messageFor(error.failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submit() {
    final code = _code.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code from the email.');
      return;
    }
    if (_resetting && _password.text.length < minPasswordLength) {
      setState(() => _error = messageFor(AccountFailure.weakPassword));
      return;
    }
    final service = ref.read(accountServiceProvider);
    final email = widget.args.email;
    _run(() async {
      final account = _resetting
          ? await service.resetPassword(email, code, _password.text)
          : await service.confirmEmail(email, code);
      if (!mounted) return;
      setState(() => _saving = true);
      await finishSignIn(context, ref, account);
      if (mounted) setState(() => _saving = false);
    });
  }

  void _sendAgain() {
    final service = ref.read(accountServiceProvider);
    final email = widget.args.email;
    _run(() async {
      await (_resetting
          ? service.sendResetCode(email)
          : service.sendNewCode(email));
      if (!mounted) return;
      _startWait();
      setState(() => _note = 'We\'ve sent a new code.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final idle = !_busy && !_saving;
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
                child: Text(
                  _resetting ? 'Reset your password' : 'Check your email',
                  style: text.headlineSmall,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit code to ${widget.args.email}. It works '
                'for an hour.',
                style: text.bodyLarge?.copyWith(color: AuraColors.muted),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _code,
                enabled: idle,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                textInputAction: _resetting
                    ? TextInputAction.next
                    : TextInputAction.done,
                onSubmitted: (_) => _resetting || !idle ? null : _submit(),
                decoration: const InputDecoration(labelText: 'Code'),
              ),
              if (_resetting) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  enabled: idle,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => idle ? _submit() : null,
                  decoration: const InputDecoration(
                    labelText: 'New password',
                    helperText: 'At least 8 characters',
                  ),
                ),
              ],
              if (_error ?? _note case final message?) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    message,
                    style: text.bodyMedium?.copyWith(
                      color: _error != null
                          ? AuraColors.error
                          : AuraColors.accentSoft,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: idle ? _submit : null,
                child: Text(
                  _saving
                      ? 'Saving your plan to your account…'
                      : _resetting
                      ? 'Save new password'
                      : 'Confirm',
                ),
              ),
              TextButton(
                onPressed: idle && _secondsLeft <= 0 ? _sendAgain : null,
                child: Text(
                  _secondsLeft > 0
                      ? 'Send a new code in $_secondsLeft s'
                      : 'Send a new code',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:aurafit/core/router.dart';
import 'package:aurafit/data/account.dart';
import 'package:aurafit/data/providers.dart';
import 'package:aurafit/data/sync/sync_controller.dart';
import 'package:aurafit/features/account/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// How long the first sync after signing in is waited for. Past it, the app
/// opens anyway and sync carries on behind it.
const _firstSyncWait = Duration(seconds: 20);

/// The step after any sign-in: the plan saved on this phone goes up to the
/// account, or the account's comes down, then the targets open. When the
/// account has no plan yet, onboarding opens instead.
Future<void> finishSignIn(
  BuildContext context,
  WidgetRef ref,
  Account account,
) async {
  // Taken now: the screen can close while the sync runs, and its ref with
  // it.
  final controller = ref.read(syncControllerProvider.notifier);
  final data = ref.read(accountDataProvider);
  final service = ref.read(accountServiceProvider);
  final profiles = ref.read(profileRepositoryProvider);

  final status = await _firstSync(controller, account);
  if (status.phase == SyncPhase.otherAccount) {
    final owner = await data.owner();
    if (!context.mounted) return;
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _OtherAccountDialog(owner: owner?.email, signingIn: account.email),
    );
    if (remove != true) {
      await service.signOut();
      if (context.mounted) {
        context.go(
          Routes.signIn,
          extra: SignInArgs(reason: SignInReason.expired, email: owner?.email),
        );
      }
      return;
    }
    await data.removeAll();
    await _firstSync(controller, account);
  }
  final hasProfile = await profiles.hasProfile();
  if (context.mounted) {
    context.go(hasProfile ? Routes.today : Routes.onboarding);
  }
}

Future<SyncStatus> _firstSync(SyncController controller, Account account) =>
    controller
        .syncNow(as: account)
        .timeout(
          _firstSyncWait,
          onTimeout: () => const SyncStatus(SyncPhase.syncing),
        );

/// This phone holds another account's data: it never goes to the one
/// signing in, so it has to come off the phone first.
class _OtherAccountDialog extends StatelessWidget {
  const _OtherAccountDialog({required this.owner, required this.signingIn});

  final String? owner;
  final String? signingIn;

  @override
  Widget build(BuildContext context) {
    final whose = owner == null ? 'another account' : owner!;
    final who = signingIn == null ? 'this account' : signingIn!;
    return AlertDialog(
      title: const Text('This phone has another account\'s plan'),
      content: Text(
        'The plan on this phone belongs to $whose. To use $who here, remove '
        'it from this phone first. It stays in its own account, apart from '
        'anything that hasn\'t reached that account yet.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Remove it'),
        ),
      ],
    );
  }
}

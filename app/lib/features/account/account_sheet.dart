import 'dart:async';

import 'package:aurafit/core/error_reporter.dart';
import 'package:aurafit/core/router.dart';
import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:aurafit/data/account.dart';
import 'package:aurafit/data/providers.dart';
import 'package:aurafit/data/sync/sync_controller.dart';
import 'package:aurafit/data/sync/sync_engine.dart';
import 'package:aurafit/features/account/sign_in_screen.dart';
import 'package:aurafit/services/data_export.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The account, where sync stands, and signing out.
Future<void> showAccountSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AuraColors.surface,
      builder: (context) => const _AccountSheet(),
    );

/// Where sync stands, in a line: what's saved, and what's still waiting.
String syncLine(SyncStatus status, int waiting, DateTime now) {
  final changes = waiting == 1 ? '1 change' : '$waiting changes';
  return switch (status.phase) {
    SyncPhase.syncing => 'Saving to your account…',
    SyncPhase.synced when waiting > 0 => '$changes waiting to be saved',
    SyncPhase.synced => switch (status.lastSynced) {
      final at? => 'Everything is saved to your account, ${_ago(at, now)}',
      null => 'Everything is saved to your account',
    },
    SyncPhase.offline when waiting > 0 =>
      '$changes waiting: you\'re offline. They go up once you\'re back.',
    SyncPhase.offline => 'You\'re offline.',
    SyncPhase.failed when waiting > 0 =>
      '$changes waiting: your account didn\'t take them. Trying again soon.',
    SyncPhase.failed => 'Couldn\'t reach your account. Trying again soon.',
    SyncPhase.otherAccount =>
      'This phone\'s plan belongs to another account, so it isn\'t saved '
          'to this one.',
    SyncPhase.off => 'Not saving to an account.',
  };
}

String _ago(DateTime at, DateTime now) {
  final minutes = now.difference(at).inMinutes;
  if (minutes < 1) return 'just now';
  if (minutes == 1) return '1 min ago';
  if (minutes < 60) return '$minutes min ago';
  final hours = minutes ~/ 60;
  return hours == 1 ? '1 hour ago' : '$hours hours ago';
}

class _AccountSheet extends ConsumerWidget {
  const _AccountSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final account = ref.watch(accountProvider).value;
    final owner = ref.watch(phoneOwnerProvider).value;
    final status = ref.watch(syncControllerProvider);
    final waiting = ref.watch(syncWaitingProvider).value ?? 0;

    final children = account == null
        ? [
            Text('Signed out', style: text.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Your session ended. Sign in again to keep saving to your '
              'account; everything on this phone stays here meanwhile.',
              style: text.bodyLarge?.copyWith(color: AuraColors.muted),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go(
                  Routes.signIn,
                  extra: SignInArgs(
                    reason: SignInReason.expired,
                    email: owner?.email,
                  ),
                );
              },
              child: const Text('Sign in again'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => exportMyData(context, ref),
              child: const Text('Export my data'),
            ),
          ]
        : [
            Text(account.email ?? 'Signed in', style: text.titleLarge),
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                syncLine(status, waiting, clock.now()),
                style: text.bodyLarge?.copyWith(color: AuraColors.muted),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: status.phase == SyncPhase.syncing
                  ? null
                  : () => ref.read(syncControllerProvider.notifier).syncNow(),
              child: const Text('Sync now'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => exportMyData(context, ref),
              child: const Text('Export my data'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => signOut(context, ref),
              child: const Text('Sign out'),
            ),
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AuraColors.error),
              onPressed: () => deleteAccount(context, ref),
              child: const Text('Delete account'),
            ),
          ];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// Signs out after checking, and takes the account's data off this phone:
/// the next account starts from nothing. Changes that haven't reached the
/// account are named first, since signing out loses them.
Future<void> signOut(BuildContext context, WidgetRef ref) async {
  final db = ref.read(appDatabaseProvider);
  final waiting = await SyncEngine.watchWaiting(db).first;
  if (!context.mounted) return;
  final changes = waiting == 1
      ? '1 change hasn\'t'
      : '$waiting changes haven\'t';
  final sure = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Sign out?'),
      content: Text(
        waiting > 0
            ? '$changes reached your account yet. Signing out now loses '
                  '${waiting == 1 ? 'it' : 'them'}.'
            : 'Your plan stays in your account and comes back when you sign '
                  'in. It leaves this phone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(waiting > 0 ? 'Stay signed in' : 'Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(waiting > 0 ? 'Sign out anyway' : 'Sign out'),
        ),
      ],
    ),
  );
  if (sure != true || !context.mounted) return;
  // The sheet closes now, and its ref with it, so take what's needed first.
  final router = GoRouter.of(context);
  final sync = ref.read(syncControllerProvider.notifier);
  final data = ref.read(accountDataProvider);
  final service = ref.read(accountServiceProvider);
  Navigator.of(context).pop();
  // Nothing syncs while the data comes off, and it comes off before the
  // session ends, so nothing mistakes this for a session that lapsed.
  await sync.stop();
  await data.removeAll();
  await service.signOut();
  router.go(Routes.onboarding);
}

/// Deletes the account on the server, with everything in it, after a
/// clear warning, then clears this phone. If the server can't be reached,
/// nothing is deleted anywhere and the person is told so.
Future<void> deleteAccount(BuildContext context, WidgetRef ref) async {
  final sure = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete your account?'),
      content: const Text(
        'This deletes your account and everything saved in it: your '
        'profile, targets, meals, water, steps and weigh-ins. Export your '
        'data first if you want a copy. It clears this phone too. It '
        'can\'t be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AuraColors.error),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete everything'),
        ),
      ],
    ),
  );
  if (sure != true || !context.mounted) return;
  // The sheet closes once it's done, and its ref with it, so take what's
  // needed first.
  final router = GoRouter.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  final sync = ref.read(syncControllerProvider.notifier);
  final data = ref.read(accountDataProvider);
  final service = ref.read(accountServiceProvider);

  // Over the sheet, which stays if this fails.
  unawaited(
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text('Deleting your account…')),
          ],
        ),
      ),
    ),
  );
  try {
    await service.deleteAccount();
  } on AccountException catch (error) {
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error.failure == AccountFailure.offline
              ? 'You\'re offline, so nothing was deleted. Try again once '
                    'you\'re back online.'
              : 'Your account couldn\'t be deleted, so nothing was. Please '
                    'try again.',
        ),
      ),
    );
    return;
  }
  // Gone on the server. Now the phone's copy, before the session ends, so
  // nothing mistakes this for a session that lapsed.
  await sync.stop();
  await data.removeAll();
  await service.signOut();
  navigator
    ..pop() // the progress dialog
    ..pop(); // the sheet
  router.go(Routes.onboarding);
  messenger.showSnackBar(
    const SnackBar(
      content: Text('Your account and everything in it are deleted.'),
    ),
  );
}

/// Builds JSON and CSV exports from the phone's database and opens the share
/// sheet (PRD A6). Works offline.
Future<void> exportMyData(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final exporter = ref.read(dataExporterProvider);
  final share = ref.read(shareServiceProvider);
  try {
    final files = await exporter.buildExport();
    await share.shareFiles(files);
  } catch (error, stack) {
    reportAuraError(error, stack, where: 'account.export');
    if (!context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Your export couldn\'t be prepared. Please try again.'),
      ),
    );
  }
}

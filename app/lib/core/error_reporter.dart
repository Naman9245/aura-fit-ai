import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

// The one file that talks to the crash reporter. A test
// (test/core/error_reporter_test.dart) fails if any other file imports it,
// so every report goes through [reportAuraError] and keeps no personal data.

/// A sanitised error record with no personal data: never raw exception
/// messages, which can carry food names, SQL values or email addresses.
@immutable
class SafeErrorReport {
  const SafeErrorReport({
    required this.where,
    required this.errorType,
    required this.stack,
    this.fatal = false,
  });

  final String where;
  final String errorType;
  final StackTrace stack;

  /// Whether nothing caught the error, so the app may not have carried on.
  final bool fatal;

  /// What a crash report shows as the error: where it happened and its
  /// type, never its message.
  @override
  String toString() => '$where: $errorType';
}

/// Hook for tests or Crashlytics. Only [reportAuraError] calls it.
typedef ErrorSink = void Function(SafeErrorReport report);

ErrorSink _sink = _defaultSink;

/// Errors the default sink hands to Flutter carry this library name, so the
/// hooks in [installErrorHooks] know they've been reported already.
const _library = 'aurafit';

void _defaultSink(SafeErrorReport report) {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: report.toString(),
      stack: report.stack,
      library: _library,
    ),
  );
}

/// Replaces the error sink in tests, restoring the default when the test ends.
@visibleForTesting
void debugSetErrorSink(ErrorSink? sink) {
  _sink = sink ?? _defaultSink;
}

/// Reports an unexpected failure keeping only [where], the error's runtime
/// type and the stack trace — never its message.
void reportAuraError(
  Object error,
  StackTrace stack, {
  required String where,
  bool fatal = false,
}) {
  _sink(
    SafeErrorReport(
      where: where,
      errorType: error.runtimeType.toString(),
      stack: stack,
      fatal: fatal,
    ),
  );
}

/// Sends errors nobody caught through [reportAuraError] too: Flutter's own
/// (a widget that throws while building) and the rest (an async error with
/// no handler). Call it once, first thing in `main`.
void installErrorHooks() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // The default sink reports through Flutter; don't report that twice.
    if (details.library == _library) return;
    reportAuraError(
      details.exception,
      details.stack ?? StackTrace.empty,
      where: 'flutter',
      fatal: true,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    reportAuraError(error, stack, where: 'uncaught', fatal: true);
    return true;
  };
}

/// Puts Crashlytics behind [reportAuraError] in release builds that have a
/// Firebase project (`android/app/google-services.json`). Without one, in
/// debug builds, or if Firebase can't start, errors are only printed on the
/// phone and the app carries on.
Future<void> startCrashReports() async {
  if (!kReleaseMode) return;
  try {
    await Firebase.initializeApp();
  } on Object catch (error) {
    debugPrint('AURA: crash reports are off (${error.runtimeType})');
    return;
  }
  final crashlytics = FirebaseCrashlytics.instance;
  _sink = (report) => unawaited(
    crashlytics.recordError(
      report,
      report.stack,
      fatal: report.fatal,
      printDetails: false,
    ),
  );
  crashReports = _CrashlyticsSwitch(crashlytics);
}

/// The "Send crash reports" switch on the account sheet.
abstract interface class CrashReportSwitch {
  /// Whether this build can send crash reports at all. When it can't, the
  /// switch isn't shown.
  bool get available;

  /// Whether crash reports are being sent.
  bool get on;

  /// Turns sending on or off. Crashlytics keeps the choice across launches;
  /// turning it off also drops reports not yet sent.
  Future<void> turn({required bool on});
}

/// The switch for this run of the app: Crashlytics' once
/// [startCrashReports] has started it, else one that isn't available.
CrashReportSwitch crashReports = const _NoCrashReports();

class _NoCrashReports implements CrashReportSwitch {
  const _NoCrashReports();

  @override
  bool get available => false;

  @override
  bool get on => false;

  @override
  Future<void> turn({required bool on}) async {}
}

class _CrashlyticsSwitch implements CrashReportSwitch {
  const _CrashlyticsSwitch(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  @override
  bool get available => true;

  @override
  bool get on => _crashlytics.isCrashlyticsCollectionEnabled;

  @override
  Future<void> turn({required bool on}) async {
    await _crashlytics.setCrashlyticsCollectionEnabled(on);
    if (!on) await _crashlytics.deleteUnsentReports();
  }
}

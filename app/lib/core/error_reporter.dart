import 'package:flutter/foundation.dart';

/// A sanitised error record with no personal data: never raw exception
/// messages, which can carry food names, SQL values or email addresses.
@immutable
class SafeErrorReport {
  const SafeErrorReport({
    required this.where,
    required this.errorType,
    required this.stack,
  });

  final String where;
  final String errorType;
  final StackTrace stack;
}

/// Hook for tests or Crashlytics. Only [reportAuraError] calls it.
typedef ErrorSink = void Function(SafeErrorReport report);

ErrorSink _sink = _defaultSink;

void _defaultSink(SafeErrorReport report) {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: '${report.where}: ${report.errorType}',
      stack: report.stack,
      library: 'aurafit',
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
void reportAuraError(Object error, StackTrace stack, {required String where}) {
  _sink(
    SafeErrorReport(
      where: where,
      errorType: error.runtimeType.toString(),
      stack: stack,
    ),
  );
}

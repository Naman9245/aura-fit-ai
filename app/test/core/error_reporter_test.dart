import 'dart:io';
import 'dart:ui';

import 'package:aurafit/core/error_reporter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final reports = <SafeErrorReport>[];

  setUp(() {
    reports.clear();
    debugSetErrorSink(reports.add);
  });
  tearDown(() => debugSetErrorSink(null));

  test('only the error reporter talks to Firebase', () {
    // The PRD's rule: every crash report goes through reportAuraError, so
    // none can carry personal data.
    final talkers = [
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File &&
            file.path.endsWith('.dart') &&
            file.readAsStringSync().contains('package:firebase_'))
          file.path.replaceAll(r'\', '/'),
    ];
    expect(talkers, ['lib/core/error_reporter.dart']);
  });

  test('a report keeps where and the error type, never the message', () {
    reportAuraError(
      StateError('paneer tikka for priya@example.com'),
      StackTrace.current,
      where: 'log_meal.parse',
    );

    final report = reports.single;
    expect(report.toString(), 'log_meal.parse: StateError');
    expect(report.fatal, isFalse);
    expect('$report ${report.errorType}', isNot(contains('paneer')));
    expect('$report ${report.errorType}', isNot(contains('@')));
  });

  group('errors nobody caught', () {
    late FlutterExceptionHandler? flutterBefore;
    late ErrorCallback? platformBefore;

    setUp(() {
      flutterBefore = FlutterError.onError;
      platformBefore = PlatformDispatcher.instance.onError;
      installErrorHooks();
    });
    tearDown(() {
      FlutterError.onError = flutterBefore;
      PlatformDispatcher.instance.onError = platformBefore;
    });

    test('from Flutter are reported as fatal, without the message', () {
      FlutterError.onError!(
        FlutterErrorDetails(
          exception: Exception('priya@example.com'),
          stack: StackTrace.current,
          library: 'widgets library',
        ),
      );

      expect(reports.single.toString(), 'flutter: _Exception');
      expect(reports.single.fatal, isTrue);
    });

    test('elsewhere are reported as fatal and handled', () {
      final handled = PlatformDispatcher.instance.onError!(
        const FormatException('2 roti aur dal'),
        StackTrace.current,
      );

      expect(handled, isTrue);
      expect(reports.single.toString(), 'uncaught: FormatException');
      expect(reports.single.fatal, isTrue);
    });

    test('an error the default sink passed to Flutter is not sent twice', () {
      FlutterError.onError!(
        FlutterErrorDetails(
          exception: 'log_meal.search: StateError',
          library: 'aurafit',
        ),
      );

      expect(reports, isEmpty);
    });
  });

  test('a build without crash reports offers no switch', () async {
    expect(crashReports.available, isFalse);
    expect(crashReports.on, isFalse);
    await crashReports.turn(on: true);
    expect(crashReports.on, isFalse);
  });
}

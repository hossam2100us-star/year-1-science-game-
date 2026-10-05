import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:science_adventure/core/diagnostics/app_log.dart';
import 'package:science_adventure/core/diagnostics/failure.dart';
import 'package:science_adventure/core/widgets.dart';

void main() {
  setUp(AppLog.clear);

  group('classifyFailure (AUD-009)', () {
    test('a full disk is reported as storage full', () {
      for (final code in [28, 112]) {
        expect(
          classifyFailure(
            FileSystemException('write', 'box.hive', OSError('full', code)),
          ),
          FailureKind.storageFull,
        );
      }
    });

    test('other file errors are storage-unavailable, not "free space"', () {
      expect(
        classifyFailure(
          const FileSystemException('open', 'box.hive', OSError('denied', 13)),
        ),
        FailureKind.storageUnavailable,
      );
      expect(
        classifyFailure(HiveError('closed')),
        FailureKind.storageUnavailable,
      );
    });

    test('unreadable data and defects are told apart', () {
      expect(
        classifyFailure(const FormatException('bad')),
        FailureKind.corruptData,
      );
      expect(classifyFailure(StateError('bug')), FailureKind.unexpected);
      expect(classifyFailure(RangeError('bug')), FailureKind.unexpected);
    });

    test('only the storage-full message asks to free space', () {
      for (final kind in FailureKind.values) {
        expect(
          saveFailureMessage(kind).contains('free some space'),
          kind == FailureKind.storageFull,
          reason: kind.name,
        );
      }
    });
  });

  group('AppLog privacy (SEC-04)', () {
    test('stores the error type but never the error text', () {
      AppLog.error(
        'save',
        'Save failed',
        const FormatException('child name Nour in payload'),
        StackTrace.current,
      );
      final text = AppLog.export();
      expect(text, contains('FormatException'));
      expect(text, contains('Save failed'));
      expect(text, isNot(contains('Nour')));
    });

    test('keeps a bounded ring buffer', () {
      for (var i = 0; i < AppLog.capacity + 25; i++) {
        AppLog.info('test', 'event');
      }
      expect(AppLog.entries.length, AppLog.capacity);
    });

    test('trims stack traces to a few frames', () {
      AppLog.error('save', 'Save failed', StateError('x'), StackTrace.current);
      final stack = AppLog.entries.single.stack!;
      expect(stack.split('\n').length, lessThanOrEqualTo(8));
    });
  });

  testWidgets('showSaveError logs and shows the real cause', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    showSaveError(context, StateError('defect'), StackTrace.current);
    await tester.pump();
    expect(find.textContaining('problem in the game'), findsOneWidget);
    expect(find.textContaining('free some space'), findsNothing);
    expect(AppLog.entries.single.level, 'SEVERE');
    expect(AppLog.entries.single.message, contains('unexpected'));
  });
}

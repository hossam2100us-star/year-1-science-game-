import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/mascot.dart';
import '../core/models.dart';

/// A "grown-ups only" check in front of parent features (AUD-015, SEC-03).
///
/// This keeps young children out of settings by accident. It is not
/// authentication and must never protect accounts, money or data leaving the
/// device; those need a real sign-in.
Future<bool> parentGate(BuildContext context, {ChildGender? gender}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ParentGateDialog(gender: gender),
    ) ??
    false;

/// Gate attempts are shared by every gate in this app session, so closing
/// and reopening the dialog does not reset the cooldown.
class ParentGatePolicy {
  ParentGatePolicy._();

  static const maxFailures = 3;
  static const cooldown = Duration(seconds: 30);

  static int _failures = 0;
  static DateTime? _lockedUntil;

  /// Replaceable for tests.
  static DateTime Function() clock = DateTime.now;

  static Duration get remainingLock {
    final until = _lockedUntil;
    if (until == null) return Duration.zero;
    final left = until.difference(clock());
    return left.isNegative ? Duration.zero : left;
  }

  static void recordFailure() {
    _failures++;
    if (_failures >= maxFailures) {
      _failures = 0;
      _lockedUntil = clock().add(cooldown);
    }
  }

  static void recordSuccess() {
    _failures = 0;
    _lockedUntil = null;
  }

  @visibleForTesting
  static void reset() {
    _failures = 0;
    _lockedUntil = null;
    clock = DateTime.now;
  }
}

class ParentGateDialog extends StatefulWidget {
  const ParentGateDialog({super.key, this.gender, this.random});
  final ChildGender? gender;

  /// Replaceable for tests; defaults to a secure source.
  final Random? random;
  @override
  State<ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<ParentGateDialog> {
  late final Random _random = widget.random ?? Random.secure();
  final _answer = TextEditingController();
  bool _retry = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _newProblem();
    _watchLock();
  }

  /// Two-digit by one-digit products (33-171) are easy for an adult and hard
  /// to guess for a young child.
  void _newProblem() {
    final (previousLeft, previousRight) = (_leftOrNull, _rightOrNull);
    do {
      _leftOrNull = 11 + _random.nextInt(9);
      _rightOrNull = 3 + _random.nextInt(7);
    } while (_leftOrNull == previousLeft && _rightOrNull == previousRight);
  }

  int? _leftOrNull, _rightOrNull;
  int get _left => _leftOrNull!;
  int get _right => _rightOrNull!;

  bool get _locked => ParentGatePolicy.remainingLock > Duration.zero;

  void _watchLock() {
    _ticker?.cancel();
    if (!_locked) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() {});
      if (!_locked) timer.cancel();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _answer.dispose();
    super.dispose();
  }

  void _submit() {
    if (_locked) return;
    var answer = _answer.text.trim();
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    for (var i = 0; i < 10; i++) {
      answer = answer.replaceAll(arabic[i], '$i');
    }
    if (answer == '${_left * _right}') {
      ParentGatePolicy.recordSuccess();
      Navigator.of(context).pop(true);
      return;
    }
    ParentGatePolicy.recordFailure();
    setState(() {
      _retry = true;
      _newProblem(); // Never the same problem twice in a row.
    });
    _answer.clear();
    _watchLock();
  }

  @override
  Widget build(BuildContext context) {
    final wait = ParentGatePolicy.remainingLock.inSeconds + 1;
    return AlertDialog(
      scrollable: true,
      title: const Text(
        'للأهل بس • Grown-ups only',
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'Cairo', fontSize: 24),
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScientistOwl(
              size: 100,
              mood: OwlMood.thinking,
              gender: widget.gender ?? ChildGender.boy,
            ),
            const Text(
              'احسب ناتج الضرب عشان نكمل\nSolve the multiplication to continue',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 20),
            ),
            const SizedBox(height: 16),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '$_left × $_right = ?',
                key: const ValueKey('parent-challenge'),
                style: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _answer,
              enabled: !_locked,
              keyboardType: TextInputType.number,
              maxLength: 3,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(labelText: 'الإجابة • Answer'),
              onSubmitted: (_) => _submit(),
            ),
            if (_locked)
              Text(
                'استنى $wait ثانية وجرّب تاني • Wait $wait seconds, then try again',
                key: const ValueKey('parent-gate-wait'),
                style: const TextStyle(fontFamily: 'Cairo'),
              )
            else if (_retry)
              const Text(
                'جرّب المسألة الجديدة • Please try the new problem',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Text('رجوع • Back'),
          ),
        ),
        FilledButton(
          onPressed: _locked ? null : _submit,
          child: const Text('كمّل • Continue'),
        ),
      ],
    );
  }
}

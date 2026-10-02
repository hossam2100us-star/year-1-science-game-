import 'package:flutter/material.dart';

import 'dart:math';

import '../core/mascot.dart';

Future<bool> parentGate(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ParentGateDialog(),
    ) ??
    false;

class ParentGateDialog extends StatefulWidget {
  const ParentGateDialog({super.key});
  @override
  State<ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<ParentGateDialog> {
  final int _left = 3 + Random.secure().nextInt(7);
  final int _right = 6 + Random.secure().nextInt(4);
  final _answer = TextEditingController();
  bool _retry = false;
  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  void _submit() {
    var answer = _answer.text.trim();
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    for (var i = 0; i < 10; i++) {
      answer = answer.replaceAll(arabic[i], '$i');
    }
    if (answer == '${_left * _right}') {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _retry = true);
      _answer.clear();
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
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
          const ScientistOwl(size: 100, mood: OwlMood.thinking),
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
            keyboardType: TextInputType.number,
            maxLength: 2,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(labelText: 'الإجابة • Answer'),
            onSubmitted: (_) => _submit(),
          ),
          if (_retry)
            const Text(
              'جرّب تاني • Please try again',
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
      FilledButton(onPressed: _submit, child: const Text('كمّل • Continue')),
    ],
  );
}

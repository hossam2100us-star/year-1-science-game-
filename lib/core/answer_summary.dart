import 'package:flutter/material.dart';

/// Relationships use bundled icons instead of platform-dependent font glyphs.
class AnswerSummary extends StatelessWidget {
  const AnswerSummary({
    super.key,
    this.pairs = const [],
    this.sequence = const [],
  });
  final List<(String, String)> pairs;
  final List<String> sequence;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        for (final pair in pairs)
          Semantics(
            label: '${pair.$1} to ${pair.$2}',
            child: Container(
              constraints: BoxConstraints(maxWidth: box.maxWidth),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(pair.$1)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward_rounded, size: 22),
                  ),
                  Flexible(child: Text(pair.$2)),
                ],
              ),
            ),
          ),
        for (var i = 0; i < sequence.length; i++)
          Chip(label: Text('${i + 1}. ${sequence[i]}')),
      ],
    ),
  );
}

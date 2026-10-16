import 'package:flutter/material.dart';

import '../../core/widgets.dart';
import 'maths_visual.dart';
import 'ordered_saves.dart';

/// A number line the child jumps along from the question's start: forward,
/// back, or start again. A learning aid only; the answer is still chosen
/// and checked. Once the question is answered, the jumps of the explanation
/// are drawn one after another (teacher review 5: "Start at 5 and count on
/// 3" showed a still line, and "three forward jumps" were never shown).
class NumberLineJumps extends StatefulWidget {
  const NumberLineJumps({
    super.key,
    required this.data,
    required this.initial,
    required this.onSave,
    required this.onSay,
    this.locked = false,
    this.revealed = false,
  });

  /// A `numberLine` diagram with `from` and the explanation's `jumps`.
  final Map<String, dynamic> data;

  /// The child's jumps so far: +1 forward, -1 back.
  final List<int> initial;
  final Future<void> Function(List<int> hops) onSave;
  final ValueChanged<String> onSay;
  final bool locked, revealed;

  static bool jumpable(Map<String, dynamic> data) =>
      data['type'] == 'numberLine' && data['from'] is num;

  @override
  State<NumberLineJumps> createState() => _NumberLineJumpsState();
}

class _NumberLineJumpsState extends State<NumberLineJumps> {
  late List<int> _hops;
  late final OrderedSaves<List<int>> _saves;

  int get _start => (widget.data['start'] as num).toInt();
  int get _end => (widget.data['end'] as num).toInt();
  int get _at =>
      (widget.data['from'] as num).toInt() + _hops.fold(0, (a, b) => a + b);

  @override
  void initState() {
    super.initState();
    _hops = [...widget.initial];
    _saves = OrderedSaves(_hops);
  }

  void _set(List<int> next) {
    setState(() => _hops = next);
    _saves.add(
      next,
      widget.onSave,
      onFailed: (saved, error, stack) {
        if (!mounted) return;
        setState(() => _hops = saved);
        showSaveError(context, error, stack);
      },
    );
  }

  void _jump(int hop) {
    if (widget.locked) return;
    _set([..._hops, hop]);
    widget.onSay('$_at');
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      for (final jump in (widget.data['jumps'] as List).cast<num>())
        for (var i = 0; i < jump.abs(); i++) jump.sign.toInt(),
    ];
    Widget line(double progress) => MathsVisual(
      data: {
        ...widget.data,
        'height': 130,
        if (widget.revealed) 'shown': steps else 'hops': _hops,
        'progress': progress,
      },
    );
    if (widget.revealed) {
      final still = MediaQuery.disableAnimationsOf(context);
      return TweenAnimationBuilder<double>(
        key: const ValueKey('maths-jumps-explained'),
        tween: Tween(begin: still ? 1 : 0, end: 1),
        duration: Duration(milliseconds: 450 * steps.length),
        builder: (context, progress, _) => line(progress),
      );
    }
    return Column(
      children: [
        line(1),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const ValueKey('maths-jump-back'),
              onPressed: widget.locked || _at <= _start
                  ? null
                  : () => _jump(-1),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Jump back'),
            ),
            FilledButton.icon(
              key: const ValueKey('maths-jump-forward'),
              onPressed: widget.locked || _at >= _end ? null : () => _jump(1),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Jump forward'),
            ),
            TextButton.icon(
              key: const ValueKey('maths-jump-reset'),
              onPressed: widget.locked || _hops.isEmpty
                  ? null
                  : () => _set(const []),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Start again'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Semantics(
          liveRegion: true,
          child: Text(
            _hops.isEmpty
                ? 'Start on ${widget.data['from']}'
                : '${_hops.length} ${_hops.length == 1 ? 'jump' : 'jumps'}: on $_at',
            key: const ValueKey('maths-jump-position'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

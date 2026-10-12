import 'package:flutter/material.dart';

import '../../core/widgets.dart';
import 'maths_art.dart';
import 'ordered_saves.dart';

/// The objects of a counting question, counted by touch as in the "Try it
/// together" practice: each touch gives an object the next number and says
/// it. A learning aid only; the answer is still chosen and checked below
/// (teacher review 5: the apples could be counted in the practice but not
/// in the question after it).
class TapCounter extends StatefulWidget {
  const TapCounter({
    super.key,
    required this.data,
    required this.initial,
    required this.onSave,
    required this.onSay,
    this.locked = false,
  });

  /// A `count` diagram: how many, which object, row or scattered.
  final Map<String, dynamic> data;
  final List<int> initial;
  final Future<void> Function(List<int> counted) onSave;
  final ValueChanged<String> onSay;
  final bool locked;

  /// Counting questions show a row or a scatter of two or more objects.
  static bool countable(Map<String, dynamic> data) =>
      data['type'] == 'count' &&
      const {'row', 'scattered'}.contains(data['arrangement'] ?? 'row') &&
      (data['count'] as num? ?? 0) >= 2;

  @override
  State<TapCounter> createState() => _TapCounterState();
}

class _TapCounterState extends State<TapCounter> {
  late List<int> _counted;
  late final OrderedSaves<List<int>> _saves;

  @override
  void initState() {
    super.initState();
    _counted = [...widget.initial];
    _saves = OrderedSaves(_counted);
  }

  void _set(List<int> next) {
    setState(() => _counted = next);
    _saves.add(
      next,
      widget.onSave,
      onFailed: (saved, error, stack) {
        if (!mounted) return;
        setState(() => _counted = saved);
        showSaveError(context, error, stack);
      },
    );
  }

  void _count(int object) {
    if (widget.locked || _counted.contains(object)) return;
    _set([..._counted, object]);
    widget.onSay('${_counted.length}');
  }

  @override
  Widget build(BuildContext context) {
    final count = (widget.data['count'] as num).toInt();
    final item = '${widget.data['item'] ?? 'counter'}';
    final scattered = widget.data['arrangement'] == 'scattered';
    return LayoutBuilder(
      builder: (context, box) {
        final perRow = count <= 5
            ? count
            : count <= 10 || box.maxWidth < 560
            ? 5
            : 10;
        final tile = ((box.maxWidth - (perRow - 1) * 8) / perRow).clamp(
          36.0,
          72.0,
        );
        return Column(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < count; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      top: scattered ? (i * 7 % 3) * 6.0 : 0,
                      bottom: scattered ? 12 - (i * 7 % 3) * 6.0 : 0,
                    ),
                    child: _object(i, item, tile),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              children: [
                Semantics(
                  liveRegion: true,
                  child: Text(
                    '${_counted.length} counted',
                    key: const ValueKey('maths-tap-count-total'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  key: const ValueKey('maths-tap-count-reset'),
                  onPressed: widget.locked || _counted.isEmpty
                      ? null
                      : () => _set(const []),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Count again'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _object(int i, String item, double tile) {
    final counted = _counted.contains(i);
    return Semantics(
      label: counted ? '$item, counted' : 'Count this $item',
      button: true,
      child: Material(
        color: counted ? const Color(0xFFDDF1CA) : const Color(0xFFF7F7F2),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: ValueKey('maths-tap-count-$i'),
          borderRadius: BorderRadius.circular(14),
          onTap: widget.locked || counted ? null : () => _count(i),
          child: SizedBox.square(
            dimension: tile,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: MathsArt(item, height: tile - 10),
                  ),
                ),
                if (counted)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF286D49),
                        borderRadius: BorderRadius.all(Radius.circular(9)),
                      ),
                      child: Text(
                        '${_counted.indexOf(i) + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/widgets.dart';
import 'maths_art.dart';
import 'maths_visual.dart';
import 'ordered_saves.dart';

/// Ungraded, guided practice. A completed action is saved through the same
/// lesson lab state as the Science experiments, never as an assessment result.
class MathsWorkshop extends StatefulWidget {
  const MathsWorkshop({
    super.key,
    required this.config,
    required this.initial,
    required this.onSave,
    required this.onSay,
    this.locked = false,
  });
  final Map<String, dynamic> config, initial;
  final Future<void> Function(Map<String, dynamic>, bool) onSave;
  final ValueChanged<String> onSay;
  final bool locked;

  static bool isComplete(
    Map<String, dynamic> config,
    Map<String, dynamic> lab,
  ) {
    final tasks = (config['tasks'] as List).cast<Map<String, dynamic>>();
    final completed = (lab['completedTasks'] as List? ?? []).cast<String>();
    return tasks.isNotEmpty &&
        tasks.every((task) => completed.contains(task['id']));
  }

  @override
  State<MathsWorkshop> createState() => _MathsWorkshopState();
}

class _MathsWorkshopState extends State<MathsWorkshop> {
  late Map<String, dynamic> _data;

  /// Touches are shown at once and saved in order (see [OrderedSaves]).
  late final OrderedSaves<Map<String, dynamic>> _saves;
  final _top = GlobalKey(), _end = GlobalKey();
  List<Map<String, dynamic>> get _tasks =>
      (widget.config['tasks'] as List).cast<Map<String, dynamic>>();
  int get _index =>
      (_data['taskIndex'] as int? ?? 0).clamp(0, _tasks.length - 1);
  Map<String, dynamic> get _task => _tasks[_index];
  List<int> get _counted => List<int>.from(_data['counted'] ?? const []);
  int get _built =>
      _data['built'] as int? ?? _task['initialCount'] as int? ?? 0;
  bool get _passed => _data['passed'] == true;
  bool get _done => MathsWorkshop.isComplete(widget.config, _data);
  bool get _locked => widget.locked || _passed || _done;
  String get _item => _task['item'] as String? ?? 'counter';

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.initial);
    _saves = OrderedSaves(_data);
    // Back at a workshop that already shows answers, feedback or the next
    // button (resumed, or reached with Back): show them too (teacher review
    // 5). This runs after the lesson's own scroll to the top.
    if (_reveals(const {}, _data)) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _show(_end, ScrollPositionAlignmentPolicy.keepVisibleAtEnd),
      );
    }
  }

  void _save(Map<String, dynamic> next, {String? say}) {
    final before = _data;
    setState(() => _data = next);
    if ((next['taskIndex'] ?? 0) != (before['taskIndex'] ?? 0)) {
      // The next idea starts with its question at the top.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _show(_top, ScrollPositionAlignmentPolicy.keepVisibleAtStart),
      );
    } else if (_reveals(before, next)) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _show(_end, ScrollPositionAlignmentPolicy.keepVisibleAtEnd),
      );
    }
    _saves.add(
      next,
      (value) =>
          widget.onSave(value, MathsWorkshop.isComplete(widget.config, value)),
      onSaved: () {
        if (mounted && say != null) widget.onSay(say);
      },
      onFailed: (saved, error, stack) {
        if (!mounted) return;
        setState(() => _data = saved);
        showSaveError(context, error, stack);
      },
    );
  }

  /// Whether [next] shows something below what the child was looking at:
  /// the answer choices after the last object is counted, feedback, or the
  /// button to the next idea.
  bool _reveals(Map<String, dynamic> before, Map<String, dynamic> next) {
    bool counted(Map<String, dynamic> data) =>
        _task['mode'] == 'count' &&
        (data['counted'] as List? ?? const []).length == _task['count'];
    return counted(next) && !counted(before) ||
        (next['message'] as String? ?? '').isNotEmpty &&
            next['message'] != before['message'] ||
        next['passed'] == true && before['passed'] != true ||
        MathsWorkshop.isComplete(widget.config, next);
  }

  /// Scrolls the lesson only as far as needed. On a tablet the choices and
  /// the next button otherwise appear below the screen's edge.
  void _show(GlobalKey key, ScrollPositionAlignmentPolicy policy) {
    final target = key.currentContext;
    if (target == null || !mounted) return;
    Scrollable.ensureVisible(
      target,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignmentPolicy: policy,
    );
  }

  void _count(int object) {
    if (_locked || _counted.contains(object)) return;
    final counted = [..._counted, object];
    _save({
      ..._data,
      'counted': counted,
      'message': '',
    }, say: '${counted.length}');
  }

  void _build(int delta) {
    if (_locked) return;
    final next = (_built + delta).clamp(0, _task['maxCount'] as int? ?? 20);
    if (next == _built) return;
    _save({..._data, 'built': next, 'message': ''}, say: '$next');
  }

  void _answer(bool correct) {
    if (_locked) return;
    final feedback = correct
        ? _task['feedback'] as String
        : _task['hint'] as String? ?? 'Look at the objects and try again.';
    _save({..._data, 'passed': correct, 'message': feedback}, say: feedback);
  }

  void _continue() {
    if (!_passed || _done) return;
    final completed = <String>{
      ...List<String>.from(_data['completedTasks'] ?? const []),
      _task['id'] as String,
    };
    final finished = completed.length == _tasks.length;
    final next = <String, dynamic>{
      'completedTasks': completed.toList(),
      'taskIndex': finished ? _index : _index + 1,
      if (finished) 'message': _task['feedback'],
    };
    _save(
      next,
      say: finished
          ? 'You are ready. Let us try your discoveries!'
          : _tasks[_index + 1]['prompt'] as String,
    );
  }

  Widget _countScene() => LayoutBuilder(
    builder: (context, box) {
      final number = _task['count'] as int;
      final columns = box.maxWidth < 420 ? 4 : 5;
      final tile = ((box.maxWidth - 44 - (columns - 1) * 8) / columns).clamp(
        40.0,
        84.0,
      );
      final rows = (number / columns).ceil();
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 125 + rows * (tile + 24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              MathsBackdrop(scene: widget.config['scene'] as String),
              Positioned(
                left: 12,
                right: 12,
                bottom: 14,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFAE8).withValues(alpha: .95),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFBC8648),
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (var i = 0; i < number; i++)
                          SizedBox(
                            width: tile,
                            height: tile + 16,
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: _task['arrangement'] == 'scattered'
                                    ? (i % 3) * 8.0
                                    : 0,
                                bottom: _task['arrangement'] == 'scattered'
                                    ? 16 - (i % 3) * 8.0
                                    : 16,
                              ),
                              child: Semantics(
                                label: _counted.contains(i)
                                    ? '$_item, counted'
                                    : 'Count this $_item',
                                button: true,
                                child: Material(
                                  color: _counted.contains(i)
                                      ? const Color(0xFFDDF1CA)
                                      : Colors.white.withValues(alpha: .8),
                                  borderRadius: BorderRadius.circular(14),
                                  child: InkWell(
                                    key: ValueKey('maths-count-object-$i'),
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: _locked || _counted.contains(i)
                                        ? null
                                        : () => _count(i),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: MathsArt(_item),
                                          ),
                                        ),
                                        if (_counted.contains(i))
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 7,
                                                    vertical: 2,
                                                  ),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF286D49),
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(10),
                                                ),
                                              ),
                                              child: Text(
                                                '${_counted.indexOf(i) + 1}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 17,
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
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _choices() {
    final choices = (_task['choices'] as List).cast<Map<String, dynamic>>();
    return LayoutBuilder(
      builder: (context, box) {
        final visualChoices = choices.any((choice) => choice['visual'] != null);
        final longLabels = choices.any(
          (choice) => (choice['label'] as String).length > 12,
        );
        final columns = box.maxWidth < 450 && (visualChoices || longLabels)
            ? 1
            : choices.length;
        final width = (box.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (final choice in choices)
              SizedBox(
                width: width,
                child: OutlinedButton(
                  key: ValueKey('maths-workshop-choice-${choice['id']}'),
                  onPressed: _locked
                      ? null
                      : () => _answer(choice['id'] == _task['correctId']),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (choice['visual'] is Map)
                        MathsVisual(
                          data: Map<String, dynamic>.from(choice['visual']),
                        ),
                      Text(
                        choice['label'] as String,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final message = _data['message'] as String? ?? '';
    return Container(
      key: _top,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1D5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_done) ...[
            const SizedBox(height: 12),
            const Icon(
              Icons.verified_rounded,
              color: Color(0xFF347E4F),
              size: 48,
            ),
            Text(
              widget.config['goal'] as String,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            const Text(
              'You are ready for the next discovery!',
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Text(
              'Try it together • ${_index + 1}/${_tasks.length}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 10),
            Text(
              _task['prompt'] as String,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            if (_task['mode'] == 'count') ...[
              _countScene(),
              const SizedBox(height: 10),
              Semantics(
                liveRegion: true,
                child: Text(
                  '${_counted.length} counted',
                  key: const ValueKey('maths-count-total'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (_counted.length == _task['count']) ...[
                const SizedBox(height: 10),
                const Text('How many altogether?', textAlign: TextAlign.center),
                const SizedBox(height: 10),
                _choices(),
              ],
            ] else ...[
              LayoutBuilder(
                builder: (context, box) => ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: double.infinity,
                    height: mathsBannerHeight(context, box.maxWidth),
                    child: MathsBackdrop(
                      scene: widget.config['scene'] as String,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_task['mode'] == 'build') ...[
                if (_task['visual'] is Map) ...[
                  MathsVisual(data: Map<String, dynamic>.from(_task['visual'])),
                  const SizedBox(height: 12),
                ],
                MathsVisual(
                  data: {
                    'type': 'count',
                    'count': _built,
                    'item': _item,
                    'arrangement': _task['arrangement'] ?? 'row',
                  },
                ),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    '$_built',
                    key: const ValueKey('maths-build-total'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      key: const ValueKey('maths-build-remove'),
                      onPressed: _locked || _built == 0
                          ? null
                          : () => _build(-1),
                      icon: const Icon(Icons.remove_rounded),
                      label: const Text('Take one away'),
                    ),
                    FilledButton.icon(
                      key: const ValueKey('maths-build-add'),
                      onPressed:
                          _locked || _built >= (_task['maxCount'] as int? ?? 20)
                          ? null
                          : () => _build(1),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add one'),
                    ),
                    FilledButton.tonal(
                      key: const ValueKey('maths-build-check'),
                      onPressed: _locked
                          ? null
                          : () => _answer(_built == _task['target']),
                      child: const Text('Check my group'),
                    ),
                  ],
                ),
              ] else ...[
                if (_task['visual'] is Map) ...[
                  MathsVisual(data: Map<String, dynamic>.from(_task['visual'])),
                  const SizedBox(height: 12),
                ],
                _choices(),
              ],
            ],
          ],
          if (message.isNotEmpty) ...[
            const SizedBox(height: 14),
            Semantics(
              liveRegion: true,
              child: Text(message, textAlign: TextAlign.center),
            ),
          ],
          if (_passed && !_done) ...[
            const SizedBox(height: 12),
            Center(
              child: FilledButton.icon(
                key: const ValueKey('maths-workshop-next'),
                onPressed: _continue,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  _index == _tasks.length - 1
                      ? 'Finish practice'
                      : 'Try the next idea',
                ),
              ),
            ),
          ],
          SizedBox(key: _end, height: 0),
        ],
      ),
    );
  }
}

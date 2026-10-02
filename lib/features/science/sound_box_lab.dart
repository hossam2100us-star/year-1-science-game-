import 'package:flutter/material.dart';

import '../../content/lesson.dart';
import '../../core/touch_cue.dart';
import 'science_lab.dart';
import 'sound_picture.dart';
import 'sound_ui.dart';

class SoundBoxLab extends StatefulWidget {
  const SoundBoxLab({
    super.key,
    required this.step,
    required this.data,
    required this.onChange,
    required this.onSound,
    required this.onSpeak,
  });
  final LessonStep step;
  final Map<String, dynamic> data;
  final Future<void> Function(Map<String, dynamic>, bool) onChange;
  final void Function(String, double) onSound;
  final ValueChanged<String> onSpeak;
  @override
  State<SoundBoxLab> createState() => _SoundBoxLabState();
}

class _SoundBoxLabState extends State<SoundBoxLab> {
  bool busy = false, retry = false;
  int pulse = 0;
  String? playing;
  Map<String, dynamic> get data => widget.data;
  Map get ui => widget.step.json['labUi'];
  Map get observation => widget.step.json['observationUi'];
  String get active => data['active'] ?? widget.step.options.first.id;
  Map get guesses => data['guesses'] ?? {};
  Set<String> get tested => Set<String>.from(data['tested'] ?? []);
  Future<void> save(Map<String, dynamic> patch) async {
    if (busy) return;
    setState(() => busy = true);
    final next = {...data, ...patch};
    try {
      await widget.onChange(
        next,
        ScienceLab.experimentComplete(widget.step, next),
      );
    } catch (_) {
      widget.onSpeak('Saving needs help. Please try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void sound() {
    setState(() {
      playing = active;
      pulse++;
    });
    widget.onSound(active == 'stone_box' ? 'stone' : 'feather', 1);
  }

  Future<void> shake() async {
    if (busy || !guesses.containsKey(active)) return;
    // Start audio in the child's gesture, before the asynchronous progress write.
    sound();
    if (!tested.contains(active))
      await save({
        'tested': {...tested, active}.toList(),
      });
  }

  Widget caption(String value) => Padding(
    padding: const EdgeInsets.all(10),
    child: Text(
      value,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
    ),
  );
  Widget button(String id, String label, VoidCallback? callback) =>
      FilledButton.tonal(
        key: ValueKey('lab-$id'),
        onPressed: busy ? null : callback,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 21),
          ),
        ),
      );
  @override
  Widget build(BuildContext context) {
    final pending = ScienceLab.pendingObservations(widget.step, data);
    final heard = tested.contains(active);
    final result = widget.step.json['results'][active];
    final phases = List<String>.from(ui['phases']);
    return SoundSurface(
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 12,
            children: [
              for (final p in widget.step.options)
                SizedBox(
                  width: 150,
                  child: OutlinedButton(
                    key: ValueKey('lab-choose-${p.id}'),
                    onPressed: busy
                        ? null
                        : () {
                            setState(() => retry = false);
                            save({'active': p.id});
                          },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: p.id == active
                          ? const Color(0xFFDEEAF0)
                          : const Color(0xFFF9F3E8),
                      padding: const EdgeInsets.all(8),
                    ),
                    child: Column(
                      children: [
                        SoundPicture(p.id, height: 85),
                        Text(
                          p.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 19),
                        ),
                        if (tested.contains(p.id) && !pending.contains(p.id))
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SoundPhases(
            labels: phases,
            current: !guesses.containsKey(active)
                ? 0
                : heard
                ? 2
                : 1,
          ),
          GestureDetector(
            key: const ValueKey('lab-sound-box'),
            onTap: busy || !guesses.containsKey(active) ? null : shake,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SoundDemonstration(
                  active,
                  key: ValueKey('box-$active-$pulse'),
                  height: 205,
                  play: playing == active && pulse > 0,
                ),
                if (guesses.containsKey(active))
                  const Positioned(right: 15, bottom: 12, child: TouchCue()),
              ],
            ),
          ),
          if (!heard) ...[
            caption(ui['prediction']),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                for (final id in ['loud', 'quiet'])
                  button(
                    'guess-$id',
                    '${guesses[active] == id ? '✓ ' : ''}${ui['choices'][id]}',
                    () => save({
                      'guesses': {...guesses, active: id},
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            button(
              'test',
              ui['action'],
              guesses.containsKey(active) ? shake : null,
            ),
          ] else ...[
            caption(
              '${ui['yourPrediction']}: ${ui['choices'][guesses[active]]}',
            ),
            button('replay', ui['replay'], shake),
            if (pending.contains(active)) ...[
              caption(observation['question']),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  for (final id in ['loud', 'quiet'])
                    button('observe-$id', ui['choices'][id], () {
                      if (id != result) {
                        setState(() => retry = true);
                        return;
                      }
                      setState(() => retry = false);
                      save({
                        'observed': {
                          ...Map.from(data['observed'] ?? {}),
                          active: id,
                        },
                      });
                    }),
                ],
              ),
              if (retry) caption(observation['retry']),
            ] else ...[
              caption('${ui['result']}: ${ui['choices'][result]}'),
              if (widget.step.options.any((p) => !tested.contains(p.id)))
                button(
                  'next-box',
                  ui['nextBox'],
                  () => save({
                    'active': widget.step.options
                        .firstWhere((p) => !tested.contains(p.id))
                        .id,
                  }),
                ),
            ],
          ],
          if (pending.any((id) => id != active))
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                for (final id in pending.where((id) => id != active))
                  button(
                    'review-$id',
                    '${observation['review']}: ${widget.step.label(id)}',
                    () => save({'active': id}),
                  ),
              ],
            ),
          caption(
            '${ui['progress']}: ${tested.length - pending.length} / ${widget.step.options.length}',
          ),
          if (ScienceLab.experimentComplete(widget.step, data))
            caption(widget.step.explanation),
        ],
      ),
    );
  }
}

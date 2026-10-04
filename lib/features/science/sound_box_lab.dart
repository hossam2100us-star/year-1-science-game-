import 'package:flutter/material.dart';

import '../../content/lesson.dart';
import '../../core/touch_cue.dart';
import 'science_lab.dart';
import 'sound_picture.dart';
import 'sound_ui.dart';
import '../../core/diagnostics/app_log.dart';

class SoundBoxLab extends StatefulWidget {
  const SoundBoxLab({
    super.key,
    required this.step,
    required this.data,
    required this.onChange,
    required this.onSound,
    required this.onSpeak,
    this.onFeedback,
  });
  final LessonStep step;
  final Map<String, dynamic> data;
  final Future<void> Function(Map<String, dynamic>, bool) onChange;
  final void Function(String, double) onSound;
  final ValueChanged<String> onSpeak;
  final ValueChanged<String>? onFeedback;
  @override
  State<SoundBoxLab> createState() => _SoundBoxLabState();
}

class _SoundBoxLabState extends State<SoundBoxLab> {
  bool busy = false, retry = false;
  int pulse = 0;
  String? playing;
  String? retryChoice;
  Map<String, dynamic> get data => widget.data;
  Map get ui => widget.step.json['labUi'];
  Map get observation => widget.step.json['observationUi'];
  String get active => data['active'] ?? widget.step.options.first.id;
  Map get guesses => data['guesses'] ?? {};
  Set<String> get tested => Set<String>.from(data['tested'] ?? []);
  void feedback(String text, {bool speak = true}) {
    if (!mounted) return;
    widget.onFeedback?.call(text);
    if (speak) widget.onSpeak(text);
  }

  String resultFeedback(Map<String, dynamic> next, String id) {
    if (!Set<String>.from(next['tested'] ?? []).contains(id)) {
      return ui['prediction'];
    }
    if (ScienceLab.pendingObservations(widget.step, next).contains(id)) {
      return '${observation['changed']} ${observation['question']}';
    }
    return '${ui['result']}: ${ui['choices'][widget.step.json['results'][id]]}.';
  }

  Future<bool> save(Map<String, dynamic> patch) async {
    if (busy) return false;
    setState(() => busy = true);
    final next = {...data, ...patch};
    try {
      await widget.onChange(
        next,
        ScienceLab.experimentComplete(widget.step, next),
      );
      return true;
    } catch (error, stack) {
      AppLog.error('sound', 'Saving the sound box lab failed', error, stack);
      feedback('Saving needs help. Please try again.');
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> chooseBox(String id) async {
    if (busy) return;
    setState(() {
      retry = false;
      retryChoice = null;
    });
    final next = {...data, 'active': id};
    if (await save({'active': id})) feedback(resultFeedback(next, id));
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
    final next = {
      ...data,
      'tested': {...tested, active}.toList(),
    };
    if (!tested.contains(active) && !await save({'tested': next['tested']})) {
      return;
    }
    // Keep speech from cutting off the experimental sound. The visible footer
    // has a replay control if the child wants to hear this instruction.
    feedback(resultFeedback(next, active), speak: false);
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
                    onPressed: busy ? null : () => chooseBox(p.id),
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
                    () async {
                      if (await save({
                        'guesses': {...guesses, active: id},
                      })) {
                        feedback(
                          '${ui['yourPrediction']}: ${ui['choices'][id]}. ${ui['afterPrediction'] ?? 'Now shake this box and listen.'}',
                        );
                      }
                    },
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
              caption(observation['changed']),
              caption(observation['question']),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  for (final id in ['loud', 'quiet'])
                    button(
                      'observe-$id',
                      '${retryChoice == id ? '? ' : ''}${ui['choices'][id]}',
                      () async {
                        if (id != result) {
                          setState(() {
                            retry = true;
                            retryChoice = id;
                          });
                          feedback(observation['retry']);
                          return;
                        }
                        final observed = {
                          ...Map.from(data['observed'] ?? {}),
                          active: id,
                        };
                        if (!await save({'observed': observed}) || !mounted)
                          return;
                        setState(() {
                          retry = false;
                          retryChoice = null;
                        });
                        feedback(
                          '${observation['complete']} ${ui['result']}: ${ui['choices'][id]}.',
                        );
                      },
                    ),
                ],
              ),
              if (retry)
                Semantics(
                  liveRegion: true,
                  child: caption(observation['retry']),
                ),
            ] else ...[
              caption('${ui['result']}: ${ui['choices'][result]}'),
              if (widget.step.options.any((p) => !tested.contains(p.id)))
                button(
                  'next-box',
                  ui['nextBox'],
                  () => chooseBox(
                    widget.step.options
                        .firstWhere((p) => !tested.contains(p.id))
                        .id,
                  ),
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
                    () => chooseBox(id),
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

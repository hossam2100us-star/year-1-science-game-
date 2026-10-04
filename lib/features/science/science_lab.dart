import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/touch_cue.dart';

import '../../content/lesson.dart';
import 'science_picture.dart';
import 'science_world_stage.dart';
import 'water_trial.dart';
import 'shape_trial.dart';
import 'force_picture.dart';
import 'force_guided_lab.dart';
import 'sound_picture.dart';
import 'sound_distance.dart';
import 'sound_box_lab.dart';
import 'sound_ui.dart';
import 'earth_collection.dart';
import '../../core/diagnostics/app_log.dart';

/// Ungraded experiments retain guesses before revealing any source-defined result.
class ScienceLab extends StatefulWidget {
  const ScienceLab({
    super.key,
    required this.step,
    required this.data,
    required this.onChange,
    required this.onSpeak,
    required this.onSound,
    this.onFeedback,
  });
  final LessonStep step;
  final Map<String, dynamic> data;
  final Future<void> Function(Map<String, dynamic>, bool) onChange;
  final ValueChanged<String> onSpeak;
  final void Function(String, double) onSound;
  final ValueChanged<String>? onFeedback;

  /// Predictions are never scored; only mismatches need an observation check.
  static List<String> pendingObservations(
    LessonStep step,
    Map<String, dynamic> data,
  ) {
    if (step.json['observationUi'] == null) return [];
    final tested = List<String>.from(data['tested'] ?? []);
    final guesses = Map<String, dynamic>.from(data['guesses'] ?? {});
    final observed = Map<String, dynamic>.from(data['observed'] ?? {});
    final results = Map<String, dynamic>.from(step.json['results']);
    return step.options
        .where(
          (p) =>
              tested.contains(p.id) &&
              guesses[p.id] != results[p.id] &&
              observed[p.id] != results[p.id],
        )
        .map((p) => p.id)
        .toList();
  }

  static bool distanceComplete(Map<String, dynamic> data) =>
      data['soundGuess'] != null &&
      Set<String>.from(data['heard'] ?? []).containsAll({'near', 'far'});

  static bool experimentComplete(LessonStep step, Map<String, dynamic> data) {
    final tested = List<String>.from(data['tested'] ?? []);
    final decision = step.json['labUi']?['decision'];
    return step.options.every((p) => tested.contains(p.id)) &&
        pendingObservations(step, data).isEmpty &&
        (decision == null ||
            step.json['results'][data['decision']] == decision['result']);
  }

  static bool shapeComplete(LessonStep step, Map<String, dynamic> data) {
    final tried = List<String>.from(data['shapeTried'] ?? []);
    final actions = <String>{};
    final outcomes = <String>{};
    for (final key in tried) {
      final parts = key.split(':');
      if (parts.length != 2) continue;
      final result = step.json['shapeResults'][parts[0]]?[parts[1]];
      if (result != null) {
        actions.add(parts[1]);
        outcomes.add(result);
      }
    }
    return actions.length == 4 && outcomes.containsAll(['change', 'same']);
  }

  static bool forceComplete(Map<String, dynamic> data) =>
      List<String>.from(data['visited'] ?? [])
          .toSet()
          .containsAll(['near', 'far']) &&
      List<String>.from(data['pushTrials'] ?? [])
          .toSet()
          .containsAll(['gentle', 'strong']);

  static bool boatComplete(Map<String, dynamic> data) =>
      (data['distance'] as num? ?? 0) >= 1 && data['boatPrediction'] != null;

  @override
  State<ScienceLab> createState() => _ScienceLabState();
}

class _ScienceLabState extends State<ScienceLab> {
  bool busy = false;
  Timer? breeze;
  String? starName;
  int soundPulse = 0;
  String? soundingBox;
  double? soundPosition;
  String? observationRetry;
  bool decisionRetry = false;
  String get mode => widget.step.json['lab'];
  Map<String, dynamic> get state => widget.data;
  Map<String, dynamic> get ui =>
      Map<String, dynamic>.from(widget.step.json['labUi'] ?? {});
  List<String> get visited => List<String>.from(state['visited'] ?? []);
  Future<bool> save(Map<String, dynamic> patch, {bool complete = false}) async {
    if (busy) return false;
    setState(() => busy = true);
    try {
      await widget.onChange({...state, ...patch}, complete);
      return true;
    } catch (error, stack) {
      AppLog.error('lab', 'Saving the science lab failed', error, stack);
      if (mounted) widget.onSpeak("Saving needs help. Please try again.");
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    breeze?.cancel();
    super.dispose();
  }

  Widget button(String key, String label, VoidCallback? action) => Padding(
    padding: const EdgeInsets.all(5),
    child: FilledButton.tonal(
      key: ValueKey('lab-$key'),
      onPressed: busy ? null : action,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22),
        ),
      ),
    ),
  );
  Widget caption(String s) => Padding(
    padding: const EdgeInsets.all(10),
    child: Text(
      s,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
    ),
  );
  Widget picture(String art, [double height = 160]) => mode == 'sound-box'
      ? SoundPicture(art, height: height)
      : ['force', 'tank', 'sailboat'].contains(mode)
      ? ForcePicture(art, height: height)
      : SciencePicture(art, height: height);
  @override
  Widget build(BuildContext context) => mode == 'sound-box'
      ? SoundBoxLab(
          step: widget.step,
          data: state,
          onChange: widget.onChange,
          onSound: widget.onSound,
          onSpeak: widget.onSpeak,
          onFeedback: widget.onFeedback,
        )
      : Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFE7EFF0),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              if (['waterproof', 'tank', 'magnet', 'sound-box'].contains(mode))
                _experiment(),
              if (mode == 'force') _force(),
              if (mode == 'distance') _distance(),
              if (mode == 'sailboat') _boat(),
              if (mode == 'shape') _shape(),
              if (mode == 'soil' || mode == 'cleanup' || mode == 'rock-sort')
                _collection(),
              if (mode == 'day-night') _day(),
              if (mode == 'earth-paint') _paint(),
              if (mode == 'stars') _stars(),
            ],
          ),
        );
  Widget _experiment() {
    final opts = widget.step.options;
    final active = state['active'] as String? ?? opts.first.id;
    final item = opts.firstWhere((o) => o.id == active);
    final guesses = Map<String, dynamic>.from(state['guesses'] ?? {});
    final tested = List<String>.from(state['tested'] ?? []);
    final revealed = tested.contains(active);
    final result = widget.step.json['results'][active] as String;
    final choices = Map<String, dynamic>.from(ui['choices']);
    final observation = Map<String, dynamic>.from(
      widget.step.json['observationUi'] ?? {},
    );
    final pending = ScienceLab.pendingObservations(widget.step, state);
    final needsObservation = pending.contains(active);
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            for (final p in opts)
              ui['pictureChoices'] == true
                  ? Padding(
                      padding: const EdgeInsets.all(5),
                      child: SizedBox(
                        width: 145,
                        child: FilledButton.tonal(
                          key: ValueKey('lab-choose-${p.id}'),
                          onPressed: busy ? null : () => save({'active': p.id}),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.all(8),
                            side: BorderSide(
                              color: active == p.id
                                  ? const Color(0xFF497B73)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              picture(mode == 'sound-box' ? p.id : p.art, 75),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 55,
                                child: Center(
                                  child: Text(
                                    p.label,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : button(
                      'choose-${p.id}',
                      p.label,
                      () => save({'active': p.id}),
                    ),
          ],
        ),
        if (pending.isNotEmpty)
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              for (final id in pending)
                button(
                  'review-$id',
                  '${observation['review']}: ${opts.firstWhere((p) => p.id == id).label}',
                  () => save({'active': id}),
                ),
            ],
          ),
        if (mode == 'waterproof' && widget.step.json['waterScene'] != null)
          WaterTrial(
            material: active,
            umbrella: widget.step.json['waterScene'] == 'umbrella',
            revealed: revealed,
            leaks: result == 'wet',
          )
        else if (mode == 'sound-box')
          GestureDetector(
            key: const ValueKey('lab-sound-box'),
            onTap: busy || !guesses.containsKey(active)
                ? null
                : () => revealed ? replayBox(active) : test(active, tested),
            child: Stack(
              children: [
                SoundDemonstration(
                  active,
                  key: ValueKey('box-$active-$soundPulse'),
                  height: 220,
                  play: revealed && soundingBox == active && soundPulse > 0,
                  revealed: revealed,
                ),
                if (guesses.containsKey(active))
                  const Positioned(right: 12, bottom: 12, child: TouchCue()),
              ],
            ),
          )
        else if (mode == 'magnet')
          _magnetScene(
            item,
            revealed,
            result,
            guesses.containsKey(active),
            () => test(active, tested),
          )
        else
          SizedBox(
            height: 300,
            child: LayoutBuilder(
              builder: (context, box) => Stack(
                alignment: Alignment.center,
                children: [
                  if (mode == 'tank')
                    Positioned(
                      left: box.maxWidth * .15,
                      right: box.maxWidth * .15,
                      top: 90,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF9FD5E5),
                          border: Border.all(
                            color: const Color(0xFF43778D),
                            width: 4,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(28),
                          ),
                        ),
                      ),
                    ),
                  if (mode == 'waterproof')
                    Positioned(
                      top: 70,
                      child: Container(
                        width: 190,
                        height: 220,
                        decoration: BoxDecoration(
                          color: revealed && result == 'wet'
                              ? const Color(0xFF9FD5E5)
                              : const Color(0xFFFDFBF1),
                          border: Border.all(
                            color: const Color(0xFF67848E),
                            width: 4,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(30),
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: revealed
                              ? caption(choices[result])
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  if (mode == 'magnet')
                    Positioned(
                      left: box.maxWidth * .08,
                      top: 60,
                      child: Draggable<String>(
                        data: 'magnet',
                        feedback: Material(
                          color: Colors.transparent,
                          child: picture('magnet', 130),
                        ),
                        childWhenDragging: const SizedBox(
                          width: 130,
                          height: 130,
                        ),
                        child: picture('magnet', 130),
                      ),
                    ),
                  AnimatedPositioned(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 850),
                    curve: Curves.easeInOut,
                    left: mode == 'magnet' && revealed && result == 'pull'
                        ? box.maxWidth * .15
                        : (box.maxWidth - 140) / 2,
                    top: mode == 'tank'
                        ? (revealed ? (result == 'float' ? 60 : 170) : 0)
                        : mode == 'waterproof'
                        ? 20
                        : 75,
                    child: DragTarget<String>(
                      onWillAcceptWithDetails: (d) =>
                          mode == 'magnet' &&
                          d.data == 'magnet' &&
                          guesses.containsKey(active) &&
                          !revealed,
                      onAcceptWithDetails: (_) => test(active, tested),
                      builder: (context, c, r) => picture(item.art, 130),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (!revealed)
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              for (final e in choices.entries)
                button(
                  'guess-${e.key}',
                  '${guesses[active] == e.key ? '✓ ' : ''}${e.value}',
                  () => save({
                    'guesses': {...guesses, active: e.key},
                  }),
                ),
            ],
          ),
        if (!revealed)
          button(
            'test',
            ui['action'],
            guesses.containsKey(active) ? () => test(active, tested) : null,
          ),
        if (revealed) ...[
          if (mode == 'sound-box')
            button('replay', ui['replay'], () => replayBox(active)),
          caption('${ui['result']}: ${choices[result]}'),
          caption('Your prediction: ${choices[guesses[active]]}'),
          if (needsObservation) ...[
            caption(observation['changed']),
            caption(
              observationRetry == active
                  ? observation['retry']
                  : observation['question'],
            ),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                for (final e in choices.entries)
                  button(
                    'observe-${e.key}',
                    e.value,
                    () => observe(active, e.key),
                  ),
              ],
            ),
          ] else if (observation.isNotEmpty &&
              (state['observed'] as Map? ?? {}).containsKey(active))
            caption(observation['complete'])
          else
            const Icon(Icons.visibility_rounded, size: 30),
        ],
        caption('${tested.length} / ${opts.length} explored'),
        if (ui['decision'] != null &&
            tested.length == opts.length &&
            pending.isEmpty) ...[
          caption(ui['decision']['question']),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              for (final p in opts)
                button(
                  'decision-${p.id}',
                  '${state['decision'] == p.id ? '✓ ' : ''}${p.label}',
                  state['decision'] == null ? () => decide(p.id) : null,
                ),
            ],
          ),
          if (decisionRetry) caption(ui['decision']['retry']),
          if (state['decision'] != null) caption(ui['decision']['complete']),
        ],
      ],
    );
  }

  Widget _magnetScene(
    PictureItem item,
    bool revealed,
    String result,
    bool predicted,
    VoidCallback tryMagnet,
  ) => ClipRRect(
    key: const ValueKey('lab-magnet-scene'),
    borderRadius: BorderRadius.circular(24),
    child: Stack(
      children: [
        const Positioned.fill(child: ScienceWorldBackdrop(row: 0)),
        SizedBox(
          height: 250,
          width: double.infinity,
          child: FittedBox(
            child: SizedBox(
              width: 440,
              height: 250,
              child: Stack(
                children: [
                  Positioned(
                    left: 35,
                    top: 70,
                    child: Draggable<String>(
                      data: 'magnet',
                      maxSimultaneousDrags: predicted && !revealed && !busy
                          ? 1
                          : 0,
                      feedback: Material(
                        color: Colors.transparent,
                        child: picture('magnet', 105),
                      ),
                      childWhenDragging: const SizedBox(
                        width: 132,
                        height: 105,
                      ),
                      child: picture('magnet', 105),
                    ),
                  ),
                  AnimatedPositioned(
                    key: const ValueKey('lab-magnet-object'),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 850),
                    curve: Curves.easeInOut,
                    left: revealed && result == 'pull' ? 155 : 275,
                    top: 70,
                    child: DragTarget<String>(
                      onWillAcceptWithDetails: (details) =>
                          !busy &&
                          predicted &&
                          !revealed &&
                          details.data == 'magnet',
                      onAcceptWithDetails: (_) => tryMagnet(),
                      builder: (context, candidates, rejected) => SizedBox(
                        width: 140,
                        height: 140,
                        child: Column(
                          children: [
                            picture(item.art, 105),
                            if (predicted && !revealed) const TouchCue(),
                          ],
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
  );

  void replayBox(String active) {
    if (busy) return;
    setState(() {
      soundPulse++;
      soundingBox = active;
    });
    widget.onSound(active == 'stone_box' ? 'stone' : 'feather', 1);
  }

  Future<void> test(String active, List<String> tested) async {
    if (tested.contains(active) ||
        !(state['guesses'] as Map? ?? {}).containsKey(active)) {
      return;
    }
    final next = {...tested, active}.toList();
    final complete = ScienceLab.experimentComplete(widget.step, {
      ...state,
      'tested': next,
    });
    if (!await save({'tested': next}, complete: complete)) return;
    if (mounted) {
      if (mode == 'sound-box') {
        setState(() {
          soundPulse++;
          soundingBox = active;
        });
        widget.onSound(active == 'stone_box' ? 'stone' : 'feather', 1);
      }
      final item = widget.step.options.firstWhere((p) => p.id == active);
      final result = widget.step.json['results'][active];
      widget.onSpeak(
        ScienceLab.pendingObservations(widget.step, {
              ...state,
              'tested': next,
            }).contains(active)
            ? '${item.label}. ${ui['choices'][result]}. ${widget.step.json['observationUi']['changed']} ${widget.step.json['observationUi']['question']}'
            : complete
            ? widget.step.explanation
            : '${item.label}. ${ui['choices'][result]}.',
      );
    }
  }

  Future<void> decide(String id) async {
    if (busy) return;
    final decision = ui['decision'];
    if (widget.step.json['results'][id] != decision['result']) {
      setState(() => decisionRetry = true);
      widget.onSpeak(decision['retry']);
      return;
    }
    final next = {...state, 'decision': id, 'active': id};
    if (await save({
          'decision': id,
          'active': id,
        }, complete: ScienceLab.experimentComplete(widget.step, next)) &&
        mounted) {
      setState(() => decisionRetry = false);
      widget.onSpeak(decision['complete']);
    }
  }

  Future<void> observe(String active, String choice) async {
    if (busy ||
        !ScienceLab.pendingObservations(widget.step, state).contains(active)) {
      return;
    }
    final observation = widget.step.json['observationUi'] as Map;
    if (choice != widget.step.json['results'][active]) {
      setState(() => observationRetry = active);
      widget.onSpeak(observation['retry']);
      return;
    }
    final observed = {
      ...Map<String, dynamic>.from(state['observed'] ?? {}),
      active: choice,
    };
    final complete = ScienceLab.experimentComplete(widget.step, {
      ...state,
      'observed': observed,
    });
    if (await save({'observed': observed}, complete: complete) && mounted) {
      setState(() => observationRetry = null);
      widget.onSpeak(observation['complete']);
    }
  }

  Widget _force() => ForceGuidedLab(
    data: state,
    ui: ui,
    onSave: (next) => save(next, complete: ScienceLab.forceComplete(next)),
    onSpeak: widget.onSpeak,
    onFeedback: widget.onFeedback,
  );

  Widget _distance() {
    final v = soundPosition ?? (state['position'] as num? ?? .5).toDouble();
    final heard = Set<String>.from(state['heard'] ?? []);
    Future<void> move(double value) async {
      await save({
        'position': value,
      }, complete: ScienceLab.distanceComplete(state));
      if (mounted) setState(() => soundPosition = null);
    }

    Future<void> listen() async {
      if (state['soundGuess'] == null || busy) return;
      final next = {...heard, if (v < .25) 'near', if (v > .75) 'far'};
      final patch = {
        'heard': next.toList(),
        'position': v,
        'soundGuess': state['soundGuess'],
        'lastHeard': v < .25
            ? 'near'
            : v > .75
            ? 'far'
            : 'middle',
        'plays': (state['plays'] as int? ?? 0) + 1,
      };
      widget.onSound('drum', 1 - v * .65);
      await save(patch, complete: ScienceLab.distanceComplete(patch));
    }

    return Column(
      children: [
        SoundPhases(
          labels: List<String>.from(ui['phases']),
          current: state['soundGuess'] == null
              ? 0
              : heard.length < 2
              ? 1
              : 2,
        ),
        if (state['soundGuess'] == null) ...[
          caption(ui['prediction']),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              for (final entry in (ui['choices'] as Map).entries)
                button(
                  'distance-guess-${entry.key}',
                  entry.value,
                  () => save({'soundGuess': entry.key}),
                ),
            ],
          ),
        ] else
          caption(
            '${ui['yourPrediction']}: ${ui['choices'][state['soundGuess']]}',
          ),
        caption(ui['instruction']),
        SoundDistance(
          position: v,
          pulse: state['plays'] as int? ?? 0,
          listenerLabel: ui['you'],
          onListen: busy || state['soundGuess'] == null ? null : listen,
          onMove: busy ? null : move,
        ),
        if (state['soundGuess'] != null)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: [
              for (final id in ['near', 'far'])
                button(
                  'distance-$id',
                  '${heard.contains(id) ? '✓ ' : ''}${ui[id]}',
                  () => move(id == 'near' ? .05 : .95),
                ),
            ],
          ),
        if (state['soundGuess'] != null)
          caption(
            v < .25
                ? ui['near']
                : v > .75
                ? ui['far']
                : ui['middle'],
          ),
        Slider(
          key: const ValueKey('lab-slider'),
          value: v,
          onChanged: busy
              ? null
              : (value) => setState(() => soundPosition = value),
          onChangeEnd: busy ? null : move,
        ),
        button(
          'distance-listen',
          ui['listen'],
          state['soundGuess'] == null ? null : listen,
        ),
        if ((state['plays'] as int? ?? 0) > 0)
          caption(
            state['lastHeard'] == 'near'
                ? ui['heardNear']
                : state['lastHeard'] == 'far'
                ? ui['heardFar']
                : ui['middle'],
          ),
        caption('${ui['progress']}: ${heard.length} / 2'),
        if (ScienceLab.distanceComplete(state)) caption(ui['result']),
      ],
    );
  }

  Widget _boat() {
    final v = (state['distance'] as num? ?? 0).toDouble();
    return Column(
      children: [
        SizedBox(
          height: 260,
          child: LayoutBuilder(
            builder: (context, c) => Stack(
              children: [
                Positioned.fill(
                  top: 160,
                  child: Container(color: const Color(0xFF9EDBE9)),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 180),
                  left: (c.maxWidth - 160) * v,
                  top: 40,
                  child: picture('sailboat', 160),
                ),
              ],
            ),
          ),
        ),
        if (state['boatPrediction'] == null) ...[
          caption(ui['prediction']),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              for (final e in (ui['choices'] as Map).entries)
                button(
                  'boat-guess-${e.key}',
                  e.value,
                  () => save({'boatPrediction': e.key}),
                ),
            ],
          ),
        ],
        Listener(
          onPointerDown: (_) {
            if (state['boatPrediction'] == null || busy) return;
            breeze?.cancel();
            breeze = Timer.periodic(const Duration(milliseconds: 200), (_) {
              final d = ((state['distance'] as num? ?? 0) + .055).clamp(
                0.0,
                1.0,
              );
              save({
                'distance': d,
              }, complete: ScienceLab.boatComplete({...state, 'distance': d}));
              if (d >= 1) breeze?.cancel();
            });
          },
          onPointerUp: (_) => breeze?.cancel(),
          onPointerCancel: (_) => breeze?.cancel(),
          child: button(
            'blow',
            ui['action'],
            state['boatPrediction'] == null
                ? null
                : () => save(
                    {'distance': (v + .15).clamp(0.0, 1.0)},
                    complete: ScienceLab.boatComplete({
                      ...state,
                      'distance': (v + .15).clamp(0.0, 1.0),
                    }),
                  ),
          ),
        ),
        if (v >= 1) ...[
          caption(ui['result']),
          caption('Your prediction: ${ui['choices'][state['boatPrediction']]}'),
        ],
      ],
    );
  }

  Widget _shape() {
    final item = widget.step.options.firstWhere(
      (p) => p.id == state['active'],
      orElse: () => widget.step.options.first,
    );
    final actions = List<String>.from(
      widget.step.json['shapeActions'][item.id],
    );
    final action = actions.contains(state['action'])
        ? state['action'] as String
        : actions.first;
    final key = '${item.id}:$action';
    final guesses = Map<String, dynamic>.from(state['shapeGuesses'] ?? {});
    final tried = List<String>.from(state['shapeTried'] ?? []);
    final revealed = tried.contains(key);
    final outcomes = tried
        .map((entry) {
          final parts = entry.split(':');
          return widget.step.json['shapeResults'][parts[0]]?[parts[1]];
        })
        .whereType<String>()
        .toSet();
    final result = widget.step.json['shapeResults'][item.id][action];
    return Column(
      children: [
        caption(ui['instruction']),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            for (final p in widget.step.options)
              button(
                'shape-${p.id}',
                '${item.id == p.id ? '• ' : ''}${p.label}',
                () => save({'active': p.id, 'action': null}),
              ),
          ],
        ),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            for (final a in actions)
              button(
                'action-$a',
                '${action == a ? '• ' : ''}$a',
                () => save({'action': a}),
              ),
          ],
        ),
        ShapeTrial(
          material: item.id,
          art: item.art,
          action: action,
          revealed: revealed,
        ),
        if (!revealed) ...[
          caption(ui['predict']),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              for (final e in (ui['choices'] as Map).entries)
                button(
                  'shape-guess-${e.key}',
                  '${guesses[key] == e.key ? '✓ ' : ''}${e.value}',
                  () => save({
                    'shapeGuesses': {...guesses, key: e.key},
                  }),
                ),
            ],
          ),
          button(
            'shape-test',
            ui['try'],
            guesses.containsKey(key)
                ? () async {
                    final next = {...tried, key}.toList();
                    if (await save(
                          {'shapeTried': next},
                          complete: ScienceLab.shapeComplete(widget.step, {
                            ...state,
                            'shapeTried': next,
                          }),
                        ) &&
                        mounted) {
                      widget.onSpeak(
                        '${item.label}. $action. ${ui[result == 'change' ? 'changed' : 'same']}',
                      );
                    }
                  }
                : null,
          ),
        ] else ...[
          caption(ui[result == 'change' ? 'changed' : 'same']),
          caption('Your prediction: ${ui['choices'][guesses[key]]}'),
        ],
        caption(
          '${ui['progress']}: ${tried.map((k) => k.split(':').last).toSet().length} / 4  -  ${ui['comparison']}: ${outcomes.length} / 2',
        ),
      ],
    );
  }

  Widget _collection() {
    return EarthCollection(
      key: ValueKey(widget.step.id),
      step: widget.step,
      data: state,
      onChange: widget.onChange,
      onSpeak: widget.onSpeak,
      onFeedback: widget.onFeedback,
    );
  }

  Widget _day() {
    final turns = (state['turns'] as int? ?? 0);
    final angle = turns * math.pi / 2;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              const Positioned.fill(child: ScienceWorldBackdrop(row: 2)),
              SizedBox(
                height: 270,
                width: double.infinity,
                child: FittedBox(
                  child: SizedBox(
                    width: 500,
                    height: 270,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(left: 22, child: picture('sun', 130)),
                        Positioned(
                          right: 25,
                          child: SizedBox(
                            width: 220,
                            height: 220,
                            child: Stack(
                              children: [
                                ClipOval(
                                  child: Transform.rotate(
                                    angle: angle,
                                    child: const SizedBox(
                                      width: 220,
                                      height: 220,
                                      child: SciencePicture(
                                        'earth',
                                        height: 220,
                                      ),
                                    ),
                                  ),
                                ),
                                const Positioned.fill(
                                  child: CustomPaint(painter: _NightShade()),
                                ),
                                Positioned(
                                  left: 96 + 60 * math.cos(angle),
                                  top: 96 + 60 * math.sin(angle),
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    size: 28,
                                    color: Color(0xFFEB5D51),
                                  ),
                                ),
                              ],
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
        caption(math.cos(angle) < 0 ? 'Your place: Day' : 'Your place: Night'),
        button(
          'turn',
          ui['action'],
          () => save({'turns': turns + 1}, complete: turns + 1 >= 4),
        ),
      ],
    );
  }

  Widget _paint() => Column(
    children: [
      SizedBox(
        height: 280,
        width: 280,
        child: CustomPaint(
          painter: PlanetPainter(
            water: state['water'] == true,
            land: state['land'] == true,
          ),
        ),
      ),
      Wrap(
        children: [
          button(
            'water',
            ui['water'],
            () => save({'water': true}, complete: state['land'] == true),
          ),
          button(
            'land',
            ui['land'],
            () => save({'land': true}, complete: state['water'] == true),
          ),
        ],
      ),
    ],
  );
  Widget _stars() {
    final points = List<int>.from(state['points'] ?? []);
    return Column(
      children: [
        SizedBox(
          height: 320,
          child: LayoutBuilder(
            builder: (context, c) => GestureDetector(
              key: const ValueKey('lab-stars'),
              onTapUp: (d) {
                final p = StarPainter.locations;
                var nearest = 0;
                var dist = double.infinity;
                for (var i = 0; i < p.length; i++) {
                  final x =
                      (Offset(p[i].dx * c.maxWidth, p[i].dy * 320) -
                              d.localPosition)
                          .distance;
                  if (x < dist) {
                    nearest = i;
                    dist = x;
                  }
                }
                if (dist < 48 && !points.contains(nearest)) {
                  save({
                    'points': [...points, nearest],
                  });
                }
              },
              child: CustomPaint(
                size: Size(c.maxWidth, 320),
                painter: StarPainter(points),
              ),
            ),
          ),
        ),
        TextFormField(
          key: const ValueKey('lab-star-name'),
          initialValue: state['name'] ?? '',
          decoration: InputDecoration(labelText: ui['name']),
          onChanged: (s) {
            starName = s;
            save({'name': s});
          },
        ),
        button(
          'finish-stars',
          ui['finish'],
          points.length >= 3
              ? () => save({
                  'name': starName ?? state['name'] ?? '',
                }, complete: true)
              : null,
        ),
      ],
    );
  }
}

class _NightShade extends CustomPainter {
  const _NightShade();
  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final path = Path()
      ..moveTo(centre.dx, centre.dy)
      ..arcTo(
        Rect.fromCircle(center: centre, radius: size.height * .475),
        -math.pi / 2,
        math.pi,
        false,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xBB172A43));
  }

  @override
  bool shouldRepaint(_NightShade old) => false;
}

class PlanetPainter extends CustomPainter {
  PlanetPainter({required this.water, required this.land});
  final bool water, land;
  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    c.drawOval(
      r,
      Paint()
        ..color = water ? const Color(0xFF4AA6D5) : const Color(0xFFDFE8EF),
    );
    c.save();
    c.clipPath(Path()..addOval(r));
    for (final rect in [
      const Rect.fromLTWH(.18, .12, .28, .25),
      const Rect.fromLTWH(.28, .48, .16, .35),
      const Rect.fromLTWH(.63, .2, .32, .22),
    ]) {
      c.drawOval(
        Rect.fromLTWH(
          rect.left * s.width,
          rect.top * s.height,
          rect.width * s.width,
          rect.height * s.height,
        ),
        Paint()
          ..color = land ? const Color(0xFF75AA72) : const Color(0xFFB8BEC1),
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(PlanetPainter old) =>
      old.water != water || old.land != land;
}

class StarPainter extends CustomPainter {
  StarPainter(this.points);
  final List<int> points;
  static const locations = [
    Offset(.12, .25),
    Offset(.3, .15),
    Offset(.51, .32),
    Offset(.75, .15),
    Offset(.9, .4),
    Offset(.78, .77),
    Offset(.55, .68),
    Offset(.3, .83),
    Offset(.14, .63),
  ];
  @override
  void paint(Canvas c, Size s) {
    c.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(25)),
      Paint()..color = const Color(0xFF213754),
    );
    Offset p(int i) =>
        Offset(locations[i].dx * s.width, locations[i].dy * s.height);
    for (var i = 1; i < points.length; i++) {
      c.drawLine(
        p(points[i - 1]),
        p(points[i]),
        Paint()
          ..color = const Color(0xFFF6D692)
          ..strokeWidth = 3,
      );
    }
    for (var i = 0; i < locations.length; i++) {
      c.drawCircle(
        p(i),
        points.contains(i) ? 10 : 7,
        Paint()..color = const Color(0xFFFFE5AA),
      );
    }
  }

  @override
  bool shouldRepaint(StarPainter old) => true;
}

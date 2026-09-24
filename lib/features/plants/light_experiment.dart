import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/lesson.dart';
import '../../core/providers.dart';
import 'light_game.dart';
import 'light_model.dart';

class LightExperiment extends ConsumerStatefulWidget {
  const LightExperiment({
    super.key,
    required this.step,
    required this.initial,
    required this.onSave,
    required this.onFinished,
    required this.onLeave,
    required this.position,
  });
  final LessonStep step;
  final Map<String, dynamic> initial;
  final Future<void> Function(Map<String, dynamic>) onSave;
  final Future<void> Function() onFinished, onLeave;
  final String position;
  @override
  ConsumerState<LightExperiment> createState() => _LightExperimentState();
}

class _LightExperimentState extends ConsumerState<LightExperiment>
    with WidgetsBindingObserver {
  late LightProgress progress;
  late LightGame game;
  bool ready = false, busy = false, active = true, saveFailed = false;
  String ui(String key) => widget.step.json['playUi'][key];
  String get observation =>
      widget.step.frames[progress.revealed ? 1 : 0]['caption'];
  String get spoken => progress.revealed
      ? '${widget.step.frames[1]['label']}. $observation. ${ui('predicted')} ${widget.step.label(progress.prediction!)}. ${ui('kindComparison')} ${widget.step.explanation}'
      : '${widget.step.prompt} ${widget.step.options.map((o) => o.label).join('. ')}. ${ui('waterInstruction')}';
  void speak() => ref.read(narrationProvider).speak(spoken);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    progress = LightProgress.restore(widget.initial);
    game = LightGame(
      onReady: () {
        if (mounted) {
          setState(() => ready = true);
          speak();
        }
      },
    )..progress = progress;
  }

  Future<bool> save(LightProgress next) async {
    try {
      await widget.onSave(next.toJson());
      if (!mounted) return false;
      setState(() {
        progress = next;
        game.progress = next;
        saveFailed = false;
      });
      return true;
    } catch (_) {
      if (mounted) setState(() => saveFailed = true);
      return false;
    }
  }

  Future<void> predict(String id) async {
    if (busy || progress.watered.isNotEmpty || progress.revealed) return;
    setState(() => busy = true);
    if (await save(progress.predict(id))) {
      ref
          .read(narrationProvider)
          .speak(
            '${ui('predicted')} ${widget.step.label(id)}. ${ui('waterInstruction')}',
          );
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> water(String place) async {
    if (busy ||
        !ready ||
        progress.prediction == null ||
        progress.revealed ||
        progress.watered.contains(place))
      return;
    setState(() => busy = true);
    if (await save(progress.water(place))) {
      game.pour(place);
      ref
          .read(narrationProvider)
          .speak(ui(progress.readyToCompare ? 'bothWatered' : 'oneWatered'));
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> compare() async {
    if (busy || !ready || !progress.readyToCompare || progress.revealed) return;
    setState(() => busy = true);
    try {
      // Confirm the saved prediction and equal watering before revealing the result.
      await widget.onSave(progress.toJson());
      game.doorTime = 1.2;
      ref.read(narrationProvider).speak(ui('waiting'));
      await Future<void>.delayed(
        Duration(milliseconds: game.reducedMotion ? 100 : 1200),
      );
      if (!mounted || !active) return;
      if (await save(progress.compare())) {
        game.doorTime = 0;
        speak();
      }
    } catch (_) {
      if (mounted) setState(() => saveFailed = true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> leave() async {
    if (busy) return;
    await ref.read(narrationProvider).stop();
    await widget.onLeave();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    active = state == AppLifecycleState.resumed;
    if (active) {
      game.resumeEngine();
    } else {
      game.pauseEngine();
      ref.read(narrationProvider).stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    game.pauseEngine();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    game.reducedMotion = MediaQuery.disableAnimationsOf(context);
    final labels = List<String>.from(widget.step.json['sceneLabels']);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (p, r) {
        if (!p) leave();
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: busy ? null : leave,
                          tooltip: 'My island',
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Expanded(
                          child: Text(
                            widget.step.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Text(
                          widget.position,
                          style: const TextStyle(fontSize: 22),
                        ),
                        IconButton(
                          onPressed: speak,
                          tooltip: 'Listen again',
                          icon: const Icon(Icons.volume_up_rounded),
                        ),
                      ],
                    ),
                    Text(
                      progress.revealed
                          ? widget.step.frames[1]['caption']
                          : widget.step.prompt,
                      key: const ValueKey('light-instruction'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.step.frames[progress.revealed ? 1 : 0]['label'],
                      key: const ValueKey('light-day'),
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth:
                            (MediaQuery.sizeOf(context).height * .53).clamp(
                              250.0,
                              430.0,
                            ) *
                            1.5,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: AspectRatio(
                          aspectRatio: 1.5,
                          child: LayoutBuilder(
                            builder: (context, box) => Stack(
                              children: [
                                Positioned.fill(
                                  child: GameWidget<LightGame>(
                                    game: game,
                                    loadingBuilder: (_) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                ),
                                if (!progress.revealed)
                                  for (final place in lightPlantCenters.keys)
                                    Positioned(
                                      left:
                                          box.maxWidth *
                                          (lightPlantCenters[place]! - .12),
                                      top: box.maxHeight * .3,
                                      width: box.maxWidth * .24,
                                      height: box.maxHeight * .54,
                                      child: Semantics(
                                        button: true,
                                        label: ui(
                                          place == 'window'
                                              ? 'waterWindow'
                                              : 'waterCupboard',
                                        ),
                                        child: GestureDetector(
                                          key: ValueKey('light-pot-$place'),
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () => water(place),
                                          child: const SizedBox.expand(),
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            labels[0],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            labels[1],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!progress.revealed) ...[
                      const SizedBox(height: 12),
                      if (progress.watered.isEmpty)
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: [
                            for (var i = 0; i < widget.step.options.length; i++)
                              OutlinedButton(
                                key: ValueKey(
                                  'light-guess-${widget.step.options[i].id}',
                                ),
                                onPressed: busy
                                    ? null
                                    : () => predict(widget.step.options[i].id),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor:
                                      progress.prediction ==
                                          widget.step.options[i].id
                                      ? const Color(0xFFD9F2DF)
                                      : Colors.white,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    LightPlantPicture(column: i + 1),
                                    Text(widget.step.options[i].label),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      if (progress.prediction != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          '${ui('predicted')} ${widget.step.label(progress.prediction!)}.',
                          style: const TextStyle(fontSize: 22),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: [
                            for (final place in lightPlantCenters.keys)
                              FilledButton.icon(
                                key: ValueKey('light-water-$place'),
                                onPressed:
                                    busy ||
                                        !ready ||
                                        progress.watered.contains(place)
                                    ? null
                                    : () => water(place),
                                icon: Icon(
                                  progress.watered.contains(place)
                                      ? Icons.check_circle_rounded
                                      : Icons.water_drop_rounded,
                                ),
                                label: Text(
                                  ui(
                                    place == 'window'
                                        ? 'waterWindow'
                                        : 'waterCupboard',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (progress.readyToCompare)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: FilledButton.icon(
                            key: const ValueKey('light-compare'),
                            onPressed: busy ? null : compare,
                            icon: const Icon(Icons.wb_sunny_rounded),
                            label: Text(ui(busy ? 'waiting' : 'compare')),
                          ),
                        ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Text(
                        '${ui('predicted')} ${widget.step.label(progress.prediction!)}. ${ui('kindComparison')}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.step.explanation,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const ValueKey('light-finish'),
                        onPressed: busy
                            ? null
                            : () async {
                                setState(() => busy = true);
                                try {
                                  await widget.onFinished();
                                } finally {
                                  if (mounted) setState(() => busy = false);
                                }
                              },
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(ui('continue')),
                      ),
                    ],
                    if (saveFailed)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          ui('saveError'),
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 20,
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
    );
  }
}

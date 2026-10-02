import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/lesson.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/mascot.dart';
import '../../games/science_art.dart';
import 'bean_game.dart';
import 'bean_model.dart';

class BeanPreview extends ConsumerWidget {
  const BeanPreview({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(lessonLibraryProvider)
      .when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, s) => const Scaffold(
          body: Center(child: Text('Please reopen the experiment.')),
        ),
        data: (library) {
          final step = library.lessons['unit_02']!.steps.firstWhere(
            (s) => s.json['experiment'] == 'bean',
          );
          return BeanExperiment(
            step: step,
            initial:
                ref.read(appProvider).journeys[BeanProgress.previewKey] ?? {},
            onSave: (j) => ref
                .read(appProvider.notifier)
                .saveJourney(BeanProgress.previewKey, j),
            onFinished: () async {
              Navigator.of(context).pop();
            },
          );
        },
      );
}

class BeanExperiment extends ConsumerStatefulWidget {
  const BeanExperiment({
    super.key,
    required this.step,
    required this.initial,
    required this.onSave,
    required this.onFinished,
    this.onPrevious,
  });
  final LessonStep step;
  final Map<String, dynamic> initial;
  final Future<void> Function(Map<String, dynamic>) onSave;
  final Future<void> Function() onFinished;
  final Future<void> Function()? onPrevious;
  @override
  ConsumerState<BeanExperiment> createState() => _BeanExperimentState();
}

class _BeanExperimentState extends ConsumerState<BeanExperiment>
    with WidgetsBindingObserver {
  late BeanProgress progress;
  late BeanGame game;
  bool ready = false, busy = false, active = true, saveFailed = false;
  String ui(String key) => widget.step.json['playUi'][key];
  String get spoken => progress.prediction == null
      ? widget.step.prompt
      : progress.finished
      ? '${ui('predicted')} ${widget.step.label(progress.prediction!)}. ${widget.step.explanation}'
      : '${widget.step.frames[progress.frame]['label']}. ${widget.step.frames[progress.frame]['caption']}';
  void speak() => ref.read(narrationProvider).speak(spoken);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    progress = BeanProgress.restore(widget.initial);
    game = BeanGame(
      onReady: () {
        if (mounted) {
          setState(() => ready = true);
          speak();
        }
      },
    )..frame = progress.frame;
  }

  Future<void> choose(String id) async {
    if (busy || progress.frame > 0) return;
    setState(() => busy = true);
    final next = progress.predict(id);
    try {
      await widget.onSave(next.toJson());
      if (mounted) {
        setState(() {
          progress = next;
          saveFailed = false;
        });
        ref
            .read(narrationProvider)
            .speak(
              '${ui('predicted')} ${widget.step.label(id)}. ${ui('water')}',
            );
      }
    } catch (_) {
      if (mounted) setState(() => saveFailed = true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> water() async {
    if (!ready || busy || progress.prediction == null || progress.finished)
      return;
    setState(() => busy = true);
    try {
      // Persist the guess before starting the experiment, even after a resumed save.
      await widget.onSave(progress.toJson());
      game.pour = 1;
      await Future<void>.delayed(
        Duration(milliseconds: game.reducedMotion ? 250 : 1000),
      );
      if (!mounted || !active) return;
      final next = progress.watered();
      await widget.onSave(next.toJson());
      if (mounted) {
        setState(() {
          progress = next;
          game.frame = next.frame;
          saveFailed = false;
        });
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
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    active = state == AppLifecycleState.resumed;
    if (active)
      game.resumeEngine();
    else {
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
    final profile = ref.watch(appProvider).profile ?? const ChildProfile();
    game.reducedMotion = MediaQuery.disableAnimationsOf(context);
    final small = MediaQuery.sizeOf(context).height < 500;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) leave();
      },
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) => Stack(
              children: [
                Positioned.fill(
                  child: GameWidget<BeanGame>(
                    game: game,
                    loadingBuilder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      if (widget.onPrevious != null)
                        Material(
                          color: const Color(0xFFFFF8EC),
                          borderRadius: BorderRadius.circular(20),
                          child: IconButton(
                            key: const ValueKey('lessonPrevious'),
                            tooltip: 'Previous screen',
                            onPressed: busy ? null : widget.onPrevious,
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                        ),
                      Material(
                        color: const Color(0xFFFFF8EC),
                        borderRadius: BorderRadius.circular(20),
                        child: IconButton(
                          onPressed: busy ? null : leave,
                          tooltip: 'My island',
                          icon: const Icon(Icons.home_rounded),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.step.title,
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: small ? 28 : 36,
                            color: const Color(0xFF23483C),
                            shadows: const [
                              Shadow(color: Colors.white, blurRadius: 8),
                            ],
                          ),
                        ),
                      ),
                      Material(
                        color: const Color(0xFFFFF8EC),
                        borderRadius: BorderRadius.circular(20),
                        child: IconButton(
                          onPressed: speak,
                          tooltip: 'Listen again',
                          icon: const Icon(Icons.volume_up_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  top: small ? 80 : 105,
                  bottom: small ? 12 : 24,
                  width: box.maxWidth * .39,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFAEE).withValues(alpha: .97),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(small ? 12 : 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!small)
                            ScientistOwl(
                              gender: profile.gender,
                              size: 85,
                              mood: progress.finished
                                  ? OwlMood.cheering
                                  : OwlMood.happy,
                            ),
                          Text(
                            progress.prediction == null
                                ? widget.step.prompt
                                : widget.step.frames[progress.frame]['label'],
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: small ? 24 : 30,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          if (progress.frame == 0) ...[
                            Text(
                              ui('predictAr'),
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                for (final option in widget.step.options)
                                  OutlinedButton(
                                    key: ValueKey('bean-${option.id}'),
                                    onPressed: busy
                                        ? null
                                        : () => choose(option.id),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor:
                                          progress.prediction == option.id
                                          ? const Color(0xFFD9F2DF)
                                          : Colors.white,
                                      padding: const EdgeInsets.all(12),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SciencePicture(
                                          art: option.art,
                                          size: small ? 44 : 62,
                                        ),
                                        Text(option.label),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ] else ...[
                            Text(
                              widget.step.frames[progress.frame]['caption'],
                              style: const TextStyle(fontSize: 22),
                              textAlign: TextAlign.center,
                            ),
                            if (progress.finished) ...[
                              const SizedBox(height: 12),
                              Text(
                                '${ui('predicted')} ${widget.step.label(progress.prediction!)}.',
                                style: const TextStyle(fontSize: 22),
                              ),
                              Text(
                                widget.step.explanation,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ],
                          ],
                          const SizedBox(height: 18),
                          if (!progress.finished)
                            FilledButton.icon(
                              key: const ValueKey('bean-water'),
                              onPressed:
                                  busy || !ready || progress.prediction == null
                                  ? null
                                  : water,
                              icon: const Icon(Icons.water_drop_rounded),
                              label: Text(busy ? ui('watch') : ui('water')),
                            )
                          else
                            FilledButton.icon(
                              key: const ValueKey('bean-finish'),
                              onPressed: widget.onFinished,
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: Text(ui('continue')),
                            ),
                          if (saveFailed)
                            Text(
                              ui('saveError'),
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 18,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: box.maxWidth * .48,
                  right: 12,
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8EC),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.step.frames[progress.frame]['label'],
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 24,
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
    );
  }
}

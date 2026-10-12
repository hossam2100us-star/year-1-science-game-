import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../content/lesson.dart';
import '../../core/answer_summary.dart';
import '../../games/discovery_game.dart';
import '../biology/ourselves_stage.dart';
import '../plants/bean_experiment.dart';
import '../plants/light_experiment.dart';
import '../plants/plant_lab_stage.dart';
import '../plants/plant_mission_stage.dart';
import '../science/science_lab.dart';
import '../science/science_stage.dart';
import '../maths/maths_stage.dart';
import '../maths/maths_workshop.dart';
import 'scene_kind.dart';

/// What a scene renderer may read from, and ask of, the lesson it is part
/// of (AUD-002). The lesson player implements it; renderers never reach
/// into its private state.
abstract interface class LessonSceneHost {
  Lesson get lesson;
  LessonStep get step;
  int get stepIndex;

  /// "3/13" style position shown by full-screen scenes.
  String get position;
  Set<String> get selected;
  Map<String, String> get placements;
  Set<String> get touched;
  Set<String> get reviewItems;
  bool get answerLocked;
  bool get freeDone;
  bool get busy;
  bool get girl;

  /// Animation frame of a predict-then-reveal step (0 before testing).
  int get frame;
  Map<String, dynamic> get lab;
  Map<String, dynamic> get bean;
  Map<String, dynamic> get light;
  DiscoveryGame get game;

  /// Plant parts already built in earlier plant-lab steps.
  Set<String> get assembledPlantParts;

  void item(String id);
  void place(String item, String target);
  void say(String text);
  void playSound(String name, [double loudness]);

  /// Shows [text] as feedback and saves it with the step.
  void showFeedback(String text);

  /// A science scene spoke: stop scene audio, keep guided/explore feedback.
  void sceneSpoke(String text);
  void reorder(List<String> items);
  void reorderSlots(Map<String, String> slots);
  Future<void> saveLab(Map<String, dynamic> data, bool complete);
  Future<void> saveLight(Map<String, dynamic> value);
  Future<void> finishLight();
  Future<void> saveBean(Map<String, dynamic> value);
  Future<void> finishBean();
  Future<void> Function()? get previous;
  Future<void> leave();
}

/// Builds the interactive part of one kind of step.
abstract class SceneRenderer {
  const SceneRenderer();
  Widget build(BuildContext context, LessonSceneHost host);

  /// Extra controls shown under the scene, after the common spacing.
  Widget? below(BuildContext context, LessonSceneHost host) => null;

  /// Registry replacing the player's `if` chains: one renderer per kind.
  static const Map<SceneKind, SceneRenderer> registry = {
    SceneKind.lightExperiment: _LightExperimentRenderer(),
    SceneKind.beanExperiment: _BeanExperimentRenderer(),
    SceneKind.scienceLab: _ScienceLabRenderer(),
    SceneKind.scienceStage: _ScienceStageRenderer(),
    SceneKind.ourselves: _OurselvesRenderer(),
    SceneKind.plantLab: _PlantLabRenderer(),
    SceneKind.plantMission: _PlantMissionRenderer(),
    SceneKind.maths: _MathsRenderer(),
    SceneKind.discovery: _DiscoveryRenderer(),
  };

  static SceneRenderer of(SceneKind kind) => registry[kind]!;
}

class _MathsRenderer extends SceneRenderer {
  const _MathsRenderer();
  @override
  Widget build(BuildContext context, LessonSceneHost host) =>
      host.step.json['mathWorkshop'] is Map
      ? MathsWorkshop(
          key: ValueKey(host.step.id),
          config: Map<String, dynamic>.from(host.step.json['mathWorkshop']),
          initial: host.lab,
          onSave: host.saveLab,
          onSay: host.say,
          locked: host.busy,
        )
      : MathsStage(
          step: host.step,
          selected: host.selected,
          placements: host.placements,
          touched: host.touched,
          reviewItems: host.reviewItems,
          locked: host.answerLocked || host.freeDone || host.busy,
          onItem: host.item,
          onPlace: host.place,
        );
}

class _LightExperimentRenderer extends SceneRenderer {
  const _LightExperimentRenderer();
  @override
  Widget build(BuildContext context, LessonSceneHost host) => LightExperiment(
    key: ValueKey(host.step.id),
    step: host.step,
    initial: host.light,
    position: host.position,
    onPrevious: host.previous,
    onSave: host.saveLight,
    onFinished: host.finishLight,
    onLeave: host.leave,
  );
}

class _BeanExperimentRenderer extends SceneRenderer {
  const _BeanExperimentRenderer();
  @override
  Widget build(BuildContext context, LessonSceneHost host) => BeanExperiment(
    key: ValueKey(host.step.id),
    step: host.step,
    initial: host.bean,
    onPrevious: host.previous,
    onSave: host.saveBean,
    onFinished: host.finishBean,
  );
}

class _ScienceLabRenderer extends SceneRenderer {
  const _ScienceLabRenderer();
  @override
  Widget build(BuildContext context, LessonSceneHost host) => ScienceLab(
    key: ValueKey(host.step.id),
    step: host.step,
    data: host.lab,
    onSpeak: host.say,
    onSound: host.playSound,
    onFeedback: host.showFeedback,
    onChange: host.saveLab,
  );
}

class _ScienceStageRenderer extends SceneRenderer {
  const _ScienceStageRenderer();
  @override
  Widget build(BuildContext context, LessonSceneHost host) => ScienceStage(
    step: host.step,
    selected: host.selected,
    placements: host.placements,
    done: host.answerLocked,
    reviewItems: host.reviewItems,
    onItem: host.item,
    onPlace: host.place,
    onSound: host.playSound,
    onSpeak: host.sceneSpoke,
    onOrder: host.reorder,
    onOrderPlacements: host.reorderSlots,
  );
}

class _OurselvesRenderer extends SceneRenderer {
  const _OurselvesRenderer();
  @override
  Widget build(BuildContext context, LessonSceneHost host) => OurselvesStage(
    step: host.step,
    selected: host.selected,
    placements: host.placements,
    done: host.answerLocked || host.freeDone,
    girl: host.girl,
    onItem: host.item,
    onPlace: host.place,
  );
}

class _PlantLabRenderer extends SceneRenderer {
  const _PlantLabRenderer();
  @override
  Widget build(BuildContext context, LessonSceneHost host) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (host.step.json['playInstruction'] != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            host.step.json['playInstruction'] as String,
            style: const TextStyle(fontSize: 22),
          ),
        ),
      PlantLabStage(
        key: ValueKey(host.step.id),
        step: host.step,
        selected: host.selected,
        touched: host.touched,
        placements: host.placements,
        done: host.answerLocked,
        assembled: host.assembledPlantParts,
        onItem: host.item,
        onPlace: host.place,
      ),
    ],
  );
}

class _PlantMissionRenderer extends SceneRenderer {
  const _PlantMissionRenderer();
  @override
  Widget build(BuildContext context, LessonSceneHost host) => PlantMissionStage(
    step: host.step,
    selected: host.selected,
    placements: host.placements,
    done: host.answerLocked,
    onItem: host.item,
    onPlace: host.place,
  );
}

/// The Flame discovery scene with its option and target buttons.
class _DiscoveryRenderer extends SceneRenderer {
  const _DiscoveryRenderer();
  @override
  Widget build(BuildContext context, LessonSceneHost host) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: SizedBox(
      height: (MediaQuery.sizeOf(context).height * .55).clamp(
        host.step.kind == 'label-diagram' ? 300.0 : 240.0,
        380.0,
      ),
      child: GameWidget<DiscoveryGame>(
        key: ValueKey(host.step.id),
        game: host.game,
      ),
    ),
  );

  /// Option buttons, and target buttons for mapping questions.
  @override
  Widget below(BuildContext context, LessonSceneHost host) {
    final step = host.step;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!host.answerLocked && !host.freeDone && host.frame == 0)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final item in step.options)
                OutlinedButton(
                  onPressed: host.busy ? null : () => host.item(item.id),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (host.selected.contains(item.id))
                        const Icon(Icons.check_circle_rounded),
                      Flexible(child: Text(item.label)),
                    ],
                  ),
                ),
            ],
          ),
        if (step.isMapping && !host.answerLocked) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < step.targets.length; i++)
                FilledButton.tonal(
                  onPressed: host.selected.isEmpty
                      ? null
                      : () =>
                            host.place(host.selected.first, step.targets[i].id),
                  child: Text(
                    step.kind == 'label-diagram'
                        ? 'Place ${i + 1}'
                        : step.targets[i].label,
                  ),
                ),
            ],
          ),
          if (host.placements.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: AnswerSummary(
                pairs: [
                  for (final e in host.placements.entries)
                    (
                      step.label(e.key),
                      step.kind == 'label-diagram'
                          ? 'Place ${step.targets.indexWhere((t) => t.id == e.value) + 1}'
                          : step.label(e.value),
                    ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

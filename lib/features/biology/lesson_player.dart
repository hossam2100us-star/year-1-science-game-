import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/answer_summary.dart';
import '../../core/diagnostics/app_log.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../content/lesson.dart';
import '../../core/models.dart';
import '../../core/mascot.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../games/discovery_game.dart';
import '../../games/question_engine.dart';
import 'session.dart';
import 'ourselves_stage.dart';
import 'shoe_measure.dart';
import '../science/science_stage.dart';
import '../science/science_lab.dart';
import '../science/force_guided_lab.dart';
import '../science/force_discovery.dart';
import '../science/science_audio.dart';
import '../plants/bean_experiment.dart';
import '../plants/light_experiment.dart';
import '../plants/light_model.dart';
import '../plants/plant_lab_stage.dart';
import '../plants/plant_mission_stage.dart';
import '../garden/alive_adventures.dart';

class LessonRoute extends ConsumerWidget {
  const LessonRoute({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(lessonLibraryProvider)
      .when(
        data: (library) => id == 'unit_01'
            ? AliveAdventures(lesson: library.lessons[id]!)
            : LessonPlayer(lesson: library.lessons[id]!),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, stack) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => ref.invalidate(lessonLibraryProvider),
              child: const Text('Try opening again'),
            ),
          ),
        ),
      );
}

class LessonPlayer extends ConsumerStatefulWidget {
  const LessonPlayer({
    super.key,
    required this.lesson,
    this.onPracticeComplete,
  });
  final Lesson lesson;
  final Future<void> Function(DecisionOutcome)? onPracticeComplete;
  @override
  ConsumerState<LessonPlayer> createState() => _LessonPlayerState();
}

class _LessonPlayerState extends ConsumerState<LessonPlayer>
    with WidgetsBindingObserver {
  late LessonSession _session;
  late QuestionEngine _engine;
  late DiscoveryGame _game;
  final _scroll = ScrollController();
  Set<String> _selected = {};
  Map<String, String> _placements = {};
  Set<String> _touched = {};
  Set<String> _reviewItems = {};
  bool _needsCorrection = false;
  String? _prediction;
  int _frame = 0, _shoeA = 9, _shoeB = 12;
  bool _busy = false, _complete = false, _freeDone = false, _saveFailed = false;
  String _feedback = '';
  Map<String, dynamic> _bean = {};
  Map<String, dynamic> _lab = {};
  Map<String, dynamic> _light = {};
  Map<String, String> _objectiveEvidence = {};
  Future<void> _writes = Future.value();
  LessonStep get step {
    final current = _session.step;
    if (current.id != 'unit_06.step.008' ||
        _session.current['legacySoundChart'] != true) {
      return current;
    }
    final legacy = widget.lesson.json['legacySoundChart'];
    if (legacy is! Map) return current;
    return LessonStep({
      ...current.json,
      ...Map<String, dynamic>.from(legacy),
      'shortExplanation': legacy['shortExplanation'] ?? legacy['explanation'],
      'soundScene': {
        ...Map<String, dynamic>.from(current.json['soundScene'] ?? {}),
        ...Map<String, dynamic>.from(legacy['soundScene'] ?? {}),
      },
    });
  }

  bool get _guidedCorrection => step.assessed && step.answer != null;
  bool get _answerLocked => _engine.done && !_needsCorrection;
  String _correctionText(String key) =>
      step.json['correctionUi']?[key] as String? ??
      const {
        'start': 'Now try the discovery yourself.',
        'retry': 'Look again, then change your choice.',
        'complete': 'You corrected it yourself. Keep exploring!',
        'review': 'Look again',
        'check': 'Check my changes',
      }[key]!;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final saved = widget.onPracticeComplete == null
        ? ref.read(appProvider).journeys[widget.lesson.id]
        : null;
    _session = saved != null && LessonSession.canRestore(widget.lesson, saved)
        ? LessonSession.restore(widget.lesson, saved)
        : LessonSession.fresh(widget.lesson);
    if (_session.finished) {
      _complete = true;
    } else {
      _prepare();
    }
  }

  void _prepare() {
    final current = _session.current;
    _lab = Map<String, dynamic>.from(current['lab'] ?? {});
    _objectiveEvidence = Map<String, String>.from(
      current['objectiveEvidence'] ?? {},
    );
    _bean = Map<String, dynamic>.from(current['bean'] ?? {});
    _light = Map<String, dynamic>.from(
      current['light'] ?? LightProgress.fromLegacy(current).toJson(),
    );
    _selected = Set<String>.from(current['selected'] ?? []);
    _placements = Map<String, String>.from(current['placements'] ?? {});
    _touched = Set<String>.from(current['touched'] ?? []);
    _reviewItems = Set<String>.from(current['reviewItems'] ?? []);
    _needsCorrection = current['needsCorrection'] == true && _guidedCorrection;
    _prediction = current['prediction'];
    _frame = current['frame'] ?? 0;
    _freeDone = current['freeDone'] ?? false;
    _feedback = current['feedback'] ?? '';
    // The garden resumes at an unfinished place, not the last watched subject.
    if (_movementGarden) _feedback = '';
    _shoeA = current['shoeA'] ?? 9;
    _shoeB = current['shoeB'] ?? 12;
    _engine = QuestionEngine(
      step,
      mistakes: current['mistakes'] ?? 0,
      done: current['done'] ?? false,
      outcome: current['outcome'] == null
          ? null
          : DecisionOutcome.values.byName(current['outcome']),
    );
    // Wording can change without changing content IDs or historical grades.
    // Never replay a cached teacher key when reopening assessed work.
    if (step.assessed && !step.isFree) {
      _feedback = _assessmentFeedback();
      if (_needsCorrection) {
        _markForReview();
        _feedback += ' ${_correctionText('start')} ${_answerReference()}';
      } else if (_engine.done) {
        _reviewItems.clear();
      } else if (_guidedCorrection && _engine.mistakes > 0) {
        _markForReview();
      }
    }
    _game = DiscoveryGame(
      step: step,
      onItem: _item,
      onPlace: _place,
      girl: ref.read(appProvider).profile?.gender == ChildGender.girl,
    );
    _syncGame();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _game.reducedMotion = MediaQuery.disableAnimationsOf(context);
      if (_scroll.hasClients) _scroll.jumpTo(0);
      _say(_feedback.isEmpty ? _instruction : _feedback);
    });
  }

  bool get _plantMission => step.json['playScene'] == 'plant-mission';
  bool get _science => step.json['playScene'] == 'science';
  bool get _movementGarden =>
      _science && step.json['forceScene']?['gardenStories'] is Map;
  bool get _guidedForces =>
      _science &&
      (step.json['lab'] == 'force' ||
          step.json['forceScene']?['mode'] == 'movement');
  bool get _ourselves => step.json['playScene'] == 'ourselves';
  bool get _plantLab => step.json['playScene'] == 'plant-lab';
  String get _displayPrompt =>
      _plantLab && step.json['partDescriptions'] != null && _selected.isNotEmpty
      ? step.json['partDescriptions'][_selected.last] ?? step.prompt
      : step.prompt;

  String get _instruction {
    if (_movementGarden) {
      return step.json['forceScene']['gardenStories'][forceGardenResumeSpot(
        _touched,
      )];
    }
    if (_science && step.json['lab'] == 'force') {
      return step.json['labUi']['guideInstructions'][forceGuideStage(_lab)];
    }
    if (_ourselves || _science) {
      return '${step.json['safety'] ?? ''} ${step.json['spokenPrompt'] ?? step.prompt}';
    }
    if (_plantLab) {
      return '$_displayPrompt ${step.json['playInstruction'] ?? ''}';
    }
    final names = step.options.map((v) => v.label).join('. ');
    final places = step.kind == 'label-diagram'
        ? List.generate(step.targets.length, (i) => 'Place ${i + 1}').join('. ')
        : step.targets.map((v) => v.label).join('. ');
    return '${step.prompt} $names. ${places.isEmpty ? '' : '$places.'}';
  }

  void _say(String text) {
    if (_science && widget.lesson.id == 'unit_06') ScienceAudio.stop();
    ref.read(narrationProvider).speak(text);
  }

  void _syncGame() {
    _game.selected = _selected;
    _game.placements = _placements;
    _game.reveal = _answerLocked || _freeDone;
    _game.frame = _frame;
  }

  Map<String, dynamic> _snapshot() => {
    if (_session.current['legacySoundChart'] == true) 'legacySoundChart': true,
    if (_objectiveEvidence.isNotEmpty)
      'objectiveEvidence': Map<String, String>.from(_objectiveEvidence),
    'bean': Map<String, dynamic>.from(_bean),
    'lab': Map<String, dynamic>.from(_lab),
    'light': Map<String, dynamic>.from(_light),
    'selected': _selected.toList(),
    'placements': Map<String, String>.from(_placements),
    'touched': _touched.toList(),
    'reviewItems': _reviewItems.toList(),
    'needsCorrection': _needsCorrection,
    'prediction': _prediction,
    'frame': _frame,
    'shoeA': _shoeA,
    'shoeB': _shoeB,
    'freeDone': _freeDone,
    'feedback': _feedback,
    'mistakes': _engine.mistakes,
    'done': _engine.done,
    'outcome': _engine.outcome?.name,
  };
  Future<void> _persist() {
    if (_complete || widget.onPracticeComplete != null) return Future.value();
    _session.current = _snapshot();
    final snapshot = _session.toJson();
    // Copy nested collections before the next interaction mutates the session.
    snapshot['responses'] = Map<String, dynamic>.from(_session.responses);
    final writer = ref.read(appProvider.notifier);
    final task = _writes.then(
      (_) => writer.saveJourney(widget.lesson.id, snapshot),
    );
    _writes = task.catchError((Object error, StackTrace stack) {
      if (mounted) {
        setState(() => _saveFailed = true);
        showSaveError(context, error, stack, area: 'journey');
      }
    });
    return task;
  }

  void _changed() {
    _syncGame();
    setState(() {});
    // Failures are logged and shown by the _writes handler in _persist.
    _persist().ignore();
  }

  void _playSound(String name, [double loudness = 1]) {
    final settings = ref.read(appProvider).settings;
    if (settings.sound) {
      // Let the child hear the experimental sound without narration over it.
      ref.read(narrationProvider).stop();
      ScienceAudio.play(
        name,
        settings.volume * (widget.lesson.id == 'unit_06' ? .5 : .35) * loudness,
      ).catchError(
        (Object error, StackTrace stack) =>
            AppLog.warning('audio', 'Scene sound did not play', error, stack),
      );
    }
  }

  void _item(String id) {
    if (_science && step.json['band'] == true) {
      final art = step.options.where((p) => p.id == id).firstOrNull?.art;
      if (art != null) _playSound(art);
    }
    if (_busy || _answerLocked || _freeDone || _frame > 0) return;
    _reviewItems.remove(id);
    if (!(_science && step.json['band'] == true && step.isFree)) {
      _say(
        _plantLab && step.kind == 'story'
            ? step.prompt
            : _plantLab && step.json['partDescriptions'] != null
            ? step.json['partDescriptions'][id] ?? step.label(id)
            : step.json['senseDescriptions']?[id] ?? step.label(id),
      );
    }
    if (['explore', 'story', 'free-plant'].contains(step.kind)) {
      if (step.json['senseDescriptions'] is Map) {
        _feedback = step.json['senseDescriptions'][id] ?? '';
      }
      _touched.remove(id);
      _touched.add(id);
      _selected = {..._touched};
      _game.celebration = .7;
    } else if (step.isMapping) {
      _selected = {id};
    } else if (step.isMulti || step.isOrder || step.kind == 'free-pair') {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    } else {
      _selected = {id};
    }
    _changed();
    if (!step.isFree && !step.isMulti && !step.isOrder && !step.isMapping) {
      _check();
    }
  }

  void _place(String item, String target) {
    if (_busy || _answerLocked || _freeDone) return;
    _reviewItems.remove(item);
    _placements[item] = target;
    if (_ourselves && step.kind == 'label-diagram') {
      final next = step.options
          .where((o) => !_placements.containsKey(o.id))
          .firstOrNull;
      _selected = next == null ? {} : {next.id};
    }
    _say(
      step.kind == 'label-diagram' && !_plantLab && !_ourselves
          ? 'Place ${step.targets.indexWhere((t) => t.id == target) + 1}'
          : step.label(target),
    );
    _changed();
    if (step.options.length == 1) _check();
  }

  dynamic get _selection => step.isMapping
      ? _placements
      : step.isMulti || step.isOrder
      ? _selected.toList()
      : _selected.firstOrNull;
  bool _mappingItemMatches(String id) => matchesAnswer(
    {
      ...step.answer!,
      'value': {id: (step.answer!['value'] as Map)[id]},
    },
    {id: _placements[id]},
  );
  String _assessmentFeedback() {
    var feedback = _engine.feedback;
    if (!_engine.done && _engine.mistakes > 0 && step.isMapping) {
      final expected = Map<String, dynamic>.from(step.answer!['value']);
      final revisit = expected.keys.where((id) => !_mappingItemMatches(id));
      feedback += ' Look again: ${revisit.map(step.label).join(', ')}.';
    } else if (!_engine.done && _engine.mistakes > 0 && step.isMulti) {
      final expected = List<String>.from(step.answer!['value']);
      final found = _selected.where(expected.contains).length;
      feedback +=
          ' $found of ${expected.length} discoveries found. Check your collection.';
    }
    return feedback;
  }

  void _check() {
    if (_busy || _answerLocked) return;
    if (_needsCorrection) {
      // This is practice after explanation. Never submit to the scoring engine.
      final corrected = matchesAnswer(step.answer!, _selection);
      _markForReview();
      if (corrected) {
        _needsCorrection = false;
        _reviewItems.clear();
        _feedback = _correctionText('complete');
        _game.celebration = 1.2;
      } else {
        _feedback = '${_correctionText('retry')} ${_answerReference()}';
      }
      _changed();
      _say(_feedback);
      return;
    }
    final previousMistakes = _engine.mistakes;
    final success = _engine.submit(_selection);
    final groups = step.json['objectiveItems'];
    if (groups is Map && step.isMapping) {
      for (final entry in groups.entries) {
        if (_objectiveEvidence.containsKey(entry.key)) continue;
        final correct = (entry.value as List).every(
          (id) => _mappingItemMatches(id),
        );
        if (correct) {
          _objectiveEvidence[entry.key] = previousMistakes == 0
              ? 'firstTry'
              : 'afterHint';
        } else if (_engine.done) {
          _objectiveEvidence[entry.key] = 'explained';
        }
      }
    }
    _feedback = _assessmentFeedback();
    if (_guidedCorrection && !success) _markForReview();
    if (_guidedCorrection && _engine.outcome == DecisionOutcome.explained) {
      _needsCorrection = true;
      _feedback += ' ${_correctionText('start')} ${_answerReference()}';
    } else if (_engine.done) {
      _reviewItems.clear();
      // Keep the learner's accepted words and ordering, including aliases.
      // Post-explanation correction is checked separately without regrading.
      if (success) _game.celebration = 1.2;
    } else {
      _game.wobble = .65;
    }
    _changed();
    _say(_feedback);
  }

  void _markForReview() {
    final expected = step.answer!['value'];
    if (step.isMapping) {
      _reviewItems = (expected as Map).keys
          .cast<String>()
          .where((id) => !_mappingItemMatches(id))
          .toSet();
    } else if (step.isMulti) {
      // Missing correct choices are not identified before the explanation.
      _reviewItems = _selected
          .where((id) => !(expected as List).contains(id))
          .toSet();
    } else {
      _reviewItems = _selected.where((id) => id != expected).toSet();
    }
  }

  String _answerReference() {
    final expected = step.answer!['value'];
    if (expected is Map) {
      return expected.entries
          .where((e) => _reviewItems.contains(e.key))
          .map((e) => '${step.label(e.key)}: ${step.label(e.value)}')
          .join('. ');
    }
    return (expected is List ? expected : [expected])
        .map((id) => step.label(id as String))
        .join(' • ');
  }

  bool get _canContinue {
    if (_needsCorrection) return false;
    if (_session.responses[step.id]?['completed'] == true) return true;
    if (_science && step.json['lab'] == 'distance') {
      return ScienceLab.distanceComplete(_lab);
    }
    if (_science && step.json['lab'] == 'force') {
      return ScienceLab.forceComplete(_lab);
    }
    if (_science && step.json['lab'] == 'sailboat') {
      return ScienceLab.boatComplete(_lab);
    }
    if (_science && step.json['shapeResults'] != null) {
      return ScienceLab.shapeComplete(step, _lab);
    }
    if (_science && step.json['observationUi'] != null) {
      return ScienceLab.experimentComplete(step, _lab);
    }
    if (_science && step.json['lab'] != null) return _freeDone;
    if (_science && step.kind == 'explore') {
      return step.options.every((o) => _touched.contains(o.id));
    }
    if (_ourselves && (step.kind == 'explore' || step.kind == 'story')) {
      return step.options.every((o) => _touched.contains(o.id));
    }
    if (_plantLab && step.kind == 'story') return _touched.contains(step.focus);
    if (_plantLab && (step.kind == 'explore' || step.kind == 'free-plant')) {
      return step.options.every((item) => _touched.contains(item.id));
    }
    if (_engine.done || _freeDone || step.kind == 'story') return true;
    if (step.kind == 'explore' || step.kind == 'free-plant') {
      return _touched.length >= (step.json['minTouches'] ?? 3);
    }
    return false;
  }

  Future<void> _testPrediction() async {
    if (_selected.isEmpty && _prediction == null || _busy) return;
    setState(() => _busy = true);
    try {
      if (_prediction == null) {
        _prediction = _selected.first;
        // Prediction is saved BEFORE any result or animation is revealed.
        await _persist();
      }
      _frame++;
      final current = step.frames[_frame - 1];
      _feedback = '${current['label']}. ${current['caption']}';
      if (_frame >= step.frames.length) {
        _freeDone = true;
        _feedback =
            'You predicted ${step.label(_prediction!)}. $_feedback Great observing! ${step.explanation}';
      }
      _syncGame();
      await _persist();
      if (mounted) {
        setState(() {});
        _say(_feedback);
      }
    } catch (error, stack) {
      if (mounted) showSaveError(context, error, stack, area: 'journey');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _previous() async {
    if (_busy || _session.index == 0) return;
    final previousIndex = _session.index;
    final previousCurrent = _snapshot();
    final previousResponses = Map<String, dynamic>.from(_session.responses);
    setState(() => _busy = true);
    try {
      await ref.read(narrationProvider).stop();
      await _persist();
      // Preserve unfinished work separately from immutable completed evidence.
      if (_session.responses[step.id]?['completed'] != true) {
        _session.responses[step.id] = {'resumeState': previousCurrent};
      }
      _session.index--;
      final saved = _session.responses[step.id] as Map? ?? {};
      _session.current = Map<String, dynamic>.from(
        saved['resumeState'] ?? saved,
      );
      if (widget.onPracticeComplete == null) {
        await ref
            .read(appProvider.notifier)
            .saveJourney(widget.lesson.id, _session.toJson());
      }
      _game.pauseEngine();
      _prepare();
    } catch (error, stack) {
      _session.index = previousIndex;
      _session.current = previousCurrent;
      _session.responses = previousResponses;
      if (mounted) {
        showSaveError(context, error, stack, area: 'journey');
        _prepare();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _next() async {
    if (!_canContinue || _busy) return;
    final previousIndex = _session.index;
    final previousCurrent = _snapshot();
    final previousResponses = Map<String, dynamic>.from(_session.responses);
    setState(() => _busy = true);
    try {
      await _persist();
      if (_session.responses[step.id]?['completed'] != true) {
        _session.responses[step.id] = {..._snapshot(), 'completed': true};
      }
      _session.index++;
      _session.current = _session.finished
          ? {}
          : Map<String, dynamic>.from(
              _session.responses[_session.step.id]?['resumeState'] ??
                  _session.responses[_session.step.id] ??
                  {},
            );
      if (_session.finished) {
        if (widget.onPracticeComplete != null) {
          await widget.onPracticeComplete!(
            _engine.outcome ?? DecisionOutcome.explained,
          );
          if (mounted) Navigator.of(context).pop();
          return;
        }
        await ref.read(appProvider.notifier).completeJourney(_session.result());
        if (mounted) {
          setState(() => _complete = true);
          _say(_resultText);
        }
      } else {
        if (widget.onPracticeComplete == null) {
          await ref
              .read(appProvider.notifier)
              .saveJourney(widget.lesson.id, _session.toJson());
        }
        _game.pauseEngine();
        _prepare();
      }
    } catch (error, stack) {
      // A failed boundary save leaves the previous completed step retryable.
      _session.index = previousIndex;
      _session.current = previousCurrent;
      _session.responses = previousResponses;
      if (mounted) {
        showSaveError(context, error, stack, area: 'journey');
        _prepare();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _resultText {
    final name = ref.read(appProvider).profile?.name ?? '';
    if (!widget.lesson.quiz) {
      return 'Great effort${name.isEmpty ? '' : ', $name'}! You explored the whole unit and earned three stars.';
    }
    final score = _session.result().firstTry;
    return score >= 8
        ? 'Excellent! $score out of ten.'
        : score >= 5
        ? 'Good! Let us look at the tricky ones. $score out of ten.'
        : 'Let us play the games again, then try next time. $score out of ten.';
  }

  Future<void> _leave() async {
    if (_busy) return;
    try {
      if (!_complete) await _persist();
      await _writes;
    } catch (error, stack) {
      if (mounted) showSaveError(context, error, stack, area: 'journey');
      return;
    }
    await ref.read(narrationProvider).stop();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      if (!_complete) {
        _game.pauseEngine();
        // Failures are logged and shown by the _writes handler in _persist.
        _persist().ignore();
      }
      ref.read(narrationProvider).stop();
    } else if (!_complete) {
      _game.resumeEngine();
    }
  }

  @override
  void dispose() {
    ScienceAudio.stop().catchError(
      (Object error, StackTrace stack) =>
          AppLog.warning('audio', 'Stopping scene sound failed', error, stack),
    );
    WidgetsBinding.instance.removeObserver(this);
    if (!_complete) _game.pauseEngine();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A practice save can notify providers while its route is popping. There
    // is no next step in this one-discovery session to render during that frame.
    if (widget.onPracticeComplete != null && _session.finished) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final profile = ref.watch(appProvider).profile;
    if (_complete) return _completion(context);
    if (step.json['experiment'] == 'light') {
      return LightExperiment(
        key: ValueKey(step.id),
        step: step,
        initial: _light,
        position: '${_session.index + 1}/${widget.lesson.steps.length}',
        onPrevious: _session.index == 0 || _busy ? null : _previous,
        onSave: (value) async {
          final previous = _light;
          _light = Map<String, dynamic>.from(value);
          try {
            await _persist();
          } catch (_) {
            _light = previous;
            rethrow;
          }
        },
        onFinished: () async {
          _prediction = _light['prediction'];
          _frame = step.frames.length;
          _freeDone = true;
          _feedback = step.explanation;
          await _next();
        },
        onLeave: _leave,
      );
    }
    if (step.json['experiment'] == 'bean') {
      return BeanExperiment(
        key: ValueKey(step.id),
        step: step,
        initial: _bean,
        onPrevious: _session.index == 0 || _busy ? null : _previous,
        onSave: (value) async {
          _bean = Map<String, dynamic>.from(value);
          await _persist();
        },
        onFinished: () async {
          _prediction = _bean['prediction'];
          _frame = 4;
          _freeDone = true;
          _feedback = step.explanation;
          await _next();
        },
      );
    }

    _game.reducedMotion = MediaQuery.disableAnimationsOf(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 600;
                    final titleText = step.title == step.section || _plantLab
                        ? step.title
                        : '${step.title} • ${step.section}';
                    // A shortened phone title keeps its full text on
                    // long-press (AUD-018).
                    final title = Tooltip(
                      message: titleText,
                      excludeFromSemantics: true,
                      child: Text(
                        titleText,
                        key: const ValueKey('lesson-title'),
                        maxLines: compact ? 2 : null,
                        overflow: compact ? TextOverflow.ellipsis : null,
                        style: compact
                            ? Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontSize: 20)
                            : Theme.of(context).textTheme.titleLarge,
                      ),
                    );
                    final controls = Row(
                      children: [
                        IconButton(
                          key: const ValueKey('lessonPrevious'),
                          tooltip: 'Previous screen',
                          onPressed: _busy || _session.index == 0
                              ? null
                              : _previous,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        IconButton(
                          onPressed: _leave,
                          tooltip: 'Save and return to map',
                          icon: const Icon(Icons.home_rounded),
                        ),
                        if (compact) const Spacer() else Expanded(child: title),
                        Text(
                          '${_session.index + 1}/${widget.lesson.steps.length}',
                          style: const TextStyle(fontSize: 22),
                        ),
                      ],
                    );
                    return compact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              controls,
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: title,
                              ),
                            ],
                          )
                        : controls;
                  },
                ),
              ),
              // Loose: short challenges keep "Check" right under the content
              // instead of across an empty tablet screen; long ones still
              // scroll with the controls pinned below (AUD-018).
              Flexible(
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        children: [
                          if (!_guidedForces)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final compact = constraints.maxWidth < 600;
                                final owl = ScientistOwl(
                                  size: compact ? 44 : 70,
                                  gender: profile?.gender ?? ChildGender.boy,
                                  mood: _engine.done
                                      ? (_engine.outcome ==
                                                DecisionOutcome.explained
                                            ? OwlMood.thinking
                                            : OwlMood.cheering)
                                      : _engine.mistakes > 0
                                      ? OwlMood.thinking
                                      : OwlMood.idle,
                                );
                                final prompt = Text(
                                  _displayPrompt,
                                  key: const ValueKey('lesson-prompt'),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                );
                                final speaker = IconButton(
                                  onPressed: () => _say(_instruction),
                                  tooltip: 'Listen again',
                                  icon: const Icon(Icons.volume_up_rounded),
                                );
                                return compact
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            children: [
                                              owl,
                                              const Spacer(),
                                              speaker,
                                            ],
                                          ),
                                          prompt,
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          owl,
                                          Expanded(child: prompt),
                                          speaker,
                                        ],
                                      );
                              },
                            ),
                          if (!_guidedForces) const SizedBox(height: 8),
                          if (step.table.isNotEmpty && !_ourselves && !_science)
                            Wrap(
                              spacing: 20,
                              runSpacing: 12,
                              children: [
                                for (final row in step.table)
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('${row['name']}: ${row['value']}'),
                                        Wrap(
                                          spacing: 4,
                                          children: [
                                            for (
                                              var i = 0;
                                              i < (row['value'] as int);
                                              i++
                                            )
                                              const Icon(
                                                Icons.circle,
                                                size: 16,
                                                color: Color(0xFF2170B5),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          if (_science && step.json['safety'] != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE7EFF0),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                step.json['safety'],
                                style: const TextStyle(
                                  fontSize: 22,
                                  color: Color(0xFF3B5665),
                                ),
                              ),
                            ),
                          if (_science)
                            step.json['lab'] != null
                                ? ScienceLab(
                                    key: ValueKey(step.id),
                                    step: step,
                                    data: _lab,
                                    onSpeak: _say,
                                    onSound: _playSound,
                                    onFeedback: (text) {
                                      if (!mounted) return;
                                      _feedback = text;
                                      _changed();
                                    },
                                    onChange: (data, complete) async {
                                      final previous = _lab;
                                      final wasDone = _freeDone;
                                      _lab = Map<String, dynamic>.from(data);
                                      _freeDone = complete || wasDone;
                                      try {
                                        await _persist();
                                        if (mounted) setState(() {});
                                      } catch (_) {
                                        _lab = previous;
                                        _freeDone = wasDone;
                                        rethrow;
                                      }
                                    },
                                  )
                                : ScienceStage(
                                    step: step,
                                    selected: _selected,
                                    placements: _placements,
                                    done: _answerLocked,
                                    reviewItems: _reviewItems,
                                    onItem: _item,
                                    onPlace: _place,
                                    onSound: _playSound,
                                    onSpeak: (text) {
                                      ScienceAudio.stop();
                                      if (_guidedForces ||
                                          step.kind == 'explore') {
                                        final stories =
                                            step.json['forceScene']?['gardenStories']
                                                as Map?;
                                        _feedback =
                                            stories?.containsValue(text) == true
                                            ? ''
                                            : text;
                                        _changed();
                                      }
                                      _say(text);
                                    },
                                    onOrder: (items) {
                                      if (_busy ||
                                          _answerLocked ||
                                          !step.isOrder) {
                                        return;
                                      }
                                      final ids = step.options
                                          .map((p) => p.id)
                                          .toSet();
                                      if (items.toSet().length !=
                                              items.length ||
                                          !ids.containsAll(items)) {
                                        return;
                                      }
                                      _selected = items.toSet();
                                      _changed();
                                    },
                                    onOrderPlacements: (slots) {
                                      if (_busy ||
                                          _answerLocked ||
                                          !step.isOrder) {
                                        return;
                                      }
                                      final ids = step.options
                                          .map((p) => p.id)
                                          .toSet();
                                      final validSlots = {
                                        for (
                                          var i = 0;
                                          i < step.options.length;
                                          i++
                                        )
                                          '$i',
                                      };
                                      if (!validSlots.containsAll(slots.keys) ||
                                          !ids.containsAll(slots.values) ||
                                          slots.values.toSet().length !=
                                              slots.length) {
                                        return;
                                      }
                                      _placements = Map.from(slots);
                                      _selected = {
                                        for (
                                          var i = 0;
                                          i < step.options.length;
                                          i++
                                        )
                                          if (slots.containsKey('$i'))
                                            slots['$i']!,
                                      };
                                      _changed();
                                    },
                                  )
                          else if (_ourselves)
                            OurselvesStage(
                              step: step,
                              selected: _selected,
                              placements: _placements,
                              done: _answerLocked || _freeDone,
                              girl: profile?.gender == ChildGender.girl,
                              onItem: _item,
                              onPlace: _place,
                            )
                          else if (_plantLab) ...[
                            if (step.json['playInstruction'] != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  step.json['playInstruction'],
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            PlantLabStage(
                              key: ValueKey(step.id),
                              step: step,
                              selected: _selected,
                              touched: _touched,
                              placements: _placements,
                              done: _answerLocked,
                              assembled: {
                                for (final previous in widget.lesson.steps.take(
                                  _session.index,
                                ))
                                  if (previous.json['playScene'] ==
                                          'plant-lab' &&
                                      previous.kind == 'label-diagram' &&
                                      _session.responses[previous
                                              .id]?['completed'] ==
                                          true)
                                    ...Map<String, String>.from(
                                      previous.answer!['value'],
                                    ).values,
                              },
                              onItem: _item,
                              onPlace: _place,
                            ),
                          ] else if (_plantMission)
                            PlantMissionStage(
                              step: step,
                              selected: _selected,
                              placements: _placements,
                              done: _answerLocked,
                              onItem: _item,
                              onPlace: _place,
                            )
                          else
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: SizedBox(
                                height:
                                    (MediaQuery.sizeOf(context).height * .55)
                                        .clamp(
                                          step.kind == 'label-diagram'
                                              ? 300.0
                                              : 240.0,
                                          380.0,
                                        ),
                                child: GameWidget<DiscoveryGame>(
                                  key: ValueKey(step.id),
                                  game: _game,
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          if (!_science &&
                              !_ourselves &&
                              !_plantLab &&
                              !_plantMission &&
                              !_answerLocked &&
                              !_freeDone &&
                              _frame == 0)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                for (final item in step.options)
                                  OutlinedButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _item(item.id),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_selected.contains(item.id))
                                          const Icon(
                                            Icons.check_circle_rounded,
                                          ),
                                        Flexible(child: Text(item.label)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          if (!_science &&
                              !_ourselves &&
                              !_plantLab &&
                              !_plantMission &&
                              step.isMapping &&
                              !_answerLocked) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                for (var i = 0; i < step.targets.length; i++)
                                  FilledButton.tonal(
                                    onPressed: _selected.isEmpty
                                        ? null
                                        : () => _place(
                                            _selected.first,
                                            step.targets[i].id,
                                          ),
                                    child: Text(
                                      step.kind == 'label-diagram'
                                          ? 'Place ${i + 1}'
                                          : step.targets[i].label,
                                    ),
                                  ),
                              ],
                            ),
                            if (_placements.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: AnswerSummary(
                                  pairs: [
                                    for (final e in _placements.entries)
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
                          if (_answerLocked)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: AnswerSummary(
                                pairs: step.isMapping
                                    ? [
                                        for (final e in _placements.entries)
                                          (
                                            step.label(e.key),
                                            step.label(e.value),
                                          ),
                                      ]
                                    : const [],
                                sequence: step.isMapping
                                    ? const []
                                    : _selected.map(step.label).toList(),
                              ),
                            ),
                          if (step.kind == 'free-measure' && !_freeDone)
                            _measure(),
                          if (step.kind == 'free-pair' && !_freeDone)
                            FilledButton(
                              onPressed: () => _freePair(),
                              child: const Text('Make my collection'),
                            ),
                          if (step.kind == 'predict-then-reveal' && !_freeDone)
                            FilledButton.icon(
                              onPressed:
                                  _busy ||
                                      (_prediction == null && _selected.isEmpty)
                                  ? null
                                  : _testPrediction,
                              icon: const Icon(Icons.water_drop_rounded),
                              label: Text(
                                step.json['action'] ?? 'Test my prediction',
                              ),
                            ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _controls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controls() => Container(
    key: const ValueKey('lesson-controls'),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    color: const Color(0xFFFFF8EC),
    child: Row(
      children: [
        Expanded(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .18,
            ),
            child: SingleChildScrollView(
              child: Text(
                _saveFailed
                    ? 'Saving needs help. Your last saved step is safe.'
                    : _visibleFeedback,
                key: const ValueKey('lesson-feedback'),
                style: const TextStyle(fontSize: 19),
              ),
            ),
          ),
        ),
        if (_feedback.isNotEmpty)
          IconButton(
            onPressed: () => _say(_feedback),
            tooltip: 'Listen to feedback',
            icon: const Icon(Icons.volume_up_rounded),
          ),
        const SizedBox(width: 8),
        if (!step.isFree &&
            !_answerLocked &&
            (step.isMulti || step.isOrder || step.isMapping))
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(64, 56),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 18),
            ),
            onPressed:
                _busy ||
                    (step.isMapping
                        ? _placements.length != step.options.length
                        : _selected.isEmpty ||
                              (_science &&
                                  widget.lesson.id == 'unit_06' &&
                                  step.isOrder &&
                                  _selected.length != step.options.length))
                ? null
                : _check,
            child: Text(
              _needsCorrection
                  ? _correctionText('check')
                  : 'Check my discovery',
            ),
          ),
        if (_canContinue)
          FilledButton.icon(
            key: const ValueKey('lessonNext'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(64, 56),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 18),
            ),
            onPressed: _busy ? null : _next,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(_busy ? 'Saving…' : 'Keep exploring'),
          ),
      ],
    ),
  );

  String get _visibleFeedback {
    if (_engine.done &&
        step.explanation.isNotEmpty &&
        _feedback.contains(step.explanation)) {
      return '${step.shortExplanation}${_needsCorrection ? ' Now try it yourself.' : ''}';
    }
    return _feedback;
  }

  Widget _measure() => _ourselves
      ? ShoeMeasure(
          values: [_shoeA, _shoeB],
          ui: Map<String, dynamic>.from(step.json['playUi']),
          onChange: (person, value) {
            if (person == 0) {
              _shoeA = value;
            } else {
              _shoeB = value;
            }
            _changed();
            _say('${step.json['playUi']['shoe']} ${person + 1}: $value');
          },
          onCompare: () {
            _freeDone = true;
            final ui = step.json['playUi'];
            _feedback = _shoeA == _shoeB
                ? ui['equal']
                : (ui['result'] as String)
                      .replaceAll('{big}', '${mathMax(_shoeA, _shoeB)}')
                      .replaceAll('{small}', '${mathMin(_shoeA, _shoeB)}');
            _changed();
            _say(_feedback);
          },
        )
      : Column(
          children: [
            for (var person = 0; person < 2; person++)
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Shoe ${person + 1}: ${person == 0 ? _shoeA : _shoeB}'),
                  IconButton(
                    tooltip: 'Smaller number',
                    onPressed: () => setState(() {
                      if (person == 0) {
                        _shoeA = (_shoeA - 1).clamp(1, 60);
                      } else {
                        _shoeB = (_shoeB - 1).clamp(1, 60);
                      }
                    }),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  IconButton(
                    tooltip: 'Bigger number',
                    onPressed: () => setState(() {
                      if (person == 0) {
                        _shoeA = (_shoeA + 1).clamp(1, 60);
                      } else {
                        _shoeB = (_shoeB + 1).clamp(1, 60);
                      }
                    }),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            FilledButton(
              onPressed: () {
                _freeDone = true;
                _feedback = _shoeA == _shoeB
                    ? 'The two numbers are equal.'
                    : '${mathMax(_shoeA, _shoeB)} is bigger than ${mathMin(_shoeA, _shoeB)}.';
                _changed();
                _say(_feedback);
              },
              child: const Text('Compare my numbers'),
            ),
          ],
        );
  void _freePair() {
    final groups = step.json['allowedGroups'] as List;
    final valid =
        _selected.length == 2 &&
        groups.every((g) => (g as List).any(_selected.contains));
    _feedback = valid
        ? step.explanation
        : 'Choose one living thing and one non-living thing.';
    _freeDone = valid;
    _changed();
    _say(_feedback);
  }

  Widget _completion(BuildContext context) => Scaffold(
    body: AdventurePage(
      maxWidth: 900,
      child: Column(
        children: [
          if (!MediaQuery.disableAnimationsOf(context))
            Lottie.asset(
              'assets/animations/celebrate.json',
              height: 100,
              repeat: false,
            ),
          ScientistOwl(
            gender: ref.read(appProvider).profile!.gender,
            mood: OwlMood.cheering,
            size: 160,
          ),
          StoryPanel(text: _resultText),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < (widget.lesson.quiz ? 10 : 3); i++)
                Icon(
                  !widget.lesson.quiz || i < _session.result().firstTry
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: const Color(0xFF9E6D0F),
                  size: 40,
                ),
            ],
          ),
          if (widget.lesson.stickers.isNotEmpty)
            Text(
              'New word stickers: ${widget.lesson.stickers.map((s) => s['word']).join(', ')}',
            ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: _leave,
                child: const Text('Back to my island'),
              ),
              if (widget.lesson.quiz && _session.result().firstTry < 10)
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => LessonRoute(id: _practiceUnit),
                    ),
                  ),
                  child: const Text('Play the tricky games again'),
                ),
            ],
          ),
        ],
      ),
    ),
  );
  String get _practiceUnit {
    final results = _session.result().objectives;
    for (final id in ['quiz01.01', 'quiz01.02', 'quiz01.08']) {
      if (results[id] != DecisionOutcome.firstTry) return 'unit_01';
    }
    for (final id in ['quiz01.03', 'quiz01.04', 'quiz01.05']) {
      if (results[id] != DecisionOutcome.firstTry) return 'unit_02';
    }
    return 'unit_03';
  }
}

int mathMax(int a, int b) => a > b ? a : b;
int mathMin(int a, int b) => a < b ? a : b;

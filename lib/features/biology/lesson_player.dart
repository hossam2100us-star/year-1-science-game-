import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
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
import '../garden/garden_adventure.dart';
import '../garden/garden_model.dart';

class LessonRoute extends ConsumerWidget {
  const LessonRoute({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(lessonLibraryProvider)
      .when(
        data: (library) => id == 'unit_01'
            ? GardenAdventure(
                content: GardenContent(library.lessons[id]!.json['garden']),
              )
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
  const LessonPlayer({super.key, required this.lesson});
  final Lesson lesson;
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
  String? _prediction;
  int _frame = 0, _shoeA = 9, _shoeB = 12;
  bool _busy = false, _complete = false, _freeDone = false, _saveFailed = false;
  String _feedback = '';
  Future<void> _writes = Future.value();
  LessonStep get step => _session.step;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final saved = ref.read(appProvider).journeys[widget.lesson.id];
    _session = saved != null && saved['version'] == widget.lesson.version
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
    _selected = Set<String>.from(current['selected'] ?? []);
    _placements = Map<String, String>.from(current['placements'] ?? {});
    _touched = Set<String>.from(current['touched'] ?? []);
    _prediction = current['prediction'];
    _frame = current['frame'] ?? 0;
    _freeDone = current['freeDone'] ?? false;
    _feedback = current['feedback'] ?? '';
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

  String get _instruction {
    final names = step.options.map((v) => v.label).join('. ');
    final places = step.kind == 'label-diagram'
        ? List.generate(step.targets.length, (i) => 'Place ${i + 1}').join('. ')
        : step.targets.map((v) => v.label).join('. ');
    return '${step.prompt} $names. ${places.isEmpty ? '' : places + '.'}';
  }

  void _say(String text) {
    ref.read(narrationProvider).speak(text);
  }

  void _syncGame() {
    _game.selected = _selected;
    _game.placements = _placements;
    _game.reveal = _engine.done || _freeDone;
    _game.frame = _frame;
  }

  Map<String, dynamic> _snapshot() => {
    'selected': _selected.toList(),
    'placements': Map<String, String>.from(_placements),
    'touched': _touched.toList(),
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
    if (_complete) return Future.value();
    _session.current = _snapshot();
    final snapshot = _session.toJson();
    // Copy nested collections before the next interaction mutates the session.
    snapshot['responses'] = Map<String, dynamic>.from(_session.responses);
    final writer = ref.read(appProvider.notifier);
    final task = _writes.then(
      (_) => writer.saveJourney(widget.lesson.id, snapshot),
    );
    _writes = task.catchError((Object error) {
      if (mounted) {
        setState(() => _saveFailed = true);
        showSaveError(context);
      }
    });
    return task;
  }

  void _changed() {
    _syncGame();
    setState(() {});
    _persist().catchError((Object _) {});
  }

  void _item(String id) {
    if (_busy || _engine.done || _freeDone || _frame > 0) return;
    _say(step.label(id));
    if (['explore', 'story', 'free-plant'].contains(step.kind)) {
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
    if (!step.isFree && !step.isMulti && !step.isOrder && !step.isMapping)
      _check();
  }

  void _place(String item, String target) {
    if (_busy || _engine.done || _freeDone) return;
    _placements[item] = target;
    _say(
      step.kind == 'label-diagram'
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
  void _check() {
    if (_busy || _engine.done) return;
    final success = _engine.submit(_selection);
    _feedback = _engine.feedback;
    if (_engine.done) {
      final value = step.answer!['value'];
      if (step.isMapping)
        _placements = Map<String, String>.from(value);
      else if (value is List)
        _selected = Set<String>.from(value);
      else
        _selected = {value as String};
      if (success) _game.celebration = 1.2;
    } else {
      _game.wobble = .65;
    }
    _changed();
    _say(_feedback);
  }

  bool get _canContinue {
    if (_engine.done || _freeDone || step.kind == 'story') return true;
    if (step.kind == 'explore' || step.kind == 'free-plant')
      return _touched.length >= (step.json['minTouches'] ?? 3);
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
    } catch (_) {
      if (mounted) showSaveError(context);
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
      _session.responses[step.id] = {..._snapshot(), 'completed': true};
      _session.index++;
      _session.current = {};
      if (_session.finished) {
        await ref.read(appProvider.notifier).completeJourney(_session.result());
        if (mounted) {
          setState(() => _complete = true);
          _say(_resultText);
        }
      } else {
        await ref
            .read(appProvider.notifier)
            .saveJourney(widget.lesson.id, _session.toJson());
        _game.pauseEngine();
        _prepare();
      }
    } catch (_) {
      // A failed boundary save leaves the previous completed step retryable.
      _session.index = previousIndex;
      _session.current = previousCurrent;
      _session.responses = previousResponses;
      if (mounted) {
        showSaveError(context);
        _prepare();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _resultText {
    final name = ref.read(appProvider).profile?.name ?? '';
    if (!widget.lesson.quiz)
      return 'Great effort${name.isEmpty ? '' : ', $name'}! You explored the whole unit and earned three stars.';
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
    } catch (_) {
      if (mounted) showSaveError(context);
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
        _persist().catchError((Object _) {});
      }
      ref.read(narrationProvider).stop();
    } else if (!_complete) {
      _game.resumeEngine();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!_complete) _game.pauseEngine();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(appProvider).profile;
    if (_complete) return _completion(context);
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
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _leave,
                      tooltip: 'Save and return to map',
                      icon: const Icon(Icons.home_rounded),
                    ),
                    Expanded(
                      child: Text(
                        '${step.title} • ${step.section}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      '${_session.index + 1}/${widget.lesson.steps.length}',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ],
                ),
              ),
              Expanded(
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ScientistOwl(
                                size: 70,
                                gender: profile?.gender ?? ChildGender.boy,
                                mood: _engine.done
                                    ? OwlMood.cheering
                                    : _engine.mistakes > 0
                                    ? OwlMood.thinking
                                    : OwlMood.idle,
                              ),
                              Expanded(
                                child: Text(
                                  step.prompt,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _say(_instruction),
                                tooltip: 'Listen again',
                                icon: const Icon(Icons.volume_up_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (step.table.isNotEmpty)
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: SizedBox(
                              height: (MediaQuery.sizeOf(context).height * .55)
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
                          if (!_engine.done && !_freeDone && _frame == 0)
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
                          if (step.isMapping && !_engine.done) ...[
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
                                child: Text(
                                  _placements.entries
                                      .map(
                                        (e) =>
                                            '${step.label(e.key)} → ${step.kind == 'label-diagram' ? 'Place ${step.targets.indexWhere((t) => t.id == e.value) + 1}' : step.label(e.value)}',
                                      )
                                      .join(' • '),
                                ),
                              ),
                          ],
                          if (_engine.done)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                step.isMapping
                                    ? _placements.entries
                                          .map(
                                            (e) =>
                                                '${step.label(e.key)} → ${step.label(e.value)}',
                                          )
                                          .join(' • ')
                                    : _selected.map(step.label).join(' → '),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
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
                          if (!step.isFree &&
                              !_engine.done &&
                              (step.isMulti ||
                                  step.isOrder ||
                                  step.options.length > 1 && step.isMapping))
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: FilledButton(
                                onPressed:
                                    _selected.isEmpty && _placements.isEmpty
                                    ? null
                                    : _check,
                                child: const Text('Check my discovery'),
                              ),
                            ),
                          if (_feedback.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _engine.done || _freeDone
                                    ? const Color(0xFFD9F2DF)
                                    : const Color(0xFFFFE9C7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Expanded(child: Text(_feedback)),
                                  IconButton(
                                    onPressed: () => _say(_feedback),
                                    tooltip: 'Listen to feedback',
                                    icon: const Icon(Icons.volume_up_rounded),
                                  ),
                                ],
                              ),
                            ),
                          if (_saveFailed)
                            const Text(
                              'Saving needs help. Your last saved step is safe.',
                            ),
                          if (_canContinue)
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: FilledButton.icon(
                                key: const ValueKey('lessonNext'),
                                onPressed: _busy ? null : _next,
                                icon: const Icon(Icons.arrow_forward_rounded),
                                label: Text(
                                  _busy ? 'Saving…' : 'Keep exploring',
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _measure() => Column(
    children: [
      for (var person = 0; person < 2; person++)
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Shoe ${person + 1}: ${person == 0 ? _shoeA : _shoeB}'),
            IconButton(
              tooltip: 'Smaller number',
              onPressed: () => setState(() {
                if (person == 0)
                  _shoeA = (_shoeA - 1).clamp(1, 60);
                else
                  _shoeB = (_shoeB - 1).clamp(1, 60);
              }),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            IconButton(
              tooltip: 'Bigger number',
              onPressed: () => setState(() {
                if (person == 0)
                  _shoeA = (_shoeA + 1).clamp(1, 60);
                else
                  _shoeB = (_shoeB + 1).clamp(1, 60);
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
    for (final id in ['quiz01.01', 'quiz01.02', 'quiz01.08'])
      if (results[id] != DecisionOutcome.firstTry) return 'unit_01';
    for (final id in ['quiz01.03', 'quiz01.04', 'quiz01.05'])
      if (results[id] != DecisionOutcome.firstTry) return 'unit_02';
    return 'unit_03';
  }
}

int mathMax(int a, int b) => a > b ? a : b;
int mathMin(int a, int b) => a < b ? a : b;

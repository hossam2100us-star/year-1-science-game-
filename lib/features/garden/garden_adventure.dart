import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/diagnostics/app_log.dart';
import '../../core/mascot.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/narration.dart';
import 'garden_model.dart';
import 'garden_scene.dart';

class GardenAdventure extends ConsumerStatefulWidget {
  const GardenAdventure({
    super.key,
    required this.content,
    this.onPracticeComplete,
  });
  final GardenContent content;
  final Future<void> Function(DecisionOutcome)? onPracticeComplete;
  @override
  ConsumerState<GardenAdventure> createState() => _GardenAdventureState();
}

class _GardenAdventureState extends ConsumerState<GardenAdventure>
    with WidgetsBindingObserver {
  late GardenRound round;
  late GardenScene scene;
  bool ready = false, busy = false, saveError = false, voiceUnavailable = false;
  Future<void> writes = Future.value();
  GardenContent get content => widget.content;
  GardenItem? get selected =>
      round.selected == null ? null : content.item(round.selected!);
  String t(String key) => content.text(key);
  bool get explained =>
      selected != null &&
      round.results[selected!.id] == DecisionOutcome.explained.name;
  String get feedbackTitle => explained ? t('explained') : t('praise');
  String get prompt => selected != null
      ? round.feedback
            ? '$feedbackTitle ${selected!.explanation}${round.needsCorrection ? ' Now choose for yourself.' : ''}'
            : round.mistakes > 0
            ? '${t('retry')} ${selected!.hint}'
            : (selected!.question ??
                  t('question')
                      .replaceAll('{name}', selected!.name.toLowerCase()))
      : round.finished(content)
      ? t('finished')
      : round.results.isEmpty
      ? t('tutorial')
      : t('hunt');
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final saved = widget.onPracticeComplete == null
        ? ref.read(appProvider).journeys[content.storageKey]
        : null;
    round = saved == null
        ? GardenRound(
            version: content.version,
            requiredIds: content.items.map((i) => i.id).toSet(),
          )
        : GardenRound.restore(saved, content);
    scene = GardenScene(
      asset: content.asset,
      bounds: content.bounds ?? gardenBounds,
      guide: content.items.first.id,
      difficulty: content.difficulty,
      onReady: () {
        if (!mounted) return;
        setState(() => ready = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _speak(prompt);
        });
      },
    );
    sync();
  }

  void sync() {
    scene.found = round.results.keys.toSet();
    scene.explained = round.results.entries
        .where((e) => e.value == DecisionOutcome.explained.name)
        .map((e) => e.key)
        .toSet();
    scene.tutorial = round.selected == null;
  }

  Future<void> _speak(String text) async {
    final voice = ref.read(narrationProvider);
    if (voice.status == VoiceStatus.browserPreview) await voice.refresh();
    await voice.speak(text);
    if (mounted)
      setState(() => voiceUnavailable = voice.status != VoiceStatus.ready);
  }

  Future<void> persist() {
    if (widget.onPracticeComplete != null) return Future.value();
    final snapshot = round.toJson(), writer = ref.read(appProvider.notifier);
    final task = writes.then(
      (_) => writer.saveJourney(content.storageKey, snapshot),
    );
    writes = task
        .then((_) {
          if (mounted && saveError) setState(() => saveError = false);
        })
        .catchError((Object error, StackTrace stack) {
          AppLog.error(
            'garden',
            'Saving the garden journey failed',
            error,
            stack,
          );
          if (mounted) setState(() => saveError = true);
        });
    return task;
  }

  void changed() {
    sync();
    setState(() {});
    persist().ignore(); // Logged and shown by persist().
  }

  void pick(String id) {
    if (!ready || busy || selected != null || round.finished(content)) return;
    if (round.results.containsKey(id)) {
      _speak(content.item(id).explanation);
      return;
    }
    round.select(id);
    changed();
    _speak('${selected!.name}. $prompt. ${t('alive')}. ${t('notAlive')}.');
  }

  void answer(bool alive) {
    if (selected == null || busy || (round.feedback && !round.needsCorrection))
      return;
    final correcting = round.needsCorrection;
    final outcome = round.answer(selected!, alive);
    if ((outcome != null && outcome != DecisionOutcome.explained) ||
        (correcting && !round.needsCorrection))
      scene.celebration = 1.2;
    changed();
    _speak(prompt);
  }

  Future<void> next() async {
    if (busy || round.needsCorrection) return;
    setState(() => busy = true);
    try {
      await persist();
      if (widget.onPracticeComplete != null && selected != null) {
        await widget.onPracticeComplete!(
          DecisionOutcome.values.byName(round.results[selected!.id]!),
        );
        if (mounted) Navigator.of(context).pop();
        return;
      }
      round.next();
      sync();
      await persist();
      if (mounted) {
        setState(() {});
        _speak(prompt);
      }
    } catch (_) {
      // Already logged by persist(); show the retry banner.
      if (mounted) setState(() => saveError = true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> replay() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      round = round.replay();
      await persist();
      sync();
      if (mounted) {
        setState(() {});
        _speak(prompt);
      }
    } catch (_) {
      // Already logged by persist(); show the retry banner.
      if (mounted) setState(() => saveError = true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> leave() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await persist();
      await writes;
      await ref.read(narrationProvider).stop();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      // Already logged by persist(); show the retry banner.
      if (mounted) setState(() => saveError = true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed)
      scene.resumeEngine();
    else {
      scene.pauseEngine();
      persist().ignore(); // Logged and shown by persist().
      ref.read(narrationProvider).stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    scene.pauseEngine();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(appProvider).profile ?? const ChildProfile();
    scene.reducedMotion = MediaQuery.disableAnimationsOf(context);
    final small = MediaQuery.sizeOf(context).height < 500;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) leave();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F5DC),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              final footerHeight = small ? 0.0 : 160.0;
              final sceneSize = Size(
                box.maxWidth - (small ? 232 : 0),
                box.maxHeight - footerHeight,
              );
              final hitboxes = gardenRects(
                sceneSize,
                touch: true,
                bounds: scene.bounds,
              );
              return Stack(
                children: [
                  Positioned.fill(
                    bottom: footerHeight,
                    right: small ? 232 : 0,
                    child: GameWidget<GardenScene>(
                      game: scene,
                      loadingBuilder: (_) =>
                          const Center(child: CircularProgressIndicator()),
                      errorBuilder: (_, error) => Center(
                        child: FilledButton(
                          onPressed: leave,
                          child: const Text('Back'),
                        ),
                      ),
                    ),
                  ),
                  if (ready && selected == null && !round.finished(content))
                    for (final item in content.items)
                      Positioned.fromRect(
                        rect: hitboxes[item.id]!,
                        child: Semantics(
                          label: item.name,
                          button: true,
                          child: GestureDetector(
                            key: ValueKey('garden-${item.id}'),
                            behavior: HitTestBehavior.opaque,
                            onTap: () => pick(item.id),
                            child: const MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: SizedBox.expand(),
                            ),
                          ),
                        ),
                      ),
                  if (small && selected == null && !round.finished(content))
                    Positioned(
                      right: 8,
                      top: 8,
                      bottom: 8,
                      width: 216,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: busy ? null : leave,
                                  tooltip: t('back'),
                                  icon: const Icon(Icons.arrow_back_rounded),
                                ),
                                IconButton(
                                  onPressed: () => _speak(prompt),
                                  tooltip: 'Listen again',
                                  icon: const Icon(Icons.volume_up_rounded),
                                ),
                              ],
                            ),
                            Text(
                              '${round.results.length} / ${content.items.length}',
                              style: const TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 25,
                              ),
                            ),
                            ScientistOwl(gender: profile.gender, size: 60),
                            Text(
                              prompt,
                              style: const TextStyle(fontSize: 22),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!small)
                    Positioned(
                      top: 14,
                      left: 12,
                      right: 12,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _pill(
                            child: IconButton(
                              onPressed: busy ? null : leave,
                              tooltip: t('back'),
                              icon: const Icon(Icons.arrow_back_rounded),
                              color: gardenInk,
                            ),
                          ),
                          const Spacer(),
                          _pill(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFAE771A),
                                    size: 28,
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    '${round.results.length} / ${content.items.length}',
                                    style: const TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontSize: 25,
                                      color: gardenInk,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!small && selected == null && !round.finished(content))
                    Positioned(
                      bottom: small ? 5 : 16,
                      height: footerHeight - (small ? 10 : 32),
                      left: small ? 12 : 32,
                      right: small ? 12 : 32,
                      child: SingleChildScrollView(
                        child: _pill(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: small ? 8 : 16,
                              vertical: small ? 4 : 10,
                            ),
                            child: Row(
                              children: [
                                ScientistOwl(
                                  gender: profile.gender,
                                  size: small ? 54 : 86,
                                  mood: OwlMood.happy,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        round.results.isEmpty
                                            ? t('tutorial')
                                            : t('hunt'),
                                        style: TextStyle(
                                          fontFamily: 'Fredoka',
                                          fontSize: small ? 22 : 28,
                                          color: gardenInk,
                                        ),
                                      ),
                                      if (!small ||
                                          MediaQuery.textScalerOf(context)
                                                  .scale(1) <
                                              1.5)
                                        const SizedBox.shrink(),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _speak(prompt),
                                  tooltip: 'Listen again',
                                  icon: Icon(
                                    voiceUnavailable
                                        ? Icons.volume_off_rounded
                                        : Icons.volume_up_rounded,
                                  ),
                                  color: gardenInk,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (selected != null || round.finished(content)) ...[
                    const Positioned.fill(
                      child: ColoredBox(color: Color(0x99506448)),
                    ),
                    Positioned.fill(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(small ? 8 : 24),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 930),
                            child: Material(
                              color: const Color(0xFFFFFAEF),
                              borderRadius: BorderRadius.circular(30),
                              elevation: 0,
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: EdgeInsets.all(small ? 14 : 26),
                                  child: round.finished(content)
                                      ? _finish(profile, small)
                                      : _decision(profile, small),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (saveError)
                    Positioned(
                      bottom: 4,
                      left: 10,
                      right: 10,
                      child: Material(
                        color: const Color(0xFFFFE9C7),
                        child: TextButton(
                          onPressed: () =>
                              persist().ignore(), // Logged by persist().
                          child: Text(
                            t('saveError'),
                            textDirection: TextDirection.ltr,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _pill({required Widget child}) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFFDF9EC).withValues(alpha: .95),
      borderRadius: BorderRadius.circular(23),
      boxShadow: const [
        BoxShadow(
          color: Color(0x23423925),
          blurRadius: 14,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );

  Widget _decision(ChildProfile profile, bool small) {
    final item = selected!, done = round.feedback && !round.needsCorrection;
    final picture = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Draggable<String>(
          data: item.id,
          maxSimultaneousDrags: done ? 0 : 1,
          feedback: Material(
            color: Colors.transparent,
            elevation: 6,
            borderRadius: BorderRadius.circular(22),
            child: GardenPortrait(
              id: item.id,
              image: scene.artwork,
              bounds: scene.bounds,
              size: 110,
            ),
          ),
          childWhenDragging: Opacity(
            opacity: .3,
            child: GardenPortrait(
              id: item.id,
              image: scene.artwork,
              bounds: scene.bounds,
              size: small ? 125 : 215,
            ),
          ),
          child: GardenPortrait(
            id: item.id,
            image: scene.artwork,
            bounds: scene.bounds,
            size: small ? 125 : 215,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          item.name,
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: small ? 25 : 32,
            color: gardenInk,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox.shrink(),
      ],
    );
    final choices = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                round.feedback
                    ? feedbackTitle
                    : (item.question ??
                          t('question')
                              .replaceAll('{name}', item.name.toLowerCase())),
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: small ? 25 : 32,
                  color: gardenInk,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _speak(prompt),
              tooltip: 'Listen again',
              icon: const Icon(Icons.volume_up_rounded),
              color: gardenInk,
            ),
          ],
        ),
        if (!done) const SizedBox.shrink(),
        const SizedBox(height: 8),
        if (!done)
          Row(
            children: [
              Expanded(child: _basket(true, small)),
              const SizedBox(width: 12),
              Expanded(child: _basket(false, small)),
            ],
          ),
        if (round.mistakes > 0 && !round.feedback)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9C7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${t('retry')} ${item.hint}',
              key: const ValueKey('garden-hint'),
              style: const TextStyle(fontSize: 22, color: gardenInk),
            ),
          ),
        if (round.needsCorrection) ...[
          Text(
            item.explanation,
            key: const ValueKey('garden-explanation'),
            style: const TextStyle(fontSize: 22, color: gardenInk),
          ),
          const Text(
            'Now choose for yourself.',
            style: TextStyle(fontSize: 22, color: gardenInk),
          ),
        ],
        if (done) ...[
          Row(
            children: [
              SizedBox(
                width: 70,
                height: 64,
                child: CustomPaint(
                  painter: BasketPicture(item.alive, highlight: !explained),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.explanation,
                  key: const ValueKey('garden-explanation'),
                  style: const TextStyle(fontSize: 22, color: gardenInk),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('garden-next'),
            onPressed: busy ? null : next,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF367A5D),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(t('next')),
          ),
        ],
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!small)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                ScientistOwl(
                  gender: profile.gender,
                  size: 68,
                  mood: done
                      ? (explained ? OwlMood.thinking : OwlMood.cheering)
                      : round.mistakes > 0
                      ? OwlMood.thinking
                      : OwlMood.happy,
                ),
                const SizedBox(width: 8),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
        LayoutBuilder(
          builder: (context, box) => box.maxWidth > 560
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(width: small ? 160 : 245, child: picture),
                    const SizedBox(width: 18),
                    Expanded(child: choices),
                  ],
                )
              : Column(
                  children: [picture, const SizedBox(height: 12), choices],
                ),
        ),
      ],
    );
  }

  Widget _basket(bool alive, bool small) {
    final enabled = (!round.feedback || round.needsCorrection) && !busy;
    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => enabled && d.data == selected!.id,
      onAcceptWithDetails: (_) => answer(alive),
      builder: (context, candidates, rejected) => Semantics(
        button: true,
        label: alive ? t('alive') : t('notAlive'),
        child: Material(
          color: candidates.isNotEmpty ? const Color(0xFFFFE9C7) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: alive ? const Color(0xFF82B59D) : const Color(0xFF98B6CB),
              width: 2,
            ),
          ),
          child: InkWell(
            key: ValueKey(alive ? 'garden-alive' : 'garden-not-alive'),
            borderRadius: BorderRadius.circular(22),
            onTap: enabled ? () => answer(alive) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: small ? 75 : 105,
                    height: small ? 55 : 80,
                    child: CustomPaint(painter: BasketPicture(alive)),
                  ),
                  Text(
                    alive ? t('alive') : t('notAlive'),
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 26,
                      color: gardenInk,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _finish(ChildProfile profile, bool small) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ScientistOwl(
        gender: profile.gender,
        size: small ? 90 : 145,
        mood: OwlMood.cheering,
      ),
      Text(
        profile.name.trim().isEmpty
            ? t('finished')
            : t('goodName').replaceAll('{name}', profile.name),
        style: const TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 32,
          color: gardenInk,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox.shrink(),
      const SizedBox(height: 12),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        children: [
          for (final i in content.items)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: GardenPortrait(
                id: i.id,
                image: scene.artwork,
                bounds: scene.bounds,
                size: small ? 56 : 78,
              ),
            ),
        ],
      ),
      const SizedBox(height: 20),
      Wrap(
        spacing: 14,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          FilledButton.icon(
            onPressed: busy ? null : replay,
            icon: const Icon(Icons.replay_rounded),
            label: Text(t('replay')),
          ),
          OutlinedButton.icon(
            onPressed: busy ? null : leave,
            icon: const Icon(Icons.map_rounded),
            label: Text(t('back')),
          ),
        ],
      ),
    ],
  );
}

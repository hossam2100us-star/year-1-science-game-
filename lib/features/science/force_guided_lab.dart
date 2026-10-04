import 'package:flutter/material.dart';

import 'force_track.dart';

String forceGuideStage(Map<String, dynamic> data) {
  final moves = Set<String>.from(data['visited'] ?? []);
  final trials = Set<String>.from(data['pushTrials'] ?? []);
  final guessed = ['gentle', 'strong'].contains(data['forceGuess']);
  final moved = moves.containsAll(['near', 'far']);
  final saved = data['forceGuide'];
  if (saved == 'push' ||
      saved == 'pull' && moves.contains('far') ||
      saved == 'guess' && moved ||
      saved == 'gentle' && moved && guessed ||
      saved == 'strong' && moved && guessed && trials.contains('gentle') ||
      saved == 'done' &&
          moved &&
          guessed &&
          trials.containsAll(['gentle', 'strong'])) {
    return saved;
  }
  if (!moves.contains('far')) return 'push';
  if (!moves.contains('near')) return 'pull';
  if (!guessed) return 'guess';
  if (!trials.contains('gentle')) return 'gentle';
  if (!trials.contains('strong')) return 'strong';
  return 'done';
}

/// A single action per stage. Existing trials and the original guess are kept.
class ForceGuidedLab extends StatefulWidget {
  const ForceGuidedLab({
    super.key,
    required this.data,
    required this.ui,
    required this.onSave,
    required this.onSpeak,
    this.onFeedback,
  });
  final Map<String, dynamic> data, ui;
  final Future<bool> Function(Map<String, dynamic>) onSave;
  final ValueChanged<String> onSpeak;
  final ValueChanged<String>? onFeedback;
  @override
  State<ForceGuidedLab> createState() => _ForceGuidedLabState();
}

class _ForceGuidedLabState extends State<ForceGuidedLab> {
  bool saving = false;
  static const stages = ['push', 'pull', 'guess', 'gentle', 'strong', 'done'];
  Map<String, dynamic> get data => widget.data;
  Map<String, dynamic> get ui => widget.ui;
  Set<String> get moves => Set<String>.from(data['visited'] ?? []);
  Set<String> get trials => Set<String>.from(data['pushTrials'] ?? []);
  bool get guessed => ['gentle', 'strong'].contains(data['forceGuess']);
  bool get moved => moves.containsAll(['near', 'far']);
  String get stage => forceGuideStage(data);

  String instruction(String current) => ui['guideInstructions'][current];
  Future<bool> save(
    Map<String, dynamic> patch,
    String feedback, {
    bool instructionOnly = false,
  }) async {
    if (saving) return false;
    setState(() => saving = true);
    try {
      final saved = await widget.onSave({...data, ...patch});
      if (saved && mounted) {
        widget.onFeedback?.call(instructionOnly ? '' : feedback);
        widget.onSpeak(feedback);
      }
      return saved;
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> go(String next) => save(
    {
      'forceGuide': next,
      if (['gentle', 'strong'].contains(next)) ...{
        'ballDistance': 0.0,
        'ballRun': (data['ballRun'] as int? ?? 0) + 1,
      },
    },
    instruction(next),
    instructionOnly: true,
  );
  Future<void> move(double position) => save(
    {
      'forceGuide': stage,
      'position': position,
      'visited': {
        ...moves,
        if (position < .25) 'near',
        if (position > .75) 'far',
      }.toList(),
    },
    position > .75
        ? ui['pushDone']
        : position < .25
        ? ui['pullDone']
        : instruction(stage),
  );
  Future<void> testPush(String strength) => save({
    'forceGuide': strength == 'strong' ? 'done' : 'gentle',
    'ballDistance': strength == 'gentle' ? .35 : .9,
    'ballRun': (data['ballRun'] as int? ?? 0) + 1,
    'pushTrials': {...trials, strength}.toList(),
  }, strength == 'gentle' ? ui['gentleDone'] : ui['result']);
  Widget action(String key, String label, VoidCallback callback) =>
      FilledButton(
        key: ValueKey('lab-$key'),
        onPressed: saving ? null : callback,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22),
          ),
        ),
      );
  @override
  Widget build(BuildContext context) {
    final current = stage, order = stages.indexOf(current);
    final trolley = current == 'push' || current == 'pull';
    final ready = current == 'push'
        ? moves.contains('far')
        : current == 'pull'
        ? moved
        : current == 'guess'
        ? guessed
        : current == 'gentle'
        ? trials.contains('gentle')
        : false;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${ui['stepCount']} ${order == 5 ? 5 : order + 1} / 5',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17),
              ),
            ),
            IconButton(
              key: const ValueKey('lab-force-listen'),
              tooltip: 'Listen again',
              onPressed: () => widget.onSpeak(instruction(current)),
              icon: const Icon(Icons.volume_up_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          instruction(current),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ForceTrack(
              key: trolley
                  ? const ValueKey('guided-trolley')
                  : ValueKey('ball-run-${data['ballRun'] ?? 0}'),
              position: trolley
                  ? (data['position'] as num? ?? .05).toDouble()
                  : (data['ballDistance'] as num? ?? 0).toDouble(),
              art: trolley ? 'trolley' : 'ball',
              you: ui['you'],
              onMove: trolley && !saving ? move : null,
              onReplay: !trolley && guessed && !saving && current != 'guess'
                  ? () => testPush(current == 'gentle' ? 'gentle' : 'strong')
                  : null,
              goalPosition: trolley
                  ? current == 'push'
                        ? .95
                        : .05
                  : null,
              animateFromStart: !trolley,
              comparisons: current == 'done' ? [.35, .9] : const [],
            ),
          ),
        ),
        if (current == 'guess' && guessed)
          Text(
            '${ui['yourGuess']}: ${ui[data['forceGuess']]}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20),
          ),
        const SizedBox(height: 8),
        if (current != 'guess' || guessed)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (order > 0) ...[
                IconButton.filledTonal(
                  key: const ValueKey('lab-force-guide-previous'),
                  tooltip: ui['previousStep'],
                  onPressed: saving ? null : () => go(stages[order - 1]),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 12),
              ],
              if (ready)
                Flexible(
                  child: action(
                    'force-guide-next',
                    ui['nextActions'][current],
                    () => go(stages[order + 1]),
                  ),
                )
              else if (trolley)
                Flexible(
                  child: action(
                    'force-$current',
                    ui[current],
                    () => move(current == 'push' ? .95 : .05),
                  ),
                )
              else if (current == 'gentle' || current == 'strong')
                Flexible(
                  child: action(
                    'force-test-$current',
                    ui[current],
                    () => testPush(current),
                  ),
                )
              else if (current == 'done')
                Flexible(
                  child: action(
                    'force-replay',
                    ui['rollAgain'],
                    () => testPush('strong'),
                  ),
                ),
            ],
          ),
        if (current == 'guess' && !guessed)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              IconButton.filledTonal(
                key: const ValueKey('lab-force-guide-previous'),
                tooltip: ui['previousStep'],
                onPressed: saving ? null : () => go('pull'),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              for (final id in ['gentle', 'strong'])
                action(
                  'force-guess-$id',
                  ui[id],
                  () => save(
                    {
                      'forceGuess': id,
                      'forceGuide': 'gentle',
                      'ballDistance': 0.0,
                    },
                    instruction('gentle'),
                    instructionOnly: true,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

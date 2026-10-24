import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../content/lesson.dart';
import '../maths/maths_art.dart';
import '../maths/number_pad.dart';
import '../science/discovery_world.dart';
import 'english_art.dart';
import 'english_visual.dart';
import 'letter_tiles.dart';

/// English questions: word and sentence cards that read themselves aloud
/// when tapped, letter tiles for spelling, and the same Check, feedback,
/// marking and saving as every other subject.
class EnglishStage extends StatelessWidget {
  const EnglishStage({
    super.key,
    required this.step,
    required this.selected,
    required this.placements,
    required this.touched,
    required this.reviewItems,
    required this.locked,
    required this.onItem,
    required this.onPlace,
    this.onWrite,
    this.onSay,
  });

  final LessonStep step;
  final Set<String> selected, touched, reviewItems;
  final Map<String, String> placements;
  final bool locked;
  final ValueChanged<String> onItem;
  final void Function(String item, String target) onPlace;
  final ValueChanged<Map<String, String>>? onWrite;
  final ValueChanged<String>? onSay;

  Map<String, dynamic>? get _visual => switch (step.json['englishVisual']) {
    final Map<String, dynamic> visual => visual,
    _ => null,
  };

  bool get _explore => step.kind == 'explore';

  /// Single words are bigger; one size for every card of a question.
  bool get _shortLabels => step.options.every((o) => o.label.length <= 12);

  bool get _anyPicture => step.options.any((o) => _pictureOf(o.id) != null);

  String? _pictureOf(String id) {
    final option = (step.json['options'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((o) => o['id'] == id);
    final picture = option['picture'] as String?;
    return picture != null && hasEnglishPicture(picture) ? picture : null;
  }

  /// A card the child taps: it reads itself aloud (the lesson player says
  /// it) and is chosen, or counted as heard on a story step.
  Widget _card(BuildContext context, PictureItem item, double width) {
    final picked = selected.contains(item.id) && !_explore;
    final heard = _explore && touched.contains(item.id);
    final revisit = reviewItems.contains(item.id);
    final picture = _pictureOf(item.id);
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: OutlinedButton(
        key: ValueKey('english-option-${item.id}'),
        onPressed: locked ? null : () => onItem(item.id),
        style: OutlinedButton.styleFrom(
          backgroundColor: picked || heard
              ? scheme.primaryContainer
              : Colors.white,
          padding: const EdgeInsets.all(14),
          alignment: _explore ? Alignment.centerLeft : Alignment.center,
          side: BorderSide(
            color: revisit ? const Color(0xFF9E6D0F) : scheme.primary,
            width: picked ? 3 : 2,
          ),
        ),
        child: _explore
            ? Row(
                children: [
                  Icon(
                    heard
                        ? Icons.check_circle_rounded
                        : Icons.volume_up_rounded,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(fontSize: 21),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // When some cards have a picture, the others keep the
                  // same room, so every card is the same size.
                  if (picture != null) ...[
                    EnglishPicture(picture, height: 84),
                    const SizedBox(height: 6),
                  ] else if (_anyPicture)
                    const SizedBox(height: 90),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: _shortLabels ? 26 : 20),
                  ),
                  if (picked && step.isOrder)
                    Text('${selected.toList().indexOf(item.id) + 1}'),
                  if (placements[item.id] case final String target)
                    Text(
                      '→ ${step.label(target)}',
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
      ),
    );
  }

  /// The answer cards in rows, or one under another when [stacked].
  Widget _cards(BuildContext context, double maxWidth, {bool stacked = false}) {
    final large = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final longest = step.options.fold<int>(
      0,
      (n, o) => math.max(n, o.label.length),
    );
    // Story parts and long sentences take a whole row; single words share
    // one.
    final columns = stacked || _explore || longest > 40
        ? 1
        : math.min(
            step.options.length,
            large
                ? (maxWidth < 650 ? 1 : 2)
                : maxWidth < 450
                ? 2
                : maxWidth < 900
                ? 3
                : 4,
          );
    final width = (maxWidth - (columns - 1) * 12) / columns;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        for (final option in step.options) _card(context, option, width),
      ],
    );
  }

  Widget _written() => step.isWord
      ? WrittenWord(
          key: ValueKey('word-${step.id}'),
          value: placements['answer'] ?? '',
          letters: Map<String, dynamic>.from(step.json['letters'] as Map),
          locked: locked,
          review: reviewItems.contains('answer'),
          onSay: onSay,
          onChanged: (value) => onWrite?.call({'answer': value}),
        )
      : WrittenNumber(
          key: ValueKey('written-${step.id}'),
          value: placements['answer'] ?? '',
          locked: locked,
          review: reviewItems.contains('answer'),
          onSay: onSay,
          onChanged: (value) => onWrite?.call({'answer': value}),
        );

  Widget _visualBox(Map<String, dynamic> visual) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: EnglishVisual(data: visual),
  );

  bool get _chart => _visual?['type'] == 'chart';

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF2FB),
      borderRadius: BorderRadius.circular(24),
    ),
    child: LayoutBuilder(
      builder: (context, box) {
        // As in Maths, a chart's answers sit beside it on a wide screen, so
        // the child never scrolls to answer.
        final beside = box.maxWidth >= 900 && _chart && !_explore;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A story step shows its own picture instead of the setting,
            // and a chart needs the room on a short screen, so everything
            // fits a tablet without scrolling.
            if (!(_explore && _visual != null) &&
                !(_chart && DiscoveryWorld.usableHeight(context) < 760)) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: double.infinity,
                  height: mathsBannerHeight(context, box.maxWidth),
                  child: EnglishBackdrop(scene: step.scene),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (beside)
              Row(
                children: [
                  Expanded(flex: 3, child: _visualBox(_visual!)),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: step.isWritten
                        ? _written()
                        : LayoutBuilder(
                            builder: (context, side) =>
                                _cards(context, side.maxWidth, stacked: true),
                          ),
                  ),
                ],
              )
            else
              ..._below(context, box.maxWidth),
          ],
        );
      },
    ),
  );

  List<Widget> _below(BuildContext context, double maxWidth) => [
    if (_visual case final visual?) ...[
      _visualBox(visual),
      const SizedBox(height: 16),
    ],
    if (step.isOrder)
      const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Text(
          'Tap in order. Tap a chosen card again to move it.',
          textAlign: TextAlign.center,
        ),
      ),
    if (step.isMapping && !locked)
      const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Text(
          'Choose a card, then choose where it belongs.',
          textAlign: TextAlign.center,
        ),
      ),
    if (step.isWritten) _written() else _cards(context, maxWidth),
    if (step.isMapping) ...[
      const SizedBox(height: 16),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          for (final target in step.targets)
            FilledButton.tonal(
              key: ValueKey('english-target-${target.id}'),
              onPressed: locked || selected.isEmpty
                  ? null
                  : () => onPlace(selected.first, target.id),
              style: FilledButton.styleFrom(
                textStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 22),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              child: Text(target.label, textAlign: TextAlign.center),
            ),
        ],
      ),
    ],
    if (step.isOrder && selected.isNotEmpty) ...[
      const SizedBox(height: 16),
      Text(
        selected.map(step.label).join(' '),
        key: const ValueKey('english-order'),
        textAlign: TextAlign.center,
        style: const TextStyle(fontFamily: 'Fredoka', fontSize: 28),
      ),
    ],
  ];
}

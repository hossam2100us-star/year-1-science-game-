import 'package:flutter/material.dart';

import '../../content/lesson.dart';
import 'force_garden_scene.dart';

const forceGardenSpots = {
  'gate': ['push', 'pull'],
  'lawn': ['roll', 'hop', 'crawl'],
  'pond': ['swim', 'slither', 'fly'],
};

String forceGardenResumeSpot(Set<String> seen) =>
    forceGardenSpots.keys.firstWhere(
      (place) => forceGardenSpots[place]!.any((id) => !seen.contains(id)),
      orElse: () => 'gate',
    );

/// One garden adventure, with freely visitable places and eight saved discoveries.
class ForceDiscovery extends StatefulWidget {
  const ForceDiscovery({
    super.key,
    required this.step,
    required this.seen,
    required this.onItem,
    this.onSpeak,
  });
  final LessonStep step;
  final Set<String> seen;
  final ValueChanged<String> onItem;
  final ValueChanged<String>? onSpeak;
  @override
  State<ForceDiscovery> createState() => _ForceDiscoveryState();
}

class _ForceDiscoveryState extends State<ForceDiscovery> {
  static const spots = forceGardenSpots;
  String spot = 'gate';
  String? watching;
  String cartMotion = 'push';
  int replay = 0;
  Map<dynamic, dynamic> get ui => widget.step.json['forceScene'];
  String story(String place) => ui['gardenStories'][place];

  @override
  void initState() {
    super.initState();
    spot = forceGardenResumeSpot(widget.seen);
    cartMotion = widget.seen.contains('push') && !widget.seen.contains('pull')
        ? 'pull'
        : 'push';
  }

  void watch(String id) {
    setState(() {
      watching = id;
      if (id == 'push' || id == 'pull') cartMotion = id;
      replay++;
    });
    widget.onItem(id);
  }

  void visit(String place) {
    if (spot == place) return;
    setState(() {
      spot = place;
      watching = null;
    });
    widget.onSpeak?.call(story(place));
  }

  @override
  Widget build(BuildContext context) {
    final ids = spots.values.expand((ids) => ids).toSet();
    final count = widget.seen.intersection(ids).length;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${ui['gardenProgress']} $count / ${ids.length}',
                style: const TextStyle(fontSize: 17),
              ),
            ),
            IconButton(
              key: const ValueKey('force-discovery-listen'),
              tooltip: 'Listen again',
              onPressed: widget.onSpeak == null
                  ? null
                  : () => widget.onSpeak!(
                      watching == null
                          ? story(spot)
                          : widget.step.json['senseDescriptions'][watching],
                    ),
              icon: const Icon(Icons.volume_up_rounded),
            ),
          ],
        ),
        Text(
          story(spot),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ForceGardenScene(
          key: ValueKey('force-garden-scene-$spot'),
          spot: spot,
          items: [
            for (final id in spots[spot]!)
              widget.step.options.firstWhere((item) => item.id == id),
          ],
          motions: Map<String, String>.from(widget.step.json['motions']),
          watching: watching,
          cartMotion: cartMotion,
          replay: replay,
          you: ui['you'],
          push: ui['gardenPush'],
          pull: ui['gardenPull'],
          onWatch: watch,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final place in spots.keys)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: TextButton(
                    key: ValueKey('force-garden-$place'),
                    onPressed: () => visit(place),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 52),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      backgroundColor: spot == place
                          ? const Color(0xFFDCEBDE)
                          : const Color(0xFFF0F1E7),
                    ),
                    child: Text(
                      ui['gardenSpots'][place],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 17),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

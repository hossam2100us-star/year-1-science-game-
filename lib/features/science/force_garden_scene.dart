import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../content/lesson.dart';
import '../../core/touch_cue.dart';
import 'force_motion.dart';
import 'force_trolley_scene.dart';
import '../../core/game_image.dart';

const forceGardenAsset = 'forces-garden-v6.webp';

/// Stable hitboxes sit in real habitats; only the last touched subject moves.
class ForceGardenScene extends StatelessWidget {
  const ForceGardenScene({
    super.key,
    required this.spot,
    required this.items,
    required this.motions,
    required this.watching,
    required this.cartMotion,
    required this.replay,
    required this.you,
    required this.push,
    required this.pull,
    required this.onWatch,
  });
  final String spot, cartMotion, you, push, pull;
  final List<PictureItem> items;
  final Map<String, String> motions;
  final String? watching;
  final int replay;
  final ValueChanged<String> onWatch;

  static const locations = {
    'roll': Rect.fromLTWH(.04, .49, .32, .43),
    'hop': Rect.fromLTWH(.39, .23, .40, .43),
    'crawl': Rect.fromLTWH(.62, .71, .34, .25),
    'fly': Rect.fromLTWH(.51, .04, .43, .38),
    'slither': Rect.fromLTWH(.04, .59, .40, .34),
    'swim': Rect.fromLTWH(.71, .44, .28, .32),
  };

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final width = box.maxWidth;
      final height = (width * .78).clamp(280.0, 440.0);
      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              Positioned.fill(child: _GardenBackground(spot)),
              if (spot == 'gate')
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 84,
                  child: Semantics(
                    button: true,
                    label: 'Watch the trolley $cartMotion',
                    child: InkWell(
                      key: const ValueKey('force-garden-trolley'),
                      onTap: () => onWatch(cartMotion),
                      child: Stack(
                        children: [
                          ForceTrolleyScene(
                            key: ValueKey('$cartMotion-$replay'),
                            motion: cartMotion,
                            active: watching != null,
                            you: you,
                            showGround: false,
                          ),
                          const Positioned(
                            right: 12,
                            bottom: 22,
                            child: TouchCue(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (spot != 'gate')
                for (final item in items) _friend(item, width, height),
              if (spot == 'gate')
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Row(
                    children: [
                      for (final id in ['push', 'pull']) ...[
                        if (id == 'pull') const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            key: ValueKey('science-item-$id'),
                            onPressed: () => onWatch(id),
                            icon: const Icon(Icons.touch_app_rounded),
                            label: Text(
                              id == 'push' ? push : pull,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  Widget _friend(PictureItem item, double width, double height) {
    final rect = locations[item.id]!;
    final targetWidth = rect.width * width;
    final targetHeight = rect.height * height;
    // Reserve room for the existing hop/travel so art stays inside its habitat.
    final size = math
        .min(
          targetWidth / 1.25 - 24,
          targetHeight - (item.id == 'hop' ? 40 : 12),
        )
        .clamp(44.0, 135.0);
    return Positioned(
      left: rect.left * width,
      top: rect.top * height,
      width: targetWidth,
      height: targetHeight,
      child: Semantics(
        button: true,
        label: 'Watch ${item.label.toLowerCase()}',
        child: InkWell(
          key: ValueKey('science-item-${item.id}'),
          onTap: () => onWatch(item.id),
          child: Center(
            child: SizedBox(
              width: size * 1.25,
              height: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  MovementSprite(
                    key: ValueKey(
                      '${item.id}-${watching == item.id ? replay : 0}',
                    ),
                    art: item.art,
                    motion: motions[item.id],
                    active: watching == item.id,
                    size: size,
                    travelScale: (width / 900).clamp(.4, 1.0),
                  ),
                  const Positioned(right: -8, bottom: -6, child: TouchCue()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GardenBackground extends StatelessWidget {
  const _GardenBackground(this.spot);
  final String spot;
  @override
  Widget build(BuildContext context) => GameImage(
    asset: forceGardenAsset,
    builder: (context, image) =>
        CustomPaint(painter: _GardenPainter(image, spot)),
    placeholder: const ColoredBox(
      color: Color(0xFFE2EFE0),
      child: Center(child: CircularProgressIndicator()),
    ),
  );
}

class _GardenPainter extends CustomPainter {
  const _GardenPainter(this.image, this.spot);
  final ui.Image image;
  final String spot;
  @override
  void paint(Canvas canvas, Size size) {
    final index = const ['gate', 'lawn', 'pond'].indexOf(spot);
    final third = image.width / 3;
    // A narrow phone visits one habitat; wider screens show its surroundings.
    // Keep the original painting's proportions instead of stretching a square.
    final viewWidth = (image.height * size.aspectRatio).clamp(
      0.0,
      image.width.toDouble(),
    );
    final left = ((index + .5) * third - viewWidth / 2).clamp(
      0.0,
      image.width - viewWidth,
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(left, 0, viewWidth, image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(_GardenPainter old) =>
      old.image != image || old.spot != spot;
}

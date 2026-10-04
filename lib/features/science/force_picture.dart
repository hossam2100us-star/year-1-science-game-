import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'force_object.dart';
import 'science_picture.dart';
import '../../core/game_image.dart';

const forceArtAssets = [
  'forces-objects-v4.png',
  'forces-characters-v4.png',
  'forces-details-v4.png',
  'forces-garden-v6.png',
];

const _objects = {
  'trolley': 0,
  'ball': 1,
  'doorbell': 2,
  'drawer': 3,
  'swing': 4,
  'sailboat': 5,
  'cork': 6,
  'balloon': 7,
  'nail': 8,
  'plastic_pot': 9,
  'stone': 10,
  'glass_marble': 11,
  'orange': 12,
  'peeled_orange': 13,
  'fridge': 14,
  'door': 15,
};
const _characters = {
  'explorer': 0,
  'explorer_push': 1,
  'explorer_pull': 2,
  'fish': 3,
  'snake': 5,
  'bird': 7,
  'kangaroo': 9,
  'baby': 11,
};

// Pixel bounds measured from the original transparent assets. Paired poses use
// the same scale and floor, even when wings or legs change their outer bounds.
const _objectRects = [
  Rect.fromLTWH(28, 52, 306, 272),
  Rect.fromLTWH(369, 61, 253, 251),
  Rect.fromLTWH(714, 69, 159, 244),
  Rect.fromLTWH(955, 58, 264, 265),
  Rect.fromLTWH(40, 334, 279, 290),
  Rect.fromLTWH(364, 332, 277, 298),
  Rect.fromLTWH(690, 366, 212, 252),
  Rect.fromLTWH(1003, 335, 181, 307),
  Rect.fromLTWH(44, 654, 257, 241),
  Rect.fromLTWH(364, 654, 261, 241),
  Rect.fromLTWH(669, 677, 265, 211),
  Rect.fromLTWH(987, 665, 229, 224),
  Rect.fromLTWH(42, 922, 280, 269),
  Rect.fromLTWH(364, 938, 269, 247),
  Rect.fromLTWH(695, 914, 223, 291),
  Rect.fromLTWH(1012, 900, 195, 310),
];
const _characterRects = [
  Rect.fromLTWH(109, 23, 138, 335),
  Rect.fromLTWH(357, 34, 246, 320),
  Rect.fromLTWH(646, 32, 251, 321),
  Rect.fromLTWH(946, 95, 290, 192),
  Rect.fromLTWH(34, 406, 280, 210),
  Rect.fromLTWH(341, 448, 275, 152),
  Rect.fromLTWH(633, 435, 303, 169),
  Rect.fromLTWH(965, 414, 263, 200),
  Rect.fromLTWH(34, 648, 268, 260),
  Rect.fromLTWH(327, 632, 281, 303),
  Rect.fromLTWH(646, 646, 287, 277),
  Rect.fromLTWH(952, 704, 265, 219),
  Rect.fromLTWH(32, 982, 268, 229),
];

/// Painted cutouts with paired poses; scene travel is handled separately.
class ForcePicture extends StatelessWidget {
  const ForcePicture(this.art, {super.key, this.height = 115, this.phase = 0});
  final String art;
  final double height, phase;
  static const subjects = {
    'trolley',
    'ball',
    'fish',
    'snake',
    'bird',
    'kangaroo',
    'baby',
    'doorbell',
    'drawer',
    'swing',
    'sailboat',
    'cork',
    'balloon',
    'nail',
    'plastic_pot',
    'stone',
    'glass_marble',
    'orange',
    'peeled_orange',
    'fridge',
    'switch',
    'zip',
  };
  @override
  Widget build(BuildContext context) {
    if (art == 'switch' || art == 'zip') return ForceObject(art, size: height);
    final character = _characters.containsKey(art);
    if (!character && !_objects.containsKey(art)) {
      return SciencePicture(art, height: height);
    }
    final base = character ? _characters[art]! : _objects[art]!;
    final paired = const {
      'fish',
      'snake',
      'bird',
      'kangaroo',
      'baby',
    }.contains(art);
    final rects = character ? _characterRects : _objectRects;
    final cell = base + (paired && math.sin(phase) > .25 ? 1 : 0);
    final natural = character && base < 3
        ? const Size(251, 335)
        : paired
        ? Size(
            math.max(rects[base].width, rects[base + 1].width),
            math.max(rects[base].height, rects[base + 1].height),
          )
        : rects[base].size;
    final picture = GameImage(
      asset: forceArtAssets[character ? 1 : 0],
      builder: (context, image) =>
          CustomPaint(painter: _ForcePainter(image, rects[cell], natural)),
      placeholder: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
    return SizedBox(
      width: height * 1.25,
      height: height,
      child: Transform.rotate(
        angle: art == 'ball'
            ? phase
            : art == 'swing'
            ? math.sin(phase) * .12
            : 0,
        alignment: art == 'swing' ? Alignment.topCenter : Alignment.center,
        child: picture,
      ),
    );
  }
}

class _ForcePainter extends CustomPainter {
  const _ForcePainter(this.image, this.source, this.natural);
  final ui.Image image;
  final Rect source;
  final Size natural;
  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / natural.width,
      size.height / natural.height,
    );
    final destination = Rect.fromLTWH(
      (size.width - source.width * scale) / 2,
      size.height - source.height * scale,
      source.width * scale,
      source.height * scale,
    );
    canvas.drawImageRect(
      image,
      source,
      destination,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(_ForcePainter old) =>
      old.image != image || old.source != source || old.natural != natural;
}

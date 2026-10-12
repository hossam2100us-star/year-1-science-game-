import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/game_image.dart';
import '../biology/illustrated_art.dart';
import '../science/discovery_world.dart';

const mathsObjectAsset = 'maths-objects-v2.webp';
const mathsBackdropAsset = 'maths-backdrops-v2.webp';
const mathsIslandAsset = 'maths-islands-v2.webp';

/// Three birds in equal cells, so a chart can tell pigeons, sparrows and
/// crows apart without one looking bigger than another (teacher review 5).
const mathsBirdAsset = 'maths-birds-v1.webp';
const mathsBirdCells = <String, int>{'pigeon': 0, 'sparrow': 1, 'crow': 2};

/// One original transparent object per atlas cell. Counts, positions and all
/// mathematical markings belong to the lesson renderer, rather than the art.
const mathsObjectCells = <String, int>{
  'apple': 0,
  'star': 1,
  'sock': 2,
  'cube': 3,
  'block': 3,
  'bean': 4,
  'bird': 5,
  'counter': 6,
  'dot': 6,
  'basket': 7,
  'pencil': 8,
  'ball': 9,
  'car': 10,
  'doll': 11,
  'banana': 12,
  'orange': 13,
  'mango': 14,
  'clock': 15,
};

// Bounds measured from connected alpha components in the 1254px source.
// Three pixels of padding retain painted edges without including neighbours.
// In particular, the horizontal pencil crosses the nominal quarter-cell edge.
const _mathsObjectBounds = <Rect>[
  Rect.fromLTRB(45, 51, 304, 309),
  Rect.fromLTRB(358, 57, 610, 302),
  Rect.fromLTRB(656, 40, 897, 313),
  Rect.fromLTRB(986, 67, 1209, 301),
  Rect.fromLTRB(47, 400, 303, 585),
  Rect.fromLTRB(332, 359, 613, 609),
  Rect.fromLTRB(678, 370, 896, 590),
  Rect.fromLTRB(951, 331, 1232, 613),
  Rect.fromLTRB(21, 737, 357, 801),
  Rect.fromLTRB(382, 654, 609, 881),
  Rect.fromLTRB(634, 680, 951, 883),
  Rect.fromLTRB(963, 632, 1231, 910),
  Rect.fromLTRB(39, 922, 323, 1179),
  Rect.fromLTRB(359, 933, 616, 1182),
  Rect.fromLTRB(656, 922, 910, 1181),
  Rect.fromLTRB(970, 923, 1223, 1183),
];

Rect mathsObjectCrop(String item) {
  final cell = mathsObjectCells[item] ?? mathsObjectCells['counter']!;
  final bounds = _mathsObjectBounds[cell];
  return Rect.fromLTRB(
    bounds.left / 1254,
    bounds.top / 1254,
    bounds.right / 1254,
    bounds.bottom / 1254,
  );
}

void paintMathsObject(
  Canvas canvas,
  ui.Image image,
  String item,
  Rect destination,
) {
  final crop = mathsObjectCrop(item);
  final source = Rect.fromLTWH(
    crop.left * image.width,
    crop.top * image.height,
    crop.width * image.width,
    crop.height * image.height,
  );
  final fit = applyBoxFit(BoxFit.contain, source.size, destination.size);
  canvas.drawImageRect(
    image,
    source,
    Alignment.center.inscribe(fit.destination, destination),
    Paint()..filterQuality = FilterQuality.high,
  );
}

class MathsArt extends StatelessWidget {
  const MathsArt(this.item, {super.key, this.height = 64, this.width});
  final String item;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: height,
      width: width ?? height,
      child: switch (mathsBirdCells[item]) {
        final int cell => IllustratedArt(
          asset: mathsBirdAsset,
          crop: Rect.fromLTWH(cell / 3, 0, 1 / 3, 1),
        ),
        null => IllustratedArt(
          asset: mathsObjectAsset,
          crop: mathsObjectCrop(item),
        ),
      },
    ),
  );
}

String mathsSceneForTheme(String? theme) {
  final unit = int.tryParse(theme?.replaceFirst('math_unit_', '') ?? '');
  if (const {3, 7, 8, 12, 15, 17}.contains(unit)) return 'workshop';
  if (const {6, 10, 18}.contains(unit)) return 'village';
  if (const {4, 16}.contains(unit) || theme == 'math_charts') return 'harbour';
  if (theme == 'math_quiz_02') return 'workshop';
  if (theme == 'math_quiz_03') return 'harbour';
  return 'orchard';
}

/// Height of a setting's decorative strip [width] wide: its painted 3.4:1
/// shape when the screen is tall enough, otherwise about an eighth of the
/// height left between the system bars (on a 1280×800 tablet, 86 instead
/// of about 310), so the question's diagram and answers come first.
double mathsBannerHeight(BuildContext context, double width) => math.min(
  width / 3.4,
  math.max(72.0, DiscoveryWorld.usableHeight(context) * .12),
);

class MathsBackdrop extends StatelessWidget {
  const MathsBackdrop({
    super.key,
    required this.scene,
    this.fit = BoxFit.cover,
  });
  final String scene;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final index = switch (scene) {
      'workshop' => 1,
      'village' => 2,
      'harbour' => 3,
      _ => 0,
    };
    return _MathsPanel(
      asset: mathsBackdropAsset,
      crop: Rect.fromLTWH((index % 2) / 2, (index ~/ 2) / 2, .5, .5),
      fit: fit,
    );
  }
}

/// The subject card shows all four islands; map cards show one whole island.
class MathsIslandArt extends StatelessWidget {
  const MathsIslandArt({super.key, this.index});
  final int? index;

  @override
  Widget build(BuildContext context) => _MathsPanel(
    asset: mathsIslandAsset,
    crop: index == null
        ? const Rect.fromLTWH(0, 0, 1, 1)
        : Rect.fromLTWH((index! % 2) / 2, (index! ~/ 2) / 2, .5, .5),
    fit: BoxFit.contain,
  );
}

class _MathsPanel extends StatelessWidget {
  const _MathsPanel({
    required this.asset,
    required this.crop,
    required this.fit,
  });
  final String asset;
  final Rect crop;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: GameImage(
      asset: asset,
      builder: (context, image) => CustomPaint(
        painter: _MathsPanelPainter(image, crop, fit),
        size: Size.infinite,
      ),
      placeholder: const Center(
        child: SizedBox.square(
          dimension: 28,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    ),
  );
}

class _MathsPanelPainter extends CustomPainter {
  const _MathsPanelPainter(this.image, this.crop, this.fit);
  final ui.Image image;
  final Rect crop;
  final BoxFit fit;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final source = Rect.fromLTWH(
      crop.left * image.width,
      crop.top * image.height,
      crop.width * image.width,
      crop.height * image.height,
    );
    final fitted = applyBoxFit(fit, source.size, size);
    canvas.drawImageRect(
      image,
      Alignment.center.inscribe(fitted.source, source),
      Alignment.center.inscribe(fitted.destination, Offset.zero & size),
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(_MathsPanelPainter old) =>
      image != old.image || crop != old.crop || fit != old.fit;
}

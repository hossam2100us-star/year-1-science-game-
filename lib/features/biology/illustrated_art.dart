import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/game_image.dart';

class IllustratedArt extends StatelessWidget {
  const IllustratedArt({
    super.key,
    required this.asset,
    this.crop = const Rect.fromLTWH(0, 0, 1, 1),
  });
  final String asset;
  final Rect crop;
  @override
  Widget build(BuildContext context) => GameImage(
    asset: asset,
    builder: (context, image) =>
        CustomPaint(painter: IllustrationPainter(image, crop)),
    placeholder: const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}

class IllustrationPainter extends CustomPainter {
  const IllustrationPainter(this.image, this.crop);
  final ui.Image image;
  final Rect crop;
  @override
  void paint(Canvas canvas, Size size) {
    final source = Rect.fromLTWH(
      crop.left * image.width,
      crop.top * image.height,
      crop.width * image.width,
      crop.height * image.height,
    );
    final fit = applyBoxFit(BoxFit.contain, source.size, size);
    canvas.drawImageRect(
      image,
      source,
      Alignment.center.inscribe(fit.destination, Offset.zero & size),
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(IllustrationPainter old) =>
      old.image != image || old.crop != crop;
}

const illustratedBodyAnchors = <String, Offset>{
  'head': Offset(.50, .135),
  'chin': Offset(.50, .245),
  'neck': Offset(.50, .273),
  'shoulder': Offset(.365, .297),
  'arm': Offset(.321, .401),
  'elbow': Offset(.278, .448),
  'wrist': Offset(.244, .514),
  'hand': Offset(.230, .549),
  'fingers': Offset(.225, .585),
  'leg': Offset(.374, .76),
  'knee': Offset(.399, .687),
  'ankle': Offset(.365, .833),
  'foot': Offset(.338, .900),
  'eyes': Offset(.438, .175),
  'ears': Offset(.61, .184),
  'nose': Offset(.50, .194),
  'tongue': Offset(.50, .222),
  'skin': Offset(.278, .448),
};
const illustratedEyeAnchors = <String, Offset>{
  'eyebrow': Offset(.50, .22),
  'eyelash': Offset(.72, .45),
  'eyelid': Offset(.43, .35),
};

({String asset, Rect crop})? illustrationFor(String raw, {bool girl = false}) {
  final id = raw.toLowerCase().replaceAll(' ', '_');
  // Reuse only subjects that actually exist in the accepted painted assets.
  // Music is represented by a musical instrument, not an unrelated symbol.
  if (const ['music', 'hear_music', 'sound', 'loud'].contains(id)) {
    return (
      asset: 'sound-atlas-v2.png',
      crop: const Rect.fromLTWH(.25, 0, .25, .35),
    );
  }
  if (const ['flower', 'flowers', 'smell_flowers'].contains(id)) {
    return (
      asset: 'plant-lab-v1.webp',
      crop: const Rect.fromLTWH(.34, .005, .29, .37),
    );
  }
  if (id == 'car') {
    return (
      asset: 'garden-v2.webp',
      crop: const Rect.fromLTWH(.609, .355, .24, .274),
    );
  }
  if (id == 'paper') {
    return (
      asset: 'science-details-v2.png',
      crop: const Rect.fromLTWH(643 / 1269, 366 / 1240, 307 / 1269, 264 / 1240),
    );
  }
  const senses = {
    'sight': 0,
    'eyes': 0,
    'hearing': 1,
    'ears': 1,
    'ear': 1,
    'smell': 2,
    'nose': 2,
    'taste': 3,
    'tongue': 3,
    'touch': 4,
    'skin': 4,
    'hand': 4,
    'big_hand': 4,
    'small_hand': 4,
  };
  if (senses.containsKey(id)) {
    return (
      asset: 'five-senses-v2.webp',
      crop: Rect.fromLTWH(senses[id]! * .2 + .006, .04, .188, .91),
    );
  }
  const objects = {
    'apple': 0,
    'lemon': 1,
    'bread': 2,
    'mug': 3,
    'traffic': 4,
    'traffic_light': 4,
    'watermelon': 5,
    'cat': 6,
    'soft_cat': 6,
    'bird': 7,
    'see_birds': 7,
    'honey': 8,
    'sweet': 8,
    'sweet_honey': 8,
  };
  if (objects.containsKey(id)) {
    final i = objects[id]!;
    const rowEdges = [0.0, .325, .636, 1.0];
    final row = i ~/ 3;
    final top = i == 7 ? .66 : rowEdges[row];
    return (
      asset: 'sense-objects-v2.webp',
      crop: Rect.fromLTWH((i % 3) / 3, top, 1 / 3, rowEdges[row + 1] - top),
    );
  }
  if (illustratedEyeAnchors.containsKey(id) || id == 'eyelashes') {
    final a = illustratedEyeAnchors[id == 'eyelashes' ? 'eyelash' : id]!;
    return (
      asset: 'five-senses-v2.webp',
      crop: Rect.fromCenter(
        center: Offset(a.dx * .2, a.dy),
        width: .13,
        height: .20,
      ),
    );
  }
  final point = illustratedBodyAnchors[id];
  if (point != null) {
    return (
      asset: girl ? 'explorer-girl-v2.webp' : 'explorer-boy-v2.webp',
      crop: Rect.fromCenter(center: point, width: .20, height: .14),
    );
  }
  return null;
}

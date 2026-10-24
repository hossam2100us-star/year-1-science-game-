import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/game_image.dart';
import '../biology/illustrated_art.dart';
import '../maths/maths_art.dart';

/// Painted English art (docs/ENGLISH_INTEGRATION.md): four islands and four
/// settings in 2 × 2 atlases, and one small picture for each word a
/// question shows, so a child who cannot read the word yet still knows it.
const englishIslandAsset = 'english-islands-v1.webp';
const englishBackdropAsset = 'english-backdrops-v1.webp';
const englishWordAsset = 'english-words-v1.webp';

/// The word pictures, eight to a row in equal cells, in this order.
const englishWords = [
  'alligator', 'bag', 'bee', 'boat', 'bottle', 'box', 'bus', 'bush', //
  'cake', 'can', 'cat', 'coat', 'crocodile', 'cup', 'dish', 'dog', //
  'egg', 'elephant', 'fox', 'frog', 'gate', 'goat', 'grass', 'hat', //
  'hen', 'hippo', 'juice', 'kangaroo', 'kite', 'kookaburra', 'lion', 'loaf', //
  'monkey', 'monster', 'moose', 'mouse', 'park', 'pencil pot', 'platypus',
  'postcard', //
  'present', 'puddle', 'rabbit', 'rain', 'recycling bin', 'road', 'school',
  'sea', //
  'seal', 'ship', 'snake', 'spider', 'straw', 'sun', 'sweet', 'teddy', //
  'telescope', 'tiger', 'tree', 'turtle', 'washing machine', 'zebra',
];
const _wordColumns = 8;
const _wordRows = 8;

/// Story scenes (teacher review 8): one picture per part of each story and
/// for the sentence cards, four to a row in equal 16:9 cells, in this
/// order.
const englishSceneAsset = 'english-scenes-v1.webp';
const englishScenes = [
  'aqsa-monster', 'aqsa-falls', 'aqsa-cloud', 'mum-washing', //
  'school-arrive', 'football', 'family-dinner', 'classroom', //
  'tiddalik-drinks', 'tiddalik-jokes', 'tiddalik-laughs', 'wombat', //
  'lion-mouse', 'tiger-trap', 'two-kings', 'swings', //
  'gogo-walk', 'red-tackies-window', 'red-tackies-proud', 'market', //
  'shark-park', 'mr-gumpy', 'rubys-worry', 'katie-morag', //
];
const _sceneColumns = 4;
const _sceneRows = 6;

/// Scenes are wider than they are tall.
const englishSceneAspect = 16 / 9;

/// Words the Maths pictures already show (a sock, a book, a school bag).
bool _inMathsArt(String word) =>
    mathsThings.contains(word) || mathsObjectCells.containsKey(word);

/// Whether [word] has a picture.
bool hasEnglishPicture(String word) =>
    englishWords.contains(word) ||
    englishScenes.contains(word) ||
    _inMathsArt(word);

/// The picture of one word; nothing for a word without one.
class EnglishPicture extends StatelessWidget {
  const EnglishPicture(this.word, {super.key, this.height = 96, this.width});
  final String word;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final scene = englishScenes.indexOf(word);
    if (scene >= 0) {
      return ExcludeSemantics(
        child: SizedBox(
          height: height,
          width: width ?? height * englishSceneAspect,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: IllustratedArt(
              asset: englishSceneAsset,
              crop: Rect.fromLTWH(
                (scene % _sceneColumns) / _sceneColumns,
                (scene ~/ _sceneColumns) / _sceneRows,
                1 / _sceneColumns,
                1 / _sceneRows,
              ),
            ),
          ),
        ),
      );
    }
    final cell = englishWords.indexOf(word);
    if (cell < 0) {
      return _inMathsArt(word)
          ? MathsArt(word, height: height, width: width)
          : const SizedBox.shrink();
    }
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: width ?? height,
        child: IllustratedArt(
          asset: englishWordAsset,
          crop: Rect.fromLTWH(
            (cell % _wordColumns) / _wordColumns,
            (cell ~/ _wordColumns) / _wordRows,
            1 / _wordColumns,
            1 / _wordRows,
          ),
        ),
      ),
    );
  }
}

/// The subject card shows all four islands; map cards show one island.
/// The painting is 16:9 and the subject card 2:1, so the card fills its
/// frame and loses a little sea at the top and bottom.
class EnglishIslandArt extends StatelessWidget {
  const EnglishIslandArt({super.key, this.index});
  final int? index;

  @override
  Widget build(BuildContext context) => _EnglishPanel(
    asset: englishIslandAsset,
    crop: index == null
        ? const Rect.fromLTWH(0, 0, 1, 1)
        : Rect.fromLTWH((index! % 2) / 2, (index! ~/ 2) / 2, .5, .5),
    fit: index == null ? BoxFit.cover : BoxFit.contain,
  );
}

/// The painted setting above a question: a story corner, a kitchen, a rainy
/// garden or a jungle.
class EnglishBackdrop extends StatelessWidget {
  const EnglishBackdrop({super.key, required this.scene});
  final String scene;

  @override
  Widget build(BuildContext context) {
    final index = switch (scene) {
      'kitchen' => 1,
      'garden' => 2,
      'jungle' => 3,
      _ => 0,
    };
    return _EnglishPanel(
      asset: englishBackdropAsset,
      crop: Rect.fromLTWH((index % 2) / 2, (index ~/ 2) / 2, .5, .5),
      fit: BoxFit.cover,
    );
  }
}

class _EnglishPanel extends StatelessWidget {
  const _EnglishPanel({
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
        painter: _PanelPainter(image, crop, fit),
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

class _PanelPainter extends CustomPainter {
  const _PanelPainter(this.image, this.crop, this.fit);
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
  bool shouldRepaint(_PanelPainter old) =>
      image != old.image || crop != old.crop || fit != old.fit;
}

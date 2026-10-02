import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../biology/illustrated_art.dart';

/// Transparent scene objects. Playing poses are used only during exploration.
class SoundPicture extends StatelessWidget {
  const SoundPicture(
    this.art, {
    super.key,
    this.height = 130,
    this.phase = 0,
    this.revealed = false,
    this.strength = 1,
  });
  final String art;
  final double height, phase;
  final bool revealed;
  final double strength;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: height * 1.25,
    height: height,
    child: soundSpriteCells.containsKey(art)
        ? Transform.translate(
            offset: Offset(
              ['maracas', 'stone_box', 'feather_box'].contains(art)
                  ? math.sin(phase) * 4
                  : 0,
              art == 'sticks' ? math.sin(phase) * 8 * strength : 0,
            ),
            child: Transform.rotate(
              angle: ['triangle', 'maracas', 'sitar'].contains(art)
                  ? math.sin(phase) * .045
                  : 0,
              child: IllustratedArt(
                asset: 'sound-atlas-v2.png',
                crop: Rect.fromLTWH(
                  (soundSpriteCells[art]! % 4) / 4,
                  const [0.0, .35, .635][soundSpriteCells[art]! ~/ 4],
                  .25,
                  const [.35, .285, .365][soundSpriteCells[art]! ~/ 4],
                ),
              ),
            ),
          )
        : soundDetailCells.containsKey(art)
        ? IllustratedArt(
            asset: 'sound-details-v2.png',
            crop: Rect.fromLTWH(
              (soundDetailCells[art]! % 3) / 3,
              (soundDetailCells[art]! ~/ 3) / 2,
              1 / 3,
              .5,
            ),
          )
        : const Icon(
            Icons.music_note_rounded,
            color: Color(0xFF648B9F),
            size: 60,
          ),
  );
}

const soundSpriteCells = {
  'triangle': 0,
  'trumpet': 1,
  'maracas': 2,
  'sitar': 3,
  'drum': 4,
  'sticks': 5,
  'stone_box': 6,
  'feather_box': 7,
  'listener': 8,
  'hearing': 9,
  'hum': 10,
  'cat': 11,
};

const soundDetailCells = {
  'sound_box': 0,
  'door': 1,
  'thunder': 2,
  'whisper': 3,
  'stone': 4,
  'feather': 5,
};

class SoundDemonstration extends StatelessWidget {
  const SoundDemonstration(
    this.art, {
    super.key,
    this.height = 130,
    this.play = false,
    this.revealed = false,
    this.strength = 1,
  });
  final String art;
  final double height;
  final bool play, revealed;
  final double strength;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: play ? 1 : 0),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 1100),
    builder: (context, value, _) => SoundPicture(
      art,
      height: height,
      phase: MediaQuery.disableAnimationsOf(context) ? 0 : value * math.pi * 8,
      revealed: revealed,
      strength: strength,
    ),
  );
}

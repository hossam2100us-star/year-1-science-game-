import 'package:flutter/material.dart';

import '../biology/illustrated_art.dart';
import '../biology/biology_art.dart';
import 'sound_picture.dart';
import 'science_atlas_crops.dart';
import 'magnet_picture.dart';

const scienceAtlases = <String, List<String>>{
  'science-details-v2.webp': [
    'plastic_pot',
    'glass_marble',
    'paper_straw',
    'wooden_block',
    'fabric',
    'glass',
    'paper_sheet',
    'metal',
    'wood',
    'plastic',
    'clay',
    'graphite',
    'visor',
    'oxygen',
    'gloves',
    'boots',
  ],
  'materials-atlas-v2.webp': [
    'spoon',
    'chair',
    'window',
    'shirt',
    'paper',
    'bottle',
    'foil',
    'sponge',
    'stone',
    'rubber_band',
    'pot',
    'pencil',
    'tissue',
    'umbrella',
    'brick',
    'dough',
  ],
  'physics-atlas-v1.webp': [
    'doorbell',
    'drawer',
    'swing',
    'trolley',
    'sailboat',
    'cork',
    'balloon',
    'nail',
    'triangle',
    'maracas',
    'trumpet',
    'sitar',
    'drum',
    'feather',
    'magnet',
    'key',
  ],
  'earth-atlas-v2.webp': [
    'pond',
    'stream',
    'river',
    'lake',
    'ocean',
    'whale',
    'crocodile',
    'frog',
    'soil',
    'worm',
    'coal',
    'diamond',
    'earth',
    'sun',
    'moon',
    'astronaut',
  ],
  'electric-atlas-v2.webp': [
    'tv',
    'vacuum',
    'lantern',
    'lamp',
    'dishwasher',
    'broom',
    'battery',
    'torch',
    'fridge',
    'clock',
    'bicycle',
    'aircon',
    'button',
    'ring',
    'hanger',
    'sock',
  ],
  'science-extras-v1.webp': [
    'snake',
    'fish',
    'kangaroo',
    'baby',
    'orange',
    'peeled_orange',
    'door',
    'ball',
    'sand',
    'dead_leaf',
    'insect',
    'bag',
    'pan',
    'box',
    'plate',
    'thunder',
  ],
};
const scienceSymbols = <String, IconData>{
  'push': Icons.arrow_forward_rounded,
  'pull': Icons.arrow_back_rounded,
  'both': Icons.swap_horiz_rounded,
  'float': Icons.waves_rounded,
  'sink': Icons.south_rounded,
  'hit': Icons.touch_app_rounded,
  'shake': Icons.vibration_rounded,
  'blow': Icons.air_rounded,
  'pluck': Icons.pan_tool_alt_rounded,
  'beat': Icons.touch_app_rounded,
  'safe': Icons.health_and_safety_rounded,
  'adult': Icons.family_restroom_rounded,
  'dry_hands': Icons.back_hand_rounded,
  'switch': Icons.toggle_on_rounded,
  'zip': Icons.unfold_more_rounded,
  'cupboard': Icons.door_sliding_rounded,
  'sticks': Icons.music_note_rounded,
  'hum': Icons.graphic_eq_rounded,
  'whisper': Icons.record_voice_over_rounded,
  'music': Icons.music_note_rounded,
  'star': Icons.star_rounded,
  'oxygen': Icons.air_rounded,
  'visor': Icons.visibility_rounded,
  'gloves': Icons.back_hand_rounded,
  'boots': Icons.hiking_rounded,
  'heat': Icons.thermostat_rounded,
  'light': Icons.light_mode_rounded,
  'air': Icons.air_rounded,
  'sound': Icons.volume_up_rounded,
  'water': Icons.water_drop_rounded,
  'coin': Icons.paid_rounded,
};

class SciencePicture extends StatelessWidget {
  const SciencePicture(this.art, {super.key, this.height = 115});
  final String art;
  final double height;
  static bool has(String id) =>
      id == 'book' ||
      _forceCutouts.containsKey(id) ||
      soundSpriteCells.containsKey(id) ||
      soundDetailCells.containsKey(id) ||
      scienceAtlases.values.any((a) => a.contains(id)) ||
      scienceSymbols.containsKey(id) ||
      illustrationFor(id) != null ||
      ['leaf', 'bird', 'cat'].contains(id);
  @override
  Widget build(BuildContext context) {
    if (art == 'book') {
      return SizedBox(
        height: height,
        width: height * 1.25,
        child: const IllustratedArt(asset: 'book-v1.webp'),
      );
    }
    if (art == 'magnet') return MagnetPicture(height: height);
    // Reuse the accepted transparent illustrations across subjects. Static
    // assessed scenes use the resting pose and never play an outcome animation.
    if (soundSpriteCells.containsKey(art) ||
        soundDetailCells.containsKey(art)) {
      return SoundPicture(art, height: height);
    }
    final cutout = _forceCutouts[art];
    if (cutout != null) {
      final rect = cutout.$2;
      return SizedBox(
        height: height,
        width: height * 1.25,
        child: IllustratedArt(
          asset: cutout.$1,
          crop: Rect.fromLTWH(
            rect.left / 1254,
            rect.top / 1254,
            rect.width / 1254,
            rect.height / 1254,
          ),
        ),
      );
    }
    for (final a in scienceAtlases.entries) {
      final i = a.value.indexOf(art);
      if (i >= 0) {
        return SizedBox(
          height: height,
          width: height * 1.25,
          child: IllustratedArt(asset: a.key, crop: scienceAtlasCrop(a.key, i)),
        );
      }
    }
    if (scienceSymbols.containsKey(art)) {
      return SizedBox(
        height: height,
        width: height,
        child: Icon(
          scienceSymbols[art],
          size: height * .68,
          color: const Color(0xFF437A95),
        ),
      );
    }
    if (illustrationFor(art) != null || ['leaf', 'bird', 'cat'].contains(art)) {
      return SizedBox(
        width: height * 1.25,
        child: BiologyPicture(art: art, height: height),
      );
    }
    return const SizedBox.shrink();
  }
}

const _forceCutouts = <String, (String, Rect)>{
  'trolley': ('forces-objects-v4.webp', Rect.fromLTWH(28, 52, 306, 272)),
  'ball': ('forces-objects-v4.webp', Rect.fromLTWH(369, 61, 253, 251)),
  'doorbell': ('forces-objects-v4.webp', Rect.fromLTWH(714, 69, 159, 244)),
  'drawer': ('forces-objects-v4.webp', Rect.fromLTWH(955, 58, 264, 265)),
  'swing': ('forces-objects-v4.webp', Rect.fromLTWH(40, 334, 279, 290)),
  'sailboat': ('forces-objects-v4.webp', Rect.fromLTWH(364, 332, 277, 298)),
  'cork': ('forces-objects-v4.webp', Rect.fromLTWH(690, 366, 212, 252)),
  'balloon': ('forces-objects-v4.webp', Rect.fromLTWH(1003, 335, 181, 307)),
  'nail': ('forces-objects-v4.webp', Rect.fromLTWH(44, 654, 257, 241)),
  'orange': ('forces-objects-v4.webp', Rect.fromLTWH(42, 922, 280, 269)),
  'peeled_orange': (
    'forces-objects-v4.webp',
    Rect.fromLTWH(364, 938, 269, 247),
  ),
  'door': ('forces-objects-v4.webp', Rect.fromLTWH(1012, 900, 195, 310)),
  'fish': ('forces-characters-v4.webp', Rect.fromLTWH(946, 95, 290, 192)),
  'snake': ('forces-characters-v4.webp', Rect.fromLTWH(341, 448, 275, 152)),
  'bird': ('forces-characters-v4.webp', Rect.fromLTWH(965, 414, 263, 200)),
  'kangaroo': ('forces-characters-v4.webp', Rect.fromLTWH(327, 632, 281, 303)),
  'baby': ('forces-characters-v4.webp', Rect.fromLTWH(952, 704, 265, 219)),
};

import 'package:flutter/material.dart';

import '../biology/illustrated_art.dart';
import '../biology/biology_art.dart';

const scienceAtlases = <String, List<String>>{
  'science-details-v1.webp': [
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
  'materials-atlas-v1.webp': [
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
  'earth-atlas-v1.webp': [
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
  'electric-atlas-v1.webp': [
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
      scienceAtlases.values.any((a) => a.contains(id)) ||
      scienceSymbols.containsKey(id) ||
      illustrationFor(id) != null ||
      ['leaf', 'bird', 'cat'].contains(id);
  @override
  Widget build(BuildContext context) {
    for (final a in scienceAtlases.entries) {
      final i = a.value.indexOf(art);
      if (i >= 0)
        return SizedBox(
          height: height,
          width: height * 1.25,
          child: IllustratedArt(
            asset: a.key,
            crop: Rect.fromLTWH(
              (i % 4) / 4 + (a.key == 'science-details-v1.webp' ? 0.018 : 0.006),
              (i ~/ 4) / 4 +
                  (a.key == 'science-details-v1.webp' ? 0.018 : 0.006),
              a.key == 'science-details-v1.webp' ? 0.214 : 0.238,
              a.key == 'science-details-v1.webp' ? 0.214 : 0.238,
            ),
          ),
        );
    }
    if (scienceSymbols.containsKey(art))
      return SizedBox(
        height: height,
        width: height,
        child: Icon(
          scienceSymbols[art],
          size: height * .68,
          color: const Color(0xFF437A95),
        ),
      );
    if (illustrationFor(art) != null || ['leaf', 'bird', 'cat'].contains(art))
      return SizedBox(
        width: height * 1.25,
        child: BiologyPicture(art: art, height: height),
      );
    return const SizedBox.shrink();
  }
}

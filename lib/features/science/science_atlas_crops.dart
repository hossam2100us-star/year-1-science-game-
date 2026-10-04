import 'dart:ui';

// Measured from generated alpha silhouettes, with five pixels of edge padding.
// Source images are unchanged. Whole cells would include neighbouring subjects.
const scienceAtlasSizes = <String, Size>{
  'materials-atlas-v2.png': Size(1254, 1254),
  'electric-atlas-v2.png': Size(1254, 1254),
  'earth-atlas-v2.png': Size(1254, 1254),
  'science-details-v2.png': Size(1269, 1240),
};

const scienceAtlasBounds = <String, List<Rect>>{
  'materials-atlas-v2.png': [
    Rect.fromLTWH(22, 48, 296, 258),
    Rect.fromLTWH(369, 8, 220, 321),
    Rect.fromLTWH(653, 34, 259, 278),
    Rect.fromLTWH(949, 41, 282, 268),
    Rect.fromLTWH(25, 352, 313, 268),
    Rect.fromLTWH(421, 331, 125, 318),
    Rect.fromLTWH(635, 373, 303, 264),
    Rect.fromLTWH(960, 375, 279, 241),
    Rect.fromLTWH(28, 689, 268, 206),
    Rect.fromLTWH(344, 714, 270, 167),
    Rect.fromLTWH(661, 655, 244, 253),
    Rect.fromLTWH(962, 648, 257, 270),
    Rect.fromLTWH(18, 932, 293, 286),
    Rect.fromLTWH(321, 926, 309, 294),
    Rect.fromLTWH(641, 970, 283, 219),
    Rect.fromLTWH(956, 958, 272, 235),
  ],
  'electric-atlas-v2.png': [
    Rect.fromLTWH(22, 73, 294, 234),
    Rect.fromLTWH(333, 9, 276, 324),
    Rect.fromLTWH(695, 7, 176, 321),
    Rect.fromLTWH(990, 23, 218, 310),
    Rect.fromLTWH(34, 338, 282, 294),
    Rect.fromLTWH(361, 335, 224, 319),
    Rect.fromLTWH(737, 355, 92, 277),
    Rect.fromLTWH(950, 415, 291, 198),
    Rect.fromLTWH(60, 650, 188, 302),
    Rect.fromLTWH(335, 659, 273, 278),
    Rect.fromLTWH(618, 687, 330, 249),
    Rect.fromLTWH(950, 717, 295, 170),
    Rect.fromLTWH(37, 973, 241, 246),
    Rect.fromLTWH(334, 994, 270, 198),
    Rect.fromLTWH(628, 962, 318, 224),
    Rect.fromLTWH(964, 945, 265, 298),
  ],
  'earth-atlas-v2.png': [
    Rect.fromLTWH(17, 53, 292, 296),
    Rect.fromLTWH(327, 27, 293, 321),
    Rect.fromLTWH(634, 78, 294, 274),
    Rect.fromLTWH(948, 63, 296, 282),
    Rect.fromLTWH(9, 404, 301, 253),
    Rect.fromLTWH(327, 374, 298, 274),
    Rect.fromLTWH(634, 400, 325, 234),
    Rect.fromLTWH(959, 420, 287, 239),
    Rect.fromLTWH(8, 663, 301, 258),
    Rect.fromLTWH(322, 675, 299, 246),
    Rect.fromLTWH(631, 668, 306, 254),
    Rect.fromLTWH(967, 700, 266, 198),
    Rect.fromLTWH(21, 936, 279, 279),
    Rect.fromLTWH(329, 938, 287, 283),
    Rect.fromLTWH(654, 943, 270, 270),
    Rect.fromLTWH(1007, 920, 174, 308),
  ],
  'science-details-v2.png': [
    Rect.fromLTWH(56, 72, 234, 235),
    Rect.fromLTWH(400, 105, 186, 187),
    Rect.fromLTWH(656, 50, 264, 268),
    Rect.fromLTWH(997, 72, 233, 237),
    Rect.fromLTWH(16, 378, 316, 233),
    Rect.fromLTWH(341, 420, 289, 165),
    Rect.fromLTWH(643, 366, 307, 264),
    Rect.fromLTWH(997, 377, 238, 239),
    Rect.fromLTWH(27, 671, 290, 231),
    Rect.fromLTWH(344, 684, 268, 208),
    Rect.fromLTWH(657, 680, 259, 211),
    Rect.fromLTWH(986, 664, 258, 227),
    Rect.fromLTWH(36, 927, 271, 276),
    Rect.fromLTWH(356, 926, 241, 282),
    Rect.fromLTWH(649, 930, 287, 267),
    Rect.fromLTWH(963, 930, 275, 278),
  ],
};

Rect scienceAtlasCrop(String asset, int index) {
  final size = scienceAtlasSizes[asset];
  if (size == null)
    return Rect.fromLTWH(
      (index % 4) / 4 + .006,
      (index ~/ 4) / 4 + .006,
      .238,
      .238,
    );
  final rect = scienceAtlasBounds[asset]![index];
  return Rect.fromLTWH(
    rect.left / size.width,
    rect.top / size.height,
    rect.width / size.width,
    rect.height / size.height,
  );
}

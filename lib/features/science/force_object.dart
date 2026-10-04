import 'package:flutter/material.dart';

import '../biology/illustrated_art.dart';

/// Storybook close-ups keep the switch rocker and zipper tab easy to recognize.
class ForceObject extends StatelessWidget {
  const ForceObject(this.art, {super.key, required this.size});
  final String art;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: IllustratedArt(
      asset: 'forces-details-v4.webp',
      crop: Rect.fromLTWH(art == 'switch' ? 0 : .5, 0, .5, 1),
    ),
  );
}

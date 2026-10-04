import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../biology/illustrated_art.dart';

/// Keep the original painted magnet, without its opaque atlas cell.
/// This is a display clip; the source illustration is not modified.
class MagnetPicture extends StatelessWidget {
  const MagnetPicture({super.key, this.height = 115});
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: height * 1.25,
    child: const Listener(
      // Keep the whole touch area usable even through the open U-shaped gap.
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AspectRatio(
          aspectRatio: 190 / 223,
          child: ClipPath(
            clipper: _MagnetOutline(),
            child: IllustratedArt(
              asset: 'physics-atlas-v1.webp',
              crop: Rect.fromLTWH(
                696 / 1254,
                965 / 1254,
                190 / 1254,
                223 / 1254,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _MagnetOutline extends CustomClipper<Path> {
  const _MagnetOutline();

  @override
  Path getClip(Size size) {
    // Coordinates follow the painted silhouette, including the open U. A
    // rectangular crop alone would retain paper around and inside the magnet.
    final path = Path()
      ..moveTo(93, 8)
      ..cubicTo(64, 0, 30, 16, 15, 42)
      ..cubicTo(-2, 66, 7, 114, 14, 166)
      ..lineTo(18, 205)
      ..quadraticBezierTo(21, 214, 46, 216)
      ..lineTo(64, 208)
      ..lineTo(48, 87)
      ..cubicTo(46, 66, 57, 57, 78, 55)
      ..cubicTo(98, 52, 110, 66, 116, 87)
      ..lineTo(122, 153)
      ..lineTo(127, 198)
      ..quadraticBezierTo(148, 205, 178, 198)
      ..lineTo(182, 195)
      ..lineTo(177, 151)
      ..lineTo(170, 75)
      ..cubicTo(167, 36, 148, 12, 117, 8)
      ..quadraticBezierTo(104, 5, 93, 8)
      ..close();
    return path.transform(
      Float64List.fromList([
        size.width / 190,
        0,
        0,
        0,
        0,
        size.height / 223,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        1,
      ]),
    );
  }

  @override
  bool shouldReclip(_MagnetOutline oldClipper) => false;
}

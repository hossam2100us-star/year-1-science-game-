import 'dart:math' as math;

import 'package:flutter/material.dart';

const worldArtAsset = 'assets/images/islands-v2.webp';
const islandRegions = [
  Rect.fromLTWH(0, 0, .5, .425),
  Rect.fromLTWH(.5, 0, .5, .425),
  Rect.fromLTWH(0, .43, .5, .57),
  Rect.fromLTWH(.5, .43, .5, .57),
];

/// Render a region from the same source painting, without creating duplicate assets.
class IslandIllustration extends StatelessWidget {
  const IslandIllustration({super.key, required this.index});
  final int index;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final r = islandRegions[index],
          width = math.max(
            box.maxWidth / r.width,
            box.maxHeight * 2 / r.height,
          ),
          height = width / 2;
      return ClipRect(
        child: Stack(
          children: [
            Positioned(
              left: box.maxWidth / 2 - r.center.dx * width,
              top: box.maxHeight / 2 - r.center.dy * height,
              width: width,
              height: height,
              child: Image.asset(
                worldArtAsset,
                fit: BoxFit.fill,
                excludeFromSemantics: true,
              ),
            ),
          ],
        ),
      );
    },
  );
}

class SeaRoutePainter extends CustomPainter {
  const SeaRoutePainter();
  @override
  void paint(Canvas c, Size s) {
    final points = [
      Offset(s.width * .485, s.height * .23),
      Offset(s.width * .51, s.height * .235),
      Offset(s.width * .51, s.height * .38),
      Offset(s.width * .48, s.height * .46),
      Offset(s.width * .49, s.height * .58),
      Offset(s.width * .52, s.height * .72),
    ];
    final p = Paint()
      ..color = const Color(0xFFFFE7AC)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    for (var j = 0; j < points.length - 1; j++) {
      final a = points[j], b = points[j + 1], length = (b - a).distance;
      for (double d = 0; d < length; d += 13) {
        c.drawLine(
          Offset.lerp(a, b, d / length)!,
          Offset.lerp(a, b, ((d + 5) / length).clamp(0, 1))!,
          p,
        );
      }
    }
  }

  @override
  bool shouldRepaint(SeaRoutePainter old) => false;
}

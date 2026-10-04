import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'force_picture.dart';

class MovementSprite extends StatelessWidget {
  const MovementSprite({
    super.key,
    required this.art,
    required this.motion,
    required this.active,
    required this.size,
    this.travelScale = 1,
  });
  final String art;
  final String? motion;
  final bool active;
  final double size, travelScale;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: active ? 1 : 0),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 2400),
    builder: (context, value, _) {
      // Reduced motion shows the neutral pose; animation never hints an answer.
      final t = active && !MediaQuery.disableAnimationsOf(context)
          ? value
          : 0.0;
      final travel = Curves.easeInOutSine.transform(t);
      final phase = t * math.pi * 6;
      final hop = math.sin(t * math.pi * 3).abs();
      final offset = switch (motion) {
        'push' => Offset(36 * travel, 0),
        'pull' => Offset(-36 * travel, 0),
        'hop' => Offset(30 * travel, -27 * hop),
        'fly' => Offset(34 * travel, -12 * math.sin(t * math.pi)),
        'swim' => Offset(30 * travel, 3 * math.sin(phase)),
        'crawl' || 'slither' || 'roll' => Offset(30 * travel, 0),
        _ => Offset.zero,
      };
      return Transform.translate(
        offset: offset * travelScale,
        child: ForcePicture(art, height: size, phase: phase),
      );
    },
  );
}

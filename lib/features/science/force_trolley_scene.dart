import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'force_picture.dart';

/// Push: the child's hands stay on the trolley while pushing, then the
/// child lets go and the trolley rolls on alone, so the gap grows ("a push
/// sends an object away from you"; teacher review 4). Pull keeps a visible
/// rope connection. Assessment scenes retain their neutral resting poses.
class ForceTrolleyScene extends StatelessWidget {
  const ForceTrolleyScene({
    super.key,
    required this.motion,
    required this.active,
    required this.you,
    this.showAction = true,
    this.showGround = true,
  });
  final String motion, you;
  final bool active;
  final bool showAction;
  final bool showGround;

  /// Share of the animation spent pushing, and of the travel done by then.
  static const release = .3;
  static const _pushedShare = .25;

  /// Where the trolley is (0-1 of the travel) at time [t] of a push.
  static double pushed(double t) => t <= release
      ? _pushedShare * Curves.easeIn.transform(t / release)
      : _pushedShare +
            (1 - _pushedShare) *
                Curves.easeOutCubic.transform((t - release) / (1 - release));

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final sceneWidth = math.max(500.0, box.maxWidth);
      final travel = math.max(50.0, sceneWidth - 285);
      final reduced = MediaQuery.disableAnimationsOf(context);
      final animation = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: active ? 1 : 0),
        duration: reduced ? Duration.zero : const Duration(milliseconds: 2200),
        curve: motion == 'push' ? Curves.linear : Curves.easeInOutSine,
        builder: (context, t, _) {
          // Reduced motion keeps the neutral pose, never reveals a direction.
          final playing = active && !reduced;
          final pushing = playing && motion == 'push';
          final letGo = pushing && t > release;
          final distance = !playing
              ? .35
              : motion == 'pull'
              ? 1 - t
              : pushed(t);
          final cartLeft = 130 + travel * distance;
          // After letting go the child stays where the push ended.
          final childLeft = pushing && showAction
              ? 130 + travel * pushed(math.min(t, release)) - 144
              : 0.0;
          return SizedBox(
            height: 225,
            child: Stack(
              children: [
                if (showGround)
                  Positioned(
                    left: 15,
                    right: 15,
                    bottom: 43,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFA9C8AA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                if (playing && showAction && motion == 'pull')
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PullRope(
                        const Offset(144, 81),
                        Offset(cartLeft + 24, 112),
                      ),
                    ),
                  ),
                Positioned(
                  key: const ValueKey('trolley-child'),
                  left: childLeft,
                  bottom: 45,
                  child: ForcePicture(
                    playing && showAction && !letGo
                        ? 'explorer_$motion'
                        : 'explorer',
                    height: 180,
                  ),
                ),
                Positioned(
                  key: const ValueKey('trolley-cart'),
                  left: cartLeft,
                  bottom: 45,
                  child: const ForcePicture('trolley', height: 112),
                ),
                Positioned(
                  left: childLeft,
                  bottom: 0,
                  width: 225,
                  child: Text(
                    you,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
      return SizedBox(
        width: box.maxWidth,
        height: 225 * box.maxWidth / sceneWidth,
        child: FittedBox(
          child: SizedBox(width: sceneWidth, height: 225, child: animation),
        ),
      );
    },
  );
}

class _PullRope extends CustomPainter {
  const _PullRope(this.hand, this.handle);
  final Offset hand, handle;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawLine(
    hand,
    handle,
    Paint()
      ..color = const Color(0xFF936C42)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round,
  );
  @override
  bool shouldRepaint(_PullRope old) => old.hand != hand || old.handle != handle;
}

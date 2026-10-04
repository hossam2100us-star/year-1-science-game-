import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'force_picture.dart';

/// Push maintains hand contact; pull maintains a visible rope connection.
/// Assessment scenes retain their neutral reference and resting poses.
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
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final sceneWidth = math.max(500.0, box.maxWidth);
      final travel = math.max(50.0, sceneWidth - 285);
      final reduced = MediaQuery.disableAnimationsOf(context);
      final animation = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: active ? 1 : 0),
        duration: reduced ? Duration.zero : const Duration(milliseconds: 2200),
        curve: Curves.easeInOutSine,
        builder: (context, t, _) {
          // Reduced motion keeps the neutral pose, never reveals a direction.
          final playing = active && !reduced;
          final distance = playing ? (motion == 'pull' ? 1 - t : t) : .35;
          final cartLeft = 130 + travel * distance;
          final childLeft = playing && showAction && motion == 'push'
              ? cartLeft - 144
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
                    playing && showAction ? 'explorer_$motion' : 'explorer',
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

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/touch_cue.dart';
import 'sound_picture.dart';

class SoundDistance extends StatefulWidget {
  const SoundDistance({
    super.key,
    required this.position,
    required this.pulse,
    required this.onMove,
    required this.listenerLabel,
    this.onListen,
  });
  final double position;
  final int pulse;
  final ValueChanged<double>? onMove;
  final String listenerLabel;
  final VoidCallback? onListen;
  @override
  State<SoundDistance> createState() => _SoundDistanceState();
}

class _SoundDistanceState extends State<SoundDistance> {
  double? dragging;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      // A padded phone previously had only a few pixels of travel. Scale a
      // complete scene so near and far stay visibly separate on every device.
      final sceneWidth = math.max(640.0, box.maxWidth);
      final scale = box.maxWidth / sceneWidth;
      const listenerHeight = 175.0;
      const start = 210.0;
      final travel = (sceneWidth - start - listenerHeight * 1.25 - 20).clamp(
        0.0,
        1500.0,
      );
      final position = dragging ?? widget.position;
      final scene = ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Container(
          height: 255,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE4F1F0), Color(0xFFEDF3D9)],
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(child: CustomPaint(painter: _SoundPark())),
              Positioned(
                left: 30,
                right: 25,
                bottom: 35,
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCDBC9C),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              Positioned(
                left: 15,
                bottom: 45,
                child: InkWell(
                  key: const ValueKey('lab-distance-drum'),
                  onTap: widget.onListen,
                  child: Stack(
                    children: [
                      SoundDemonstration(
                        'drum',
                        key: ValueKey('distance-drum-${widget.pulse}'),
                        height: 145,
                        play: widget.pulse > 0,
                      ),
                      if (widget.onListen != null)
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: TouchCue(),
                        ),
                    ],
                  ),
                ),
              ),
              for (var i = 0; i < 5; i++)
                Positioned(
                  left: start + travel * i / 5,
                  bottom: 34,
                  child: const Icon(
                    Icons.circle,
                    size: 6,
                    color: Color(0xFFAA9B7E),
                  ),
                ),
              AnimatedPositioned(
                duration:
                    dragging != null || MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 400),
                left: start + travel * position,
                bottom: 45,
                child: GestureDetector(
                  key: const ValueKey('sound-listener'),
                  onHorizontalDragStart: widget.onMove == null || travel == 0
                      ? null
                      : (_) => setState(() => dragging = widget.position),
                  onHorizontalDragUpdate: widget.onMove == null || travel == 0
                      ? null
                      : (d) => setState(
                          () => dragging =
                              ((dragging ?? widget.position) +
                                      d.delta.dx / (travel * scale))
                                  .clamp(0.0, 1.0),
                        ),
                  onHorizontalDragEnd: widget.onMove == null || travel == 0
                      ? null
                      : (_) {
                          final value = dragging ?? widget.position;
                          setState(() => dragging = null);
                          widget.onMove!(value);
                        },
                  onHorizontalDragCancel: () => setState(() => dragging = null),
                  child: Semantics(
                    label: widget.listenerLabel,
                    child: const Stack(
                      children: [
                        SoundPicture('listener', height: listenerHeight),
                        Positioned(
                          right: listenerHeight * .18,
                          bottom: 15,
                          child: TouchCue(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return SizedBox(
        width: box.maxWidth,
        height: 255 * scale,
        child: FittedBox(
          child: SizedBox(width: sceneWidth, height: 255, child: scene),
        ),
      );
    },
  );
}

class _SoundPark extends CustomPainter {
  const _SoundPark();
  @override
  void paint(Canvas c, Size s) {
    final ground = Paint()..color = const Color(0xFFD5E3BF);
    c.drawPath(
      Path()
        ..moveTo(0, s.height * .62)
        ..quadraticBezierTo(
          s.width * .35,
          s.height * .45,
          s.width,
          s.height * .67,
        )
        ..lineTo(s.width, s.height)
        ..lineTo(0, s.height)
        ..close(),
      ground,
    );
    final foliage = Paint()..color = const Color(0xFFBDCFB4);
    for (var i = 0; i < 5; i++) {
      c.drawOval(
        Rect.fromLTWH(
          s.width * .08 + i * s.width * .2,
          s.height * .39,
          s.width * .16,
          s.height * .28,
        ),
        foliage,
      );
    }
    final fence = Paint()
      ..color = const Color(0xFFF3EDDC)
      ..strokeWidth = 3;
    c.drawLine(
      Offset(0, s.height * .62),
      Offset(s.width, s.height * .62),
      fence,
    );
    c.drawLine(
      Offset(0, s.height * .69),
      Offset(s.width, s.height * .69),
      fence,
    );
    for (var x = 12.0; x < s.width; x += 48) {
      c.drawLine(Offset(x, s.height * .58), Offset(x, s.height * .72), fence);
    }
  }

  @override
  bool shouldRepaint(_SoundPark old) => false;
}

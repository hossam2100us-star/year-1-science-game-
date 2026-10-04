import 'package:flutter/material.dart';

import 'force_picture.dart';
import '../../core/touch_cue.dart';

/// The person stays at the left, so away/towards have a stable reference.
class ForceTrack extends StatefulWidget {
  const ForceTrack({
    super.key,
    required this.position,
    required this.art,
    required this.you,
    this.onMove,
    this.animateFromStart = false,
    this.comparisons = const [],
    this.goalPosition,
    this.onReplay,
  });
  final double position;
  final bool animateFromStart;
  final String art, you;
  final ValueChanged<double>? onMove;
  final List<double> comparisons;
  final double? goalPosition;
  final VoidCallback? onReplay;
  @override
  State<ForceTrack> createState() => _ForceTrackState();
}

class _ForceTrackState extends State<ForceTrack> {
  double? dragPosition;
  double? initialPosition;
  @override
  void initState() {
    super.initState();
    if (widget.animateFromStart) {
      initialPosition = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => initialPosition = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final sceneWidth = box.maxWidth < 500 ? 500.0 : box.maxWidth;
      final scale = box.maxWidth / sceneWidth;
      final travel = (sceneWidth - 305).clamp(50.0, 1200.0);
      final position = dragPosition ?? initialPosition ?? widget.position;
      final scene = SizedBox(
        width: sceneWidth,
        height: 210,
        child: Stack(
          children: [
            Positioned(
              left: 120,
              right: 12,
              bottom: 40,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFB8D1C4),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              bottom: 45,
              child: ForcePicture('explorer', height: 145),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              width: 181.25,
              child: Text(
                widget.you,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            if (widget.goalPosition != null)
              Positioned(
                left: 175 + travel * widget.goalPosition!,
                bottom: 25,
                child: const Icon(
                  Icons.flag_rounded,
                  color: Color(0xFF936C42),
                  size: 30,
                ),
              ),
            for (final mark in widget.comparisons)
              Positioned(
                left: 215 + travel * mark,
                bottom: 28,
                child: Container(
                  width: 4,
                  height: 36,
                  color: const Color(0xFF708D83),
                ),
              ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: position),
              duration:
                  dragPosition != null ||
                      MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 1400),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Positioned(
                left: 145 + travel * value,
                bottom: 45,
                child: GestureDetector(
                  key: const ValueKey('force-track-object'),
                  onTap: widget.onReplay,
                  onHorizontalDragStart: widget.onMove == null
                      ? null
                      : (_) => setState(() => dragPosition = widget.position),
                  onHorizontalDragUpdate: widget.onMove == null
                      ? null
                      : (d) => setState(
                          () => dragPosition =
                              ((dragPosition ?? widget.position) +
                                      d.delta.dx / (travel * scale))
                                  .clamp(0.0, 1.0),
                        ),
                  onHorizontalDragEnd: widget.onMove == null
                      ? null
                      : (_) {
                          final value = dragPosition ?? widget.position;
                          setState(() => dragPosition = null);
                          widget.onMove!(value);
                        },
                  onHorizontalDragCancel: () =>
                      setState(() => dragPosition = null),
                  child: SizedBox(
                    width: 144,
                    height: 115,
                    child: Stack(
                      children: [
                        ForcePicture(
                          widget.art,
                          height: 115,
                          phase:
                              value * travel / (widget.art == 'ball' ? 37 : 10),
                        ),
                        if (widget.onMove != null || widget.onReplay != null)
                          const Positioned(
                            right: 0,
                            bottom: 0,
                            child: TouchCue(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
      return SizedBox(
        width: box.maxWidth,
        height: 210 * scale,
        child: FittedBox(child: scene),
      );
    },
  );
}

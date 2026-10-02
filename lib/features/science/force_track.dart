import 'package:flutter/material.dart';

import 'force_picture.dart';

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
  });
  final double position;
  final bool animateFromStart;
  final String art, you;
  final ValueChanged<double>? onMove;
  final List<double> comparisons;
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
      final travel = (box.maxWidth - 220).clamp(80.0, 1200.0);
      final position = dragPosition ?? initialPosition ?? widget.position;
      return SizedBox(
        height: 210,
        child: Stack(
          children: [
            Positioned(
              left: 95,
              right: 12,
              bottom: 40,
              child: Container(
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFB8D1C4),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            Positioned(
              left: 10,
              bottom: 35,
              child: Column(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 65,
                    color: Color(0xFF617D83),
                  ),
                  Text(widget.you, style: const TextStyle(fontSize: 20)),
                ],
              ),
            ),
            for (final mark in widget.comparisons)
              Positioned(
                left: 100 + travel * mark,
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
                left: 90 + travel * value,
                bottom: 45,
                child: GestureDetector(
                  key: const ValueKey('force-track-object'),
                  onHorizontalDragStart: widget.onMove == null
                      ? null
                      : (_) => setState(() => dragPosition = widget.position),
                  onHorizontalDragUpdate: widget.onMove == null
                      ? null
                      : (d) => setState(
                          () => dragPosition =
                              ((dragPosition ?? widget.position) +
                                      d.delta.dx / travel)
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
                  child: ForcePicture(
                    widget.art,
                    height: 115,
                    phase: value * travel / (widget.art == 'ball' ? 37 : 10),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

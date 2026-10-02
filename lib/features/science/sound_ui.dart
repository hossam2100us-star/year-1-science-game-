import 'package:flutter/material.dart';

class SoundSurface extends StatelessWidget {
  const SoundSurface({super.key, required this.child, this.outdoor = false});
  final Widget child;
  final bool outdoor;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: outdoor
            ? const [Color(0xFFEBF4E7), Color(0xFFDDE9D8)]
            : const [Color(0xFFFFF1D8), Color(0xFFF0DFC3)],
      ),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xFFD1C4A8)),
    ),
    child: child,
  );
}

class SoundPhases extends StatelessWidget {
  const SoundPhases({super.key, required this.labels, required this.current});
  final List<String> labels;
  final int current;
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 8,
    runSpacing: 8,
    children: [
      for (var i = 0; i < labels.length; i++)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: i == current
                ? const Color(0xFFDEEAF0)
                : const Color(0xFFF9F3E8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: i == current
                  ? const Color(0xFF527C90)
                  : const Color(0xFFD6CDBD),
            ),
          ),
          child: Text(
            '${i + 1}. ${labels[i]}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: i == current ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
    ],
  );
}

class SoundStudio extends StatelessWidget {
  const SoundStudio({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: Stack(
      children: [
        const Positioned.fill(child: CustomPaint(painter: _StudioRoom())),
        Padding(padding: const EdgeInsets.all(18), child: child),
      ],
    ),
  );
}

class _StudioRoom extends CustomPainter {
  const _StudioRoom();
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFF4E9D0));
    final floor = Rect.fromLTWH(0, s.height - 85, s.width, 85);
    c.drawRect(
      floor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFDDC29E), Color(0xFFCCAD85)],
        ).createShader(floor),
    );
    final wood = Paint()
      ..color = const Color(0xFFBD9E78)
      ..strokeWidth = 1;
    for (var y = s.height - 65; y < s.height; y += 22) {
      c.drawLine(Offset(0, y), Offset(s.width, y), wood);
    }
    c.drawRect(
      Rect.fromLTWH(0, 0, s.width, 10),
      Paint()..color = const Color(0xFF9BB1AA),
    );
    for (final x in [0.0, s.width - 16]) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 10, 16, s.height - 95),
          const Radius.circular(8),
        ),
        Paint()..color = const Color(0xFFB6C6B5),
      );
    }
  }

  @override
  bool shouldRepaint(_StudioRoom old) => false;
}

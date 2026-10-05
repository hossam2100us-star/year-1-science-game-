import 'package:flutter/material.dart';

class ShoeMeasure extends StatelessWidget {
  const ShoeMeasure({
    super.key,
    required this.values,
    required this.ui,
    required this.onChange,
    required this.onCompare,
  });
  final List<int> values;
  final Map<String, dynamic> ui;
  final void Function(int, int) onChange;
  final VoidCallback onCompare;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Wrap(
        spacing: 20,
        runSpacing: 20,
        alignment: WrapAlignment.center,
        children: [
          for (var i = 0; i < 2; i++)
            Container(
              width: 300,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3DB),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Text(
                    '${ui['shoe']} ${i + 1}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    height: 120,
                    child: CustomPaint(
                      size: const Size(264, 120),
                      painter: ShoePainter(i == 0),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        key: ValueKey('shoe-less-$i'),
                        tooltip: ui['smaller'],
                        constraints: const BoxConstraints(
                          minWidth: 64,
                          minHeight: 64,
                        ),
                        onPressed: values[i] <= 1
                            ? null
                            : () => onChange(i, values[i] - 1),
                        icon: const Icon(Icons.remove_circle_outline, size: 32),
                      ),
                      Text(
                        '${values[i]}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        key: ValueKey('shoe-more-$i'),
                        tooltip: ui['bigger'],
                        constraints: const BoxConstraints(
                          minWidth: 64,
                          minHeight: 64,
                        ),
                        onPressed: values[i] >= 60
                            ? null
                            : () => onChange(i, values[i] + 1),
                        icon: const Icon(Icons.add_circle_outline, size: 32),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
      const SizedBox(height: 18),
      FilledButton(
        key: const ValueKey('compare-shoes'),
        onPressed: onCompare,
        child: Text(ui['compare']),
      ),
    ],
  );
}

class ShoePainter extends CustomPainter {
  const ShoePainter(this.blue);
  final bool blue;
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 260, s.height / 120);
    final p = Path()
      ..moveTo(36, 31)
      ..lineTo(92, 43)
      ..lineTo(123, 16)
      ..quadraticBezierTo(148, 48, 182, 64)
      ..quadraticBezierTo(236, 70, 236, 95)
      ..lineTo(30, 95)
      ..close();
    c.drawPath(
      p,
      Paint()..color = blue ? const Color(0xFF5B9DBC) : const Color(0xFFB488AE),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(29, 93, 209, 13),
        const Radius.circular(7),
      ),
      Paint()..color = Colors.white,
    );
    for (var i = 0; i < 3; i++) {
      c.drawLine(
        Offset(125 + i * 14, 51 + i * 7),
        Offset(111 + i * 14, 68 + i * 7),
        Paint()
          ..color = const Color(0xFFFFF6D9)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(ShoePainter old) => old.blue != blue;
}

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/game_image.dart';
import 'maths_art.dart';

/// Original, neutral diagrams described by lesson JSON. The answer key never
/// enters this widget, so illustrations cannot highlight the correct choice.
class MathsVisual extends StatelessWidget {
  const MathsVisual({super.key, required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final type = data['type'];
    if (type == 'groups' || type == 'pattern') {
      final items = (data['items'] as List? ?? []).cast<Map<String, dynamic>>();
      // Groups of counters side by side use one counter size, so the group
      // with fewer counters does not show bigger ones (teacher review 5).
      final slots = items
          .where((item) => item['type'] == 'count')
          .fold<int>(
            0,
            (n, item) => math.max(n, (item['count'] as num).toInt()),
          );
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          for (final item in items)
            SizedBox(
              width: type == 'pattern'
                  ? 90
                  : item['type'] == 'ruler'
                  ? 220
                  : 150,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MathsVisual(
                    data: {
                      ...item,
                      if (item['type'] == 'count') 'slots': slots,
                    },
                  ),
                  if (item['label'] != null)
                    Text('${item['label']}', textAlign: TextAlign.center),
                ],
              ),
            ),
        ],
      );
    }
    if (type == 'chart') return _Chart(data: data);
    if (type == 'text' || type == 'missing') {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          '${data['text'] ?? '?'}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Fredoka', fontSize: 32),
        ),
      );
    }
    if (type == 'carroll') return CarrollTable(data: data);
    // A picture inside an answer may ask for less height.
    final height =
        (data['height'] as num?)?.toDouble() ??
        switch (type) {
          'numberLine' => 100.0,
          'robot' => 230.0,
          'venn' => 190.0,
          'balance' => 184.0,
          'sky' => 140.0,
          'ruler' => 120.0,
          'clock' => 200.0,
          'count' => 170.0,
          _ => 160.0,
        };
    return Semantics(
      label: data['description'] as String? ?? _description,
      image: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: const {'count', 'clock', 'ruler', 'venn'}.contains(type)
            ? GameImage(
                asset: mathsObjectAsset,
                builder: (context, image) =>
                    CustomPaint(painter: _MathsPainter(data, image: image)),
                placeholder: CustomPaint(painter: _MathsPainter(data)),
              )
            : CustomPaint(painter: _MathsPainter(data)),
      ),
    );
  }

  String get _description => switch (data['type']) {
    'count' => 'Objects to count',
    'clock' => 'Clock face with an hour hand and a minute hand',
    'fraction' => 'A shape divided into parts',
    'ruler' => 'An object aligned with a ruler',
    'numberLine' => 'Number line',
    'money' => 'Coins',
    'balance' => 'A pan balance',
    'sky' => 'The sky',
    'venn' => 'A Venn diagram with two overlapping hoops',
    'robot' => 'A robot and a star on a grid',
    _ => 'Maths diagram',
  };
}

/// What an Egyptian coin worth [piastres] says: 25 or 50 piastres, or 1
/// pound for a hundred (teacher review 5: there is no "100 piastres" coin).
({String amount, String unit}) coinDenomination(int piastres) =>
    piastres >= 100 && piastres % 100 == 0
    ? (amount: '${piastres ~/ 100}', unit: piastres == 100 ? 'pound' : 'pounds')
    : (amount: '$piastres', unit: 'piastres');

class _Chart extends StatelessWidget {
  const _Chart({required this.data});
  final Map<String, dynamic> data;

  String? _categoryArt(String label) => switch (label.toLowerCase()) {
    'apple' => 'apple',
    'banana' => 'banana',
    'orange' => 'orange',
    'mango' => 'mango',
    'cars' || 'car' => 'car',
    'balls' => 'ball',
    'dolls' => 'doll',
    'blocks' => 'cube',
    'pigeons' => 'pigeon',
    'sparrows' => 'sparrow',
    'crows' => 'crow',
    _ => null,
  };

  String get _markerArt {
    final unit = '${data['unit'] ?? ''}'.toLowerCase();
    if (unit.contains('star')) return 'star';
    if (unit.contains('bird')) return 'bird';
    if (unit.contains('person') || unit.contains('people')) return 'person';
    return 'counter';
  }

  /// One mark of a pictogram. A person is a person symbol, not a coloured
  /// circle that looks like the apples in the first row (teacher review 5).
  Widget _mark(String art, {required double height, double? width}) =>
      art == 'person'
      ? SizedBox(
          height: height,
          width: width ?? height,
          child: const CustomPaint(painter: _PersonPainter()),
        )
      : MathsArt(art, height: height, width: width);

  Widget _rowLabel(Map<String, dynamic> row, {bool compact = false}) {
    final label = '${row['label']}';
    final art = _categoryArt(label);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (art != null) MathsArt(art, height: compact ? 36 : 40),
        Text(
          label,
          textAlign: TextAlign.center,
          style: compact ? const TextStyle(fontSize: 16) : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = (data['rows'] as List).cast<Map<String, dynamic>>();
    final largestValue = rows.fold<int>(
      1,
      (largest, row) => math.max(largest, (row['value'] as num).toInt()),
    );
    final maxValue = math.max(
      largestValue,
      (data['axisMax'] as num?)?.toInt() ?? largestValue,
    );
    final tickStep = math.max(1, (data['tickStep'] as num?)?.toInt() ?? 1);
    final pictogram = data['style'] == 'pictogram';
    if (!pictogram) {
      final unitHeight = MediaQuery.textScalerOf(context)
          .scale(14)
          .clamp(22.0, 36.0);
      final chartHeight = maxValue * unitHeight;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (data['title'] != null)
            Text('${data['title']}', textAlign: TextAlign.center),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 34,
                height: chartHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var n = 0; n <= maxValue; n += tickStep)
                      Positioned(
                        top: chartHeight - n * unitHeight - 10,
                        right: 6,
                        child: Text('$n', style: const TextStyle(fontSize: 14)),
                      ),
                  ],
                ),
              ),
              for (final (rowIndex, row) in rows.indexed)
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: chartHeight,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            for (var n = 0; n <= maxValue; n += tickStep)
                              Positioned(
                                top: chartHeight - n * unitHeight,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 1,
                                  color: const Color(0xFFB7CFD1),
                                ),
                              ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                widthFactor: .72,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (
                                      var i = 0;
                                      i < (row['value'] as num).toInt();
                                      i++
                                    )
                                      Container(
                                        height: unitHeight,
                                        decoration: BoxDecoration(
                                          color: const [
                                            Color(0xFF3C8F83),
                                            Color(0xFFE29A40),
                                            Color(0xFF9B73AA),
                                            Color(0xFF5D92B9),
                                            Color(0xFFC97963),
                                          ][rowIndex % 5],
                                          border: data['style'] == 'bar'
                                              ? null
                                              : Border.all(color: Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _rowLabel(row, compact: true),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (data['unit'] != null) ...[
            const SizedBox(height: 12),
            Text('Each unit: ${data['unit']}', textAlign: TextAlign.center),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data['title'] != null)
          Text('${data['title']}', textAlign: TextAlign.center),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (_categoryArt('${row['label']}')
                        case final String art) ...[
                      MathsArt(art, height: 36),
                      const SizedBox(width: 8),
                    ],
                    Expanded(child: Text('${row['label']}')),
                  ],
                ),
                LayoutBuilder(
                  builder: (context, box) {
                    final unit = math.min(32.0, box.maxWidth / maxValue);
                    return Row(
                      children: [
                        for (var i = 0; i < maxValue; i++)
                          SizedBox(
                            width: unit,
                            height: 30,
                            child: i < (row['value'] as num).toInt()
                                ? _mark(_markerArt, height: 30, width: unit)
                                : null,
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        if (data['unit'] != null)
          // Wraps on a phone with large text instead of overflowing.
          Wrap(
            key: const ValueKey('maths-pictogram-key'),
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Key: '),
              _mark(_markerArt, height: 28),
              Text(' = ${data['unit']}'),
            ],
          ),
        if (!pictogram)
          Text(
            List.generate(maxValue + 1, (i) => '$i').join('  '),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
      ],
    );
  }
}

/// A simple person symbol for pictograms: a head and a rounded body.
class _PersonPainter extends CustomPainter {
  const _PersonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF2E6F8E);
    final side = math.min(size.width, size.height);
    final centre = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(centre + Offset(0, -side * .26), side * .17, paint);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromCenter(
          center: centre + Offset(0, side * .22),
          width: side * .56,
          height: side * .44,
        ),
        topLeft: Radius.circular(side * .22),
        topRight: Radius.circular(side * .22),
        bottomLeft: Radius.circular(side * .05),
        bottomRight: Radius.circular(side * .05),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_PersonPainter oldDelegate) => false;
}

class _MathsPainter extends CustomPainter {
  _MathsPainter(this.data, {this.image});
  final Map<String, dynamic> data;
  final ui.Image? image;
  static const blue = Color(0xFF2170B5);
  static const dark = Color(0xFF223D50);

  Paint _paint(Color color, {bool stroke = false}) => Paint()
    ..color = color
    ..style = stroke ? PaintingStyle.stroke : PaintingStyle.fill
    ..strokeWidth = 3;

  Paint _material(Color color, Rect bounds) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(color, Colors.white, .28)!,
        color,
        Color.lerp(color, dark, .14)!,
      ],
      stops: const [0, .6, 1],
    ).createShader(bounds);

  void _text(Canvas canvas, String value, Offset center, {double size = 22}) {
    final text = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: dark,
          fontFamily: 'Nunito',
          fontSize: size,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    switch (data['type']) {
      case 'count':
        _count(canvas, size);
      case 'clock':
        _clock(canvas, size);
      case 'numberLine':
        _numberLine(canvas, size);
      case 'money':
        _money(canvas, size);
      case 'ruler':
        _ruler(canvas, size);
      case 'fraction':
        _fraction(canvas, size);
      case 'balance':
        _balance(canvas, size);
      case 'sky':
        _sky(canvas, size);
      case 'venn':
        _venn(canvas, size);
      case 'robot':
        _robot(canvas, size);
      case 'shape':
        final side = math.min(size.width * .75, size.height * .75);
        canvas.save();
        canvas.translate(size.width / 2, size.height / 2);
        canvas.rotate((data['rotation'] as num? ?? 0) * math.pi / 180);
        _shape(
          canvas,
          '${data['shape']}',
          Rect.fromCenter(center: Offset.zero, width: side, height: side),
          _color,
        );
        canvas.restore();
      default:
        _text(canvas, '${data['text'] ?? '?'}', size.center(Offset.zero));
    }
  }

  Color get _color => switch (data['color']) {
    'red' => const Color(0xFFD0504B),
    'yellow' => const Color(0xFFE6B746),
    'green' => const Color(0xFF3E9B5A),
    'orange' => const Color(0xFFE88A2E),
    'purple' => const Color(0xFF794D91),
    'blue' => blue,
    _ => const Color(0xFF4F9685),
  };

  void _count(Canvas canvas, Size size) {
    final count = math.max(0, (data['count'] as num? ?? 0).toInt());
    final frame = data['arrangement'] == 'tenFrame';
    final pairs = data['arrangement'] == 'pairs';
    if (count == 0 && !frame) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
          const Radius.circular(16),
        ),
        _paint(const Color(0xFFFFF7E8)),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
          const Radius.circular(16),
        ),
        _paint(dark, stroke: true),
      );
      return;
    }
    final frameCells = frame ? math.max(10, (count / 10).ceil() * 10) : count;
    final pairColumns = size.width >= 260
        ? 6
        : size.width >= 130
        ? 4
        : 2;
    final columns = frame
        ? 5
        : pairs
        ? math.min(pairColumns, math.max(2, (count / 2).ceil() * 2))
        : math.min(count, 5);
    final rows = (frameCells / columns).ceil();
    final pairGap = pairs ? 10.0 : 0.0;
    final frameGap = frame ? 8.0 : 0.0;
    final cellW = (size.width - pairGap * (columns / 2 - 1)) / columns;
    final cellH = (size.height - frameGap * (frameCells / 10 - 1)) / rows;
    // A shared size for groups shown together (see MathsVisual.groups).
    final slots = (data['slots'] as num?)?.toInt() ?? 0;
    final sizeW = frame || pairs
        ? cellW
        : size.width / math.min(math.max(count, slots), 5);
    final radius = math.min(36.0, math.min(sizeW, cellH) * .36);
    // A counter given a colour is drawn in it: the art's own counter is
    // always coral, which made '4 blue dots and 3 orange dots' all orange.
    final tinted =
        data['color'] != null &&
        const {'dot', 'counter'}.contains(data['item'] ?? 'counter');
    final removed = (data['removed'] as num? ?? 0).toInt();
    for (var i = 0; i < frameCells; i++) {
      var center = Offset(
        (i % columns + .5) * cellW + (i % columns ~/ 2) * pairGap,
        (i ~/ columns + .5) * cellH + (i ~/ columns ~/ 2) * frameGap,
      );
      if (data['arrangement'] == 'scattered') {
        center += Offset(
          (i.isEven ? 1 : -1) * radius * .4,
          ((i % 3) - 1) * radius * .5,
        );
      }
      final rect = Rect.fromCircle(center: center, radius: radius);
      if (frame) {
        canvas.drawRect(
          Rect.fromCenter(center: center, width: cellW - 2, height: cellH - 2),
          _paint(const Color(0xFFFFFAEE)),
        );
        canvas.drawRect(
          Rect.fromCenter(center: center, width: cellW - 2, height: cellH - 2),
          _paint(const Color(0xFFA47745), stroke: true),
        );
        if (i >= count) continue;
      }
      if (image != null && !tinted) {
        paintMathsObject(canvas, image!, '${data['item'] ?? 'counter'}', rect);
      } else if (data['item'] == 'star') {
        final path = Path();
        for (var p = 0; p < 10; p++) {
          final angle = -math.pi / 2 + p * math.pi / 5;
          final r = radius * (p.isEven ? 1 : .45);
          final point = center + Offset(math.cos(angle), math.sin(angle)) * r;
          if (p == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        canvas.drawPath(path..close(), _paint(_color));
      } else if (data['item'] == 'cube' || data['item'] == 'square') {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          _paint(_color),
        );
      } else if (data['item'] == 'sock') {
        final sock = Path()
          ..moveTo(rect.left + radius * .5, rect.top)
          ..lineTo(rect.right, rect.top)
          ..lineTo(rect.right, rect.bottom - radius * .3)
          ..quadraticBezierTo(
            rect.right,
            rect.bottom,
            rect.left + radius * .4,
            rect.bottom,
          )
          ..lineTo(rect.left, rect.bottom - radius * .5)
          ..lineTo(rect.left + radius * .5, rect.center.dy)
          ..close();
        canvas.drawPath(sock, _paint(_color));
        canvas.drawPath(sock, _paint(dark, stroke: true));
      } else {
        canvas.drawOval(rect, _paint(_color));
        if (data['item'] == 'apple') {
          canvas.drawLine(
            center - Offset(0, radius),
            center - Offset(-3, radius + 5),
            _paint(dark),
          );
          canvas.drawOval(
            Rect.fromCenter(
              center: center + Offset(6, -radius - 2),
              width: 9,
              height: 5,
            ),
            _paint(const Color(0xFF27764A)),
          );
        }
      }
      if (i >= count - removed) {
        canvas.drawLine(rect.topLeft, rect.bottomRight, _paint(dark));
        canvas.drawLine(rect.topRight, rect.bottomLeft, _paint(dark));
      }
    }
  }

  void _clock(Canvas canvas, Size size) {
    final radius = math.min(size.width, size.height) * .45;
    final center = size.center(Offset.zero);
    final bounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center + const Offset(0, 4),
      radius,
      _paint(const Color(0x332B453E)),
    );
    canvas.drawCircle(
      center,
      radius,
      _material(const Color(0xFFC99654), bounds),
    );
    if (image != null) {
      paintMathsObject(canvas, image!, 'clock', bounds.inflate(6));
    }
    // Numerals and both hands are always drawn from the book's exact time.
    // The opaque face also prevents decorative atlas markings from showing.
    canvas.drawCircle(center, radius * .9, _paint(const Color(0xFFFFFBF0)));
    canvas.drawCircle(
      center,
      radius * .9,
      _paint(const Color(0xFF876B47), stroke: true),
    );
    for (var hour = 1; hour <= 12; hour++) {
      final angle = hour * math.pi / 6 - math.pi / 2;
      _text(
        canvas,
        '$hour',
        center + Offset(math.cos(angle), math.sin(angle)) * radius * .78,
        size: radius < 70 ? 14 : 18,
      );
    }
    final hour = (data['hour'] as num? ?? 12).toDouble();
    final minute = (data['minute'] as num? ?? 0).toDouble();
    final hourAngle = (hour % 12 + minute / 60) * math.pi / 6 - math.pi / 2;
    final minuteAngle = minute * math.pi / 30 - math.pi / 2;
    canvas.drawLine(
      center,
      center + Offset(math.cos(hourAngle), math.sin(hourAngle)) * radius * .48,
      _paint(dark)..strokeWidth = 6,
    );
    canvas.drawLine(
      center,
      center +
          Offset(math.cos(minuteAngle), math.sin(minuteAngle)) * radius * .66,
      _paint(blue)..strokeWidth = 4,
    );
    canvas.drawCircle(center, 5, _paint(dark));
  }

  void _numberLine(Canvas canvas, Size size) {
    final start = (data['start'] as num? ?? 0).toInt();
    final end = (data['end'] as num? ?? 20).toInt();
    final range = math.max(1, end - start);
    final span = size.width - 28;
    final y = size.height * .5;
    canvas.drawLine(Offset(14, y), Offset(size.width - 14, y), _paint(dark));
    final markers = (data['markers'] as List? ?? []).cast<num>();
    final stride = span / range < 23 ? 2 : 1;
    for (var n = start; n <= end; n++) {
      final x = 14 + (n - start) / range * span;
      canvas.drawLine(Offset(x, y - 5), Offset(x, y + 5), _paint(dark));
      if ((n - start) % stride == 0 || n == end) {
        _text(canvas, '$n', Offset(x, y + 24), size: 16);
      }
      if (markers.contains(n)) {
        canvas.drawCircle(Offset(x, y), 6, _paint(blue));
      }
    }
    // Jumps from a start (teacher review 5): the child's own (blue forward,
    // orange back), or the explanation's, shown one after another in green.
    final from = data['from'] as num?;
    if (from == null) return;
    double xOf(num n) => 14 + (n - start) / range * span;
    void arc(num a, num b, Color colour) {
      final x1 = xOf(a), x2 = xOf(b);
      final h = math.min((x2 - x1).abs() * .6, 34.0);
      final control = Offset((x1 + x2) / 2, y - h * 2);
      final tip = Offset(x2, y);
      canvas.drawPath(
        Path()
          ..moveTo(x1, y)
          ..quadraticBezierTo(control.dx, control.dy, tip.dx, tip.dy),
        _paint(colour, stroke: true)..strokeWidth = 3,
      );
      final way = tip - control;
      final dir = way / way.distance, side = Offset(-dir.dy, dir.dx);
      final back = tip - dir * 10;
      canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo((back + side * 5).dx, (back + side * 5).dy)
          ..lineTo((back - side * 5).dx, (back - side * 5).dy)
          ..close(),
        _paint(colour),
      );
    }

    canvas.drawCircle(Offset(xOf(from), y), 9, _paint(const Color(0xFF3E9B5A)));
    canvas.drawCircle(Offset(xOf(from), y), 4, _paint(Colors.white));
    var at = from;
    final shown = (data['shown'] as List?)?.cast<num>();
    if (shown != null) {
      final progress = (data['progress'] as num? ?? 1).toDouble();
      final visible = (progress * shown.length).ceil();
      for (final step in shown.take(visible)) {
        arc(at, at + step, const Color(0xFF3E9B5A));
        at += step;
      }
      if (visible > 0) {
        canvas.drawCircle(
          Offset(xOf(at), y),
          7,
          _paint(const Color(0xFF3E9B5A)),
        );
      }
      return;
    }
    for (final hop in (data['hops'] as List? ?? const []).cast<num>()) {
      arc(at, at + hop, hop > 0 ? blue : const Color(0xFFE88A2E));
      at += hop;
    }
    if (at != from) canvas.drawCircle(Offset(xOf(at), y), 7, _paint(blue));
  }

  /// A small five-pointed star.
  void _star(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (var p = 0; p < 10; p++) {
      final angle = -math.pi / 2 + p * math.pi / 5;
      final r = radius * (p.isEven ? 1 : .45);
      final point = center + Offset(math.cos(angle), math.sin(angle)) * r;
      if (p == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path..close(), _paint(color));
  }

  /// A pan balance with equal cubes in each pan; the heavier side goes down
  /// (teacher review 5: the balance questions showed no balance).
  void _balance(Canvas canvas, Size size) {
    Map<String, dynamic> side(String key) =>
        Map<String, dynamic>.from(data[key] as Map? ?? const {});
    final tilt = switch (data['tilt']) {
      'left' => 1.0,
      'right' => -1.0,
      _ => 0.0,
    };
    final cx = size.width / 2;
    final pivot = Offset(cx, size.height * .3);
    final arm = math.min(size.width * .34, 160.0);
    final angle = tilt * .22;
    final beam = _paint(dark)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final string = _paint(dark)..strokeWidth = 1.5;
    canvas.drawLine(pivot, Offset(cx, size.height - 14), beam);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, size.height - 10),
          width: 96,
          height: 10,
        ),
        const Radius.circular(4),
      ),
      _paint(dark),
    );
    final left = pivot + Offset(-math.cos(angle) * arm, math.sin(angle) * arm);
    final right = pivot + Offset(math.cos(angle) * arm, -math.sin(angle) * arm);
    canvas.drawLine(left, right, beam);
    canvas.drawCircle(pivot, 7, _paint(const Color(0xFFE6B746)));
    for (final (end, load, colour) in [
      (left, side('left'), const Color(0xFFE88A2E)),
      (right, side('right'), blue),
    ]) {
      final panY = end.dy + 44;
      canvas.drawLine(end, Offset(end.dx - 40, panY), string);
      canvas.drawLine(end, Offset(end.dx + 40, panY), string);
      final pan = Rect.fromCenter(
        center: Offset(end.dx, panY),
        width: 98,
        height: 20,
      );
      canvas.drawArc(pan, 0, math.pi, true, _paint(const Color(0xFFB7CFD1)));
      canvas.drawArc(pan, 0, math.pi, true, _paint(dark, stroke: true));
      final count = (load['count'] as num? ?? 0).toInt();
      const cube = 20.0;
      for (var i = 0; i < count; i++) {
        final row = i ~/ 3, inRow = math.min(3, count - row * 3);
        final x = end.dx + (i % 3 - (inRow - 1) / 2) * (cube + 2);
        final y = panY - 2 - (row + .5) * (cube + 2);
        final rect = Rect.fromCenter(
          center: Offset(x, y),
          width: cube,
          height: cube,
        );
        canvas.drawRect(rect, _material(colour, rect));
        canvas.drawRect(rect, _paint(dark, stroke: true)..strokeWidth = 1);
      }
      if (load['label'] case final String label) {
        _text(canvas, label, Offset(end.dx, panY + 26), size: 18);
      }
    }
  }

  /// The sky at a time of day; at night, the Moon and stars.
  void _sky(Canvas canvas, Size size) {
    final night = data['time'] == 'night';
    final area = (Offset.zero & size).deflate(6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(area, const Radius.circular(16)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: night
              ? const [Color(0xFF0E1E45), Color(0xFF2D3F7A)]
              : const [Color(0xFF7FC4F0), Color(0xFFD6EEFB)],
        ).createShader(area),
    );
    if (night) {
      final moon = Offset(size.width * .72, size.height * .4);
      final r = math.min(size.height * .2, 30.0);
      canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addOval(Rect.fromCircle(center: moon, radius: r)),
          Path()..addOval(
            Rect.fromCircle(
              center: moon + Offset(r * .45, -r * .15),
              radius: r * .9,
            ),
          ),
        ),
        _paint(const Color(0xFFF6E7A1)),
      );
      for (final (x, y, s) in const [
        (.12, .3, 7.0),
        (.3, .6, 5.0),
        (.45, .25, 6.0),
        (.57, .7, 4.0),
        (.88, .72, 5.0),
        (.22, .78, 4.0),
      ]) {
        _star(
          canvas,
          Offset(size.width * x, size.height * y),
          s,
          const Color(0xFFFFF4C2),
        );
      }
    } else {
      final high = data['time'] == 'midday';
      canvas.drawCircle(
        Offset(size.width * (high ? .5 : .2), size.height * (high ? .3 : .7)),
        math.min(size.height * .18, 26),
        _paint(const Color(0xFFF6C344)),
      );
    }
  }

  /// Two overlapping hoops, each with its rule, and objects placed by the
  /// rules they fit: one rule, both, or neither (outside, top right).
  void _venn(Canvas canvas, Size size) {
    final labels = (data['labels'] as List? ?? const []).cast<String>();
    final r = math.min(size.height * .36, size.width * .22);
    final cy = size.height * .58;
    final left = Offset(size.width / 2 - r * .62, cy);
    final right = Offset(size.width / 2 + r * .62, cy);
    for (final (centre, colour) in [
      (left, const Color(0x33D0504B)),
      (right, const Color(0x332170B5)),
    ]) {
      canvas.drawCircle(centre, r, _paint(colour));
      canvas.drawCircle(centre, r, _paint(dark, stroke: true));
    }
    if (labels.length == 2) {
      _text(canvas, labels[0], left + Offset(-r * .35, -r - 13), size: 16);
      _text(canvas, labels[1], right + Offset(r * .35, -r - 13), size: 16);
    }
    final places = {
      'left': left + Offset(-r * .5, 0),
      'both': Offset(size.width / 2, cy),
      'right': right + Offset(r * .5, 0),
      'outside': Offset(size.width - r * .3 - 6, r * .3 + 6),
    };
    for (final item
        in (data['items'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      final at = places[item['region']] ?? places['outside']!;
      final side = item['region'] == 'outside' ? r * .5 : r * .62;
      final dest = Rect.fromCenter(center: at, width: side, height: side);
      if (image != null) {
        paintMathsObject(canvas, image!, '${item['item']}', dest);
      } else {
        canvas.drawCircle(at, side / 3, _paint(blue));
      }
    }
  }

  /// A robot on a grid with the way it faces, a star, and the routes the
  /// child has chosen (data['show']), each drawn from the same start.
  void _robot(Canvas canvas, Size size) {
    final cols = (data['cols'] as num? ?? 4).toInt();
    final rows = (data['rows'] as num? ?? 5).toInt();
    final cell = math.min((size.width - 8) / cols, (size.height - 8) / rows);
    final origin = Offset(
      (size.width - cell * cols) / 2,
      (size.height - cell * rows) / 2,
    );
    Offset centre(Offset p) => origin + (p + const Offset(.5, .5)) * cell;
    Offset point(String key) {
      final p = (data[key] as List).cast<num>();
      return Offset(p[0].toDouble(), p[1].toDouble());
    }

    for (var c = 0; c < cols; c++) {
      for (var r = 0; r < rows; r++) {
        final rect = Rect.fromLTWH(
          origin.dx + c * cell,
          origin.dy + r * cell,
          cell,
          cell,
        );
        canvas.drawRect(rect, _paint(const Color(0xFFFFFAEE)));
        canvas.drawRect(
          rect,
          _paint(const Color(0xFFA47745), stroke: true)..strokeWidth = 1.5,
        );
      }
    }
    final start = point('start');
    const facings = ['up', 'right', 'down', 'left'];
    const moves = [Offset(0, -1), Offset(1, 0), Offset(0, 1), Offset(-1, 0)];
    final first = math.max(0, facings.indexOf('${data['facing'] ?? 'up'}'));
    final routes = Map<String, dynamic>.from(data['routes'] as Map? ?? {});
    final shown = (data['show'] as List? ?? const []).cast<String>();
    const colours = [Color(0xFF2170B5), Color(0xFFE88A2E), Color(0xFF794D91)];
    for (final (i, label) in shown.indexed) {
      var facing = first;
      var at = start;
      final points = [at];
      for (final move in (routes[label] as List? ?? const []).cast<String>()) {
        switch (move) {
          case 'R':
            facing = (facing + 1) % 4;
          case 'L':
            facing = (facing + 3) % 4;
          case 'F':
            at += moves[facing];
            points.add(at);
          case 'B':
            at -= moves[facing];
            points.add(at);
        }
      }
      // Routes along the same cells sit side by side, not on top.
      final shift = const Offset(1, 1) * ((i - (shown.length - 1) / 2) * 5);
      final path = Path();
      for (final (j, p) in points.indexed) {
        final o = centre(p) + shift;
        if (j == 0) {
          path.moveTo(o.dx, o.dy);
        } else {
          path.lineTo(o.dx, o.dy);
        }
      }
      final colour = colours[i % colours.length];
      canvas.drawPath(
        path,
        _paint(colour, stroke: true)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawCircle(centre(points.last) + shift, 6, _paint(colour));
    }
    // The star stays visible on top of routes that reach it.
    _star(canvas, centre(point('star')), cell * .32, const Color(0xFFE6B746));
    final home = centre(start);
    final body = Rect.fromCenter(
      center: home,
      width: cell * .58,
      height: cell * .58,
    );
    final rounded = RRect.fromRectAndRadius(body, Radius.circular(cell * .12));
    canvas.drawRRect(rounded, _material(const Color(0xFF6E8FA8), body));
    canvas.drawRRect(rounded, _paint(dark, stroke: true));
    final ahead = moves[first], across = Offset(-ahead.dy, ahead.dx);
    Offset at(double forward, double side) =>
        home + ahead * (cell * forward) + across * (cell * side);
    final tip = at(.2, 0), back1 = at(-.08, .14), back2 = at(-.08, -.14);
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(back1.dx, back1.dy)
        ..lineTo(back2.dx, back2.dy)
        ..close(),
      _paint(Colors.white),
    );
  }

  /// Egyptian coins: 25 and 50 piastres, and the 1 pound coin. Values stay
  /// in piastres for comparing; a hundred is written and drawn as a pound
  /// (teacher review 5: there is no "100 piastres" coin).
  void _money(Canvas canvas, Size size) {
    final coins = (data['coins'] as List? ?? []).cast<num>();
    if (coins.isEmpty) return;
    final radius = math.min(27.0, size.width / (coins.length * 2 + 1));
    for (var i = 0; i < coins.length; i++) {
      final value = coins[i].toInt();
      final (:amount, :unit) = coinDenomination(value);
      final pounds = unit != 'piastres';
      final center = Offset(
        size.width * (i + .5) / coins.length,
        size.height / 2 - 8,
      );
      canvas.drawCircle(
        center,
        radius,
        _material(
          const Color(0xFFE6B746),
          Rect.fromCircle(center: center, radius: radius),
        ),
      );
      if (pounds) {
        // The pound coin: a silver centre inside a golden ring.
        canvas.drawCircle(
          center,
          radius * .68,
          _material(
            const Color(0xFFC9CED6),
            Rect.fromCircle(center: center, radius: radius * .68),
          ),
        );
      }
      canvas.drawCircle(
        center,
        radius,
        _paint(const Color(0xFF9C6D2C), stroke: true),
      );
      canvas.drawCircle(
        center,
        radius * .82,
        _paint(const Color(0x99FFF4CD), stroke: true)..strokeWidth = 1.5,
      );
      _text(canvas, amount, center, size: radius < 20 ? 14 : 20);
      _text(canvas, unit, center + Offset(0, radius + 14), size: 13);
    }
  }

  void _ruler(Canvas canvas, Size size) {
    final units = (data['units'] as num? ?? 6).toInt();
    final end = math.max(units + 2, (data['end'] as num? ?? 10).toInt());
    final span = size.width - 32;
    final length = units / end * span;
    if (data['unit'] == 'cube') {
      for (var i = 0; i < units; i++) {
        final rect = Rect.fromLTWH(16 + i / end * span, 64, span / end, 28);
        canvas.drawRect(rect, _material(const Color(0xFFE6B746), rect));
        canvas.drawRect(rect, _paint(dark, stroke: true));
      }
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(16, 65, span, 45),
          const Radius.circular(4),
        ),
        _material(const Color(0xFFE5BC77), Rect.fromLTWH(16, 65, span, 45)),
      );
      for (var i = 0; i <= end; i++) {
        final x = 16 + i / end * span;
        canvas.drawLine(Offset(x, 65), Offset(x, 76), _paint(dark));
        _text(canvas, '$i', Offset(x, 94), size: 14);
      }
    }
    if (data['item'] == 'pencil') {
      if (image != null) {
        final sourceCrop = mathsObjectCrop('pencil');
        final source = Rect.fromLTWH(
          sourceCrop.left * image!.width,
          sourceCrop.top * image!.height,
          sourceCrop.width * image!.width,
          sourceCrop.height * image!.height,
        );
        // Both visible ends align with the exact measurement endpoints.
        canvas.drawImageRect(
          image!,
          source,
          Rect.fromLTWH(16, 16, length, 40),
          Paint()..filterQuality = FilterQuality.high,
        );
        return;
      }
      final tip = math.min(12.0, length * .2);
      canvas.drawRect(Rect.fromLTWH(16, 24, length - tip, 20), _paint(blue));
      canvas.drawPath(
        Path()
          ..moveTo(16 + length - tip, 24)
          ..lineTo(16 + length, 34)
          ..lineTo(16 + length - tip, 44)
          ..close(),
        _paint(const Color(0xFFE6B746)),
      );
      return;
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(16, 24, length, 20),
        const Radius.circular(3),
      ),
      _paint(blue),
    );
  }

  void _fraction(Canvas canvas, Size size) {
    final circle = data['shape'] == 'circle';
    final square = data['shape'] == 'square';
    final height = size.height * .8;
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: math.min(size.width * .8, circle || square ? height : 210),
      height: circle || square ? math.min(size.width * .8, height) : height,
    );
    final parts = (data['parts'] as num? ?? 2).toInt();
    final shaded = (data['shaded'] as num? ?? 1).toInt();
    final split = data['equal'] == false ? .3 : 1 / math.max(1, parts);
    canvas.save();
    if (circle) {
      canvas.clipPath(Path()..addOval(rect));
    } else {
      canvas.clipRect(rect);
    }
    canvas.drawRect(rect, _material(const Color(0xFFFFF5DB), rect));
    if (data['orientation'] == 'diagonal') {
      if (shaded > 0) {
        canvas.drawPath(
          Path()
            ..moveTo(rect.left, rect.top)
            ..lineTo(rect.right, rect.bottom)
            ..lineTo(rect.left, rect.bottom)
            ..close(),
          _material(blue, rect),
        );
      }
      canvas.drawLine(rect.topLeft, rect.bottomRight, _paint(dark));
    } else if (circle && data['equal'] != false) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * shaded / math.max(1, parts),
        true,
        _material(blue, rect),
      );
      for (var i = 0; i < parts; i++) {
        final angle = -math.pi / 2 + 2 * math.pi * i / parts;
        canvas.drawLine(
          rect.center,
          rect.center +
              Offset(
                math.cos(angle) * rect.width / 2,
                math.sin(angle) * rect.height / 2,
              ),
          _paint(dark),
        );
      }
    } else {
      canvas.drawRect(
        Rect.fromLTWH(
          rect.left,
          rect.top,
          rect.width * split * shaded,
          rect.height,
        ),
        _material(blue, rect),
      );
      for (var i = 1; i < parts; i++) {
        final x =
            rect.left +
            rect.width * (data['equal'] == false ? split : i / parts);
        canvas.drawLine(
          Offset(x, rect.top),
          Offset(x, rect.bottom),
          _paint(dark),
        );
      }
    }
    canvas.restore();
    if (circle) {
      canvas.drawOval(rect, _paint(dark, stroke: true));
    } else {
      canvas.drawRect(rect, _paint(dark, stroke: true));
    }
  }

  void _shape(Canvas canvas, String shape, Rect r, Color color) {
    final fill = _material(color, r);
    final edge = _paint(dark, stroke: true);
    switch (shape) {
      case 'triangle':
      case 'cone':
        final path = Path()
          ..moveTo(r.center.dx, r.top)
          ..lineTo(r.right, r.bottom)
          ..lineTo(r.left, r.bottom)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, edge);
        if (shape == 'cone') {
          canvas.drawOval(
            Rect.fromLTWH(
              r.left,
              r.bottom - r.height * .16,
              r.width,
              r.height * .25,
            ),
            edge,
          );
        }
      case 'rectangle':
        final rect = Rect.fromCenter(
          center: r.center,
          width: r.width,
          height: r.height * .6,
        );
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, edge);
      case 'cube':
      case 'cuboid':
        final front = Rect.fromLTWH(
          r.left,
          r.top + r.height * .2,
          r.width * .75,
          r.height * (shape == 'cuboid' ? .45 : .75),
        );
        final depth = Offset(r.width * .22, -r.height * .2);
        final top = Path()
          ..moveTo(front.left, front.top)
          ..lineTo(front.left + depth.dx, front.top + depth.dy)
          ..lineTo(front.right + depth.dx, front.top + depth.dy)
          ..lineTo(front.right, front.top)
          ..close();
        final side = Path()
          ..moveTo(front.right, front.top)
          ..lineTo(front.right + depth.dx, front.top + depth.dy)
          ..lineTo(front.right + depth.dx, front.bottom + depth.dy)
          ..lineTo(front.right, front.bottom)
          ..close();
        canvas.drawPath(
          top,
          _material(Color.lerp(color, Colors.white, .35)!, r),
        );
        canvas.drawPath(side, _material(Color.lerp(color, dark, .2)!, r));
        canvas.drawRect(front, fill);
        canvas.drawPath(top, edge);
        canvas.drawPath(side, edge);
        canvas.drawRect(front, edge);
      case 'cylinder':
        final middle = Rect.fromLTWH(
          r.left,
          r.top + r.height * .15,
          r.width,
          r.height * .7,
        );
        canvas.drawRect(middle, fill);
        canvas.drawOval(
          Rect.fromLTWH(
            r.left,
            r.bottom - r.height * .3,
            r.width,
            r.height * .3,
          ),
          fill,
        );
        canvas.drawOval(
          Rect.fromLTWH(r.left, r.top, r.width, r.height * .3),
          _material(Color.lerp(color, Colors.white, .35)!, r),
        );
        canvas.drawOval(
          Rect.fromLTWH(r.left, r.top, r.width, r.height * .3),
          edge,
        );
        canvas.drawArc(
          Rect.fromLTWH(
            r.left,
            r.bottom - r.height * .3,
            r.width,
            r.height * .3,
          ),
          0,
          math.pi,
          false,
          edge,
        );
        canvas.drawLine(
          Offset(r.left, middle.top),
          Offset(r.left, middle.bottom),
          edge,
        );
        canvas.drawLine(
          Offset(r.right, middle.top),
          Offset(r.right, middle.bottom),
          edge,
        );
      case 'square':
        canvas.drawRect(r, fill);
        canvas.drawRect(r, edge);
      case 'pyramid':
        final apex = Offset(r.center.dx, r.top);
        final left = Offset(r.left, r.bottom - r.height * .15);
        final front = Offset(r.center.dx, r.bottom);
        final right = Offset(r.right, r.bottom - r.height * .15);
        final face = Path()
          ..moveTo(apex.dx, apex.dy)
          ..lineTo(left.dx, left.dy)
          ..lineTo(front.dx, front.dy)
          ..close();
        final side = Path()
          ..moveTo(apex.dx, apex.dy)
          ..lineTo(front.dx, front.dy)
          ..lineTo(right.dx, right.dy)
          ..close();
        canvas.drawPath(face, fill);
        canvas.drawPath(side, _material(Color.lerp(color, dark, .2)!, r));
        canvas.drawPath(face, edge);
        canvas.drawPath(side, edge);
      case 'oval':
        final oval = Rect.fromCenter(
          center: r.center,
          width: r.width,
          height: r.height * .6,
        );
        canvas.drawOval(oval, fill);
        canvas.drawOval(oval, edge);
      default:
        canvas.drawOval(r, fill);
        canvas.drawOval(r, edge);
        if (shape == 'sphere') {
          canvas.drawArc(
            Rect.fromCenter(
              center: r.center,
              width: r.width * .6,
              height: r.height,
            ),
            -math.pi / 2,
            math.pi,
            false,
            edge,
          );
          canvas.drawArc(
            Rect.fromCenter(
              center: r.center,
              width: r.width,
              height: r.height * .35,
            ),
            0,
            math.pi,
            false,
            edge,
          );
        }
    }
  }

  @override
  bool shouldRepaint(_MathsPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.image != image;
}

/// A Carroll diagram: one column per sorting rule. The cards sorted so far
/// appear in their column, and a tap on a column puts the chosen card there
/// (teacher review 5: "Sort the numbers into the Carroll diagram" showed no
/// diagram, only buttons).
class CarrollTable extends StatelessWidget {
  const CarrollTable({
    super.key,
    required this.data,
    this.columns,
    this.placed = const {},
    this.onColumn,
  });

  final Map<String, dynamic> data;

  /// Column IDs and headings; by default the headings in data['columns'].
  final List<({String id, String label})>? columns;

  /// Card labels already sorted, by column ID.
  final Map<String, List<String>> placed;
  final ValueChanged<String>? onColumn;

  @override
  Widget build(BuildContext context) {
    final cols =
        columns ??
        [
          for (final heading in data['columns'] as List? ?? const [])
            (id: '$heading', label: '$heading'),
        ];
    return Semantics(
      label: 'Carroll diagram',
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, column) in cols.indexed)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                  child: Material(
                    color: const Color(0xFFFFFAEE),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        color: Color(0xFFA47745),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: ValueKey('maths-carroll-${column.id}'),
                      onTap: onColumn == null
                          ? null
                          : () => onColumn!(column.id),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            color: i.isEven
                                ? const Color(0xFFF6D9A8)
                                : const Color(0xFFD8E8F4),
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              column.label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 64),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  for (final card in placed[column.id] ?? [])
                                    Chip(label: Text(card)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

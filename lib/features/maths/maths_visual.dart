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
        // A plus sign sits level with the groups beside it.
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final item in items)
            SizedBox(
              width:
                  (item['width'] as num?)?.toDouble() ??
                  (type == 'pattern'
                      ? 90
                      : item['type'] == 'ruler'
                      ? 220
                      : 150),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MathsVisual(
                    data: {
                      ...item,
                      // An answer card may ask for room for more counters, so
                      // every answer shows one counter size.
                      if (item['type'] == 'count')
                        'slots': math.max(
                          slots,
                          (item['slots'] as num? ?? 0).toInt(),
                        ),
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
    if (type == 'object') {
      // One or more real objects side by side: a bed, or an open and a
      // closed eye for a blink.
      final items = [
        for (final item in data['items'] as List? ?? [data['item']]) '$item',
      ];
      final height = (data['height'] as num?)?.toDouble() ?? 140;
      // A long thing (a string) may be wider than it is tall.
      final width = (data['artWidth'] as num?)?.toDouble();
      return Semantics(
        label: data['description'] as String? ?? items.join(' and '),
        image: true,
        child: SizedBox(
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final item in items)
                Flexible(
                  child: MathsArt(item, height: height, width: width),
                ),
            ],
          ),
        ),
      );
    }
    // A picture inside an answer may ask for less height.
    final height =
        (data['height'] as num?)?.toDouble() ??
        switch (type) {
          'numberLine' => 100.0,
          'robot' || 'grid' => 230.0,
          'place' => 180.0,
          'table' =>
            44.0 * ((data['rows'] as List? ?? const []).length + 1) + 8,
          'venn' => 190.0,
          'balance' => 184.0,
          'sky' => 140.0,
          'cycle' => 270.0,
          'podium' => 190.0,
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
        child: type == 'robot'
            ? RobotRoutes(data: data)
            : const {'count', 'clock', 'ruler', 'venn'}.contains(type)
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
    'grid' => 'A robot on a grid with lettered columns and numbered rows',
    'place' => 'A ball and a piece of furniture',
    'table' => 'A table of information',
    'cycle' => 'Names in order around a circle',
    'podium' => 'A winners podium with first, second and third places',
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

  /// A row's picture, shown only when every row has one (teacher review 7:
  /// only "car" had a picture in the walk, bus, car, bike chart).
  String? _categoryArt(String label) {
    final rows = (data['rows'] as List).cast<Map<String, dynamic>>();
    if (rows.any((row) => _art('${row['label']}') == null)) return null;
    return _art(label);
  }

  String? _art(String label) => switch (label.toLowerCase()) {
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
      case 'robot' || 'grid':
        _robot(canvas, size);
      case 'place':
        _place(canvas, size);
      case 'table':
        _table(canvas, size);
      case 'cycle':
        _cycle(canvas, size);
      case 'podium':
        _podium(canvas, size);
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

  Color get _color => _colorOf(data['color']);

  Color _colorOf(Object? name) => switch (name) {
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
    // Two equal rows, as in 'double 7' or 'half of 16'.
    final twoRows = data['arrangement'] == 'double';
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
    // A shared size for groups shown together (see MathsVisual.groups).
    final slots = (data['slots'] as num?)?.toInt() ?? 0;
    final cells = math.max(count, slots);
    final pairColumns = size.width >= 260
        ? 6
        : size.width >= 130
        ? 4
        : 2;
    // A picture may set its columns: six cups close together in two rows
    // of three, then spread out in one long row.
    final fixed = (data['columns'] as num?)?.toInt();
    final columns =
        fixed ??
        (frame
            ? 5
            : pairs
            ? math.min(pairColumns, math.max(2, (cells / 2).ceil() * 2))
            : twoRows
            ? math.max(1, (count / 2).ceil())
            : math.min(count, 5));
    final rows = (frameCells / columns).ceil();
    final pairGap = pairs ? 10.0 : 0.0;
    final frameGap = frame ? 8.0 : 0.0;
    final cellH = (size.height - frameGap * (frameCells / 10 - 1)) / rows;
    final spaces = frame || pairs || twoRows || fixed != null
        ? columns
        : math.max(columns, math.min(cells, 5));
    // Counters stay close together, in the middle: two dots no longer sit
    // at the far ends of a wide picture.
    final cellW = math.min(
      (size.width - pairGap * (columns / 2 - 1)) / spaces,
      cellH * 1.6,
    );
    final left =
        (size.width - columns * cellW - pairGap * (columns / 2 - 1)) / 2;
    final radius = math.min(36.0, math.min(cellW, cellH) * .36);
    // A counter given a colour is drawn in it: the art's own counter is
    // always coral, which made '4 blue dots and 3 orange dots' all orange.
    final tinted =
        data['color'] != null &&
        const {'dot', 'counter'}.contains(data['item'] ?? 'counter');
    final removed = (data['removed'] as num? ?? 0).toInt();
    // The counters after 'split' are drawn in a second colour: 6 and 4 in a
    // ten frame, or the two halves of a double.
    final split =
        (data['split'] as num?)?.toInt() ?? (twoRows ? columns : null);
    for (var i = 0; i < frameCells; i++) {
      var center = Offset(
        left + (i % columns + .5) * cellW + (i % columns ~/ 2) * pairGap,
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
      final colour = split != null && i >= split
          ? _colorOf(data['color2'] ?? 'blue')
          : _color;
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
        canvas.drawPath(path..close(), _paint(colour));
      } else if (data['item'] == 'cube' || data['item'] == 'square') {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          _paint(colour),
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
        canvas.drawPath(sock, _paint(colour));
        canvas.drawPath(sock, _paint(dark, stroke: true));
      } else {
        canvas.drawOval(rect, _paint(colour));
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
    // Label every 1, 2, 5 or 10 numbers, whichever leaves room to read.
    final stride = const [
      1,
      2,
      5,
      10,
    ].firstWhere((s) => span / range * s >= 30, orElse: () => 10);
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
          colors: switch (data['time']) {
            'night' => const [Color(0xFF0E1E45), Color(0xFF2D3F7A)],
            'evening' => const [Color(0xFF6B4C8C), Color(0xFFF2A65A)],
            'morning' => const [Color(0xFF9FD3F2), Color(0xFFFCE7C2)],
            _ => const [Color(0xFF7FC4F0), Color(0xFFD6EEFB)],
          },
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
      // The sun: low on the left in the morning, high at midday, lower on
      // the right in the afternoon, setting in the evening.
      final (x, y) = switch (data['time']) {
        'midday' => (.5, .3),
        'afternoon' => (.72, .42),
        'evening' => (.8, .82),
        _ => (.2, .7),
      };
      canvas.drawCircle(
        Offset(size.width * x, size.height * y),
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
  /// child has chosen (data['show']), each drawn from the same start. The
  /// robot drives along data['robotRoute'] (the route chosen last) as far
  /// as data['robotProgress'] (0 to 1), drawing that route as it goes
  /// (teacher review 6); without one it waits at the start.
  void _robot(Canvas canvas, Size size) {
    final cols = (data['cols'] as num? ?? 4).toInt();
    final rows = (data['rows'] as num? ?? 5).toInt();
    // A grid like the class book's: columns A, B, C... along the bottom and
    // rows 1, 2, 3... up the side, counted from the bottom.
    final labelled = data['labels'] == true;
    final pad = labelled ? 26.0 : 0.0;
    final cell = math.min(
      (size.width - 8 - pad) / cols,
      (size.height - 8 - pad) / rows,
    );
    final origin = Offset(
      (size.width - cell * cols + pad) / 2,
      (size.height - cell * rows - pad) / 2,
    );
    if (labelled) {
      for (var c = 0; c < cols; c++) {
        _text(
          canvas,
          String.fromCharCode(65 + c),
          origin + Offset((c + .5) * cell, rows * cell + 14),
          size: 18,
        );
      }
      for (var r = 0; r < rows; r++) {
        _text(
          canvas,
          '${rows - r}',
          origin + Offset(-14, (r + .5) * cell),
          size: 18,
        );
      }
    }
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
    // Where the robot is and which way it faces (in quarter turns clockwise
    // from up) at the start and after each instruction of a route.
    List<(Offset, double)> poses(String label) {
      var facing = first;
      var turned = first.toDouble();
      var at = start;
      final out = [(at, turned)];
      for (final move in (routes[label] as List? ?? const []).cast<String>()) {
        switch (move) {
          case 'R':
            facing = (facing + 1) % 4;
            turned += 1;
          case 'L':
            facing = (facing + 3) % 4;
            turned -= 1;
          case 'F':
            at += moves[facing];
          case 'B':
            at -= moves[facing];
        }
        out.add((at, turned));
      }
      return out;
    }

    final driving = data['robotRoute'] as String?;
    final progress = ((data['robotProgress'] as num?) ?? 1).toDouble().clamp(
      0.0,
      1.0,
    );
    var robot = (start, first.toDouble());
    const colours = [Color(0xFF2170B5), Color(0xFFE88A2E), Color(0xFF794D91)];
    for (final (i, label) in shown.indexed) {
      final steps = poses(label);
      var points = [for (final (at, _) in steps) at];
      if (label == driving) {
        // The part driven so far, ending where the robot is now.
        final t = progress * (steps.length - 1);
        final k = math.min(t.floor(), math.max(0, steps.length - 2));
        final f = steps.length < 2 ? 0.0 : t - k;
        final (a, turnA) = steps[k];
        final (b, turnB) = steps[math.min(k + 1, steps.length - 1)];
        robot = (Offset.lerp(a, b, f)!, turnA + (turnB - turnA) * f);
        points = [...points.take(k + 1), robot.$1];
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
      if (label != driving || progress == 1) {
        canvas.drawCircle(centre(points.last) + shift, 6, _paint(colour));
      }
    }
    // The star stays visible on top of routes that reach it, and beside the
    // robot once the robot has driven onto it.
    const gold = Color(0xFFE6B746);
    // A class-book grid has no star.
    final hasStar = data['star'] != null;
    final reached = hasStar && (robot.$1 - point('star')).distance < .05;
    if (hasStar && !reached) {
      _star(canvas, centre(point('star')), cell * .32, gold);
    }
    final home = centre(robot.$1);
    final body = Rect.fromCenter(
      center: home,
      width: cell * .58,
      height: cell * .58,
    );
    final rounded = RRect.fromRectAndRadius(body, Radius.circular(cell * .12));
    canvas.drawRRect(rounded, _material(const Color(0xFF6E8FA8), body));
    canvas.drawRRect(rounded, _paint(dark, stroke: true));
    final angle = robot.$2 * math.pi / 2;
    final ahead = Offset(math.sin(angle), -math.cos(angle));
    final across = Offset(-ahead.dy, ahead.dx);
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
    if (reached) {
      _star(canvas, home + Offset(cell * .3, -cell * .3), cell * .2, gold);
    }
  }

  /// A ball above, under, in front of or behind a table or a box (class
  /// book unit 8: words for position).
  void _place(Canvas canvas, Size size) {
    final place = '${data['place']}';
    final table = data['thing'] != 'box';
    final floor = size.height - 10;
    final w = math.min(size.width * .5, 220.0);
    final left = (size.width - w) / 2;
    final top = floor - size.height * .45;
    final ballRadius = math.min(size.width, size.height) * .13;
    final wood = const Color(0xFFB98552);
    void ball(Offset at, {double scale = 1}) {
      final rect = Rect.fromCircle(center: at, radius: ballRadius * scale);
      canvas.drawCircle(at, ballRadius * scale, _material(_color, rect));
      canvas.drawCircle(at, ballRadius * scale, _paint(dark, stroke: true));
    }

    void furniture() {
      if (table) {
        final board = Rect.fromLTWH(left, top, w, 14);
        canvas.drawRect(board, _material(wood, board));
        canvas.drawRect(board, _paint(dark, stroke: true));
        for (final x in [left + 10, left + w - 22]) {
          final leg = Rect.fromLTRB(x, top + 14, x + 12, floor);
          canvas.drawRect(leg, _paint(wood));
          canvas.drawRect(leg, _paint(dark, stroke: true));
        }
      } else {
        final box = Rect.fromLTRB(left, top, left + w, floor);
        canvas.drawRect(box, _material(const Color(0xFFD9A15B), box));
        canvas.drawRect(box, _paint(dark, stroke: true));
      }
    }

    canvas.drawLine(
      Offset(8, floor),
      Offset(size.width - 8, floor),
      _paint(dark, stroke: true),
    );
    switch (place) {
      case 'behind':
        // Drawn first, so the box hides its lower part and the edge of the
        // box cuts across it: it is behind, not on top.
        ball(Offset(left + w - ballRadius * .2, top + ballRadius * .35));
        furniture();
      case 'in front':
        furniture();
        ball(Offset(left + w * .5, floor - ballRadius * 1.3), scale: 1.3);
      case 'under':
        furniture();
        ball(Offset(left + w / 2, floor - ballRadius));
      case 'next to':
        furniture();
        ball(Offset(left + w + ballRadius * 2, floor - ballRadius));
      default: // above
        furniture();
        ball(Offset(left + w / 2, top - ballRadius * 2.4));
    }
  }

  /// A small table of information: a heading row, then one row per item.
  void _table(Canvas canvas, Size size) {
    final headings = (data['headings'] as List).cast<Object>();
    final rows = (data['rows'] as List).cast<List<Object?>>();
    const rowHeight = 44.0;
    final width = math.min(size.width - 8, 460.0);
    final left = (size.width - width) / 2;
    final columns = headings.length;
    for (var r = 0; r <= rows.length; r++) {
      final cells = r == 0 ? headings : rows[r - 1];
      for (var c = 0; c < columns; c++) {
        final rect = Rect.fromLTWH(
          left + c * width / columns,
          4 + r * rowHeight,
          width / columns,
          rowHeight,
        );
        canvas.drawRect(
          rect,
          _paint(r == 0 ? const Color(0xFFE3F0D6) : const Color(0xFFFFFAEE)),
        );
        canvas.drawRect(
          rect,
          _paint(const Color(0xFFA47745), stroke: true)..strokeWidth = 1.5,
        );
        _text(canvas, '${cells[c]}', rect.center, size: r == 0 ? 19 : 21);
      }
    }
  }

  /// A winners' podium: 2nd on the left, 1st in the middle and highest,
  /// 3rd on the right, each with the runner's name above.
  void _podium(Canvas canvas, Size size) {
    final places = (data['places'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    final width = math.min(size.width / 3, 160.0);
    final left = (size.width - width * 3) / 2;
    const order = [2, 1, 3];
    const heights = {1: .66, 2: .48, 3: .32};
    const colours = {
      1: Color(0xFFE6B746),
      2: Color(0xFFB9C3C9),
      3: Color(0xFFC98A4B),
    };
    for (final (i, place) in order.indexed) {
      final h = size.height * heights[place]!;
      final block = Rect.fromLTWH(left + i * width, size.height - h, width, h);
      canvas.drawRect(block, _material(colours[place]!, block));
      canvas.drawRect(block, _paint(dark, stroke: true));
      _text(canvas, '$place', block.center, size: 30);
      final runner = places.firstWhere(
        (p) => p['place'] == place,
        orElse: () => const {},
      );
      if (runner['name'] case final String name) {
        _text(canvas, name, Offset(block.center.dx, block.top - 20), size: 22);
      }
    }
  }

  /// Days of the week or months of the year around a circle, with arrows in
  /// order, so the last one leads back to the first ("the day after
  /// Saturday is Sunday").
  void _cycle(Canvas canvas, Size size) {
    final labels = (data['labels'] as List? ?? const []).cast<String>();
    if (labels.isEmpty) return;
    final centre = size.center(Offset.zero);
    final radius = math.min(size.width * .4, size.height * .4);
    final step = 2 * math.pi / labels.length;
    Offset at(int i, [double r = 1]) =>
        centre +
        Offset(
              math.cos(-math.pi / 2 + i * step),
              math.sin(-math.pi / 2 + i * step),
            ) *
            (radius * r);
    final arrow = _paint(const Color(0xFFA47745), stroke: true)
      ..strokeWidth = 2;
    for (var i = 0; i < labels.length; i++) {
      // A short clockwise arc from this label towards the next.
      final from = -math.pi / 2 + (i + .3) * step;
      final sweep = step * .4;
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: radius * .78),
        from,
        sweep,
        false,
        arrow,
      );
      final end = from + sweep;
      final tip =
          centre + Offset(math.cos(end), math.sin(end)) * (radius * .78);
      final along = Offset(-math.sin(end), math.cos(end));
      final across = Offset(math.cos(end), math.sin(end));
      canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(
            (tip - along * 7 + across * 4).dx,
            (tip - along * 7 + across * 4).dy,
          )
          ..lineTo(
            (tip - along * 7 - across * 4).dx,
            (tip - along * 7 - across * 4).dy,
          )
          ..close(),
        _paint(const Color(0xFFA47745)),
      );
    }
    final box = labels.length > 8 ? 50.0 : 58.0;
    for (final (i, label) in labels.indexed) {
      final rect = Rect.fromCenter(center: at(i), width: box, height: 32);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        _paint(i == 0 ? const Color(0xFFF6D9A8) : const Color(0xFFFFFAEE)),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        _paint(const Color(0xFFA47745), stroke: true)..strokeWidth = 1.5,
      );
      _text(canvas, label, rect.center, size: 16);
    }
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
      case 'pentagon' || 'hexagon':
        final sides = shape == 'pentagon' ? 5 : 6;
        final radius = r.shortestSide / 2;
        final path = Path();
        for (var i = 0; i < sides; i++) {
          final angle = -math.pi / 2 + i * 2 * math.pi / sides;
          final point =
              r.center + Offset(math.cos(angle), math.sin(angle)) * radius;
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, edge);
      case 'prism':
        // A triangular prism lying down, like a tent: two triangle ends
        // joined by rectangles.
        final depth = Offset(r.width * .55, -r.height * .22);
        final a = Offset(r.left, r.bottom);
        final b = Offset(r.left + r.width * .45, r.bottom);
        final c = Offset(r.left + r.width * .225, r.top + r.height * .38);
        Path poly(List<Offset> points) {
          final path = Path()..moveTo(points.first.dx, points.first.dy);
          for (final p in points.skip(1)) {
            path.lineTo(p.dx, p.dy);
          }
          return path..close();
        }

        final roof = poly([c, b, b + depth, c + depth]);
        final front = poly([a, b, c]);
        canvas.drawPath(roof, _material(Color.lerp(color, dark, .2)!, r));
        canvas.drawPath(roof, edge);
        canvas.drawPath(front, fill);
        canvas.drawPath(front, edge);
      case 'thermometer':
        final tube = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(r.center.dx, r.top + r.height * .42),
            width: r.width * .2,
            height: r.height * .8,
          ),
          Radius.circular(r.width * .1),
        );
        final bulb = Offset(r.center.dx, r.bottom - r.width * .17);
        canvas.drawRRect(tube, _paint(Colors.white));
        canvas.drawRRect(tube, edge);
        const red = Color(0xFFD0504B);
        canvas.drawRect(
          Rect.fromLTRB(
            r.center.dx - r.width * .05,
            r.top + r.height * .35,
            r.center.dx + r.width * .05,
            bulb.dy,
          ),
          _paint(red),
        );
        canvas.drawCircle(bulb, r.width * .17, _paint(red));
        canvas.drawCircle(bulb, r.width * .17, edge);
        for (var i = 0; i < 6; i++) {
          final y = r.top + r.height * (.12 + i * .11);
          canvas.drawLine(
            Offset(tube.right + 3, y),
            Offset(tube.right + r.width * .12, y),
            _paint(dark, stroke: true)..strokeWidth = 2,
          );
        }
      case 'measuringJug':
        final body = Path()
          ..moveTo(r.left + r.width * .18, r.top + r.height * .1)
          ..lineTo(r.left + r.width * .72, r.top + r.height * .1)
          ..lineTo(r.left + r.width * .68, r.bottom)
          ..lineTo(r.left + r.width * .22, r.bottom)
          ..close();
        canvas.save();
        canvas.clipPath(body);
        canvas.drawRect(
          Rect.fromLTRB(r.left, r.top + r.height * .45, r.right, r.bottom),
          _paint(const Color(0xFF8CC8EE)),
        );
        canvas.restore();
        canvas.drawPath(body, edge);
        // The handle and the scale that make it a measuring jug.
        canvas.drawArc(
          Rect.fromLTWH(
            r.left + r.width * .62,
            r.top + r.height * .25,
            r.width * .3,
            r.height * .45,
          ),
          -math.pi / 2,
          math.pi,
          false,
          _paint(dark, stroke: true)..strokeWidth = 5,
        );
        for (var i = 0; i < 4; i++) {
          final y = r.top + r.height * (.25 + i * .18);
          canvas.drawLine(
            Offset(r.left + r.width * .24, y),
            Offset(r.left + r.width * .36, y),
            _paint(dark, stroke: true)..strokeWidth = 2,
          );
        }
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
      case 'car':
        // A toy car seen from the side, in the colour the question names.
        final body = RRect.fromRectAndCorners(
          Rect.fromLTRB(
            r.left,
            r.top + r.height * .38,
            r.right,
            r.bottom - r.height * .2,
          ),
          topLeft: Radius.circular(r.height * .12),
          topRight: Radius.circular(r.height * .2),
          bottomLeft: Radius.circular(r.height * .06),
          bottomRight: Radius.circular(r.height * .06),
        );
        final roof = Path()
          ..moveTo(r.left + r.width * .22, r.top + r.height * .4)
          ..lineTo(r.left + r.width * .34, r.top + r.height * .14)
          ..lineTo(r.left + r.width * .66, r.top + r.height * .14)
          ..lineTo(r.left + r.width * .8, r.top + r.height * .4)
          ..close();
        canvas.drawPath(roof, fill);
        canvas.drawPath(roof, edge);
        canvas.drawPath(
          Path()
            ..moveTo(r.left + r.width * .3, r.top + r.height * .37)
            ..lineTo(r.left + r.width * .37, r.top + r.height * .2)
            ..lineTo(r.left + r.width * .63, r.top + r.height * .2)
            ..lineTo(r.left + r.width * .72, r.top + r.height * .37)
            ..close(),
          _paint(const Color(0xFFD8EEFB)),
        );
        canvas.drawRRect(body, fill);
        canvas.drawRRect(body, edge);
        for (final x in [.26, .74]) {
          final wheel = Offset(r.left + r.width * x, r.bottom - r.height * .2);
          canvas.drawCircle(wheel, r.height * .15, _paint(dark));
          canvas.drawCircle(
            wheel,
            r.height * .06,
            _paint(const Color(0xFFB9C3C9)),
          );
        }
      case 'house':
        // A house built from flat shapes: a square wall, a triangle roof, a
        // rectangle door, two square windows and two triangle flags, so the
        // child counts 3 triangles (the book's "draw a house" question).
        final wall = Rect.fromLTRB(
          r.left + r.width * .2,
          r.top + r.height * .45,
          r.right - r.width * .2,
          r.bottom,
        );
        void draw(Path path, Color c) {
          canvas.drawPath(path, _material(c, path.getBounds()));
          canvas.drawPath(path, edge);
        }

        Path triangle(Offset top, double w, double h) => Path()
          ..moveTo(top.dx, top.dy)
          ..lineTo(top.dx + w / 2, top.dy + h)
          ..lineTo(top.dx - w / 2, top.dy + h)
          ..close();
        draw(Path()..addRect(wall), const Color(0xFFF4D9A6));
        draw(
          triangle(
            Offset(r.center.dx, r.top + r.height * .18),
            wall.width * 1.3,
            r.height * .27,
          ),
          const Color(0xFFD9534F),
        );
        for (final x in [r.left + r.width * .07, r.right - r.width * .07]) {
          // A garden flag on a pole beside the house, pointing towards it.
          final side = x < r.center.dx ? 1.0 : -1.0;
          final top = Offset(x, r.top + r.height * .08);
          canvas.drawLine(
            top,
            Offset(x, r.bottom),
            _paint(dark, stroke: true)..strokeWidth = 3,
          );
          draw(
            Path()
              ..moveTo(top.dx, top.dy)
              ..lineTo(top.dx + side * r.width * .11, top.dy + r.height * .08)
              ..lineTo(top.dx, top.dy + r.height * .16)
              ..close(),
            const Color(0xFFE6B746),
          );
        }
        draw(
          Path()..addRect(
            Rect.fromLTWH(
              wall.center.dx - wall.width * .11,
              wall.bottom - wall.height * .48,
              wall.width * .22,
              wall.height * .48,
            ),
          ),
          const Color(0xFF8A5A3B),
        );
        for (final x in [.24, .76]) {
          draw(
            Path()..addRect(
              Rect.fromCenter(
                center: Offset(
                  wall.left + wall.width * x,
                  wall.top + wall.height * .35,
                ),
                width: wall.width * .2,
                height: wall.width * .2,
              ),
            ),
            const Color(0xFFBFE3F5),
          );
        }
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
    // A Carroll diagram in a picture shows the cards already sorted.
    final cards = placed.isNotEmpty
        ? placed
        : {
            for (final MapEntry(:key, :value)
                in (data['placed'] as Map? ?? const {}).entries)
              '$key': [for (final card in value as List) '$card'],
          };
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
                                  for (final card in cards[column.id] ?? [])
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

/// The robot grid: when the child chooses a route, the robot drives it, one
/// instruction at a time, before anything is checked (teacher review 6). A
/// route chosen earlier (a resumed question) is shown already driven.
class RobotRoutes extends StatefulWidget {
  const RobotRoutes({super.key, required this.data});
  final Map<String, dynamic> data;

  @override
  State<RobotRoutes> createState() => _RobotRoutesState();
}

class _RobotRoutesState extends State<RobotRoutes>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drive = AnimationController(
    vsync: this,
    value: 1,
  );
  String? _route;

  List<String> _shown(Map<String, dynamic> data) =>
      (data['show'] as List? ?? const []).cast<String>();

  @override
  void initState() {
    super.initState();
    _route = _shown(widget.data).lastOrNull;
  }

  @override
  void didUpdateWidget(RobotRoutes old) {
    super.didUpdateWidget(old);
    final before = _shown(old.data);
    final now = _shown(widget.data);
    final added = [
      for (final label in now)
        if (!before.contains(label)) label,
    ];
    if (added.isNotEmpty) {
      _route = added.last;
      final steps =
          ((widget.data['routes'] as Map?)?[_route] as List?)?.length ?? 1;
      _drive.duration = Duration(milliseconds: 500 * math.max(1, steps));
      if (MediaQuery.disableAnimationsOf(context)) {
        _drive.value = 1;
      } else {
        _drive.forward(from: 0);
      }
    } else if (!now.contains(_route)) {
      _route = now.lastOrNull;
      _drive.value = 1;
    }
  }

  @override
  void dispose() {
    _drive.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _drive,
    builder: (context, _) => CustomPaint(
      painter: _MathsPainter({
        ...widget.data,
        'robotRoute': ?_route,
        'robotProgress': _drive.value,
      }),
    ),
  );
}

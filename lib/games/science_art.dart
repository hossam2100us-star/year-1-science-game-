import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Original, code-drawn illustrations shared by scenes and accessible picture controls.
void drawPicture(
  Canvas canvas,
  Rect rect,
  String art, {
  double motion = 0,
  bool girl = false,
}) {
  canvas.save();
  canvas.translate(rect.left, rect.top);
  canvas.scale(rect.width / 100, rect.height / 100);
  final p = Paint()..strokeCap = StrokeCap.round;
  const ink = Color(0xFF223D50),
      green = Color(0xFF3E9B5A),
      blue = Color(0xFF2170B5),
      brown = Color(0xFF99663F);
  void oval(double x, double y, double w, double h, Color color) {
    canvas.drawOval(
      Rect.fromLTWH(x, y, w, h),
      p
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  void box(
    double x,
    double y,
    double w,
    double h,
    Color color, [
    double radius = 5,
  ]) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        Radius.circular(radius),
      ),
      p
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  void line(
    double x,
    double y,
    double xx,
    double yy,
    Color color, [
    double width = 5,
  ]) {
    canvas.drawLine(
      Offset(x, y),
      Offset(xx, yy),
      p
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  void path(List<Offset> points, Color color) {
    final shape = Path()..moveTo(points.first.dx, points.first.dy);
    for (final v in points.skip(1)) {
      shape.lineTo(v.dx, v.dy);
    }
    shape.close();
    canvas.drawPath(
      shape,
      p
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  final id = art.toLowerCase().replaceAll(' ', '_');
  if ([
    'tree',
    'mint_plant',
    'plant',
    'flower',
    'dandelion',
    'grows',
    'growing',
    'makes_seeds',
    'healthy',
    'green_and_strong',
    'green',
    'bean_8',
    'light',
  ].contains(id)) {
    if (id == 'tree') {
      box(43, 44, 14, 48, brown);
      oval(15, 12, 70, 60, green);
      oval(27, 0, 47, 64, green);
    } else {
      if (id != 'flower') box(23, 78, 54, 18, const Color(0xFFD79B6C));
      line(50, 82, 50, 25, green, 7);
      oval(19, 47, 31, 15, green);
      oval(50, 32, 30, 17, green);
      for (var i = 0; i < 6; i++) {
        final a = i * math.pi / 3;
        oval(
          40 + 14 * math.cos(a),
          10 + 14 * math.sin(a),
          20,
          20,
          const Color(0xFFF4BF56),
        );
      }
      oval(42, 12, 16, 16, brown);
    }
  } else if (['root', 'roots', 'bean_4'].contains(id)) {
    line(50, 8, 50, 88, brown, 6);
    for (var i = 0; i < 3; i++) {
      line(50, 32 + i * 17, 22 - i * 3, 43 + i * 17, brown, 4);
      line(50, 34 + i * 17, 78 + i * 3, 49 + i * 17, brown, 4);
    }
  } else if ([
    'stem',
    'celery',
    'sugar_cane',
    'bean_7',
    'thin_floppy_stem',
    'thick_stem',
  ].contains(id)) {
    line(50, 88, 50, 15, green, 12);
    line(50, 45, 30, 26, green, 7);
    line(50, 57, 74, 36, green, 7);
  } else if ([
    'leaf',
    'lettuce',
    'mint',
    'parsley',
    'leaves_make_food',
  ].contains(id)) {
    oval(19, 10, 63, 78, green);
    line(46, 92, 56, 26, const Color(0xFFCAE3A3), 4);
    for (var i = 0; i < 3; i++) {
      line(50, 36 + i * 15, 28, 28 + i * 15, const Color(0xFFCAE3A3), 3);
    }
  } else if (['carrot', 'radish'].contains(id)) {
    path([
      const Offset(26, 28),
      const Offset(77, 32),
      const Offset(39, 94),
    ], id == 'carrot' ? const Color(0xFFE88A2E) : const Color(0xFFAE5071));
    line(48, 32, 35, 8, green, 7);
    line(50, 31, 62, 6, green, 7);
  } else if (['broccoli', 'cauliflower'].contains(id)) {
    line(49, 90, 49, 45, green, 16);
    for (final pt in [
      const Offset(30, 30),
      const Offset(55, 24),
      const Offset(70, 40),
      const Offset(39, 49),
    ]) {
      oval(
        pt.dx - 18,
        pt.dy - 18,
        38,
        38,
        id == 'broccoli' ? green : const Color(0xFFF3E8BC),
      );
    }
  } else if ([
    'bean_1',
    'seed',
    'beans',
    'rice',
    'lentils',
    'peas',
  ].contains(id)) {
    for (var i = 0; i < (id == 'bean_1' ? 1 : 5); i++) {
      oval(
        18 + (i % 3) * 24,
        25 + (i ~/ 3) * 29,
        20,
        28,
        id == 'peas' ? green : const Color(0xFFD5AD72),
      );
    }
  } else if ([
    'cat',
    'soft_cat',
    'lizard',
    'giraffe',
    'worm',
    'fly',
    'bird',
    'baby_bird',
    'mosquito',
  ].contains(id)) {
    if (id == 'worm') {
      for (var i = 0; i < 6; i++) {
        oval(
          5 + i * 12,
          45 + math.sin(i + motion) * 8,
          23,
          25,
          const Color(0xFFC58B72),
        );
      }
      oval(77, 45, 4, 4, ink);
    } else if (id == 'fly' || id == 'mosquito') {
      oval(8, 12, 40, 40, const Color(0xFFB4DCE7));
      oval(52, 12, 40, 40, const Color(0xFFB4DCE7));
      oval(37, 27, 26, 52, ink);
      line(33, 49, 18, 64, ink, 3);
      line(65, 49, 82, 64, ink, 3);
    } else if (id == 'bird' || id == 'baby_bird') {
      oval(18, 30, 59, 50, const Color(0xFF69AACC));
      oval(47, 19, 35, 32, const Color(0xFF69AACC));
      path([
        const Offset(80, 30),
        const Offset(97, 37),
        const Offset(80, 45),
      ], const Color(0xFFEAB14C));
      oval(68, 28, 5, 5, ink);
      oval(22, 40, 34, 20, blue);
      line(41, 78, 36, 92, brown, 3);
      line(60, 78, 65, 92, brown, 3);
    } else if (id == 'giraffe') {
      box(22, 50, 47, 25, const Color(0xFFE3B152));
      box(60, 16, 14, 47, const Color(0xFFE3B152));
      oval(55, 9, 33, 22, const Color(0xFFE3B152));
      for (final x in [27.0, 61.0]) {
        line(x, 70, x, 93, brown, 6);
      }
      for (final pt in [
        const Offset(36, 57),
        const Offset(54, 60),
        const Offset(66, 35),
      ]) {
        oval(pt.dx, pt.dy, 8, 8, brown);
      }
      oval(76, 16, 4, 4, ink);
    } else {
      final fur = id == 'lizard' ? green : const Color(0xFFC99061);
      oval(20, 47, 58, 32, fur);
      oval(53, 23, 32, 35, fur);
      if (id != 'lizard') {
        path([
          const Offset(55, 29),
          const Offset(54, 13),
          const Offset(68, 25),
        ], fur);
        path([
          const Offset(72, 25),
          const Offset(86, 14),
          const Offset(84, 34),
        ], fur);
      }
      line(23, 57, 8, 34, fur, 9);
      line(32, 71, 29, 91, fur, 8);
      line(65, 71, 69, 91, fur, 8);
      oval(62, 34, 4, 5, ink);
      oval(75, 34, 4, 5, ink);
    }
  } else if ([
    'human',
    'person',
    'baby',
    'doll',
    'body',
    'boy',
    'girl',
  ].contains(id)) {
    drawBody(
      canvas,
      const Rect.fromLTWH(0, 0, 100, 100),
      girl: girl || id == 'girl',
    );
  } else if ([
    'head',
    'neck',
    'chin',
    'shoulder',
    'arm',
    'elbow',
    'wrist',
    'hand',
    'fingers',
    'leg',
    'knee',
    'ankle',
    'foot',
  ].contains(id)) {
    drawBody(canvas, const Rect.fromLTWH(0, 0, 100, 100), girl: girl);
    final spot = bodyAnchor(id);
    canvas.drawCircle(
      Offset(spot.dx * 100, spot.dy * 100),
      9,
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0xFFE88A2E),
    );
  } else if (['eyes', 'eye', 'sight', 'eyebrow', 'eyelash', 'eyelid', 'checks_eyes_and_gives_glasses'].contains(id)) {
    oval(9, 27, 82, 44, Colors.white);
    oval(34, 30, 32, 38, blue);
    oval(43, 38, 14, 22, ink);
    line(15, 18, 83, 14, brown, 7);
    for (var i = 0; i < 5; i++) {
      line(20 + i * 15, 28, 16 + i * 15, 18, ink, 3);
    }
    if (id == 'eyelid') box(12, 29, 76, 18, const Color(0xFFE9B899), 9);
    if (id == 'checks_eyes_and_gives_glasses') {
      canvas.drawCircle(
        const Offset(28, 54),
        23,
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = blue,
      );
      canvas.drawCircle(const Offset(75, 54), 23, p);
      line(50, 52, 54, 52, blue, 4);
    }
  } else if (['ear', 'ears', 'hearing', 'hear_music', 'sound', 'loud'].contains(id)) {
    oval(25, 8, 52, 77, const Color(0xFFE8B390));
    canvas.drawArc(
      const Rect.fromLTWH(38, 22, 25, 38),
      -1,
      4.8,
      false,
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = brown,
    );
  } else if (['nose', 'smell', 'smell_flowers'].contains(id)) {
    path([
      const Offset(50, 15),
      const Offset(26, 65),
      const Offset(66, 73),
    ], const Color(0xFFE7B18D));
    oval(24, 59, 25, 18, const Color(0xFFD59A76));
    oval(59, 60, 21, 18, const Color(0xFFD59A76));
  } else if (['tongue', 'taste', 'taste_buds', 'sweet', 'sweet_honey'].contains(id)) {
    oval(11, 26, 78, 48, ink);
    oval(28, 36, 44, 52, const Color(0xFFD78791));
    for (var i = 0; i < 8; i++) {
      oval(
        34 + (i % 3) * 10,
        42 + (i ~/ 3) * 11,
        4,
        4,
        const Color(0xFF994C67),
      );
    }
  } else if (['skin', 'touch', 'handful'].contains(id)) {
    oval(22, 39, 53, 45, const Color(0xFFE8B390));
    for (var i = 0; i < 4; i++) {
      box(23 + i * 13, 12 + (i == 0 ? 10 : 0), 11, 45, const Color(0xFFE8B390));
    }
    box(66, 42, 26, 12, const Color(0xFFE8B390));
  } else if (['car', 'traffic', 'moves'].contains(id)) {
    box(7, 42, 85, 34, blue, 12);
    path([
      const Offset(22, 44),
      const Offset(34, 18),
      const Offset(67, 18),
      const Offset(83, 44),
    ], blue);
    box(36, 24, 27, 18, const Color(0xFFDCF2EF), 3);
    oval(19, 65, 21, 21, ink);
    oval(64, 65, 21, 21, ink);
  } else if (['chair', 'wooden_chair', 'table'].contains(id)) {
    box(20, 48, 62, 10, brown);
    line(27, 58, 27, 91, brown, 8);
    line(75, 58, 75, 91, brown, 8);
    if (id != 'table') {
      box(19, 12, 13, 44, brown);
      box(20, 15, 55, 20, brown);
    }
  } else if (['mug', 'kettle', 'water', 'drinks_water', 'water_and_light'].contains(id)) {
    if (id == 'water' || id == 'drinks_water') {
      path([
        const Offset(50, 6),
        const Offset(21, 58),
        const Offset(30, 82),
        const Offset(52, 91),
        const Offset(77, 74),
        const Offset(81, 54),
      ], const Color(0xFF4A9FE0));
    } else {
      box(20, 23, 49, 61, const Color(0xFFE9BA68), 10);
      canvas.drawOval(
        const Rect.fromLTWH(58, 34, 31, 34),
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..color = const Color(0xFFE9BA68),
      );
      if (id == 'kettle') {
        path([
          const Offset(22, 45),
          const Offset(4, 27),
          const Offset(8, 62),
          const Offset(27, 70),
        ], const Color(0xFFE9BA68));
      }
    }
  } else if (['cloud', 'air', 'wind', 'breathe', 'breathes'].contains(id)) {
    for (final r in [
      const Rect.fromLTWH(7, 42, 45, 32),
      const Rect.fromLTWH(28, 20, 43, 53),
      const Rect.fromLTWH(56, 39, 37, 36),
    ]) {
      canvas.drawOval(
        r,
        p
          ..style = PaintingStyle.fill
          ..color = const Color(0xFFE9F2F8),
      );
    }
    if (id != 'cloud') line(20, 82, 79, 82, blue, 3);
  } else if (['egg_with_a_growing_chick', 'egg'].contains(id)) {
    oval(22, 4, 57, 86, const Color(0xFFEBDBB9));
    oval(28, 15, 45, 66, Colors.white);
    oval(36, 44, 34, 29, const Color(0xFFF3CB67));
    oval(46, 32, 25, 24, const Color(0xFFF3CB67));
    oval(61, 39, 4, 4, ink);
  } else if (['bread', 'apple', 'lemon', 'watermelon', 'food', 'eats', 'eating'].contains(id)) {
    if (id == 'bread') {
      box(17, 22, 65, 61, const Color(0xFFDCAA67), 23);
    } else if (id == 'watermelon') {
      oval(8, 22, 84, 61, green);
      oval(14, 28, 72, 48, const Color(0xFFD88983));
    } else {
      oval(
        17,
        27,
        66,
        61,
        id == 'lemon' ? const Color(0xFFEAC857) : const Color(0xFFCF7463),
      );
      line(49, 32, 55, 12, brown, 5);
      oval(53, 13, 25, 12, green);
    }
  } else if (['rock', 'stone', 'soil', 'dust'].contains(id)) {
    path([
      const Offset(14, 71),
      const Offset(23, 36),
      const Offset(58, 21),
      const Offset(88, 59),
      const Offset(74, 84),
      const Offset(31, 86),
    ], const Color(0xFF9CA5A5));
  } else if (['pale_and_floppy', 'pale_yellow', 'dry_and_drooping', 'not_healthy', 'light_result'].contains(id)) {
    box(24, 78, 53, 18, const Color(0xFFD79B6C));
    line(50, 78, 59, 24, const Color(0xFFBAAF67), 5);
    line(59, 24, 78, 46, const Color(0xFFBAAF67), 5);
    oval(56, 38, 22, 13, const Color(0xFFDAD298));
  } else if (['sunlight', 'sun', 'bright'].contains(id)) {
    oval(26, 26, 48, 48, const Color(0xFFEAC35B));
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      line(
        50 + 31 * math.cos(a),
        50 + 31 * math.sin(a),
        50 + 43 * math.cos(a),
        50 + 43 * math.sin(a),
        const Color(0xFFEAC35B),
        5,
      );
    }
  } else if (['yes', 'true', 'alive'].contains(id)) {
    line(22, 51, 42, 72, green, 10);
    line(42, 72, 81, 25, green, 10);
  } else if (['no', 'false', 'not_alive'].contains(id)) {
    canvas.drawCircle(
      const Offset(50, 50),
      32,
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = blue,
    );
    line(30, 50, 70, 50, blue, 6);
  } else {
    final icons = <String, IconData>{
      'toy': Icons.toys_rounded,
      'toys': Icons.toys_rounded,
      'book': Icons.menu_book_rounded,
      'paper': Icons.description_rounded,
      'spoon': Icons.restaurant_rounded,
      'made_in_a_factory': Icons.factory_rounded,
      'being_made_in_a_factory': Icons.factory_rounded,
      'three': Icons.looks_3_rounded,
      'five': Icons.looks_5_rounded,
      'ten': Icons.format_list_numbered_rounded,
      'traffic_light': Icons.traffic_rounded,
      'teeth': Icons.sentiment_satisfied_rounded,
      'hair': Icons.face_rounded,
      'cuts_hair': Icons.content_cut_rounded,
      'looks_after_teeth': Icons.sentiment_satisfied_rounded,
      'david': Icons.pan_tool_rounded,
      'zara': Icons.pan_tool_rounded,
      'jack': Icons.pan_tool_rounded,
      'grows_bigger': Icons.open_in_full_rounded,
      'grown': Icons.open_in_full_rounded,
      'gets_smaller': Icons.close_fullscreen_rounded,
      'stays_the_same_size': Icons.drag_handle_rounded,
      'around_the_cage': Icons.home_rounded,
      'when_hungry': Icons.restaurant_rounded,
      'air_through_its_beak': Icons.air_rounded,
      'baby_becomes_bigger': Icons.open_in_full_rounded,
      'holds_the_plant_up': Icons.height_rounded,
      'catches_sunlight': Icons.wb_sunny_rounded,
      'see_birds': Icons.visibility_rounded,
    };
    final icon = icons[id] ?? Icons.auto_awesome_rounded;
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          fontSize: 72,
          color: blue,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, const Offset(14, 12));
  }
  canvas.restore();
}

Offset bodyAnchor(String id) => switch (id) {
  'head' => const Offset(.5, .12),
  'neck' => const Offset(.5, .27),
  'chin' => const Offset(.5, .22),
  'shoulder' => const Offset(.35, .32),
  'arm' => const Offset(.28, .40),
  'elbow' => const Offset(.22, .48),
  'wrist' => const Offset(.19, .57),
  'hand' => const Offset(.17, .63),
  'fingers' => const Offset(.15, .68),
  'leg' => const Offset(.42, .71),
  'knee' => const Offset(.4, .78),
  'ankle' => const Offset(.39, .91),
  'foot' => const Offset(.34, .95),
  'eyebrow' => const Offset(.5, .14),
  'eyelash' => const Offset(.3, .26),
  'eyelid' => const Offset(.2, .40),
  _ => const Offset(.5, .5),
};
void drawBody(Canvas canvas, Rect rect, {bool girl = false}) {
  canvas.save();
  canvas.translate(rect.left, rect.top);
  canvas.scale(rect.width / 100, rect.height / 100);
  final p = Paint()..strokeCap = StrokeCap.round;
  const skin = Color(0xFFE6B492), ink = Color(0xFF223D50);
  void line(Offset a, Offset b, Color c, double w) {
    canvas.drawLine(
      a,
      b,
      p
        ..color = c
        ..strokeWidth = w
        ..style = PaintingStyle.stroke,
    );
  }

  line(const Offset(50, 25), const Offset(50, 36), skin, 10);
  line(const Offset(36, 34), const Offset(22, 48), skin, 10);
  line(const Offset(22, 48), const Offset(16, 66), skin, 9);
  line(const Offset(64, 34), const Offset(78, 48), skin, 10);
  line(const Offset(78, 48), const Offset(84, 66), skin, 9);
  line(const Offset(43, 60), const Offset(40, 92), const Color(0xFF396F99), 11);
  line(const Offset(57, 60), const Offset(61, 92), const Color(0xFF396F99), 11);
  line(const Offset(40, 95), const Offset(30, 95), ink, 9);
  line(const Offset(61, 95), const Offset(71, 95), ink, 9);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(34, 30, 32, 34),
      const Radius.circular(9),
    ),
    p
      ..style = PaintingStyle.fill
      ..color = (girl ? const Color(0xFF94639E) : const Color(0xFF4A9FE0)),
  );
  canvas.drawOval(const Rect.fromLTWH(35, 1, 30, 26), p..color = skin);
  canvas.drawArc(
    const Rect.fromLTWH(34, 0, 32, 26),
    math.pi,
    math.pi,
    false,
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = const Color(0xFF755037),
  );
  for (final x in [44.0, 56.0]) {
    canvas.drawCircle(
      Offset(x, 12),
      1.7,
      p
        ..style = PaintingStyle.fill
        ..color = ink,
    );
  }
  canvas.drawArc(
    const Rect.fromLTWH(44, 14, 12, 7),
    0,
    math.pi,
    false,
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = ink,
  );
  canvas.restore();
}

class SciencePicture extends StatelessWidget {
  const SciencePicture({super.key, required this.art, this.size = 80});
  final String art;
  final double size;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _PicturePainter(art));
}

class _PicturePainter extends CustomPainter {
  _PicturePainter(this.art);
  final String art;
  @override
  void paint(Canvas c, Size s) => drawPicture(c, Offset.zero & s, art);
  @override
  bool shouldRepaint(covariant _PicturePainter old) => old.art != art;
}

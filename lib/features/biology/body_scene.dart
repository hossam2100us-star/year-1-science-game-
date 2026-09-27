import 'package:flutter/material.dart';

import '../../content/lesson.dart';

/// Shared artwork coordinates keep the picture and its touch targets aligned.
const explorerAnchors = <String, Offset>{
  'head': Offset(.50, .10),
  'chin': Offset(.50, .235),
  'neck': Offset(.50, .29),
  'shoulder': Offset(.365, .335),
  'arm': Offset(.285, .39),
  'elbow': Offset(.245, .46),
  'wrist': Offset(.18, .555),
  'hand': Offset(.155, .604),
  'fingers': Offset(.135, .66),
  'leg': Offset(.415, .68),
  'knee': Offset(.405, .775),
  'ankle': Offset(.39, .89),
  'foot': Offset(.36, .952),
  'eyes': Offset(.455, .16),
  'ears': Offset(.65, .175),
  'nose': Offset(.50, .187),
  'tongue': Offset(.50, .215),
  'skin': Offset(.245, .46),
};
const eyeAnchors = <String, Offset>{
  'eyebrow': Offset(.49, .145),
  'eyelash': Offset(.80, .44),
  'eyelid': Offset(.28, .46),
};

class BodyScene extends StatelessWidget {
  const BodyScene({
    super.key,
    required this.step,
    required this.selected,
    required this.placements,
    required this.done,
    required this.girl,
    required this.onItem,
    required this.onPlace,
  });
  final LessonStep step;
  final Set<String> selected;
  final Map<String, String> placements;
  final bool done, girl;
  final ValueChanged<String> onItem;
  final void Function(String, String) onPlace;
  bool get diagram => step.kind == 'label-diagram';
  bool get eye => step.scene == 'eye';
  List<PictureItem> get spots => diagram ? step.targets : step.options;
  Rect get camera {
    if (eye) return const Rect.fromLTWH(0, 0, 1, 1);
    if (step.kind == 'story' && step.options.length > 1)
      return const Rect.fromLTWH(.30, .10, .40, .18);
    if (!diagram && !step.isOrder) return const Rect.fromLTWH(0, 0, 1, 1);
    final id = diagram ? step.options.first.id : 'arm';
    if (['head', 'neck', 'chin'].contains(id))
      return const Rect.fromLTWH(.23, 0, .54, .33);
    if (['shoulder', 'arm', 'elbow'].contains(id) || step.isOrder)
      return const Rect.fromLTWH(.015, .27, .49, .45);
    if (['wrist', 'hand', 'fingers'].contains(id))
      return const Rect.fromLTWH(.02, .50, .35, .23);
    return const Rect.fromLTWH(.22, .59, .55, .41);
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (diagram)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Draggable<String>(
            data: step.options.first.id,
            maxSimultaneousDrags: done ? 0 : 1,
            feedback: Material(
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  step.options.first.label,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            child: Chip(
              avatar: const Icon(Icons.touch_app),
              label: Text(
                step.options.first.label,
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
        ),
      ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: LayoutBuilder(
          builder: (context, box) {
            final height = diagram || step.isOrder ? 390.0 : 560.0;
            final size = Size(box.maxWidth, height);
            final canvasSize = eye
                ? const Size(600, 400)
                : const Size(400, 600);
            final crop = Rect.fromLTWH(
              camera.left * canvasSize.width,
              camera.top * canvasSize.height,
              camera.width * canvasSize.width,
              camera.height * canvasSize.height,
            );
            final fit = applyBoxFit(BoxFit.contain, crop.size, size);
            final dest = Alignment.center.inscribe(
              fit.destination,
              Offset.zero & size,
            );
            Offset point(String id) {
              final a = (eye ? eyeAnchors : explorerAnchors)[id]!;
              return Offset(
                dest.left +
                    (a.dx * canvasSize.width - crop.left) *
                        dest.width /
                        crop.width,
                dest.top +
                    (a.dy * canvasSize.height - crop.top) *
                        dest.height /
                        crop.height,
              );
            }

            return SizedBox(
              height: height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: ExplorerPainter(
                        girl: girl,
                        eye: eye,
                        crop: crop,
                      ),
                    ),
                  ),
                  for (var i = 0; i < spots.length; i++)
                    if ((eye ? eyeAnchors : explorerAnchors).containsKey(
                      spots[i].id,
                    ))
                      Positioned.fromRect(
                        rect: Rect.fromCenter(
                          center: point(spots[i].id),
                          width: 64,
                          height: 64,
                        ),
                        child: DragTarget<String>(
                          onWillAcceptWithDetails: (d) =>
                              diagram &&
                              !done &&
                              d.data == step.options.first.id,
                          onAcceptWithDetails: (d) =>
                              onPlace(d.data, spots[i].id),
                          builder: (context, candidate, rejected) => Semantics(
                            label: diagram && !done
                                ? '${step.json['spotLabel']} ${i + 1}'
                                : spots[i].label,
                            button: true,
                            child: InkWell(
                              key: ValueKey('body-spot-${spots[i].id}'),
                              onTap: done
                                  ? null
                                  : () => diagram
                                        ? onPlace(
                                            step.options.first.id,
                                            spots[i].id,
                                          )
                                        : onItem(spots[i].id),
                              borderRadius: BorderRadius.circular(40),
                              child: Center(
                                child: AnimatedContainer(
                                  duration: Duration(
                                    milliseconds:
                                        MediaQuery.disableAnimationsOf(context)
                                        ? 0
                                        : 180,
                                  ),
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        candidate.isNotEmpty ||
                                            selected.contains(spots[i].id) ||
                                            placements.containsValue(
                                              spots[i].id,
                                            )
                                        ? const Color(0xFFE8AE4B)
                                        : const Color(0xCCFFFFFF),
                                    border: Border.all(
                                      color: const Color(0xFF356D75),
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x22000000),
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      step.isOrder &&
                                              selected.contains(spots[i].id)
                                          ? '${selected.toList().indexOf(spots[i].id) + 1}'
                                          : diagram
                                          ? '${i + 1}'
                                          : '•',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        color: Color(0xFF254957),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            );
          },
        ),
      ),
      if (!diagram && selected.isNotEmpty)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            selected.map(step.label).join(' → '),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
    ],
  );
}

class ExplorerPainter extends CustomPainter {
  const ExplorerPainter({this.girl = false, this.eye = false, this.crop});
  final bool girl, eye;
  final Rect? crop;
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFE7F3EE), Color(0xFFFFF4DF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Offset.zero & s),
    );
    final full = eye ? const Size(600, 400) : const Size(400, 600);
    final source = crop ?? Offset.zero & full;
    final fit = applyBoxFit(BoxFit.contain, source.size, s);
    final dest = Alignment.center.inscribe(fit.destination, Offset.zero & s);
    c.save();
    c.translate(dest.left, dest.top);
    c.scale(dest.width / source.width, dest.height / source.height);
    c.translate(-source.left, -source.top);
    if (eye) {
      drawExplorerEye(c);
    } else {
      drawExplorer(c, girl: girl);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(ExplorerPainter old) =>
      old.girl != girl || old.eye != eye || old.crop != crop;
}

void drawExplorer(Canvas c, {bool girl = false}) {
  const skin = Color(0xFFE5AD83),
      shadow = Color(0xFFC88A63),
      ink = Color(0xFF38414A),
      hair = Color(0xFF65402F);
  void oval(Rect r, Color color) => c.drawOval(r, Paint()..color = color);
  void stroke(List<Offset> pts, Color color, double width) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final pt in pts.skip(1)) {
      p.lineTo(pt.dx, pt.dy);
    }
    c.drawPath(
      p,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  oval(const Rect.fromLTWH(98, 573, 210, 15), const Color(0x22768B76));
  if (girl) oval(const Rect.fromLTWH(133, 31, 139, 133), hair);
  for (final sign in [-1, 1]) {
    double x(double value) => 200 + sign * value;
    stroke(
      [Offset(x(28), 352), Offset(x(37), 459), Offset(x(44), 550)],
      skin,
      35,
    );
    oval(Rect.fromLTWH(sign < 0 ? 122 : 224, 548, 62, 29), skin);
    stroke([Offset(x(44), 550), Offset(x(63), 564)], skin, 24);
    stroke(
      [Offset(x(58), 203), Offset(x(102), 276), Offset(x(127), 334)],
      skin,
      29,
    );
    oval(
      Rect.fromCenter(center: Offset(x(138), 362), width: 31, height: 44),
      skin,
    );
    for (var i = 0; i < 4; i++) {
      stroke(
        [
          Offset(x(127 + i * 7.0), 370),
          Offset(x(126 + i * 8.0), 393 + (i == 1 ? 8 : 0)),
        ],
        skin,
        6,
      );
    }
    stroke([Offset(x(127), 352), Offset(x(113), 365)], skin, 9);
    stroke([Offset(x(100), 278), Offset(x(108), 278)], shadow, 2);
    stroke([Offset(x(39), 464), Offset(x(31), 464)], shadow, 2);
  }
  c.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(161, 327, 78, 52),
      const Radius.circular(14),
    ),
    Paint()..color = const Color(0xFF376D83),
  );
  stroke(
    [const Offset(185, 359), const Offset(182, 391)],
    const Color(0xFF376D83),
    39,
  );
  stroke(
    [const Offset(216, 359), const Offset(218, 391)],
    const Color(0xFF376D83),
    39,
  );
  stroke([const Offset(200, 143), const Offset(200, 195)], skin, 30);
  final shirt = Path()
    ..moveTo(166, 188)
    ..quadraticBezierTo(146, 187, 131, 211)
    ..lineTo(153, 231)
    ..lineTo(160, 224)
    ..lineTo(158, 347)
    ..quadraticBezierTo(200, 359, 243, 347)
    ..lineTo(240, 224)
    ..lineTo(248, 232)
    ..lineTo(270, 211)
    ..quadraticBezierTo(254, 188, 233, 188)
    ..quadraticBezierTo(200, 206, 166, 188)
    ..close();
  c.drawPath(
    shirt,
    Paint()
      ..shader = LinearGradient(
        colors: girl
            ? const [Color(0xFFA580C6), Color(0xFF7650A4)]
            : const [Color(0xFF73B9DA), Color(0xFF3786B5)],
      ).createShader(const Rect.fromLTWH(130, 187, 140, 165)),
  );
  oval(const Rect.fromLTWH(182, 233, 36, 36), const Color(0x55FFFFFF));
  for (final x in [139.0, 246.0]) oval(Rect.fromLTWH(x, 89, 20, 36), skin);
  oval(const Rect.fromLTWH(143, 42, 115, 108), skin);
  c.drawPath(
    Path()
      ..moveTo(141, 90)
      ..quadraticBezierTo(123, 24, 198, 25)
      ..quadraticBezierTo(271, 21, 260, 91)
      ..lineTo(250, 74)
      ..quadraticBezierTo(213, 72, 211, 47)
      ..quadraticBezierTo(185, 79, 145, 73)
      ..close(),
    Paint()..color = hair,
  );
  for (final x in [181.0, 220.0]) {
    oval(
      Rect.fromCenter(center: Offset(x, 98), width: 19, height: 24),
      Colors.white,
    );
    oval(Rect.fromCenter(center: Offset(x, 99), width: 11, height: 16), ink);
    oval(
      Rect.fromCenter(center: Offset(x - 2, 95), width: 4, height: 5),
      Colors.white,
    );
    stroke([Offset(x - 8, 82), Offset(x + 7, 81)], hair, 3);
  }
  stroke(
    [const Offset(201, 104), const Offset(197, 114), const Offset(204, 115)],
    shadow,
    3,
  );
  oval(const Rect.fromLTWH(184, 120, 34, 17), ink);
  oval(const Rect.fromLTWH(192, 128, 20, 8), const Color(0xFFE78B91));
  oval(const Rect.fromLTWH(156, 116, 19, 8), const Color(0x44D57772));
  oval(const Rect.fromLTWH(229, 116, 19, 8), const Color(0x44D57772));
}

void drawExplorerEye(Canvas c) {
  c.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(35, 20, 530, 360),
      const Radius.circular(90),
    ),
    Paint()..color = const Color(0xFFF0C2A0),
  );
  final eyebrow = Path()
    ..moveTo(140, 106)
    ..quadraticBezierTo(298, 13, 459, 96);
  c.drawPath(
    eyebrow,
    Paint()
      ..color = const Color(0xFF71503D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 25
      ..strokeCap = StrokeCap.round,
  );
  final lid = Path()
    ..moveTo(103, 222)
    ..quadraticBezierTo(290, 70, 499, 223)
    ..quadraticBezierTo(300, 335, 103, 222)
    ..close();
  c.drawPath(lid, Paint()..color = const Color(0xFFCD936E));
  final white = Path()
    ..moveTo(110, 229)
    ..quadraticBezierTo(295, 140, 490, 229)
    ..quadraticBezierTo(302, 317, 110, 229)
    ..close();
  c.drawPath(white, Paint()..color = Colors.white);
  c.save();
  c.clipPath(white);
  c.drawCircle(
    const Offset(300, 230),
    65,
    Paint()..color = const Color(0xFF608C79),
  );
  c.drawCircle(
    const Offset(300, 230),
    32,
    Paint()..color = const Color(0xFF293A42),
  );
  c.drawCircle(const Offset(282, 212), 12, Paint()..color = Colors.white);
  c.restore();
  c.drawPath(
    Path()
      ..moveTo(110, 229)
      ..quadraticBezierTo(295, 140, 490, 229),
    Paint()
      ..color = const Color(0xFF573F33)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7,
  );
  for (var i = 0; i < 7; i++) {
    final x = 378.0 + i * 18, y = 185.0 + i * 5;
    c.drawLine(
      Offset(x, y),
      Offset(x + 10, y - 29),
      Paint()
        ..color = const Color(0xFF573F33)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }
}

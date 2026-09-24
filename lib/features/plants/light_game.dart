import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'light_model.dart';

const lightRoomAsset = 'assets/images/light-room-v1.png';
const lightPlantsAsset = 'assets/images/light-plants-v1.png';
const lightPlantCenters = {'window': .265, 'cupboard': .745};

class LightGame extends FlameGame {
  LightGame({required this.onReady});
  final VoidCallback onReady;
  ui.Image? room, plants;
  LightProgress progress = const LightProgress();
  String? watering;
  double waterTime = 0, doorTime = 0;
  bool reducedMotion = false;

  @override
  Future<void> onLoad() async {
    final loaded = await Future.wait([
      images.load('light-room-v1.png'),
      images.load('light-plants-v1.png'),
    ]);
    room = loaded[0];
    plants = loaded[1];
    onReady();
  }

  @override
  Color backgroundColor() => const Color(0xFFFFF0D7);
  @override
  void update(double dt) {
    super.update(dt);
    waterTime = math.max(0, waterTime - dt);
    doorTime = math.max(0, doorTime - dt);
  }

  void pour(String place) {
    watering = place;
    waterTime = 1.1;
  }

  @override
  void render(Canvas c) {
    super.render(c);
    if (room == null || plants == null) return;
    final w = size.x, h = size.y;
    final paint = Paint()..filterQuality = FilterQuality.medium;
    c.drawImageRect(
      room!,
      Rect.fromLTWH(0, 0, room!.width.toDouble(), room!.height.toDouble()),
      Rect.fromLTWH(0, 0, w, h),
      paint,
    );
    for (final place in lightPlantCenters.keys) {
      // A prediction NEVER changes the observed plant. Both start with column 0.
      final column = !progress.revealed
          ? 0
          : place == 'window'
          ? 1
          : 2;
      final source = Rect.fromLTWH(
        plants!.width * column / 3,
        0,
        plants!.width / 3,
        plants!.height.toDouble(),
      );
      final width = w * .20, height = width * source.height / source.width;
      final target = Rect.fromLTWH(
        w * lightPlantCenters[place]! - width / 2,
        h * .715 - height * .95,
        width,
        height,
      );
      c.drawImageRect(plants!, source, target, paint);
      if (waterTime > 0 && watering == place) {
        for (var i = 0; i < 12; i++) {
          final t = reducedMotion
              ? .6
              : ((1.1 - waterTime) * 1.2 + i * .06) % 1;
          final x = target.center.dx + math.sin(i * 3.2) * width * .13;
          final y = target.bottom - height * .4 + t * height * .34;
          c.drawOval(
            Rect.fromCenter(center: Offset(x, y), width: 5, height: 9),
            Paint()..color = const Color(0xFF56B4EC),
          );
        }
      }
    }
    if (doorTime > 0) {
      final r = Rect.fromLTWH(w * .535, h * .14, w * .38, h * .6);
      c.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(8)),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFAF7140), Color(0xFF754321)],
          ).createShader(r),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(r.deflate(12), const Radius.circular(6)),
        Paint()
          ..color = const Color(0xFFC59362)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      c.drawCircle(
        Offset(r.right - 15, r.center.dy),
        5,
        Paint()..color = const Color(0xFFFFDB85),
      );
    }
  }
}

class LightPlantPicture extends StatelessWidget {
  const LightPlantPicture({super.key, required this.column});
  final int column;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 60,
    height: 120,
    child: ClipRect(
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          children: [
            Positioned(
              left: -column * 60,
              top: 0,
              width: 180,
              height: 120,
              child: Image.asset(
                lightPlantsAsset,
                fit: BoxFit.fill,
                excludeFromSemantics: true,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

const plantLabAsset = 'assets/images/plant-lab-v1.png';
const plantPartRegions = {
  'roots': Rect.fromLTWH(.295, .62, .37, .36),
  'stem': Rect.fromLTWH(.475, .37, .035, .25),
  'leaf': Rect.fromLTWH(.26, .315, .18, .24),
  'flower': Rect.fromLTWH(.34, .005, .29, .37),
};
const plantRightLeafRegion = Rect.fromLTWH(.535, .405, .17, .195);
String plantPartId(String id) => id == 'root'
    ? 'roots'
    : id == 'leaf-right'
    ? 'leaf'
    : id;

Rect plantPartRect(String id, Size size, {bool touch = false}) {
  final r = id == 'leaf-right'
      ? plantRightLeafRegion
      : plantPartRegions[plantPartId(id)]!;
  final center = Offset(r.center.dx * size.width, r.center.dy * size.height);
  return Rect.fromCenter(
    center: center,
    width: touch ? math.max(64, r.width * size.width) : r.width * size.width,
    height: touch
        ? math.max(64, r.height * size.height)
        : r.height * size.height,
  );
}

class PlantLabGame extends FlameGame {
  ui.Image? illustration;
  String? activePart;
  Set<String> discovered = {};
  bool assembling = false, reducedMotion = false;
  double animationLeft = 0;
  void animatePart(String id) {
    activePart = plantPartId(id);
    animationLeft = 1.3;
  }

  @override
  Future<void> onLoad() async {
    illustration = await images.load('plant-lab-v1.png');
  }

  @override
  Color backgroundColor() => const Color(0xFFDAEBB2);

  @override
  void update(double dt) {
    super.update(dt);
    animationLeft = math.max(0, animationLeft - dt);
  }

  @override
  void render(Canvas c) {
    super.render(c);
    final image = illustration;
    if (image == null) return;
    final bounds = Rect.fromLTWH(0, 0, size.x, size.y);
    final source = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final p = Paint()..filterQuality = FilterQuality.medium;
    c.drawImageRect(image, source, bounds, p);
    if (assembling) {
      for (final entry in [
        ...plantPartRegions.entries,
        const MapEntry('leaf-right', plantRightLeafRegion),
      ]) {
        if (discovered.contains(plantPartId(entry.key))) continue;
        final r = plantPartRect(entry.key, Size(size.x, size.y));
        c.drawRRect(
          RRect.fromRectAndRadius(r.inflate(3), const Radius.circular(18)),
          Paint()..color = const Color(0xBDFFF8EC),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(r.inflate(3), const Radius.circular(18)),
          Paint()
            ..color = const Color(0xFF66825B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
    final active = activePart;
    if (active == null || !plantPartRegions.containsKey(active)) return;
    final focus = plantPartRect(active, Size(size.x, size.y)).inflate(6);
    c.drawRRect(
      RRect.fromRectAndRadius(focus, const Radius.circular(24)),
      Paint()
        ..color = const Color(0xFFFFEE83)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    if (animationLeft <= 0) return;
    final t = reducedMotion ? .5 : 1 - animationLeft / 1.3;
    Offset pt(double x, double y) => Offset(size.x * x, size.y * y);
    if (active == 'stem' || active == 'roots') {
      for (var i = 0; i < 5; i++) {
        final progress = (t + i * .17) % 1;
        final position = active == 'stem'
            ? Offset.lerp(pt(.49, .61), pt(.49, .37), progress)!
            : Offset.lerp(pt(.35 + i * .072, .88), pt(.49, .63), progress)!;
        c.drawCircle(position, 5, Paint()..color = const Color(0xFF188ACA));
        c.drawCircle(
          position.translate(-1, -1),
          2,
          Paint()..color = Colors.white,
        );
      }
    } else if (active == 'leaf') {
      for (var i = 0; i < 4; i++) {
        final position = Offset.lerp(
          pt(.18, .10),
          pt(.34 + i * .027, .46),
          (t + i * .2) % 1,
        )!;
        c.drawCircle(position, 5, Paint()..color = const Color(0xFFFFED78));
      }
    } else if (active == 'flower') {
      for (var i = 0; i < 7; i++) {
        final angle = i * math.pi * 2 / 7;
        final position = pt(
          .49 + math.cos(angle) * .045,
          .20 + math.sin(angle) * .055,
        );
        c.drawOval(
          Rect.fromCenter(center: position, width: 7, height: 10),
          Paint()..color = const Color(0xFFFFD278),
        );
      }
    }
  }
}

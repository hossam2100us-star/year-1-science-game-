import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

const beanAtlasAsset = 'assets/images/bean-stages-v1.webp';
const greenhouseAsset = 'assets/images/greenhouse-v1.webp';

class BeanGame extends FlameGame {
  BeanGame({required this.onReady});
  final VoidCallback onReady;
  ui.Image? atlas, background;
  int frame = 0;
  double pour = 0, time = 0;
  bool reducedMotion = false;
  @override
  Future<void> onLoad() async {
    final imagesLoaded = await Future.wait([
      images.load('bean-stages-v1.webp'),
      images.load('greenhouse-v1.webp'),
    ]);
    atlas = imagesLoaded[0];
    background = imagesLoaded[1];
    onReady();
  }

  @override
  Color backgroundColor() => const Color(0xFFEDEACB);
  @override
  void update(double dt) {
    super.update(dt);
    if (!reducedMotion) time += dt;
    pour = math.max(0, pour - dt);
  }

  @override
  void render(Canvas c) {
    super.render(c);
    if (atlas == null || background == null) return;
    final w = size.x,
        h = size.y,
        p = Paint()..filterQuality = FilterQuality.medium;
    final fit = applyBoxFit(
      BoxFit.cover,
      Size(background!.width.toDouble(), background!.height.toDouble()),
      Size(w, h),
    );
    final src = Alignment.center.inscribe(
      fit.source,
      Rect.fromLTWH(
        0,
        0,
        background!.width.toDouble(),
        background!.height.toDouble(),
      ),
    );
    c.drawImageRect(background!, src, Rect.fromLTWH(0, 0, w, h), p);
    // The atlas always shows the exact day chosen from content. No future state is drawn.
    final crop = Rect.fromLTWH(
      frame.isEven ? 0 : .5,
      frame < 2 ? 0 : .47,
      .5,
      frame < 2 ? .47 : .53,
    );
    final source = Rect.fromLTWH(
      crop.left * atlas!.width,
      crop.top * atlas!.height,
      crop.width * atlas!.width,
      crop.height * atlas!.height,
    );
    final width = math.min(w * .32, h * .61),
        height = width * source.height / source.width;
    final target = Rect.fromLTWH(
      w * .70 - width / 2,
      h * .85 - height,
      width,
      height,
    );
    c.drawOval(
      Rect.fromCenter(
        center: target.bottomCenter,
        width: width * .74,
        height: 14,
      ),
      p..color = const Color(0x245F4930),
    );
    p.color = Colors.white;
    c.drawImageRect(atlas!, source, target, p);
    if (pour > 0) {
      for (var i = 0; i < 14; i++) {
        final phase = ((1 - pour) * 1.8 + i * .075) % 1;
        final x = target.center.dx - 18 + math.sin(i * 2) * 17,
            y = target.top - 45 + phase * height * .6;
        c.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: 5, height: 9),
          p..color = const Color(0xFF72BEE9),
        );
      }
    }
  }
}

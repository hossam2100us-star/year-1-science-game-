import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flutter/widgets.dart';

/// Paints a bundled image from Flame's image cache.
///
/// The load future is created once per asset and kept across rebuilds
/// (AUD-016); previously every rebuild created a new future.
class GameImage extends StatefulWidget {
  const GameImage({
    super.key,
    required this.asset,
    required this.builder,
    this.placeholder = const SizedBox.shrink(),
  });
  final String asset;
  final Widget Function(BuildContext context, ui.Image image) builder;
  final Widget placeholder;

  @override
  State<GameImage> createState() => GameImageState();
}

class GameImageState extends State<GameImage> {
  late Future<ui.Image> _image;

  @visibleForTesting
  Future<ui.Image> get image => _image;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(GameImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) _resolve();
  }

  void _resolve() => _image = Flame.images.load(widget.asset);

  @override
  Widget build(BuildContext context) => FutureBuilder<ui.Image>(
    future: _image,
    builder: (context, snapshot) => snapshot.hasData
        ? widget.builder(context, snapshot.data!)
        : widget.placeholder,
  );
}

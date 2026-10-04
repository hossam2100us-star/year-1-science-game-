import 'package:flame/flame.dart';
import 'package:flutter/widgets.dart';

/// Keeps decoded images bounded on low-RAM tablets (AUD-008).
///
/// The bundled atlases decode to roughly 6 MB each (RGBA). Flame's global
/// cache never evicted anything, so after visiting every unit about 150 MB
/// of decoded art could stay resident.
abstract final class ImageBudget {
  /// Upper bound for Flutter's own cache (Image.asset on the hub and map).
  static const flutterCacheBytes = 64 << 20;

  static void configure() {
    PaintingBinding.instance.imageCache.maximumSizeBytes = flutterCacheBytes;
  }
}

/// Wraps one unit: images the unit loads into Flame's cache are released when
/// the unit is closed. Images that were already cached when it opened are
/// kept, because the screen underneath may still be using them.
class UnitImageScope extends StatefulWidget {
  const UnitImageScope({super.key, required this.child});
  final Widget child;

  @override
  State<UnitImageScope> createState() => _UnitImageScopeState();
}

class _UnitImageScopeState extends State<UnitImageScope> {
  late final Set<String> _before;

  @override
  void initState() {
    super.initState();
    _before = Flame.images.keys.toSet();
  }

  @override
  void dispose() {
    for (final key in Flame.images.keys.toList()) {
      if (!_before.contains(key)) Flame.images.clear(key);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

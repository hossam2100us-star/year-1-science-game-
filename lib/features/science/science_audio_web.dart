import 'dart:js_interop';

@JS('Audio')
extension type _Audio._(JSObject _) implements JSObject {
  external factory _Audio(String src);
  external set volume(double value);
  external JSPromise<JSAny?> play();
  external void pause();
}

class ScienceAudio {
  static _Audio? player;
  static Future<void> play(String name, double volume) async {
    player?.pause();
    final next = _Audio('assets/assets/audio/$name.wav')
      ..volume = volume.clamp(0.0, .5);
    player = next;
    try {
      await next.play().toDart;
    } catch (_) {
      /* A browser may require another user gesture. */
    }
  }

  static Future<void> stop() async {
    player?.pause();
    player = null;
  }
}

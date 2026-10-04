import 'dart:js_interop';

import '../../core/diagnostics/app_log.dart';

@JS('Audio')
extension type _Audio._(JSObject _) implements JSObject {
  external factory _Audio(String src);
  external set volume(double value);
  external JSPromise<JSAny?> play();
  external void pause();
}

class ScienceAudio {
  static _Audio? _player;
  static Future<void> play(String name, double volume) async {
    _player?.pause();
    final next = _Audio('assets/assets/audio/$name.wav')
      ..volume = volume.clamp(0.0, .5);
    _player = next;
    try {
      await next.play().toDart;
    } catch (error, stack) {
      // A browser may require another user gesture before playing audio.
      AppLog.warning('audio', 'Browser blocked scene sound', error, stack);
    }
  }

  static Future<void> stop() async {
    _player?.pause();
    _player = null;
  }
}

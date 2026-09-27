import 'package:flutter/services.dart';

class ScienceAudio {
  static const channel = MethodChannel('science_adventure/sounds');
  static Future<void> play(String name, double volume) async {
    try {
      await channel.invokeMethod<void>('play', {
        'name': name,
        'volume': volume.clamp(0.0, .5),
      });
    } on MissingPluginException {
      /* Widget tests and unsupported hosts stay silent. */
    }
  }

  static Future<void> stop() async {
    try {
      await channel.invokeMethod<void>('stop');
    } on MissingPluginException {
      /* No native player on test hosts. */
    }
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/core/models.dart';

void main() {
  group('AppSettings.copyWith voices (AUD-019)', () {
    const chosen = AppSettings(boyVoice: 'en-GB-a', girlVoice: 'en-US-b');

    test('a voice can be reset to the device default', () {
      final reset = chosen.copyWith(boyVoice: () => null);
      expect(reset.boyVoice, isNull);
      expect(reset.girlVoice, 'en-US-b');
      expect(chosen.copyWith(girlVoice: () => null).girlVoice, isNull);
    });

    test('omitting a voice keeps the saved one', () {
      final changed = chosen.copyWith(volume: .5, arabic: false);
      expect(changed.boyVoice, 'en-GB-a');
      expect(changed.girlVoice, 'en-US-b');
      expect(changed.volume, .5);
      expect(changed.arabic, isFalse);
    });

    test('a voice can be changed to another one', () {
      expect(chosen.copyWith(boyVoice: () => 'en-AU-c').boyVoice, 'en-AU-c');
    });

    test('a reset voice survives a save round trip as null', () {
      final saved = AppSettings.fromJson(
        chosen.copyWith(boyVoice: () => null).toJson(),
      );
      expect(saved.boyVoice, isNull);
      expect(saved.girlVoice, 'en-US-b');
    });
  });
}

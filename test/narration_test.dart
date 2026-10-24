import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/narration.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tts');
  final calls = <MethodCall>[];
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'getVoices') {
            return [
              {
                'name': 'English local',
                'locale': 'en-GB',
                'network_required': '0',
                'features': '',
              },
              {
                'name': 'English online',
                'locale': 'en-US',
                'network_required': '1',
                'features': '',
              },
              {
                'name': 'Not installed',
                'locale': 'en-US',
                'network_required': '0',
                'features': 'notInstalled',
              },
              {'name': 'Unknown network', 'locale': 'en-US'},
              {
                'name': 'Arabic local',
                'locale': 'ar-EG',
                'network_required': '0',
              },
            ];
          }
          return 1;
        });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  test('Only installed offline English voices can speak', () async {
    final service = NarrationService();
    await service.initialize();
    expect(service.voices.map((v) => v.name), ['English local']);
    expect(service.status, VoiceStatus.ready);
    await service.speak('Hello, scientist!');
    expect(calls.where((c) => c.method == 'setSpeechRate').last.arguments, .43);
    expect(calls.where((c) => c.method == 'setVoice').last.arguments, {
      'name': 'English local',
      'locale': 'en-GB',
    });
    service.configure(const AppSettings(narration: false), ChildGender.girl);
    final before = calls.where((c) => c.method == 'speak').length;
    await service.speak('Muted');
    expect(calls.where((c) => c.method == 'speak').length, before);
    service.dispose();
  });

  group('a Huawei tablet (24 October 2026)', () {
    // What the tablet's engine reports: plain English voices and an
    // unusual "en-Qaag" listed first.
    const huaweiVoices = [
      {
        'name': 'en',
        'locale': 'en-Qaag',
        'network_required': 0,
        'features': '',
      },
      {'name': 'en', 'locale': 'en', 'network_required': 0, 'features': ''},
      {
        'name': 'en-US',
        'locale': 'en-US',
        'network_required': 0,
        'features': '',
      },
    ];

    void engine(Future<Object?> Function(MethodCall call) answer) =>
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              calls.add(call);
              return answer(call);
            });

    test('the automatic voice is a plain English one', () async {
      engine((call) async => call.method == 'getVoices' ? huaweiVoices : 1);
      final service = NarrationService();
      await service.initialize();
      expect(service.voices.map((v) => v.locale), ['en', 'en-US', 'en-Qaag']);
      await service.speak('Hello');
      expect(calls.where((c) => c.method == 'setVoice').last.arguments, {
        'name': 'en',
        'locale': 'en',
      });
      service.dispose();
    });

    test('a stopped speech engine is connected again and the sentence '
        'still plays', () async {
      var bound = true;
      engine((call) async {
        switch (call.method) {
          case 'getVoices':
            return huaweiVoices;
          case 'getDefaultEngine':
            return 'com.huawei.hiai';
          case 'setEngine':
            bound = true;
            return 1;
          case 'setVoice' when !bound:
            // What the plugin answers when Android stopped the engine.
            throw PlatformException(
              code: 'error',
              message: 'Attempt to invoke interface method on a null object',
            );
        }
        return 1;
      });
      final service = NarrationService();
      await service.initialize();
      bound = false; // Android stops the engine in the background.
      await service.speak('Tap each part of the story to listen.');
      expect(
        calls.where((c) => c.method == 'setEngine').single.arguments,
        'com.huawei.hiai',
      );
      expect(
        [for (final c in calls.where((c) => c.method == 'speak')) c.arguments],
        ['Tap each part of the story to listen.'],
      );
      // One failure never turns the voice off.
      expect(service.status, VoiceStatus.ready);
      await service.speak('Beginning.');
      expect(calls.where((c) => c.method == 'speak'), hasLength(2));
      service.dispose();
    });

    test('a voice the engine cannot find by name still speaks its '
        'language', () async {
      engine((call) async {
        if (call.method == 'getVoices') return huaweiVoices;
        if (call.method == 'setVoice') return 0;
        return 1;
      });
      final service = NarrationService();
      await service.speak('Hello');
      expect(
        calls.where((c) => c.method == 'setLanguage').single.arguments,
        'en',
      );
      expect(calls.where((c) => c.method == 'speak'), hasLength(1));
      service.dispose();
    });
  });
}

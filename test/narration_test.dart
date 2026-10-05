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
}

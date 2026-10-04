import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'diagnostics/app_log.dart';
import 'models.dart';
import 'preview_voice_stub.dart'
    if (dart.library.js_interop) 'preview_voice_web.dart'
    as preview;

enum VoiceStatus { loading, ready, unavailable, browserPreview }

class EnglishVoice {
  const EnglishVoice(this.name, this.locale);
  final String name, locale;
  String get id => '$locale::$name';
}

class NarrationService extends ChangeNotifier {
  NarrationService({FlutterTts? engine}) : _tts = engine ?? FlutterTts();
  final FlutterTts _tts;
  VoiceStatus status = VoiceStatus.loading;
  List<EnglishVoice> voices = [];
  AppSettings _settings = const AppSettings();
  ChildGender _gender = ChildGender.boy;
  Future<void>? _initialization;
  int _generation = 0;
  bool _disposed = false;

  Future<void> initialize() => _initialization ??= _initialize();
  Future<void> _initialize() async {
    if (kIsWeb) {
      try {
        final raw = await preview.localVoices();
        voices = raw
            .map((v) => EnglishVoice(v['name']!, v['locale']!))
            .toList();
        status = voices.isEmpty
            ? VoiceStatus.browserPreview
            : VoiceStatus.ready;
      } catch (error, stack) {
        AppLog.warning('narration', 'Browser voices unavailable', error, stack);
        status = VoiceStatus.browserPreview;
      }
      if (!_disposed) notifyListeners();
      return;
    }
    try {
      final raw = await _tts.getVoices;
      voices = (raw as List)
          .whereType<Map>()
          .where((v) {
            final locale = (v['locale'] ?? '').toString().toLowerCase();
            final network = v['network_required'];
            final offline =
                defaultTargetPlatform != TargetPlatform.android ||
                network == false ||
                network == 'false' ||
                network == 0 ||
                network == '0';
            final features = (v['features'] ?? '').toString().toLowerCase();
            return locale.startsWith('en') &&
                offline &&
                !features.contains('notinstalled');
          })
          .map(
            (v) => EnglishVoice(v['name'].toString(), v['locale'].toString()),
          )
          .toList();
      status = voices.isEmpty ? VoiceStatus.unavailable : VoiceStatus.ready;
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(.43);
    } catch (error, stack) {
      AppLog.warning(
        'narration',
        'Offline voices could not be loaded',
        error,
        stack,
      );
      status = VoiceStatus.unavailable;
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> refresh() async {
    _initialization = null;
    await initialize();
  }

  void configure(AppSettings settings, ChildGender gender) {
    _settings = settings;
    _gender = gender;
    if (!settings.narration) stop();
  }

  Future<void> speak(String text) async {
    final token = ++_generation;
    await initialize();
    if (_disposed ||
        token != _generation ||
        !_settings.narration ||
        status != VoiceStatus.ready)
      return;
    try {
      if (!kIsWeb) await _tts.stop();
      final chosen = _gender == ChildGender.girl
          ? _settings.girlVoice
          : _settings.boyVoice;
      final voice =
          voices.where((v) => v.id == chosen).firstOrNull ?? voices.first;
      if (kIsWeb) {
        if (token == _generation && !_disposed)
          preview.speakLocal(text, voice.name, voice.locale, _settings.volume);
        return;
      }
      await _tts.setVoice({'name': voice.name, 'locale': voice.locale});
      await _tts.setVolume(_settings.volume);
      await _tts.setPitch(1.0);
      if (token == _generation && !_disposed) await _tts.speak(text);
    } catch (error, stack) {
      AppLog.warning('narration', 'Speaking failed', error, stack);
      status = VoiceStatus.unavailable;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> stop() async {
    _generation++;
    try {
      if (kIsWeb)
        preview.stopLocal();
      else
        await _tts.stop();
    } catch (error, stack) {
      AppLog.warning('narration', 'Stopping speech failed', error, stack);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    super.dispose();
  }
}

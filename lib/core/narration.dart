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

/// `en`, or `en` with a two-letter region (`en-GB`, `en_US`).
bool _plainEnglish(String locale) =>
    RegExp(r'^en([-_][A-Za-z]{2})?$').hasMatch(locale);

class NarrationService extends ChangeNotifier {
  NarrationService({FlutterTts? engine}) : _tts = engine ?? FlutterTts();
  final FlutterTts _tts;
  VoiceStatus status = VoiceStatus.loading;
  List<EnglishVoice> voices = [];
  AppSettings _settings = const AppSettings();
  ChildGender _gender = ChildGender.boy;
  Future<void>? _initialization;
  Future<bool>? _reconnection;
  DateTime _lastAttempt = DateTime.fromMillisecondsSinceEpoch(0);
  static const _retryAfter = Duration(seconds: 20);
  int _generation = 0;
  bool _disposed = false;

  Future<void> initialize() => _initialization ??= _initialize();
  Future<void> _initialize() async {
    _lastAttempt = DateTime.now();
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
          .whereType<Map<dynamic, dynamic>>()
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
      // Plain English locales first (en-GB, en-US, en): the automatic
      // voice is the first one, and some engines also list unusual ones
      // (a Huawei tablet lists "en-Qaag").
      voices = [
        ...voices.where((v) => _plainEnglish(v.locale)),
        ...voices.where((v) => !_plainEnglish(v.locale)),
      ];
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
    // No voice at start-up (the engine was not ready yet): look again, at
    // most every [_retryAfter], instead of staying silent until the app is
    // closed.
    if (!kIsWeb &&
        status == VoiceStatus.unavailable &&
        _settings.narration &&
        DateTime.now().difference(_lastAttempt) >= _retryAfter) {
      await _reconnect();
      await refresh();
    }
    if (_disposed ||
        token != _generation ||
        !_settings.narration ||
        status != VoiceStatus.ready) {
      return;
    }
    final chosen = _gender == ChildGender.girl
        ? _settings.girlVoice
        : _settings.boyVoice;
    final voice =
        voices.where((v) => v.id == chosen).firstOrNull ?? voices.first;
    if (kIsWeb) {
      if (token == _generation && !_disposed) {
        preview.speakLocal(text, voice.name, voice.locale, _settings.volume);
      }
      return;
    }
    try {
      await _say(text, voice, token);
    } catch (error, stack) {
      // Android may stop the speech engine in the background (seen on a
      // Huawei tablet: its next call fails, "not bound to TTS engine").
      // Connect to the engine again and try once more; one failure never
      // turns the voice off for the rest of the session.
      AppLog.warning(
        'narration',
        'Speaking failed; reconnecting',
        error,
        stack,
      );
      if (!await _reconnect() || _disposed || token != _generation) return;
      try {
        await _say(text, voice, token);
      } catch (error, stack) {
        AppLog.warning('narration', 'Speaking failed again', error, stack);
      }
    }
  }

  Future<void> _say(String text, EnglishVoice voice, int token) async {
    await _tts.stop();
    // A voice the engine does not find by name still speaks its language.
    final chosen = await _tts.setVoice({
      'name': voice.name,
      'locale': voice.locale,
    });
    if (chosen != 1) await _tts.setLanguage(voice.locale);
    await _tts.setVolume(_settings.volume);
    await _tts.setPitch(1.0);
    if (token == _generation && !_disposed) await _tts.speak(text);
  }

  /// Binds the default speech engine again. Several failed calls share one
  /// reconnection.
  Future<bool> _reconnect() => _reconnection ??= () async {
    try {
      final engine =
          await _tts.getDefaultEngine as String? ??
          ((await _tts.getEngines) as List?)?.firstOrNull?.toString();
      if (engine == null) return false;
      await _tts.setEngine(engine);
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(.43);
      return true;
    } catch (error, stack) {
      AppLog.warning(
        'narration',
        'The speech engine could not be reconnected',
        error,
        stack,
      );
      return false;
    } finally {
      _reconnection = null;
    }
  }();

  Future<void> stop() async {
    _generation++;
    try {
      if (kIsWeb) {
        preview.stopLocal();
      } else {
        await _tts.stop();
      }
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

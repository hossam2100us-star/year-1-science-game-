import 'dart:js_interop';

@JS('window.speechSynthesis')
external SpeechEngine get _engine;

extension type SpeechEngine(JSObject _) implements JSObject {
  external JSArray<LocalVoice> getVoices();
  external void speak(Utterance u);
  external void cancel();
}

extension type LocalVoice(JSObject _) implements JSObject {
  external String get name;
  external String get lang;
  external bool get localService;
}

@JS('SpeechSynthesisUtterance')
extension type Utterance._(JSObject _) implements JSObject {
  external factory Utterance(String text);
  external set voice(LocalVoice value);
  external set lang(String value);
  external set rate(double value);
  external set volume(double value);
}

Future<List<Map<String, String>>> localVoices() async {
  for (var attempt = 0; attempt < 3; attempt++) {
    final voices = _engine
        .getVoices()
        .toDart
        .where((v) => v.localService && v.lang.toLowerCase().startsWith('en'))
        .toList();
    if (voices.isNotEmpty)
      return voices.map((v) => {'name': v.name, 'locale': v.lang}).toList();
    if (attempt < 2)
      await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  return [];
}

void speakLocal(String text, String name, String locale, double volume) {
  // Fail closed: never allow the browser to choose a remote default voice.
  final local = _engine
      .getVoices()
      .toDart
      .where((v) => v.localService && v.name == name && v.lang == locale)
      .firstOrNull;
  if (local == null) throw StateError('No installed local English voice');
  _engine.cancel();
  final u = Utterance(text)
    ..voice = local
    ..lang = locale
    ..rate = .86
    ..volume = volume;
  _engine.speak(u);
}

void stopLocal() => _engine.cancel();

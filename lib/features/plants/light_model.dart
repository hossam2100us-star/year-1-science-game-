class LightProgress {
  const LightProgress({
    this.prediction,
    this.watered = const {},
    this.revealed = false,
  });
  final String? prediction;
  final Set<String> watered;
  final bool revealed;
  static const choices = ['green_and_strong', 'pale_and_floppy'];
  bool get readyToCompare => watered.containsAll(['window', 'cupboard']);
  LightProgress predict(String id) =>
      choices.contains(id) && watered.isEmpty && !revealed
      ? LightProgress(prediction: id)
      : this;
  LightProgress water(String place) =>
      prediction != null &&
          !revealed &&
          const ['window', 'cupboard'].contains(place)
      ? LightProgress(prediction: prediction, watered: {...watered, place})
      : this;
  LightProgress compare() => prediction != null && readyToCompare
      ? LightProgress(prediction: prediction, watered: watered, revealed: true)
      : this;
  Map<String, dynamic> toJson() => {
    'prediction': prediction,
    'watered': watered.toList(),
    'revealed': revealed,
  };
  factory LightProgress.restore(Map<String, dynamic> j) {
    final prediction = choices.contains(j['prediction'])
        ? j['prediction'] as String
        : null;
    final watered = prediction == null
        ? <String>{}
        : (j['watered'] as List? ?? [])
              .whereType<String>()
              .where((p) => const ['window', 'cupboard'].contains(p))
              .toSet();
    return LightProgress(
      prediction: prediction,
      watered: watered,
      revealed:
          prediction != null && watered.length == 2 && j['revealed'] == true,
    );
  }
  factory LightProgress.fromLegacy(Map<String, dynamic> j) =>
      LightProgress.restore({
        'prediction': j['prediction'],
        'watered': (j['frame'] as int? ?? 0) > 0 ? ['window', 'cupboard'] : [],
        'revealed': (j['frame'] as int? ?? 0) >= 2 || j['freeDone'] == true,
      });
}

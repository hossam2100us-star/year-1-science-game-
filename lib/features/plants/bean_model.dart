class BeanProgress {
  BeanProgress({this.prediction, this.frame = 0});
  final String? prediction;
  final int frame;
  static const previewKey = 'unit_02.bean';
  bool get finished => frame == 3;
  Map<String, dynamic> toJson() => {'prediction': prediction, 'frame': frame};
  factory BeanProgress.restore(Map<String, dynamic> j) {
    final prediction = ['root', 'leaf'].contains(j['prediction'])
        ? j['prediction'] as String
        : null;
    return BeanProgress(
      prediction: prediction,
      frame: prediction == null ? 0 : (j['frame'] as int? ?? 0).clamp(0, 3),
    );
  }
  BeanProgress predict(String value) =>
      frame == 0 && ['root', 'leaf'].contains(value)
      ? BeanProgress(prediction: value)
      : this;
  BeanProgress watered() => prediction == null || finished
      ? this
      : BeanProgress(prediction: prediction, frame: frame + 1);
}

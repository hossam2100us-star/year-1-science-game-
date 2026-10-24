import '../../content/lesson.dart';

/// Which scene renders a lesson step (AUD-002). Resolved once from the
/// step's content instead of by chains of `if` checks inside the player.
enum SceneKind {
  /// Full-screen light-and-plants experiment.
  lightExperiment(fullScreen: true),

  /// Full-screen bean-growing experiment.
  beanExperiment(fullScreen: true),

  /// Science experiment with its own lab state (`lab` in content).
  scienceLab,

  /// Science sorting, ordering and mapping scenes.
  scienceStage,

  /// "Ourselves" body and senses scenes.
  ourselves,

  /// Plant parts lab.
  plantLab,

  /// Plant mission choices.
  plantMission,

  /// Number, shape and measurement activities using the shared lesson engine.
  maths,

  /// Word and sentence cards, letter tiles and stories (English).
  english,

  /// The original Flame discovery scene, used when no other scene applies.
  discovery;

  const SceneKind({this.fullScreen = false});

  /// Full-screen scenes own their whole layout, including navigation.
  final bool fullScreen;

  static SceneKind of(LessonStep step) {
    final json = step.json;
    if (json['experiment'] == 'light') return lightExperiment;
    if (json['experiment'] == 'bean') return beanExperiment;
    return switch (json['playScene']) {
      'science' => json['lab'] != null ? scienceLab : scienceStage,
      'ourselves' => ourselves,
      'plant-lab' => plantLab,
      'plant-mission' => plantMission,
      'maths' => maths,
      'english' => english,
      _ => discovery,
    };
  }

  bool get isScience => this == scienceLab || this == scienceStage;
}

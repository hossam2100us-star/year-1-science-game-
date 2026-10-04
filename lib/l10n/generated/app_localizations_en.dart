// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get parentAreaDeleteTheDamagedCopies => 'Delete the damaged copies?';

  @override
  String get parentAreaMakeSureYouCopiedAnd =>
      'Make sure you copied and kept the data first. This cannot be undone.';

  @override
  String get parentAreaCancel => 'Cancel';

  @override
  String get parentAreaDelete => 'Delete';

  @override
  String get parentAreaBackToChild => 'Back to child';

  @override
  String get parentAreaGrownUps => 'Grown-ups';

  @override
  String get parentAreaFollowLearningThroughPlayDecisions =>
      'Follow learning through play decisions. Predictions and free play are not graded.';

  @override
  String get parentAreaResults => 'Results';

  @override
  String get parentAreaSettings => 'Settings';

  @override
  String get parentAreaGuide => 'Guide';

  @override
  String get parentAreaChildAndAppearance => 'Child and appearance';

  @override
  String parentAreaScientistGuide(Object guideName) {
    return 'Scientist guide: $guideName';
  }

  @override
  String get parentAreaEditNameGenderOrPicture =>
      'Edit name, gender or picture';

  @override
  String get parentAreaAdventureColours => 'Adventure colours';

  @override
  String get parentAreaAutomatic => 'Automatic';

  @override
  String get parentAreaOcean => 'Ocean';

  @override
  String get parentAreaBerry => 'Berry';

  @override
  String get parentAreaForest => 'Forest';

  @override
  String get parentAreaEditingThisProfileKeepsProgress =>
      'Editing this profile keeps progress. The first name, photo and preferences stay on this device.';

  @override
  String get parentAreaUnitAssessment => 'Unit assessment';

  @override
  String get parentAreaStarsRewardEffortAndCompletion =>
      'Stars reward effort and completion. Understanding uses first decisions before hints. Predictions and free play are not graded.';

  @override
  String get parentAreaTimeOnTheChildScreens => 'Time on the child screens';

  @override
  String get parentAreaNoTimeRecordedYet => 'No time recorded yet';

  @override
  String get parentAreaMin => 'min';

  @override
  String get parentAreaTimeOnChildScreensIs =>
      'Time on child screens is not a learning score. Parent-area and background time are excluded.';

  @override
  String get parentAreaBreaksAndAudio => 'Breaks and audio';

  @override
  String parentAreaAGentleBreakEveryMinutes(Object breakMinutes) {
    return 'A gentle break every $breakMinutes minutes';
  }

  @override
  String get parentAreaNarration => 'Narration';

  @override
  String get parentAreaNarrationVolume => 'Narration volume';

  @override
  String get parentAreaSoundEffectsWithTheGames =>
      'Sound effects — with the games';

  @override
  String get parentAreaMusicComingLater => 'Music — coming later';

  @override
  String get parentAreaHowToUseTheAdventure => 'How to use the adventure';

  @override
  String get parentAreaBasedOnTheBookPage => 'Based on the book, page 2.';

  @override
  String get parentAreaResetProgress => 'Reset progress';

  @override
  String get parentAreaThisClearsResultsTimeAnd =>
      'This clears results, time and stars, keeping the profile, photo and settings.';

  @override
  String get parentAreaClearAllProgress => 'Clear all progress?';

  @override
  String get parentAreaThisCannotBeUndone => 'This cannot be undone.';

  @override
  String get parentAreaClearProgress => 'Clear progress';

  @override
  String get parentAreaResetWithConfirmation => 'Reset with confirmation';

  @override
  String get parentAreaDataNeedingAttention => 'Data needing attention';

  @override
  String get parentAreaDataCopied => 'Data copied';

  @override
  String get parentAreaCopyTheData => 'Copy the data';

  @override
  String get parentAreaDeleteDamagedCopies => 'Delete damaged copies';

  @override
  String get parentAreaDiagnostics => 'Diagnostics';

  @override
  String get parentAreaIfSavingOrSoundGoes =>
      'If saving or sound goes wrong, copy this log and send it to support yourself. It holds only error types and code locations — never the child\'s name or photo — and is never sent automatically.';

  @override
  String get parentAreaLogCopied => 'Log copied';

  @override
  String get parentAreaCopyLog => 'Copy log';

  @override
  String get voiceSettingsEnglishVoiceOnThisDevice =>
      'English voice on this device';

  @override
  String voiceSettingsOfflineEnglishVoicesAvailable(Object length) {
    return '$length offline English voices available.';
  }

  @override
  String get voiceSettingsBrowserPreviewHasNoNarration =>
      'Browser preview has no narration. Test voices in the Android APK.';

  @override
  String get voiceSettingsNoOfflineEnglishVoiceIs =>
      'No offline English voice is available.';

  @override
  String get voiceSettingsAndroidDoesNotReliablyIdentify =>
      'Android does not reliably identify voice gender. Listen and choose a suitable voice for Zizo or Zizi.';

  @override
  String get voiceSettingsVoiceForThisGuide => 'Voice for this guide';

  @override
  String get voiceSettingsAutomaticDeviceDefault =>
      'Automatic (device default)';

  @override
  String get voiceSettingsTryVoice => 'Try voice';

  @override
  String get voiceSettingsCheckVoicesAgain => 'Check voices again';

  @override
  String get voiceSettingsIfNoVoiceIsAvailable =>
      'If no voice is available, use the tablet settings once:';

  @override
  String get voiceSettings1OpenDeviceSettings2 =>
      '1. Open device Settings.\n2. Search for Text-to-speech.\n3. Open the speech engine settings.\n4. Choose Install voice data.\n5. Download English.\n6. Return and tap Check voices again.';

  @override
  String get voiceSettingsMenuNamesVaryInstallingVoice =>
      'Menu names vary. Installing voice data in system settings needs internet once; the game has no internet permission.';

  @override
  String get unitReportOpenUnitForPractice => 'Open unit for practice';

  @override
  String get unitReportLearningSoFarUnitIn =>
      'Learning so far — unit in progress:';

  @override
  String get unitReportIndependentThisTime => 'Independent this time';

  @override
  String get unitReportPracticeNext => 'Practice next';

  @override
  String get unitReportScenePracticeIsSeparateFrom =>
      'Scene practice is separate from the full unit assessment.';

  @override
  String get unitReportActivityNotAvailableYet => 'Activity not available yet';

  @override
  String get unitReportNoCompletedAttemptYetThis =>
      'No completed attempt yet. This is not a learning score.';

  @override
  String unitReportLatestAttempt(Object completedAt) {
    return 'Latest attempt: $completedAt';
  }

  @override
  String unitReportFirstTryOf(Object firstTry, Object length) {
    return 'First try: $firstTry of $length';
  }

  @override
  String unitReportAfterAHintExplanationShown(
    Object afterHint,
    Object explained,
  ) {
    return 'After a hint: $afterHint • Explanation shown: $explained';
  }

  @override
  String unitReportEffortStarsOf3(Object effortStars) {
    return 'Effort stars: $effortStars of 3';
  }

  @override
  String unitReportBestAttemptOf(Object firstTry, Object length) {
    return 'Best attempt: $firstTry of $length';
  }

  @override
  String unitReportChangeFromPreviousAttempt(Object firstTry) {
    return 'Change from previous attempt: $firstTry';
  }

  @override
  String get unitReportPracticeNext2 => 'Practice next:';

  @override
  String get unitReportReplayForPractice => 'Replay for practice';

  @override
  String get unitReportBookActivityWithAGrown =>
      'Book activity — with a grown-up:';

  @override
  String unitReportDiscoveriesOf(Object length, Object length1) {
    return 'Discoveries: $length of $length1';
  }

  @override
  String parentAreaName(Object name) {
    return 'Name: $name';
  }

  @override
  String get parentAreaNameNotEntered => 'Not entered';

  @override
  String parentAreaRecoveryAffected(Object count) {
    return 'Some saved data could not be read and has not been deleted. Affected child records: $count.';
  }

  @override
  String get parentAreaRecoveryRestored =>
      'The game restored the last good copy.';

  @override
  String get parentAreaRecoveryAdvice =>
      'Copy the data and keep it in a file; afterwards you can delete the damaged copies.';

  @override
  String unitReportBeanStage(Object stage) {
    return 'Bean experiment: stage $stage of 4. Predictions are not graded.';
  }

  @override
  String unitReportInProgress(Object step, Object total) {
    return 'In progress: $step of $total steps.';
  }

  @override
  String unitReportPracticeFor(Object objective) {
    return 'Practice for: $objective';
  }

  @override
  String unitReportGoalSourcePages(Object pages) {
    return 'Goal source pages: $pages';
  }

  @override
  String unitReportSourcePages(Object pages) {
    return 'Source pages: $pages';
  }

  @override
  String unitReportOutcomeCounts(
    Object firstTry,
    Object afterHint,
    Object explained,
  ) {
    return 'First try: $firstTry • After a hint: $afterHint • Explanation needed: $explained';
  }

  @override
  String unitReportPracticeItem(Object name) {
    return 'Practice next: $name';
  }

  @override
  String childChooserDeleteTitle(Object name) {
    return 'Delete $name\'s profile?';
  }

  @override
  String get childChooserDeleteBody =>
      'This deletes the child\'s name, picture, progress and settings from this device. It cannot be undone. Other children\'s profiles stay saved.';

  @override
  String get childChooserCancel => 'Cancel';

  @override
  String get childChooserDeleteConfirm => 'Delete profile';
}

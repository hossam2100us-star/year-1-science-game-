import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @parentAreaDeleteTheDamagedCopies.
  ///
  /// In en, this message translates to:
  /// **'Delete the damaged copies?'**
  String get parentAreaDeleteTheDamagedCopies;

  /// No description provided for @parentAreaMakeSureYouCopiedAnd.
  ///
  /// In en, this message translates to:
  /// **'Make sure you copied and kept the data first. This cannot be undone.'**
  String get parentAreaMakeSureYouCopiedAnd;

  /// No description provided for @parentAreaCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get parentAreaCancel;

  /// No description provided for @parentAreaDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get parentAreaDelete;

  /// No description provided for @parentAreaBackToChild.
  ///
  /// In en, this message translates to:
  /// **'Back to child'**
  String get parentAreaBackToChild;

  /// No description provided for @parentAreaGrownUps.
  ///
  /// In en, this message translates to:
  /// **'Grown-ups'**
  String get parentAreaGrownUps;

  /// No description provided for @parentAreaFollowLearningThroughPlayDecisions.
  ///
  /// In en, this message translates to:
  /// **'Follow learning through play decisions. Predictions and free play are not graded.'**
  String get parentAreaFollowLearningThroughPlayDecisions;

  /// No description provided for @parentAreaResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get parentAreaResults;

  /// No description provided for @parentAreaSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get parentAreaSettings;

  /// No description provided for @parentAreaGuide.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get parentAreaGuide;

  /// No description provided for @parentAreaChildAndAppearance.
  ///
  /// In en, this message translates to:
  /// **'Child and appearance'**
  String get parentAreaChildAndAppearance;

  /// No description provided for @parentAreaScientistGuide.
  ///
  /// In en, this message translates to:
  /// **'Scientist guide: {guideName}'**
  String parentAreaScientistGuide(Object guideName);

  /// No description provided for @parentAreaEditNameGenderOrPicture.
  ///
  /// In en, this message translates to:
  /// **'Edit name, gender or picture'**
  String get parentAreaEditNameGenderOrPicture;

  /// No description provided for @parentAreaAdventureColours.
  ///
  /// In en, this message translates to:
  /// **'Adventure colours'**
  String get parentAreaAdventureColours;

  /// No description provided for @parentAreaAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get parentAreaAutomatic;

  /// No description provided for @parentAreaOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get parentAreaOcean;

  /// No description provided for @parentAreaBerry.
  ///
  /// In en, this message translates to:
  /// **'Berry'**
  String get parentAreaBerry;

  /// No description provided for @parentAreaForest.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get parentAreaForest;

  /// No description provided for @parentAreaEditingThisProfileKeepsProgress.
  ///
  /// In en, this message translates to:
  /// **'Editing this profile keeps progress. The first name, photo and preferences stay on this device.'**
  String get parentAreaEditingThisProfileKeepsProgress;

  /// No description provided for @parentAreaUnitAssessment.
  ///
  /// In en, this message translates to:
  /// **'Unit assessment'**
  String get parentAreaUnitAssessment;

  /// No description provided for @parentAreaStarsRewardEffortAndCompletion.
  ///
  /// In en, this message translates to:
  /// **'Stars reward effort and completion. Understanding uses first decisions before hints. Predictions and free play are not graded.'**
  String get parentAreaStarsRewardEffortAndCompletion;

  /// No description provided for @parentAreaTimeOnTheChildScreens.
  ///
  /// In en, this message translates to:
  /// **'Time on the child screens'**
  String get parentAreaTimeOnTheChildScreens;

  /// No description provided for @parentAreaNoTimeRecordedYet.
  ///
  /// In en, this message translates to:
  /// **'No time recorded yet'**
  String get parentAreaNoTimeRecordedYet;

  /// No description provided for @parentAreaMin.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get parentAreaMin;

  /// No description provided for @parentAreaTimeOnChildScreensIs.
  ///
  /// In en, this message translates to:
  /// **'Time on child screens is not a learning score. Parent-area and background time are excluded.'**
  String get parentAreaTimeOnChildScreensIs;

  /// No description provided for @parentAreaBreaksAndAudio.
  ///
  /// In en, this message translates to:
  /// **'Breaks and audio'**
  String get parentAreaBreaksAndAudio;

  /// No description provided for @parentAreaAGentleBreakEveryMinutes.
  ///
  /// In en, this message translates to:
  /// **'A gentle break every {breakMinutes} minutes'**
  String parentAreaAGentleBreakEveryMinutes(Object breakMinutes);

  /// No description provided for @parentAreaNarration.
  ///
  /// In en, this message translates to:
  /// **'Narration'**
  String get parentAreaNarration;

  /// No description provided for @parentAreaNarrationVolume.
  ///
  /// In en, this message translates to:
  /// **'Narration volume'**
  String get parentAreaNarrationVolume;

  /// No description provided for @parentAreaSoundEffectsWithTheGames.
  ///
  /// In en, this message translates to:
  /// **'Sound effects — with the games'**
  String get parentAreaSoundEffectsWithTheGames;

  /// No description provided for @parentAreaMusicComingLater.
  ///
  /// In en, this message translates to:
  /// **'Music — coming later'**
  String get parentAreaMusicComingLater;

  /// No description provided for @parentAreaHowToUseTheAdventure.
  ///
  /// In en, this message translates to:
  /// **'How to use the adventure'**
  String get parentAreaHowToUseTheAdventure;

  /// No description provided for @parentAreaBasedOnTheBookPage.
  ///
  /// In en, this message translates to:
  /// **'Based on the book, page 2.'**
  String get parentAreaBasedOnTheBookPage;

  /// No description provided for @parentAreaResetProgress.
  ///
  /// In en, this message translates to:
  /// **'Reset progress'**
  String get parentAreaResetProgress;

  /// No description provided for @parentAreaThisClearsResultsTimeAnd.
  ///
  /// In en, this message translates to:
  /// **'This clears results, time and stars, keeping the profile, photo and settings.'**
  String get parentAreaThisClearsResultsTimeAnd;

  /// No description provided for @parentAreaClearAllProgress.
  ///
  /// In en, this message translates to:
  /// **'Clear all progress?'**
  String get parentAreaClearAllProgress;

  /// No description provided for @parentAreaThisCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get parentAreaThisCannotBeUndone;

  /// No description provided for @parentAreaClearProgress.
  ///
  /// In en, this message translates to:
  /// **'Clear progress'**
  String get parentAreaClearProgress;

  /// No description provided for @parentAreaResetWithConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Reset with confirmation'**
  String get parentAreaResetWithConfirmation;

  /// No description provided for @parentAreaDataNeedingAttention.
  ///
  /// In en, this message translates to:
  /// **'Data needing attention'**
  String get parentAreaDataNeedingAttention;

  /// No description provided for @parentAreaDataCopied.
  ///
  /// In en, this message translates to:
  /// **'Data copied'**
  String get parentAreaDataCopied;

  /// No description provided for @parentAreaCopyTheData.
  ///
  /// In en, this message translates to:
  /// **'Copy the data'**
  String get parentAreaCopyTheData;

  /// No description provided for @parentAreaDeleteDamagedCopies.
  ///
  /// In en, this message translates to:
  /// **'Delete damaged copies'**
  String get parentAreaDeleteDamagedCopies;

  /// No description provided for @parentAreaDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get parentAreaDiagnostics;

  /// No description provided for @parentAreaIfSavingOrSoundGoes.
  ///
  /// In en, this message translates to:
  /// **'If saving or sound goes wrong, copy this log and send it to support yourself. It holds only error types and code locations — never the child\'s name or photo — and is never sent automatically.'**
  String get parentAreaIfSavingOrSoundGoes;

  /// No description provided for @parentAreaLogCopied.
  ///
  /// In en, this message translates to:
  /// **'Log copied'**
  String get parentAreaLogCopied;

  /// No description provided for @parentAreaCopyLog.
  ///
  /// In en, this message translates to:
  /// **'Copy log'**
  String get parentAreaCopyLog;

  /// No description provided for @voiceSettingsEnglishVoiceOnThisDevice.
  ///
  /// In en, this message translates to:
  /// **'English voice on this device'**
  String get voiceSettingsEnglishVoiceOnThisDevice;

  /// No description provided for @voiceSettingsOfflineEnglishVoicesAvailable.
  ///
  /// In en, this message translates to:
  /// **'{length} offline English voices available.'**
  String voiceSettingsOfflineEnglishVoicesAvailable(Object length);

  /// No description provided for @voiceSettingsBrowserPreviewHasNoNarration.
  ///
  /// In en, this message translates to:
  /// **'Browser preview has no narration. Test voices in the Android APK.'**
  String get voiceSettingsBrowserPreviewHasNoNarration;

  /// No description provided for @voiceSettingsNoOfflineEnglishVoiceIs.
  ///
  /// In en, this message translates to:
  /// **'No offline English voice is available.'**
  String get voiceSettingsNoOfflineEnglishVoiceIs;

  /// No description provided for @voiceSettingsAndroidDoesNotReliablyIdentify.
  ///
  /// In en, this message translates to:
  /// **'Android does not reliably identify voice gender. Listen and choose a suitable voice for Zizo or Zizi.'**
  String get voiceSettingsAndroidDoesNotReliablyIdentify;

  /// No description provided for @voiceSettingsVoiceForThisGuide.
  ///
  /// In en, this message translates to:
  /// **'Voice for this guide'**
  String get voiceSettingsVoiceForThisGuide;

  /// No description provided for @voiceSettingsAutomaticDeviceDefault.
  ///
  /// In en, this message translates to:
  /// **'Automatic (device default)'**
  String get voiceSettingsAutomaticDeviceDefault;

  /// No description provided for @voiceSettingsTryVoice.
  ///
  /// In en, this message translates to:
  /// **'Try voice'**
  String get voiceSettingsTryVoice;

  /// No description provided for @voiceSettingsCheckVoicesAgain.
  ///
  /// In en, this message translates to:
  /// **'Check voices again'**
  String get voiceSettingsCheckVoicesAgain;

  /// No description provided for @voiceSettingsIfNoVoiceIsAvailable.
  ///
  /// In en, this message translates to:
  /// **'If no voice is available, use the tablet settings once:'**
  String get voiceSettingsIfNoVoiceIsAvailable;

  /// No description provided for @voiceSettings1OpenDeviceSettings2.
  ///
  /// In en, this message translates to:
  /// **'1. Open device Settings.\n2. Search for Text-to-speech.\n3. Open the speech engine settings.\n4. Choose Install voice data.\n5. Download English.\n6. Return and tap Check voices again.'**
  String get voiceSettings1OpenDeviceSettings2;

  /// No description provided for @voiceSettingsMenuNamesVaryInstallingVoice.
  ///
  /// In en, this message translates to:
  /// **'Menu names vary. Installing voice data in system settings needs internet once; the game has no internet permission.'**
  String get voiceSettingsMenuNamesVaryInstallingVoice;

  /// No description provided for @unitReportOpenUnitForPractice.
  ///
  /// In en, this message translates to:
  /// **'Open unit for practice'**
  String get unitReportOpenUnitForPractice;

  /// No description provided for @unitReportLearningSoFarUnitIn.
  ///
  /// In en, this message translates to:
  /// **'Learning so far — unit in progress:'**
  String get unitReportLearningSoFarUnitIn;

  /// No description provided for @unitReportIndependentThisTime.
  ///
  /// In en, this message translates to:
  /// **'Independent this time'**
  String get unitReportIndependentThisTime;

  /// No description provided for @unitReportPracticeNext.
  ///
  /// In en, this message translates to:
  /// **'Practice next'**
  String get unitReportPracticeNext;

  /// No description provided for @unitReportScenePracticeIsSeparateFrom.
  ///
  /// In en, this message translates to:
  /// **'Scene practice is separate from the full unit assessment.'**
  String get unitReportScenePracticeIsSeparateFrom;

  /// No description provided for @unitReportActivityNotAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'Activity not available yet'**
  String get unitReportActivityNotAvailableYet;

  /// No description provided for @unitReportNoCompletedAttemptYetThis.
  ///
  /// In en, this message translates to:
  /// **'No completed attempt yet. This is not a learning score.'**
  String get unitReportNoCompletedAttemptYetThis;

  /// No description provided for @unitReportLatestAttempt.
  ///
  /// In en, this message translates to:
  /// **'Latest attempt: {completedAt}'**
  String unitReportLatestAttempt(Object completedAt);

  /// No description provided for @unitReportFirstTryOf.
  ///
  /// In en, this message translates to:
  /// **'First try: {firstTry} of {length}'**
  String unitReportFirstTryOf(Object firstTry, Object length);

  /// No description provided for @unitReportAfterAHintExplanationShown.
  ///
  /// In en, this message translates to:
  /// **'After a hint: {afterHint} • Explanation shown: {explained}'**
  String unitReportAfterAHintExplanationShown(
    Object afterHint,
    Object explained,
  );

  /// No description provided for @unitReportEffortStarsOf3.
  ///
  /// In en, this message translates to:
  /// **'Effort stars: {effortStars} of 3'**
  String unitReportEffortStarsOf3(Object effortStars);

  /// No description provided for @unitReportBestAttemptOf.
  ///
  /// In en, this message translates to:
  /// **'Best attempt: {firstTry} of {length}'**
  String unitReportBestAttemptOf(Object firstTry, Object length);

  /// No description provided for @unitReportChangeFromPreviousAttempt.
  ///
  /// In en, this message translates to:
  /// **'Change from previous attempt: {firstTry}'**
  String unitReportChangeFromPreviousAttempt(Object firstTry);

  /// No description provided for @unitReportPracticeNext2.
  ///
  /// In en, this message translates to:
  /// **'Practice next:'**
  String get unitReportPracticeNext2;

  /// No description provided for @unitReportReplayForPractice.
  ///
  /// In en, this message translates to:
  /// **'Replay for practice'**
  String get unitReportReplayForPractice;

  /// No description provided for @unitReportBookActivityWithAGrown.
  ///
  /// In en, this message translates to:
  /// **'Book activity — with a grown-up:'**
  String get unitReportBookActivityWithAGrown;

  /// No description provided for @unitReportDiscoveriesOf.
  ///
  /// In en, this message translates to:
  /// **'Discoveries: {length} of {length1}'**
  String unitReportDiscoveriesOf(Object length, Object length1);

  /// No description provided for @parentAreaName.
  ///
  /// In en, this message translates to:
  /// **'Name: {name}'**
  String parentAreaName(Object name);

  /// No description provided for @parentAreaNameNotEntered.
  ///
  /// In en, this message translates to:
  /// **'Not entered'**
  String get parentAreaNameNotEntered;

  /// No description provided for @parentAreaRecoveryAffected.
  ///
  /// In en, this message translates to:
  /// **'Some saved data could not be read and has not been deleted. Affected child records: {count}.'**
  String parentAreaRecoveryAffected(Object count);

  /// No description provided for @parentAreaRecoveryRestored.
  ///
  /// In en, this message translates to:
  /// **'The game restored the last good copy.'**
  String get parentAreaRecoveryRestored;

  /// No description provided for @parentAreaRecoveryAdvice.
  ///
  /// In en, this message translates to:
  /// **'Copy the data and keep it in a file; afterwards you can delete the damaged copies.'**
  String get parentAreaRecoveryAdvice;

  /// No description provided for @unitReportBeanStage.
  ///
  /// In en, this message translates to:
  /// **'Bean experiment: stage {stage} of 4. Predictions are not graded.'**
  String unitReportBeanStage(Object stage);

  /// No description provided for @unitReportInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress: {step} of {total} steps.'**
  String unitReportInProgress(Object step, Object total);

  /// No description provided for @unitReportPracticeFor.
  ///
  /// In en, this message translates to:
  /// **'Practice for: {objective}'**
  String unitReportPracticeFor(Object objective);

  /// No description provided for @unitReportGoalSourcePages.
  ///
  /// In en, this message translates to:
  /// **'Goal source pages: {pages}'**
  String unitReportGoalSourcePages(Object pages);

  /// No description provided for @unitReportSourcePages.
  ///
  /// In en, this message translates to:
  /// **'Source pages: {pages}'**
  String unitReportSourcePages(Object pages);

  /// No description provided for @unitReportOutcomeCounts.
  ///
  /// In en, this message translates to:
  /// **'First try: {firstTry} • After a hint: {afterHint} • Explanation needed: {explained}'**
  String unitReportOutcomeCounts(
    Object firstTry,
    Object afterHint,
    Object explained,
  );

  /// No description provided for @unitReportPracticeItem.
  ///
  /// In en, this message translates to:
  /// **'Practice next: {name}'**
  String unitReportPracticeItem(Object name);

  /// No description provided for @childChooserDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}\'s profile?'**
  String childChooserDeleteTitle(Object name);

  /// No description provided for @childChooserDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes the child\'s name, picture, progress and settings from this device. It cannot be undone. Other children\'s profiles stay saved.'**
  String get childChooserDeleteBody;

  /// No description provided for @childChooserCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get childChooserCancel;

  /// No description provided for @childChooserDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete profile'**
  String get childChooserDeleteConfirm;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

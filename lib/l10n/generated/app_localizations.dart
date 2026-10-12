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

  /// No description provided for @parentAreaMathsResultsRetry.
  ///
  /// In en, this message translates to:
  /// **'Try opening the Maths results again'**
  String get parentAreaMathsResultsRetry;

  /// No description provided for @parentAreaMathsGuideRetry.
  ///
  /// In en, this message translates to:
  /// **'Try opening the Maths guide again'**
  String get parentAreaMathsGuideRetry;

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

  /// No description provided for @childChooserDeleteLinked.
  ///
  /// In en, this message translates to:
  /// **'This child is saved in your parent account, so the profile and progress are also removed from the account and from your other devices.'**
  String get childChooserDeleteLinked;

  /// No description provided for @parentAreaAccount.
  ///
  /// In en, this message translates to:
  /// **'Parent account'**
  String get parentAreaAccount;

  /// No description provided for @parentAreaEditingLinkedProfile.
  ///
  /// In en, this message translates to:
  /// **'Editing this profile keeps progress. The first name and preferences are also saved in your parent account; the photo stays on this device.'**
  String get parentAreaEditingLinkedProfile;

  /// No description provided for @choiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome! Before we start'**
  String get choiceTitle;

  /// No description provided for @choiceBody.
  ///
  /// In en, this message translates to:
  /// **'A grown-up chooses how the game keeps the children\'s progress. You can change this later in the parent area.'**
  String get choiceBody;

  /// No description provided for @choiceDeviceButton.
  ///
  /// In en, this message translates to:
  /// **'Play on this device only'**
  String get choiceDeviceButton;

  /// No description provided for @choiceContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue to the game'**
  String get choiceContinue;

  /// No description provided for @accountNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get accountNotNow;

  /// No description provided for @accountDeviceOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'This device only'**
  String get accountDeviceOnlyTitle;

  /// No description provided for @accountDeviceOnlyBody.
  ///
  /// In en, this message translates to:
  /// **'Children and their progress are saved on this device only. The app does not connect to the Internet.'**
  String get accountDeviceOnlyBody;

  /// No description provided for @accountWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'A parent account'**
  String get accountWhyTitle;

  /// No description provided for @accountWhyBody.
  ///
  /// In en, this message translates to:
  /// **'With a parent account, the children you choose appear with their progress on your other devices and on the website. You can stop at any time; nothing is deleted from this device.'**
  String get accountWhyBody;

  /// No description provided for @accountUseAccount.
  ///
  /// In en, this message translates to:
  /// **'Set up a parent account'**
  String get accountUseAccount;

  /// No description provided for @accountConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you start'**
  String get accountConsentTitle;

  /// No description provided for @accountConsentTrial.
  ///
  /// In en, this message translates to:
  /// **'Private trial: this wording is a draft for the trial with family and friends.'**
  String get accountConsentTrial;

  /// No description provided for @accountConsentParent.
  ///
  /// In en, this message translates to:
  /// **'I am the parent or guardian of the children I will save in the account.'**
  String get accountConsentParent;

  /// No description provided for @accountConsentData.
  ///
  /// In en, this message translates to:
  /// **'For each child I save in the account, I agree that the first name, gender, avatar, colours, settings, lesson progress and play time are stored on the family server. Photos never leave this device.'**
  String get accountConsentData;

  /// No description provided for @accountConsentDelete.
  ///
  /// In en, this message translates to:
  /// **'I know I can delete the account and everything stored in it at any time.'**
  String get accountConsentDelete;

  /// No description provided for @accountContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get accountContinue;

  /// No description provided for @accountCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get accountCancel;

  /// No description provided for @accountSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get accountSignInTitle;

  /// No description provided for @accountEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get accountEmail;

  /// No description provided for @accountPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get accountPassword;

  /// No description provided for @accountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get accountSignIn;

  /// No description provided for @accountCreate.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get accountCreate;

  /// No description provided for @accountCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a parent account'**
  String get accountCreateTitle;

  /// No description provided for @accountPasswordRule.
  ///
  /// In en, this message translates to:
  /// **'At least 12 characters. A short sentence is easy to remember.'**
  String get accountPasswordRule;

  /// No description provided for @accountPasswordRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat the password'**
  String get accountPasswordRepeat;

  /// No description provided for @accountPasswordsDiffer.
  ///
  /// In en, this message translates to:
  /// **'The two passwords are different.'**
  String get accountPasswordsDiffer;

  /// No description provided for @accountPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 12 characters.'**
  String get accountPasswordShort;

  /// No description provided for @accountEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an email address.'**
  String get accountEmailInvalid;

  /// No description provided for @accountHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get accountHaveAccount;

  /// No description provided for @accountForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot the password?'**
  String get accountForgot;

  /// No description provided for @accountForgotSend.
  ///
  /// In en, this message translates to:
  /// **'Send a reset link'**
  String get accountForgotSend;

  /// No description provided for @accountForgotSent.
  ///
  /// In en, this message translates to:
  /// **'If this email has an account, a link to choose a new password is on its way.'**
  String get accountForgotSent;

  /// No description provided for @accountBackToDevice.
  ///
  /// In en, this message translates to:
  /// **'Keep it on this device only'**
  String get accountBackToDevice;

  /// No description provided for @accountErrorCredentials.
  ///
  /// In en, this message translates to:
  /// **'The email or password is not right.'**
  String get accountErrorCredentials;

  /// No description provided for @accountErrorOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection to the server. Check the Internet and try again.'**
  String get accountErrorOffline;

  /// No description provided for @accountErrorBusy.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait a little and try again.'**
  String get accountErrorBusy;

  /// No description provided for @accountErrorBreached.
  ///
  /// In en, this message translates to:
  /// **'Choose another password: this one appears in known data breaches.'**
  String get accountErrorBreached;

  /// No description provided for @accountErrorClosed.
  ///
  /// In en, this message translates to:
  /// **'Creating accounts is closed right now.'**
  String get accountErrorClosed;

  /// No description provided for @accountErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again later.'**
  String get accountErrorGeneric;

  /// No description provided for @accountCreatedCheckEmail.
  ///
  /// In en, this message translates to:
  /// **'We sent an email to confirm the address. If you already had an account, sign in with its password.'**
  String get accountCreatedCheckEmail;

  /// No description provided for @accountSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String accountSignedInAs(Object email);

  /// No description provided for @accountConfirmEmail.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email address to start syncing: open the link we sent to {email}.'**
  String accountConfirmEmail(Object email);

  /// No description provided for @accountResend.
  ///
  /// In en, this message translates to:
  /// **'Send the email again'**
  String get accountResend;

  /// No description provided for @accountResent.
  ///
  /// In en, this message translates to:
  /// **'Sent. Check the inbox and the spam folder.'**
  String get accountResent;

  /// No description provided for @accountConfirmed.
  ///
  /// In en, this message translates to:
  /// **'I confirmed it'**
  String get accountConfirmed;

  /// No description provided for @accountChildrenTitle.
  ///
  /// In en, this message translates to:
  /// **'Children on this device'**
  String get accountChildrenTitle;

  /// No description provided for @accountChildrenBody.
  ///
  /// In en, this message translates to:
  /// **'Only the children you save in the account are synced. The others stay on this device only.'**
  String get accountChildrenBody;

  /// No description provided for @accountLinked.
  ///
  /// In en, this message translates to:
  /// **'Saved in the account'**
  String get accountLinked;

  /// No description provided for @accountNotLinked.
  ///
  /// In en, this message translates to:
  /// **'This device only'**
  String get accountNotLinked;

  /// No description provided for @accountLink.
  ///
  /// In en, this message translates to:
  /// **'Add to the account'**
  String get accountLink;

  /// No description provided for @accountLinkName.
  ///
  /// In en, this message translates to:
  /// **'Edit the name first: up to 24 letters, without numbers or symbols.'**
  String get accountLinkName;

  /// No description provided for @accountLinkConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Save {name} in the account?'**
  String accountLinkConfirmTitle(Object name);

  /// No description provided for @accountLinkConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The first name, gender, avatar, colours, settings, lesson progress and play time will be stored in your parent account and will appear on your other devices. The photo stays here.'**
  String get accountLinkConfirmBody;

  /// No description provided for @accountSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get accountSyncTitle;

  /// No description provided for @accountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email'**
  String get accountConfirmTitle;

  /// No description provided for @accountSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get accountSyncNow;

  /// No description provided for @accountSyncRunning.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get accountSyncRunning;

  /// No description provided for @accountSyncLast.
  ///
  /// In en, this message translates to:
  /// **'Last synced: {time}'**
  String accountSyncLast(Object time);

  /// No description provided for @accountSyncNever.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet.'**
  String get accountSyncNever;

  /// No description provided for @accountSyncWaiting.
  ///
  /// In en, this message translates to:
  /// **'Changes waiting to be sent: {count}'**
  String accountSyncWaiting(int count);

  /// No description provided for @accountSyncAllSent.
  ///
  /// In en, this message translates to:
  /// **'Everything is saved in the account.'**
  String get accountSyncAllSent;

  /// No description provided for @accountSyncOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection. Changes wait on this device and are sent later.'**
  String get accountSyncOffline;

  /// No description provided for @accountSyncUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The server is busy. Sync will try again later.'**
  String get accountSyncUnavailable;

  /// No description provided for @accountSyncUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Sync ran into a problem and will try again. The diagnostics log has details.'**
  String get accountSyncUnexpected;

  /// No description provided for @accountSyncSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to continue syncing. Nothing on this device changed.'**
  String get accountSyncSignedOut;

  /// No description provided for @accountSyncRefused.
  ///
  /// In en, this message translates to:
  /// **'Changes the account refused, kept on this device: {count}'**
  String accountSyncRefused(int count);

  /// No description provided for @accountSyncRetry.
  ///
  /// In en, this message translates to:
  /// **'Send them again'**
  String get accountSyncRetry;

  /// No description provided for @accountIssueName.
  ///
  /// In en, this message translates to:
  /// **'{child}: the name was changed on another device to “{theirs}”. This device had “{mine}”.'**
  String accountIssueName(Object child, Object theirs, Object mine);

  /// No description provided for @accountIssueGender.
  ///
  /// In en, this message translates to:
  /// **'{child}: the gender was changed on another device.'**
  String accountIssueGender(Object child);

  /// No description provided for @accountIssueKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get accountIssueKeep;

  /// No description provided for @accountIssueUseMine.
  ///
  /// In en, this message translates to:
  /// **'Use this device\'s'**
  String get accountIssueUseMine;

  /// No description provided for @accountIssueRemoved.
  ///
  /// In en, this message translates to:
  /// **'{child} was removed from the account on another device, so it was removed here too.'**
  String accountIssueRemoved(Object child);

  /// No description provided for @accountIssueUnavailable.
  ///
  /// In en, this message translates to:
  /// **'{child} could not be saved in the account because it was deleted from the account before. It stays on this device only.'**
  String accountIssueUnavailable(Object child);

  /// No description provided for @accountIssueOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get accountIssueOk;

  /// No description provided for @accountManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountManageTitle;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// No description provided for @accountSignOutBody.
  ///
  /// In en, this message translates to:
  /// **'Children and progress stay on this device. Sync stops until you sign in again.'**
  String get accountSignOutBody;

  /// No description provided for @accountLeave.
  ///
  /// In en, this message translates to:
  /// **'Stop using the account on this device'**
  String get accountLeave;

  /// No description provided for @accountLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'Every child stays on this device with all progress, as a device-only child. The account keeps its own copy.'**
  String get accountLeaveBody;

  /// No description provided for @accountDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete the account'**
  String get accountDelete;

  /// No description provided for @accountDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes the parent account and everything stored in it. The children and their progress stay on this device. Enter the password to confirm.'**
  String get accountDeleteBody;

  /// No description provided for @accountDeleteScheduled.
  ///
  /// In en, this message translates to:
  /// **'The account will be deleted on {date}.'**
  String accountDeleteScheduled(Object date);
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

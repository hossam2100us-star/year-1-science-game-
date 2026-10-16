// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get parentAreaDeleteTheDamagedCopies => 'تمسح النسخ البايظة؟';

  @override
  String get parentAreaMakeSureYouCopiedAnd =>
      'اتأكد إنك نسخت البيانات وحفظتها الأول. المسح نهائي.';

  @override
  String get parentAreaCancel => 'إلغاء';

  @override
  String get parentAreaDelete => 'امسح';

  @override
  String get parentAreaBackToChild => 'ارجع للطفل';

  @override
  String get parentAreaGrownUps => 'ركن الأهل';

  @override
  String get parentAreaFollowLearningThroughPlayDecisions =>
      'تابع تقدم الطفل من قراراته أثناء اللعب. التوقعات واللعب الحر مش درجات.';

  @override
  String get parentAreaResults => 'النتائج';

  @override
  String get parentAreaSettings => 'الإعدادات';

  @override
  String get parentAreaGuide => 'دليل الاستخدام';

  @override
  String get parentAreaChildAndAppearance => 'بيانات الطفل وشكل اللعبة';

  @override
  String parentAreaScientistGuide(Object guideName) {
    return 'الشخصية المرافقة: $guideName';
  }

  @override
  String get parentAreaEditNameGenderOrPicture =>
      'غيّر الاسم أو الجنس أو الصورة';

  @override
  String get parentAreaAdventureColours => 'ألوان اللعبة';

  @override
  String get parentAreaAutomatic => 'حسب اختيار الطفل';

  @override
  String get parentAreaOcean => 'أزرق';

  @override
  String get parentAreaBerry => 'بنفسجي';

  @override
  String get parentAreaForest => 'أخضر';

  @override
  String get parentAreaEditingThisProfileKeepsProgress =>
      'تغيير البيانات مش بيمسح التقدم. الاسم الأول والصورة والاختيارات بتفضل على الجهاز بس.';

  @override
  String get parentAreaUnitAssessment => 'تقييم كل وحدة';

  @override
  String get parentAreaStarsRewardEffortAndCompletion =>
      'النجوم للمجهود والإكمال. تقييم الفهم بيتحسب من أول قرار قبل التلميح؛ التوقع واللعب الحر مش درجات.';

  @override
  String get parentAreaMathsResultsRetry => 'جرّب تفتح نتايج الرياضيات تاني';

  @override
  String get parentAreaMathsGuideRetry => 'جرّب تفتح دليل الرياضيات تاني';

  @override
  String get parentAreaTimeOnTheChildScreens => 'وقت الاستخدام';

  @override
  String get parentAreaNoTimeRecordedYet => 'لسه مفيش وقت مسجل';

  @override
  String get parentAreaMin => 'دقيقة';

  @override
  String get parentAreaTimeOnChildScreensIs =>
      'الوقت ده وقت فتح شاشات الطفل، مش دليل على التعلم. وقت ركن الأهل والخلفية مش بيتحسب.';

  @override
  String get parentAreaBreaksAndAudio => 'الراحة والصوت';

  @override
  String parentAreaAGentleBreakEveryMinutes(Object breakMinutes) {
    return 'تذكير راحة كل $breakMinutes دقيقة';
  }

  @override
  String get parentAreaNarration => 'قراءة الكلام';

  @override
  String get parentAreaNarrationVolume => 'مستوى صوت القراءة';

  @override
  String get parentAreaSoundEffectsWithTheGames =>
      'المؤثرات — هتتوفر مع الألعاب';

  @override
  String get parentAreaMusicComingLater => 'الموسيقى — هتتوفر لاحقًا';

  @override
  String get parentAreaHowToUseTheAdventure => 'نستخدم اللعبة إزاي؟';

  @override
  String get parentAreaBasedOnTheBookPage => 'مبني على قواعد الكتاب، صفحة ٢.';

  @override
  String get parentAreaResetProgress => 'مسح التقدم';

  @override
  String get parentAreaThisClearsResultsTimeAnd =>
      'ده بيمسح النتائج والوقت والنجوم بس، وبيسيب اسم الطفل وصورته والإعدادات.';

  @override
  String get parentAreaClearAllProgress => 'متأكد من مسح التقدم؟';

  @override
  String get parentAreaThisCannotBeUndone => 'المسح نهائي ومفيش رجوع.';

  @override
  String get parentAreaClearProgress => 'امسح التقدم';

  @override
  String get parentAreaResetWithConfirmation => 'مسح التقدم بعد التأكيد';

  @override
  String get parentAreaDataNeedingAttention => 'بيانات محتاجة مراجعة';

  @override
  String get parentAreaDataCopied => 'اتنسخت البيانات';

  @override
  String get parentAreaCopyTheData => 'انسخ البيانات';

  @override
  String get parentAreaDeleteDamagedCopies => 'امسح النسخ البايظة';

  @override
  String get parentAreaDiagnostics => 'سجل الأعطال';

  @override
  String get parentAreaIfSavingOrSoundGoes =>
      'لو حصلت مشكلة في الحفظ أو الصوت، انسخ السجل وابعته للدعم بنفسك. السجل فيه نوع العطل ومكانه في الكود بس؛ مفيهوش اسم الطفل أو صورته، ومش بيتبعت لأي حد تلقائيًا.';

  @override
  String get parentAreaLogCopied => 'اتنسخ السجل';

  @override
  String get parentAreaCopyLog => 'انسخ السجل';

  @override
  String get voiceSettingsEnglishVoiceOnThisDevice =>
      'الصوت الإنجليزي على الجهاز';

  @override
  String voiceSettingsOfflineEnglishVoicesAvailable(Object length) {
    return 'متاح $length صوت إنجليزي يعمل من غير إنترنت.';
  }

  @override
  String get voiceSettingsBrowserPreviewHasNoNarration =>
      'معاينة المتصفح من غير قراءة صوتية. جرّب الصوت في نسخة APK على التابلت.';

  @override
  String get voiceSettingsNoOfflineEnglishVoiceIs =>
      'مش لاقيين صوت إنجليزي جاهز من غير إنترنت.';

  @override
  String get voiceSettingsAndroidDoesNotReliablyIdentify =>
      'أندرويد مش بيحدد جنس كل صوت. اسمع الصوت واختار المناسب لزيزو أو زيزي.';

  @override
  String get voiceSettingsVoiceForThisGuide => 'صوت الشخصية الحالية';

  @override
  String get voiceSettingsAutomaticDeviceDefault =>
      'تلقائي (صوت الجهاز الافتراضي)';

  @override
  String get voiceSettingsTryVoice => 'جرّب الصوت';

  @override
  String get voiceSettingsCheckVoicesAgain => 'افحص الأصوات تاني';

  @override
  String get voiceSettingsIfNoVoiceIsAvailable =>
      'لو الصوت مش موجود، اعمل الخطوات دي من إعدادات التابلت مرة واحدة:';

  @override
  String get voiceSettings1OpenDeviceSettings2 =>
      '١. افتح إعدادات الجهاز.\n٢. ابحث عن «تحويل النص إلى كلام».\n٣. افتح إعدادات محرك الصوت.\n٤. اختار «تثبيت بيانات الصوت».\n٥. نزّل English.\n٦. ارجع للعبة واضغط «افحص الأصوات تاني».';

  @override
  String get voiceSettingsMenuNamesVaryInstallingVoice =>
      'أسماء القوايم ممكن تختلف. تنزيل الصوت من إعدادات الجهاز محتاج إنترنت مرة واحدة؛ اللعبة نفسها مفيهاش إذن إنترنت.';

  @override
  String get unitReportOpenUnitForPractice => 'افتح الوحدة للتدريب';

  @override
  String get unitReportLearningSoFarUnitIn =>
      'ملاحظات أثناء اللعب — قبل إكمال الوحدة:';

  @override
  String get unitReportIndependentThisTime => 'أتقن في المحاولة دي';

  @override
  String get unitReportPracticeNext => 'محتاج تدريب';

  @override
  String get unitReportScenePracticeIsSeparateFrom =>
      'نتائج تدريب المشاهد منفصلة عن تقييم الوحدة الكاملة.';

  @override
  String get unitReportActivityNotAvailableYet => 'النشاط لسه مش متاح';

  @override
  String get unitReportNoCompletedAttemptYetThis =>
      'لسه مفيش محاولة كاملة — مش معناه إن الطفل مش فاهم.';

  @override
  String unitReportLatestAttempt(Object completedAt) {
    return 'آخر محاولة: $completedAt';
  }

  @override
  String unitReportFirstTryOf(Object firstTry, Object length) {
    return 'من أول مرة: $firstTry من $length';
  }

  @override
  String unitReportAfterAHintExplanationShown(
    Object afterHint,
    Object explained,
  ) {
    return 'بعد تلميح: $afterHint • بعد شرح: $explained';
  }

  @override
  String unitReportEffortStarsOf3(Object effortStars) {
    return 'نجوم المجهود: $effortStars من ٣';
  }

  @override
  String unitReportBestAttemptOf(Object firstTry, Object length) {
    return 'أفضل محاولة: $firstTry من $length';
  }

  @override
  String unitReportChangeFromPreviousAttempt(Object firstTry) {
    return 'الفرق عن المحاولة السابقة: $firstTry';
  }

  @override
  String get unitReportPracticeNext2 => 'لسه محتاج تدريب:';

  @override
  String get unitReportReplayForPractice => 'ارجع للعبة للتدريب';

  @override
  String get unitReportBookActivityWithAGrown =>
      'نشاط منزلي من الكتاب — مع شخص كبير:';

  @override
  String unitReportDiscoveriesOf(Object length, Object length1) {
    return 'اكتشافات: $length من $length1';
  }

  @override
  String parentAreaName(Object name) {
    return 'الاسم: $name';
  }

  @override
  String get parentAreaNameNotEntered => 'مش مكتوب';

  @override
  String parentAreaRecoveryAffected(Object count) {
    return 'في بيانات محفوظة ما قدرناش نقراها، وما اتمسحتش. عدد سجلات الأطفال المتأثرة: $count.';
  }

  @override
  String get parentAreaRecoveryRestored => 'اللعبة رجعت لآخر نسخة سليمة.';

  @override
  String get parentAreaRecoveryAdvice =>
      'انسخ البيانات واحفظها في ملف، وبعدين تقدر تمسح النسخ البايظة.';

  @override
  String unitReportBeanStage(Object stage) {
    return 'تجربة الفاصوليا: المرحلة $stage من ٤. التوقع مش بيتحسب بدرجة.';
  }

  @override
  String unitReportInProgress(Object step, Object total) {
    return 'مكمل لحد خطوة $step من $total.';
  }

  @override
  String unitReportPracticeFor(Object objective) {
    return 'تدريب مناسب للهدف: $objective';
  }

  @override
  String unitReportGoalSourcePages(Object pages) {
    return 'مرجع الهدف: $pages';
  }

  @override
  String unitReportSourcePages(Object pages) {
    return 'صفحات المرجع: $pages';
  }

  @override
  String unitReportOutcomeCounts(
    Object firstTry,
    Object afterHint,
    Object explained,
  ) {
    return 'من أول مرة: $firstTry • بعد تلميح: $afterHint • احتاج شرح: $explained';
  }

  @override
  String unitReportPracticeItem(Object name) {
    return 'محتاج تدريب: $name';
  }

  @override
  String childChooserDeleteTitle(Object name) {
    return 'حذف ملف $name؟';
  }

  @override
  String get childChooserDeleteBody =>
      'سيتم حذف اسم الطفل وصورته وتقدمه وإعداداته من هذا الجهاز. لا يمكن التراجع عن الحذف. ملفات الأطفال الآخرين ستبقى محفوظة.';

  @override
  String get childChooserCancel => 'إلغاء';

  @override
  String get childChooserDeleteConfirm => 'حذف الملف';

  @override
  String get childChooserDeleteLinked =>
      'الطفل ده محفوظ في حساب ولي الأمر، فبياناته وتقدّمه هيتمسحوا كمان من الحساب ومن أجهزتك التانية.';

  @override
  String get parentAreaAccount => 'حساب ولي الأمر';

  @override
  String get parentAreaEditingLinkedProfile =>
      'تغيير البيانات مش بيمسح التقدم. الاسم الأول والاختيارات بيتحفظوا كمان في حساب ولي الأمر، والصورة بتفضل على الجهاز ده بس.';

  @override
  String get choiceTitle => 'أهلاً بيك! قبل ما نبدأ';

  @override
  String get loginBody =>
      'سجّل دخول بحساب ولي الأمر عشان تشوف تقدّم الأطفال على كل أجهزتك، أو كمّل من غير إنترنت باللي محفوظ على الجهاز ده.';

  @override
  String get loginOffline => 'كمّل من غير إنترنت';

  @override
  String get loginOfflineBody =>
      'هتلعب بالأطفال والتقدّم المحفوظين على الجهاز ده. تقدر تسجّل دخول بعدين، من هنا أو من ركن الأهل.';

  @override
  String get accountNotNow => 'مش دلوقتي';

  @override
  String get accountDeviceOnlyTitle => 'على الجهاز ده بس';

  @override
  String get accountDeviceOnlyBody =>
      'الأطفال وتقدّمهم محفوظين على الجهاز ده بس، واللعبة مش بتتصل بالإنترنت.';

  @override
  String get accountWhyTitle => 'حساب ولي الأمر';

  @override
  String get accountWhyBody =>
      'بحساب ولي الأمر، الأطفال اللي تختارهم بيظهروا بتقدّمهم على أجهزتك التانية وعلى الموقع. تقدر توقف في أي وقت، ومفيش حاجة بتتمسح من الجهاز ده.';

  @override
  String get accountUseAccount => 'جهّز حساب ولي الأمر';

  @override
  String get accountConsentTitle => 'قبل ما تبدأ';

  @override
  String get accountConsentTrial =>
      'تجربة خاصة: الكلام ده مسودة لتجربة الأهل والأصحاب.';

  @override
  String get accountConsentParent =>
      'أنا ولي أمر الأطفال اللي هحفظهم في الحساب.';

  @override
  String get accountConsentData =>
      'موافق إن لكل طفل أحفظه في الحساب، يتحفظ على سيرفر العيلة: الاسم الأول والجنس والشخصية والألوان والإعدادات وتقدّم الدروس ووقت اللعب. الصور عمرها ما بتخرج من الجهاز ده.';

  @override
  String get accountConsentDelete =>
      'عارف إني أقدر أمسح الحساب وكل اللي محفوظ فيه في أي وقت.';

  @override
  String get accountContinue => 'كمّل';

  @override
  String get accountCancel => 'إلغاء';

  @override
  String get accountSignInTitle => 'تسجيل الدخول';

  @override
  String get accountEmail => 'الإيميل';

  @override
  String get accountPassword => 'كلمة السر';

  @override
  String get accountSignIn => 'ادخل';

  @override
  String get accountCreate => 'اعمل حساب جديد';

  @override
  String get accountCreateTitle => 'حساب ولي أمر جديد';

  @override
  String get accountPasswordRule =>
      '١٢ حرف على الأقل. جملة قصيرة بتبقى أسهل في الحفظ.';

  @override
  String get accountPasswordRepeat => 'اكتب كلمة السر تاني';

  @override
  String get accountPasswordsDiffer => 'كلمتين السر مش زي بعض.';

  @override
  String get accountPasswordShort => 'استخدم ١٢ حرف على الأقل.';

  @override
  String get accountEmailInvalid => 'اكتب إيميل صحيح.';

  @override
  String get accountHaveAccount => 'عندي حساب بالفعل';

  @override
  String get accountForgot => 'نسيت كلمة السر؟';

  @override
  String get accountForgotSend => 'ابعت لينك التغيير';

  @override
  String get accountForgotSent =>
      'لو الإيميل ده عليه حساب، هيوصله لينك تختار بيه كلمة سر جديدة.';

  @override
  String get accountBackToDevice => 'خليها على الجهاز ده بس';

  @override
  String get accountErrorCredentials => 'الإيميل أو كلمة السر مش صح.';

  @override
  String get accountErrorOffline =>
      'مفيش اتصال بالسيرفر. اتأكد من النت وجرّب تاني.';

  @override
  String get accountErrorBusy => 'محاولات كتير. استنى شوية وجرّب تاني.';

  @override
  String get accountErrorBreached =>
      'اختار كلمة سر تانية: دي ظهرت في تسريبات بيانات معروفة.';

  @override
  String get accountErrorClosed => 'عمل حسابات جديدة مقفول دلوقتي.';

  @override
  String get accountErrorGeneric => 'حصلت مشكلة. جرّب تاني بعد شوية.';

  @override
  String get accountCreatedCheckEmail =>
      'بعتنالك إيميل عشان تأكد العنوان. لو كان عندك حساب قبل كده، ادخل بكلمة السر بتاعته.';

  @override
  String accountSignedInAs(Object email) {
    return 'داخل بحساب $email';
  }

  @override
  String accountConfirmEmail(Object email) {
    return 'أكّد الإيميل عشان المزامنة تبدأ: افتح اللينك اللي بعتناه على $email.';
  }

  @override
  String get accountResend => 'ابعت الإيميل تاني';

  @override
  String get accountResent => 'اتبعت. بص في الوارد وفي الـSpam.';

  @override
  String get accountConfirmed => 'أكدته';

  @override
  String get accountChildrenTitle => 'الأطفال على الجهاز ده';

  @override
  String get accountChildrenBody =>
      'الأطفال اللي تحفظهم في الحساب بس هم اللي بيتزامنوا، والباقي بيفضل على الجهاز ده بس.';

  @override
  String get accountLinked => 'محفوظ في الحساب';

  @override
  String get accountNotLinked => 'على الجهاز ده بس';

  @override
  String get accountLink => 'ضيفه للحساب';

  @override
  String get accountLinkName =>
      'عدّل الاسم الأول: لحد ٢٤ حرف من غير أرقام أو رموز.';

  @override
  String accountLinkConfirmTitle(Object name) {
    return 'تحفظ $name في الحساب؟';
  }

  @override
  String get accountLinkConfirmBody =>
      'الاسم الأول والجنس والشخصية والألوان والإعدادات وتقدّم الدروس ووقت اللعب هيتحفظوا في حساب ولي الأمر ويظهروا على أجهزتك التانية. الصورة بتفضل هنا.';

  @override
  String get accountSyncTitle => 'المزامنة';

  @override
  String get accountConfirmTitle => 'أكّد الإيميل';

  @override
  String get accountSyncNow => 'زامن دلوقتي';

  @override
  String get accountSyncRunning => 'بيزامن…';

  @override
  String accountSyncLast(Object time) {
    return 'آخر مزامنة: $time';
  }

  @override
  String get accountSyncNever => 'لسه ما اتزامنش.';

  @override
  String accountSyncWaiting(int count) {
    return 'تغييرات مستنية تتبعت: $count';
  }

  @override
  String get accountSyncAllSent => 'كل حاجة محفوظة في الحساب.';

  @override
  String get accountSyncOffline =>
      'مفيش اتصال. التغييرات مستنية على الجهاز وهتتبعت بعدين.';

  @override
  String get accountSyncUnavailable =>
      'السيرفر مشغول. المزامنة هتحاول تاني بعدين.';

  @override
  String get accountSyncUnexpected =>
      'المزامنة واجهت مشكلة وهتحاول تاني. التفاصيل في سجل التشخيص.';

  @override
  String get accountSyncSignedOut =>
      'ادخل تاني عشان المزامنة تكمّل. مفيش حاجة اتغيرت على الجهاز.';

  @override
  String accountSyncRefused(int count) {
    return 'تغييرات الحساب رفضها ومحفوظة على الجهاز: $count';
  }

  @override
  String get accountSyncRetry => 'ابعتهم تاني';

  @override
  String accountIssueName(Object child, Object theirs, Object mine) {
    return '$child: الاسم اتغير على جهاز تاني لـ«$theirs»، والجهاز ده كان عليه «$mine».';
  }

  @override
  String accountIssueGender(Object child) {
    return '$child: الجنس اتغير على جهاز تاني.';
  }

  @override
  String get accountIssueKeep => 'سيبه كده';

  @override
  String get accountIssueUseMine => 'استخدم اللي على الجهاز ده';

  @override
  String accountIssueRemoved(Object child) {
    return '$child اتمسح من الحساب على جهاز تاني، فاتمسح هنا كمان.';
  }

  @override
  String accountIssueUnavailable(Object child) {
    return '$child ما اتحفظش في الحساب لأنه كان اتمسح منه قبل كده، وهيفضل على الجهاز ده بس.';
  }

  @override
  String get accountIssueOk => 'تمام';

  @override
  String get accountManageTitle => 'الحساب';

  @override
  String get accountSignOut => 'اخرج من الحساب';

  @override
  String get accountSignOutBody =>
      'الأطفال والتقدم بيفضلوا على الجهاز. المزامنة بتقف لحد ما تدخل تاني.';

  @override
  String get accountLeave => 'بطّل استخدام الحساب على الجهاز ده';

  @override
  String get accountLeaveBody =>
      'كل الأطفال بيفضلوا على الجهاز بكل تقدّمهم، على الجهاز ده بس. والحساب بيحتفظ بنسخته.';

  @override
  String get accountDelete => 'امسح الحساب';

  @override
  String get accountDeleteBody =>
      'ده بيمسح حساب ولي الأمر وكل اللي محفوظ فيه. الأطفال وتقدّمهم بيفضلوا على الجهاز ده. اكتب كلمة السر للتأكيد.';

  @override
  String accountDeleteScheduled(Object date) {
    return 'الحساب هيتمسح يوم $date.';
  }
}

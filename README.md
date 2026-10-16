# Science Adventure

لعبة علوم للأطفال على موبايل وتابلت أندرويد وفي المتصفح. اللعب كله بيشتغل من غير إنترنت، وحساب ولي الأمر اختياري (التفاصيل في «حساب ولي الأمر والإنترنت» تحت).

**تنزيل النسخة:** ملفات APK وAAB الموقّعة بتتنشر في صفحة [GitHub Releases](../../releases) للمستودع، ومش بتتحفظ جوه Git. تقدر كمان تبنيها بنفسك من الكود بالخطوات في [docs/RELEASE.md](docs/RELEASE.md). كل تعديل بيتفحص تلقائيًا في GitHub Actions (تحليل الكود، الاختبارات، بناء أندرويد، فحص الأمان).

أول مرة: اسم الطفل، ولد أو بنت، ثم ثعلب أو أرنب أو قطة، أو صورة يختارها ولي الأمر من الجهاز. زيزو للولد وزيزي للبنت. الألوان بتتغير تلقائيًا، وممكن تغييرها من ركن الأهل. الصورة عمرها ما بتخرج من الجهاز. باقي البيانات بتفضل على الجهاز بس، إلا لو ولي الأمر اختار حساب وحفظ الطفل فيه.

اتنفذ كمان: خريطة الجزر، حفظ الإعدادات، القراءة الإنجليزية المحلية ومساعدة تثبيت الصوت، بوابة الأهل، الإعدادات عربي RTL وإنجليزي، وتذكير الراحة. تقارير الوحدات جاهزة لاستقبال نتائج اللعب في المراحل الجاية؛ حاليًا بتقول بوضوح إن لسه مفيش نتيجة.

[خطوات تجربة المرحلة ١](docs/PHASE_1_TRY.md) • [نتائج الفحص وحدود التجربة](docs/PHASE_1_REPORT.md)

## الملفات المهمة

- [قرارات المشروع](docs/PRODUCT_DECISIONS.md)
- [مراجعة الكتاب والوحدات التسعة](docs/CONTENT_AUDIT.md)
- [شكل ملفات المحتوى](docs/CONTENT_SCHEMA.md)
- [تصور لعبة حي ولا غير حي](docs/UNIT_01_PLAY_CONCEPT.md)
- [متابعة المرحلة 0](docs/PHASE_0_CHECKLIST.md)
- [نتائج الفحوص والصلاحيات الفعلية](docs/PHASE_0_REPORT.md)
- [مصادر الأصول](CREDITS.md)

## تثبيت APK التجريبي بعد تسليمه

APK هو ملف تثبيت التطبيق على أندرويد. تجربة الملف مش محتاجة Android Studio أو أي برنامج برمجة على التابلت.

1. وصّل التابلت بالكمبيوتر بكابل USB.
2. اختار «نقل الملفات / File transfer» من إشعار USB على التابلت.
3. افتح مجلد Downloads الخاص بالتابلت من الكمبيوتر.
4. انسخ ملف APK اللي نزّلته من صفحة Releases (أو اللي بنيته بنفسك) للمجلد ده.
5. افتح تطبيق «الملفات / Files» على التابلت.
6. افتح Downloads.
7. اضغط ملف APK.
8. لو ظهرت رسالة منع تثبيت، اضغط «الإعدادات / Settings» في الرسالة.
9. فعّل «السماح من هذا المصدر / Allow from this source» لتطبيق الملفات.
10. ارجع لشاشة التثبيت.
11. اضغط «تثبيت / Install».
12. اضغط «فتح / Open».
13. بعد التثبيت، اقفل «السماح من هذا المصدر» من نفس صفحة الإعدادات.

أسماء القوائم ممكن تختلف شوية حسب الشركة. نسخة المرحلة ١ تجريبية بتوقيع التطوير، مش نسخة الإصدار النهائي. هنجهز المفتاح الدائم وشرح نسخه احتياطيًا في المرحلة 7. فقدان مفتاح الإصدار الدائم يمنع تحديث نفس التطبيق بالتوقيع نفسه؛ المفتاح وكلمات السر ما يدخلّوش Git.

## أدوات الكمبيوتر — للضرورة فقط

Flutter أداة بناء التطبيق؛ Android SDK أدوات بناء أندرويد؛ Android Studio برنامج بيجهز الأدوات دي بواجهة مرئية. تنزيل الأدوات على الكمبيوتر محتاج إنترنت، لكن اللعبة نفسها هتشتغل من غيره.

التجهيز المحلي المكتمل بيستخدم Flutter 3.47.5 مع Dart 3.13.4، وJava 21، وأدوات Android داخل .tools. كل أدوات بناء أندرويد اكتملت وتم استخدامها لإنتاج APK.

لو محتاج تثبيت Android Studio يدويًا:

1. افتح https://developer.android.com/studio على الكمبيوتر.
2. اضغط Download Android Studio.
3. راجع شروط التحميل.
4. وافق على الشروط لو موافق عليها.
5. نزّل نسخة Windows.
6. افتح ملف التثبيت.
7. اضغط Next.
8. اختار Android Studio.
9. كمّل التثبيت بالإعدادات المقترحة.
10. افتح Android Studio.
11. اختار Standard في معالج الإعداد.
12. وافق على رخص الأدوات اللي أنت موافق عليها.
13. استنى تحميل الأدوات.
14. من شاشة البداية افتح More Actions.
15. اختار SDK Manager.
16. من SDK Platforms اختار Android API 36.
17. من SDK Tools فعّل Android SDK Command-line Tools (latest).
18. اتأكد إن Android SDK Platform-Tools وAndroid SDK Build-Tools متفعّلين.
19. اضغط Apply.
20. اضغط Finish بعد اكتمال التحميل.

## توصيل جهاز للتشغيل المباشر — اختياري

مش محتاج الخطوات دي لتثبيت APK؛ دي لو هنوصل الجهاز بأدوات التطوير.

1. افتح «الإعدادات» على التابلت.
2. افتح «حول الجهاز / About tablet».
3. افتح «معلومات البرنامج / Software information» لو موجودة.
4. اضغط «رقم الإصدار / Build number» 7 مرات.
5. اكتب رمز قفل التابلت لو طلبه.
6. ارجع للإعدادات.
7. افتح «خيارات المطور / Developer options».
8. فعّل «تصحيح USB / USB debugging».
9. وصّل التابلت بالكمبيوتر.
10. افتح قفل التابلت.
11. وافق على رسالة السماح بتصحيح USB للكمبيوتر ده.

## أوامر المشروع بعد اكتمال الأدوات

1. افتح PowerShell؛ ده برنامج أوامر موجود في Windows.
2. انسخ الأمر ده:

```powershell
cd E:\seif-science-game
```

3. جهّز مسارات الأدوات للجلسة الحالية:

```powershell
. .\scripts\environment.ps1
```

4. افحص التجهيز:

```powershell
flutter doctor -v
```

5. اعرض الأجهزة:

```powershell
flutter devices
```

6. شغّل على الجهاز الموصل:

```powershell
flutter run --no-hot
```

## حساب ولي الأمر والإنترنت

أول ما التطبيق يتفتح بيسأل مرة واحدة: «العب على الجهاز ده بس» أو «حساب ولي الأمر». الاختيار ده يتغير بعدين من ركن الأهل.

- **على الجهاز ده بس (الافتراضي):** التطبيق مش بيتصل بالإنترنت خالص. مفيش أي طلب شبكة، وكل البيانات على الجهاز.
- **حساب ولي الأمر:** محتاج بوابة الأهل، والموافقة على 3 نقط، وإيميل وكلمة سر. الحساب بيتحفظ على سيرفر العيلة (Synology). اللي بيتبعت:
  - للحساب: الإيميل، وكلمة السر (السيرفر بيحفظها مشفّرة بـArgon2id ومش بيحفظ النص نفسه)، ورقم نسخة الموافقة.
  - لكل طفل ولي الأمر **يحفظه في الحساب** بنفسه، طفل طفل: الاسم الأول، والجنس، والشخصية، والألوان، والإعدادات، وتقدّم الدروس، ووقت اللعب لكل يوم. ده عشان الطفل يظهر بتقدّمه على أجهزة ولي الأمر التانية.
- **عمره ما بيتبعت:** صور الأطفال، والأطفال اللي متحفظوش في الحساب، وأي حاجة في وضع «الجهاز ده بس». مفيش إعلانات ولا تتبع.
- ولي الأمر يقدر يخرج من الحساب أو يوقف استخدامه على الجهاز، والأطفال وتقدّمهم بيفضلوا على الجهاز. يقدر كمان يمسح الحساب وكل اللي محفوظ فيه من ركن الأهل، والمسح بيتم بعد فترة سماح.
- التفاصيل التقنية: [docs/ARCHITECTURE_DECISIONS.md](docs/ARCHITECTURE_DECISIONS.md) (ADR-0002 وADR-0018).

## الأمان والصلاحيات

تم فحص APK فعليًا: من نسخة 0.5.0 التطبيق بيطلب صلاحية INTERNET بس، وبيستخدمها بس لما ولي الأمر يختار حساب (نسخة الإصدار بتسمح بـHTTPS بس). مفيش كاميرا ولا ميكروفون ولا تخزين. فيه إذن حماية داخلي واحد من AndroidX اسمه com.scienceadventure.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION، من نوع signature، ومش بيطلب موافقة المستخدم. مفيش إعلانات أو تتبع. النسخ الاحتياطي السحابي متوقف. نسخة الكتاب الأصلية مستبعدة من Git ومن أصول التطبيق، ومفيش صور من الكتاب مستخدمة في الواجهة.

## English project notes

Parent accounts are optional: by default the app makes no network request at all (device-only mode has no network client). A parent who chooses an account saves children in it one by one; photos never leave the device (see "حساب ولي الأمر والإنترنت" above, ADR-0002 and ADR-0018). Install files (APK/AAB) are published as GitHub Release assets or on the family server's download page and are never committed; build them from source with the steps in docs/RELEASE.md. CI (.github/workflows) runs analysis, tests, Android builds and security scans on every push. Physical-device testing remains pending.

Implemented: first-name onboarding, boy/girl selection, three original cartoon avatars or an optional local photo, matching Zizo/Zizi guide, gender-based default palette with parent override, responsive islands, local Fredoka/Nunito/Cairo fonts, Riverpod, SQLite (Drift; Hive on the web), offline English flutter_tts, parent gate, Arabic RTL/English parent settings, foreground usage tracking, and gentle breaks. Android TTS does not reliably identify voice gender; parents can audition and choose installed voices. All visible curriculum levels are explicitly marked as future activities. No test scores are fabricated. Flame mini-games begin in Phase 2.

The browser preview is an additional UI preview with separate browser-local data and narration disabled. Use the APK to test native photo selection, persisted Android data and offline speech.

The supplied PDF is the only educational authority. Source drafts live in assets/content, with the PDF SHA-256 and Answer Key references. Source question drafts are not bundled or presented as gameplay. Only catalog.json supplies runtime navigation and the page-2 parent guide. Later scene interactions will assess learning through play, following the parent's revised instructions.

All direct production dependencies use exact versions and the lockfile is committed. Keep tools, signing material, passwords, build outputs, debug symbols and the original PDF out of Git. The INTERNET permission exists only for the optional parent account; release builds allow HTTPS only, and debug builds allow plain HTTP to the emulator host only. Release signing, R8 and Dart obfuscation are required before the final release gate. The preview uses a debug certificate; moving to the final signing key may require uninstalling the preview. Preserve signing continuity before children accumulate real progress.

Official setup references: https://docs.flutter.dev/install/archive and https://docs.flutter.dev/platform-integration/android/setup .

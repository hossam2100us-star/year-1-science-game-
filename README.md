# Science Adventure

لعبة علوم أوفلاين للأطفال على موبايل وتابلت أندرويد. حاليًا في المرحلة 0: تجهيز المشروع وتجربة التشغيل. **APK المرحلة 0 جاهز للتجربة: [تحميل ملف التثبيت](output/apk/ScienceAdventure-phase0-debug.apk)، حوالي 150 ميجابايت. مستني تجربتك على التابلت قبل المرحلة 1.**

الطفل هيكتب اسمه أول مرة، والتشجيع هيكون موجه ليه. التعلم هيبقى جوه مشاهد وألعاب، مش نقل أسئلة الكتاب على الشاشة. لكل وحدة تقرير للأهل يوضح الإكمال، القرارات الصحيحة من أول مرة، واستخدام التلميحات والحاجات اللي محتاجة تدريب.

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
4. انسخ ملف ScienceAdventure-phase0-debug.apk للمجلد ده الموجود في رابط التحميل فوق.
5. افتح تطبيق «الملفات / Files» على التابلت.
6. افتح Downloads.
7. اضغط ملف APK.
8. لو ظهرت رسالة منع تثبيت، اضغط «الإعدادات / Settings» في الرسالة.
9. فعّل «السماح من هذا المصدر / Allow from this source» لتطبيق الملفات.
10. ارجع لشاشة التثبيت.
11. اضغط «تثبيت / Install».
12. اضغط «فتح / Open».
13. بعد التثبيت، اقفل «السماح من هذا المصدر» من نفس صفحة الإعدادات.

أسماء القوائم ممكن تختلف شوية حسب الشركة. نسخة المرحلة 0 تجريبية بتوقيع التطوير، مش نسخة الإصدار النهائي. هنجهز المفتاح الدائم وشرح نسخه احتياطيًا في المرحلة 7. فقدان مفتاح الإصدار الدائم يمنع تحديث نفس التطبيق بالتوقيع نفسه؛ المفتاح وكلمات السر ما يدخلّوش Git.

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

## الأمان والصلاحيات

تم فحص APK فعليًا: مفيش صلاحيات نظام، بما فيها INTERNET والكاميرا والميكروفون والتخزين. فيه إذن حماية داخلي واحد من AndroidX اسمه com.scienceadventure.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION، من نوع signature، ومش بيطلب موافقة المستخدم. مفيش إعلانات أو تتبع. النسخ الاحتياطي السحابي متوقف. نسخة الكتاب الأصلية مستبعدة من Git ومن أصول التطبيق، ومفيش صور من الكتاب مستخدمة في الواجهة.

## English project notes

Phase 0 only. The verified debug APK is in output/apk/ScienceAdventure-phase0-debug.apk (150,364,210 bytes; minSdk 24; ARM32, ARM64, x86_64). The current Flutter screen is a responsive device smoke check, not a completed game. Physical-device testing is still pending. Child-name onboarding, narration, custom bundled fonts, Riverpod, Hive, Flame, and Lottie belong to later approved phases. No third-party Flutter dependencies have been added yet.

The supplied PDF is the only educational authority. Source drafts live in assets/content, with the PDF SHA-256 and Answer Key references. These drafts are not bundled by pubspec.yaml and are not presented as gameplay. Later scene interactions will assess learning through play, following the parent's revised instructions.

All production dependencies will use exact versions and the lockfile will be committed. Keep tools, signing material, passwords, build outputs, debug symbols and the original PDF out of Git. Do not enable internet permission to make hot reload work. Release signing, R8 and Dart obfuscation are required before the final release gate. The preview uses a debug certificate; moving to the final signing key may require uninstalling the preview. Preserve signing continuity before children accumulate real progress.

Official setup references: https://docs.flutter.dev/install/archive and https://docs.flutter.dev/platform-integration/android/setup .

# Executive Summary — الملخص التنفيذي

**المشروع:** Science Adventure (`com.scienceadventure.app`) · الإصدار 0.3.0+3 · Commit `9fbdaf4` · تاريخ الفحص 2026-10-04
**طريقة الفحص:** قراءة فقط (READ-ONLY). محصلش أي تعديل على كود المشروع.

---

## بالعربي (ملخص لصاحب المشروع)

### المشروع ده إيه؟
لعبة علوم تعليمية للأطفال، شغالة **من غير إنترنت**، ومعمولة بـ **Flutter** (مش Kotlin/Java). فيها 13 وحدة ومسابقة على 4 جزر، ورسومات ومشاهد تفاعلية بمحرك Flame، وأصوات، وركن للأهل عليه بوابة حماية، ودعم لأكتر من طفل على نفس الجهاز. كل البيانات محفوظة على الجهاز بس.

### النتيجة العامة: **63 / 100 — مقبول (Acceptable)**

| المجال | الدرجة |
|---|---|
| جودة الكود | 11 / 20 |
| المعمارية (Architecture) | 8 / 15 |
| الأمان | 17 / 20 ✅ أقوى نقطة |
| الواجهة وتجربة المستخدم | 11 / 15 |
| الأداء | 5 / 10 |
| الاختبارات | 6 / 10 |
| سهولة الصيانة | 5 / 10 |

### الحاجات الكويسة
- **الأمان والخصوصية ممتازين لتطبيق أطفال:** التطبيق مش طالب ولا صلاحية (لا إنترنت ولا كاميرا ولا تخزين)، ومفيش أي كلمات سر أو مفاتيح سرية جوه الكود. صورة الطفل بتتنضف من أي بيانات زيادة، والنسخ الاحتياطي السحابي مقفول.
- **التطبيق بيتبني وبيشتغل:** اتعمل منه APK بنجاح، والفحص الآلي للكود طلع من غير أخطاء، و**الـ 203 اختبار الموجودين نجحوا كلهم**.
- الرسومات أصلية وجميلة، والأزرار كبيرة ومناسبة للأطفال، والتقدم بيتحفظ بدقة حتى لو الطفل قفل في نص النشاط.

### المشاكل الأساسية
1. **المشروع بيتبني على جهاز واحد بس**، ومفيش نظام بناء واختبار تلقائي (CI). في أول الفحص المشروع ما كانش بيتبني خالص لأن المكتبات اتمسحت من الكمبيوتر.
2. **ملف واحد ضخم (LessonPlayer) فيه حوالي 1400 سطر** ماسك منطق كل المشاهد، وده بيخلي أي تعديل جديد فيه خطر يبوّظ حاجة تانية.
3. **البيانات متخزنة كـ "كتلة واحدة"** فيها كل الأطفال وصورهم، وبتتكتب من الأول كل 10 ثواني ومع كل لمسة. ده بطيء، ولو الكتلة دي باظت الطفل يخسر كل تقدمه، ومش هينفع نبني عليها مزامنة.
4. **عيب حقيقي لقيته:** في نسخة الويب، حذف ملف الطفل بيفشل وبتطلع رسالة غلط بتقول "مفيش مساحة".
5. الصور تقيلة: 44 ميجا، وممكن تاخد حوالي 156 ميجا من الذاكرة، وده خطر على التابلت الضعيف (ما اتقاسش فعليًا).
6. واجهة الطفل كلها بالإنجليزي، والنصوص مكتوبة جوه الكود بدل ملفات ترجمة.

### هل ينفع نحوّله لـ Android + Web + سيرفر + قاعدة بيانات مركزية؟
**أيوه، والقرار: إعادة هيكلة للتطبيق الحالي (Refactor)، مش إعادة كتابة.**
السبب إن Flutter أصلًا بيشتغل على الويب، يعني نفس اللعبة هتشتغل على الكمبيوتر من غير ما نعيد بنائها. بس لازم الأول نعيد ترتيب طبقة البيانات قبل ما نبني السيرفر.

**التقنيات المقترحة:**
- السيرفر: **NestJS (TypeScript)**
- قاعدة البيانات: **PostgreSQL**
- الويب: **Flutter Web** (نفس كود اللعبة)
- الاتصال: **REST API** بمواصفات OpenAPI
- تسجيل الدخول: بالإيميل لـ **ولي الأمر بس**. كلمة السر بتتخزن مشفرة بـ Argon2id، والجلسة بتوكنات قصيرة بتتجدد. الأطفال يفضلوا ملفات تحت حساب الأهل، من غير كلمات سر.
- المزامنة: التطبيق يفضل شغال من غير إنترنت، والتعديلات بتتسجل في طابور وتتبعت لما النت يرجع. لو حصل تعارض بين الموبايل والكمبيوتر **مفيش بيانات بتضيع**: كل نوع بيانات ليه قاعدة دمج خاصة بيه.

> ⚠️ **قرار مهم لازم ياخده صاحب المشروع الأول:** ملف قرارات المشروع بيقول "مفيش حسابات أو إرسال بيانات". إننا نرفع بيانات أطفال على سيرفر ليه التزامات قانونية وخصوصية، زي موافقة ولي الأمر وسياسة خصوصية. ومقترحنا إن الصور ما تترفعش افتراضيًا.

### أهم 5 خطوات
1. نظام بناء واختبار تلقائي، وحماية مفتاح توقيع التطبيق.
2. قرار الخصوصية والحسابات.
3. إصلاح عيب الحذف على الويب، وحماية البيانات من التلف.
4. تقسيم الملف الضخم، وتحويل البيانات لنماذج واضحة وقاعدة بيانات محلية (SQLite).
5. بعد كده: السيرفر، ثم تسجيل الدخول، ثم المزامنة، ثم الويب.

---

## English

**What it is.** An offline Flutter (Dart 3.13 / Flutter 3.47.5) educational science game for children, targeting Android tablets and phones in landscape. It has 13 lessons and quizzes across 4 islands, Flame-based illustrated scenes, offline English TTS, a gated parent area with per-unit reports, and multiple child profiles. Everything is stored locally in a single Hive box.

**Overall score: 63 / 100 (Acceptable).** Code Quality 11/20 · Architecture 8/15 · Security 17/20 · UI/UX 11/15 · Performance 5/10 · Testing 6/10 · Maintainability 5/10.

**Verified facts.** `flutter analyze`: 0 issues (after restoring the Pub cache) · `flutter test`: **203/203 passed** · `flutter build apk --debug`: **passed**, 208 MB · APK requests **no platform permissions** · no secrets in the repo · 18 manual functional checks on the web preview (15 pass, 2 partial, 1 fail) and 6 not tested.

**Issues.** 0 critical · 4 high · 8 medium · 8 low · 2 info (see `Issues_Register.md`).

**Top risks.** A non-reproducible single-machine build with no CI (AUD-001). The 1,391-line `LessonPlayer` god class (AUD-002). An untyped `Map<String, dynamic>` state model (AUD-003). The whole app state, including photos, rewritten as one blob every 10 s and on every interaction (AUD-004). A confirmed web bug when deleting a child (AUD-005).

**Decision: B — Refactor the existing application.** Keep Flutter, Riverpod, Flame, the content pipeline and the assets. Replace the Hive blob with SQLite (drift) plus an outbox, introduce typed domain models and repositories, then add NestJS + PostgreSQL, parent email auth (Argon2id, rotating refresh tokens), offline-first sync with per-entity conflict rules, and a **Flutter Web** client that reuses the game.

**Precondition.** Revise the documented "no accounts / no data sending" decision with privacy and legal input (children's data).

| Recommended | Choice |
|---|---|
| Strategy | Refactor |
| Backend | NestJS (TypeScript), modular monolith · alternatives: Serverpod (Dart), Supabase (managed) |
| Web | Flutter Web (shared codebase) · alternative: Next.js for a marketing/legal site |
| Database | PostgreSQL (17/18), UUIDv7 keys |
| API | REST + OpenAPI 3.1, generated Dart client |
| Auth | Parent email + password (Argon2id), email verification, 15-min access JWT plus rotating opaque refresh token with reuse detection; Android Keystore and web HttpOnly SameSite=Strict cookie |
| Sync | Offline-first outbox, push/pull with `change_seq` cursor, idempotent mutation IDs, optimistic concurrency (`version`), per-entity merge (append-only attempts, per-device usage counters, field-level profile merge, progress-monotonic journeys), tombstones |

Detailed reports: `Software_Technical_Audit_Report.pdf`, `Future_System_Architecture.pdf`, `Issues_Register.md`, `Security_Findings.md`, `Test_Results.md`, `Architecture_Diagrams.md`, `Development_Roadmap.md`.

# تشغيل Science Adventure على الـ Synology NAS (تجربة خاصة)

الدليل ده بيجهّز اللعبة على الـNAS بتاعك عشان أصحابك يلعبوا من بيوتهم:
- **على المتصفح** من أي جهاز (حتى الآيفون).
- **على الأندرويد** بتطبيق ينزّلوه من صفحة على الـNAS نفسه.

كل حاجة بتتعمل **مرة واحدة**، ما عدا التحديثات (آخر الدليل). لو أي خطوة وقفت معاك، صوّرلي الشاشة.

## الصورة الكبيرة

```
أصحابك ──HTTPS──► راوتر البيت (بورت 443 بس)
                     │
                     ▼
          Synology Reverse Proxy  (HTTPS + الشهادة)
                     │  http://localhost:8480
                     ▼
   ┌──────────── Container Manager: مشروع science-adventure ────────────┐
   │  web     ← بيعرض اللعبة وصفحة التحميل، وبيوصّل /api للسيرفر         │
   │  api     ← الحسابات والمزامنة                                       │
   │  db      ← قاعدة البيانات (ملهاش أي طريق للإنترنت)                  │
   │  backup  ← نسخة احتياطية كل يوم في فولدر backups                    │
   └─────────────────────────────────────────────────────────────────────┘
```

صفحة إعدادات الـNAS نفسه (DSM) **ما بتتفتحش للإنترنت**، اللي بيتفتح هو اللعبة بس.

---

## الخطوة 1 — اسم للـNAS على الإنترنت + شهادة HTTPS

1. افتح **Control Panel ← External Access ← DDNS ← Add**.
2. Service provider: **Synology**. اختار اسم، مثلًا `science-hossam` (هيبقى `science-hossam.synology.me`).
3. علّم على **Get a certificate from Let's Encrypt and set it as default**، وبعدين **OK**.
4. **ابعتلي الاسم ده** عشان أجهّز ملفات الإعدادات عليه.

## الخطوة 2 — الراوتر

من صفحة الراوتر اعمل **Port Forwarding**:

| الخارجي | الداخلي | البروتوكول |
|---|---|---|
| 443 | IP الـNAS : 443 | TCP |

- ⚠️ **ما تفتحش** 5000 ولا 5001 (دول بتوع إعدادات الـNAS).
- لو الشهادة رفضت تتجدد بعدين، افتح كمان 80 ← 80.

## الخطوة 3 — إيميل Gmail للرسايل (تأكيد الحساب ونسيت كلمة السر)

1. ادخل **myaccount.google.com ← Security**.
2. لازم **2-Step Verification** تبقى شغالة.
3. ادخل **App passwords**، واكتب اسم `Science Adventure NAS`، وبعدين **Create**.
4. هيطلعلك 16 حرف. **دي مش كلمة سر Gmail بتاعتك**، دي كلمة سر للـNAS بس. هتحطها في الخطوة 6.

## الخطوة 4 — مفتاح قراءة من GitHub (عشان الـNAS ينزّل نسخ اللعبة الـprivate)

1. على GitHub: الصورة بتاعتك ← **Settings ← Developer settings ← Personal access tokens ← Tokens (classic) ← Generate new token (classic)**.
2. Note: `NAS read`. Expiration: 90 days.
3. علّم على **`read:packages` بس**، ولا أي حاجة تانية.
4. **Generate token** وانسخه واحتفظ بيه. بيظهر مرة واحدة بس.

## الخطوة 5 — Container Manager وتسجيل الدخول على GitHub

1. من **Package Center** سطّب **Container Manager**.
2. فعّل SSH مؤقتًا: **Control Panel ← Terminal & SNMP ← Enable SSH service**.
3. من الكمبيوتر افتح PowerShell واكتب (حط اسم المستخدم بتاعك وIP الـNAS):
   ```
   ssh YOUR_DSM_USER@NAS_IP
   sudo docker login ghcr.io -u hossam2100us-star
   ```
   - هيطلب كلمة سر الـNAS (للـsudo)، وبعدها Password: الصق **مفتاح GitHub** من الخطوة 4.
   - لازم تظهر **Login Succeeded**.
4. اكتب `exit`، و**اقفل SSH تاني** من نفس الشاشة.

## الخطوة 6 — فولدر المشروع

1. من **File Station**: جوه فولدر `docker` اعمل فولدر اسمه `science-adventure`.
2. ارفع جواه:
   - `docker-compose.yml` (من الفولدر ده في المشروع)
   - `db.env` و`api.env` (أنا هجهّزهم بعد ما تبعتلي الاسم، **ودول سريين**)
   - فولدر `downloads` (فيه `index.html`، وأنا هحط جنبه `science-adventure.apk`)
3. افتح `api.env` بـ **Text Editor** وكمّل:
   - `SMTP_URL=smtps://hossam2100us%40gmail.com:XXXXXXXXXXXXXXXX@smtp.gmail.com:465`
     (الـ16 حرف من الخطوة 3 **من غير مسافات**، وعلامة @ اللي في الإيميل بتتكتب `%40`)
   - `EMAIL_FROM=Science Adventure <hossam2100us@gmail.com>`
   - `GOOGLE_CLIENT_IDS=` هنملاها بعدين لما نجهّز الدخول بجوجل.

## الخطوة 7 — تشغيل المشروع

1. **Container Manager ← Project ← Create**.
2. Project name: `science-adventure`. Path: `/docker/science-adventure`.
3. Source: **Use existing docker-compose.yml**، وبعدين **Next** لحد **Done**.
4. استنى دقيقتين. لازم تشوف 4 حاويات شغالة: `db` و`api` و`web` و`backup`.

## الخطوة 8 — الـReverse Proxy (اللي بيوصّل الإنترنت للعبة)

1. **Control Panel ← Login Portal ← Advanced ← Reverse Proxy ← Create**.
2. Description: `Science Adventure`.
3. **Source**:
   - Protocol: HTTPS
   - Hostname: `science-hossam.synology.me` (اسمك)
   - Port: 443
   - علّم **Enable HSTS**
4. **Destination**:
   - Protocol: HTTP
   - Hostname: `localhost`
   - Port: `8480`
5. تبويب **Custom Header ← Create**:
   - Header name: `X-Forwarded-For`
   - Value: `$proxy_add_x_forwarded_for`
6. **Save**.
7. **Control Panel ← Security ← Certificate ← Settings**: اختار شهادة `synology.me` قصاد `science-hossam.synology.me`.

## الخطوة 9 — التجربة

1. من موبايلك على **بيانات الموبايل** (مش الـWi-Fi)، افتح `https://science-hossam.synology.me`. اللعبة لازم تفتح.
2. لينك التحميل لأصحابك: `https://science-hossam.synology.me/download/`.

---

## النسخ الاحتياطية

- كل يوم بيتعمل ملف `science-....dump` في فولدر `backups`، والملفات الأقدم من 14 يوم بتتمسح.
- اعمل **Hyper Backup** لفولدر `docker/science-adventure` كله (فيه البيانات والنسخ وملفات الإعدادات) على فلاشة أو Google Drive.
- لو احتجنا نرجّع نسخة: كلّمني الأول، والخطوات في آخر الملف (بالإنجليزي).

## التحديثات

لما أقولك فيه نسخة جديدة اسمها `trial`:
1. فعّل SSH مؤقتًا.
2. اكتب:
   ```
   ssh YOUR_DSM_USER@NAS_IP
   cd /volume1/docker/science-adventure
   sudo docker compose pull
   sudo docker compose up -d
   ```
3. اقفل SSH.

البيانات **ما بتتمسحش** مع التحديث، لأنها في فولدر `data` اللي على الـNAS.

## الأمان (مهم)

- فعّل **2-Step Verification** لحساب الـNAS نفسه: **Personal ← Security**.
- **Control Panel ← Security ← Protection**: فعّل **Auto Block**.
- خلّي DSM محدّث.
- ما تفتحش أي بورت تاني على الراوتر.
- ملفات `api.env` و`db.env` سرية: ما تتبعتش على واتساب ولا إيميل.

---

### Restore (for the developer)

```
cd /volume1/docker/science-adventure
sudo docker compose stop api web
sudo docker compose exec db sh -c 'dropdb -U "$POSTGRES_USER" "$POSTGRES_DB" && createdb -U "$POSTGRES_USER" "$POSTGRES_DB"'
sudo docker compose exec -T db sh -c 'pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB"' < backups/science-YYYYMMDD-HHMM.dump
sudo docker compose start api web
```

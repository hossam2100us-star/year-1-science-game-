# Parent account consent screen — DRAFT for legal review

> Shown behind the grown-ups gate, before an account is created (M4).
> Both choices are shown as equal options; "This device only" is the
> default and needs no consent because nothing leaves the device.
> **Draft, not legal advice** — review together with
> `PRIVACY_POLICY_DRAFT.md`. Until the reviewed text is supplied, production
> builds keep account creation switched off (ADR-0002).

---

## بالعربي

**عايز تتابع الأطفال على أكتر من جهاز؟**

**الاختيار ١ — على الجهاز ده بس (موصى به لو جهاز واحد)**
كل حاجة بتفضل على الجهاز ده، ومفيش أي حاجة بتتبعت على الإنترنت.
[زرار: كمّل على الجهاز ده بس]

**الاختيار ٢ — حساب ولي أمر**
بنحفظ نسخة من تقدّم الأطفال اللي تختارهم على السيرفر بتاعنا، عشان تظهر على أجهزتك التانية.

إيه اللي بيترفع: الاسم الأول، ولد أو بنت، رقم الشخصية الكرتونية، الألوان والإعدادات، النتايج، الدرس الحالي، ووقت اللعب.
إيه اللي **مش** بيترفع: صورة الطفل. الصور بتفضل على الجهاز.
تقدر تمسح كل حاجة أو ترجع لـ«الجهاز ده بس» في أي وقت من ركن الأهل.

☐ أنا ولي الأمر أو الوصي القانوني على الأطفال دول، وعندي 18 سنة أو أكتر.
☐ موافق إن البيانات اللي فوق تتحفظ على سيرفر Science Adventure للغرض ده بس.
☐ قريت [سياسة الخصوصية].

[زرار: اعمل حساب] — بيتفعل بس لما الـ3 علامات يتعلّموا.

بعد ما الحساب يتعمل، بنسألك عن كل طفل لوحده: «تربط [الاسم] بالحساب؟» — والطفل اللي ما تربطوش يفضل على الجهاز بس.

---

## English

**Follow your children on more than one device?**

**Option 1 — This device only (recommended for one device)**
Everything stays on this device. Nothing is sent over the internet.
[Button: Continue on this device only]

**Option 2 — Parent account**
We keep a copy of the progress of the children you choose on our server, so
it appears on your other devices.

Uploaded: first name, boy or girl, avatar number, colours and settings,
results, the lesson in progress, and play time.
**Not** uploaded: the child's photo. Photos stay on the device.
You can delete everything, or go back to "this device only", at any time
from the grown-ups area.

☐ I am the parent or legal guardian of these children and I am 18 or older.
☐ I agree that the data above is stored on Science Adventure's server for
  this purpose only.
☐ I have read the [privacy policy].

[Button: Create account] — enabled only when all three boxes are ticked.

After the account is created we ask for each child separately: "Link
[name] to your account?" — a child who is not linked stays on this device
only.

---

## Notes for the reviewer

- Consent is recorded server-side with the policy version and time
  (audit log, no child data in the log).
- Changing the policy later asks the parent to confirm again.
- Withdrawing consent = deleting the account (14-day grace, then erasure)
  or unlinking children; local play continues unaffected.

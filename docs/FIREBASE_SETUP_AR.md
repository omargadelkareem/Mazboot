# ربط Firebase خطوة بخطوة

## 1) إنشاء تطبيق Android

داخل Firebase Console أنشئ مشروعًا، ثم Android app بالـpackage `com.hetta.customer`. نزّل `google-services.json` وضعه في `android/app/` من غير تعديل الاسم.

لا يوجد ملف حقيقي داخل الحزمة لأن هذا الملف يحتوي معرفات مشروعك ولا يمكن إنشاؤه من غير حساب Firebase الخاص بك.

## 2) طرق تسجيل الدخول

- من Authentication > Sign-in method فعّل **Google** واختر بريد الدعم.
- فعّل **Email/Password** لحسابات الصنايعية. التطبيق يحوّل رقم الموبايل داخليًا إلى عنوان تقني من نطاق `provider.hetta.app` ويعرض للصنايعي رقم الموبايل فقط.
- حساب العميل وحساب الصنايعي هويتان مستقلتان. لا تستخدم Link Account ولا تربط Google بحساب الصنايعي.
- يمكن ترك **Anonymous** مغلقًا؛ المسار الجديد لا يعتمد عليه.
- أضف SHA-1 وSHA-256 الخاصة بمفتاح Debug، ثم أعد تنزيل `google-services.json`.
- تأكد أن package name هو `com.hetta.customer`. تسجيل Google لن يعمل لو البصمة أو اسم الحزمة مختلفان.

لطباعة البصمات على Windows من مجلد Android:

```bash
gradlew signingReport
```

## 3) Realtime Database

أنشئ Realtime Database في المنطقة المناسبة. لا تبدأ في Test Mode على نسخة إنتاج.

انشر `firebase/database.rules.json` من Firebase Console أو Firebase CLI:

```bash
firebase login
firebase use YOUR_PROJECT_ID
firebase deploy --only database
```

استورد `firebase/seed.json` من Realtime Database > الثلاث نقاط > Import JSON، واختر جذر القاعدة `/`.

ملف Seed يستخدم IDs تجريبية مثل `mohamed-ali`. في الحسابات الحقيقية يكون مفتاح الفني داخل `public_providers` مساويًا لـFirebase Auth UID لحساب الصنايعي، لأن قواعد الطلبات تعتبر UID هو `technicianId`.

طلبات انضمام الصنايعية تحفظ في:

```text
/provider_applications/{applicantUid}
```

الصنايعي يستطيع إنشاء طلب واحد بحالة `pending` ومشاهدة حالته فقط. القبول وتفعيل الاشتراك والنشر متاحون لحساب يحمل Custom Claim بقيمة `role=admin` أو بريد الإدارة المضبوط في القواعد `admin@hetta.com`.

كلمة مرور الصنايعي لا تكتب في Realtime Database نهائيًا؛ Firebase Authentication هو المسؤول عن تخزينها والتحقق منها.

## 4) Cloud Messaging

وجود `google-services.json` يسمح بتشغيل FCM في foreground وbackground. التطبيق يسجل FCM token في:

```text
/users/{customerUid}/fcmToken
```

إرسال الإشعار نفسه يجب أن يتم من Cloud Functions أو Backend موثوق عند تغير حالة الطلب أو وصول رسالة؛ لا تضع Server Key داخل تطبيق Flutter.

لكي يفتح الضغط على الإشعار شاشة التتبع مباشرة، أرسل `orderId` داخل حقل `data` في رسالة FCM.

## 5) صلاحية الإدارة

القواعد تعتمد Custom Claim بالشكل:

```json
{"role":"admin"}
```

ضعها باستخدام Firebase Admin SDK فقط. حساب الإدارة يستطيع إدارة الأقسام والفنيين والاشتراكات والإشعارات. التطبيق لا يحتوي Admin SDK ولا أسرار خادم.

## 6) مراجعة الصنايعي والاشتراك الشهري

عند قبول البيانات، حدّث الطلب من Backend أو لوحة الإدارة الموثوقة:

```text
/provider_applications/{providerUid}/status = approved
```

بعد تأكيد دفع `50 ج.م` من Backend أو لوحة الإدارة، حدّث:

```text
/provider_applications/{providerUid}/subscriptionActive = true
/provider_applications/{providerUid}/published = true
/public_providers/{providerUid}/subscriptionActive = true
```

وأنشئ ملفه داخل `public_providers` بقيم `approvalStatus=approved` و`isActive=true`، وانسخ `photoBase64` إلى `imageBase64`. نفّذ هذه التغييرات كـmulti-location update من Backend حتى تكون ذرّية. عند انتهاء الاشتراك اجعل `subscriptionActive=false`. التطبيق يفلتر الفني تلقائيًا ولن يسمح بإنشاء طلب لفني غير مقبول أو اشتراكه غير نشط.

المشروع يحتوي Cloud Function جاهزة تنفذ النشر والإيقاف تلقائيًا. قاعدة البيانات المضبوطة حاليًا هي منطقة بلجيكا `europe-west1`؛ لو أنشأت RTDB في منطقة أخرى غيّر `region` داخل `functions/index.js` قبل النشر:

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

نشر Cloud Functions على الإنتاج يتطلب خطة Firebase Blaze. لو لم تستخدم Functions، نفّذ نفس الـmulti-location update من لوحة إدارة أو Backend موثوق.

لا توجد رسوم معاينة أو رسوم مسبقة في مسار الطلب؛ الحقل القديم `visitFee` إن وُجد تكون قيمته `0` للتوافق مع البيانات السابقة.

## 7) الصور بدون Firebase Storage

التطبيق يضغط الصورة إلى حد أقصى 1280×1280 وجودة 55، ويرفض أي ناتج أكبر من 900KB قبل Base64. قواعد RTDB تضع حدًا يقارب 1.25 مليون حرف Base64.

هذا مناسب لـMVP وحجم استخدام محدود. مع زيادة الاستخدام انقل الصور إلى Object Storage/CDN واحتفظ بالرابط فقط لتقليل تكلفة وحجم Realtime Database.

## 8) تجربة الربط

بعد وضع الملف الحقيقي:

```bash
flutter clean
flutter pub get
flutter run
```

لو فشل Firebase في البدء، يتحول التطبيق تلقائيًا إلى وضع المعاينة وتظهر علامة صغيرة. راجع `adb logcat` ومكان `google-services.json` وpackage name، أو شغّل بالقيم الصريحة المذكورة في README.

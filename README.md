# حِتّة — تطبيق العميل والصنايعي

تطبيق Flutter عربي RTL يربط أصحاب البيوت بالفنيين ومقدمي الخدمات المنزلية في مصر. حساب العميل وحساب الصنايعي منفصلان بالكامل، ومبني ليعمل على Flutter `3.24.3` وDart `3.5.3`. الإصدار الحالي `1.2.0+5` يثبت توافق Android على JDK 17 وAGP 8.5.1 وGradle 8.7 وSDK 34.

## الموجود داخل المشروع

- Splash وOnboarding وهوية حِتّة وخط Tajawal محلي.
- اختيار الدور: عميل أو صنايعي.
- دخول العميل بحساب Google فقط من Firebase Authentication.
- إنشاء حساب الصنايعي المستقل برقم الموبايل وكلمة المرور أثناء تقديم طلب الانضمام؛ كلمة المرور تبقى داخل Firebase Authentication ولا تحفظ في Realtime Database.
- طلب انضمام الصنايعي بالاسم والموبايل والحرفة والمحافظة والمدينة والصورة، مع متابعة حالة المراجعة لحظيًا.
- لوحة صنايعي كاملة بعد القبول والتفعيل: الرئيسية، حالة التوفر، الطلبات ومراحلها، تفاصيل الطلب، المحادثات، الاشتراك، الملف المهني، وسجل الخدمات.
- وضع محلي تلقائي لو إعدادات Firebase غير موجودة لتجربة المسارين بدون Backend؛ طلب الصنايعي يُقبل تلقائيًا في المعاينة فقط حتى تقدر تشوف الواجهة كاملة.
- اختيار المحافظة والمنطقة ودعم تحديد GPS بعد أخذ الإذن.
- Home كريتيف Room-first وBento بدل الصفحة التقليدية.
- 14 قسمًا للخدمات المنزلية وبيانات بداية لـ14 فنيًا.
- بحث وفرز وتصفية الفنيين، ملف فني، أعمال سابقة، تقييمات، ومفضلة.
- إنشاء طلب مع موعد وعنوان وصورة مضغوطة محفوظة Base64 من غير Firebase Storage.
- إرسال الطلب بدون رسوم معاينة أو دفع مسبق؛ السعر يتفق عليه مع الفني قبل التنفيذ.
- طلبات حالية ومكتملة وملغاة وتتبّع لحظي لحالة الطلب.
- طلب إلغاء آمن في مسار منفصل لحين اعتماده من الإدارة أو الـBackend.
- محادثة لحظية مرتبطة بكل طلب، مع إرسال نصوص وصور.
- تقييم الفني بعد اكتمال الطلب فقط.
- عناوين محفوظة، ملف شخصي وصورة، إشعارات داخلية وFCM، دعم وشروط وخصوصية.
- Firebase Realtime Database repository وقواعد أمان وملف Seed.
- Cloud Function تنشر ملف الصنايعي تلقائيًا بعد موافقة الإدارة وتفعيل الاشتراك.
- Local repository دائم باستخدام GetStorage لتجربة كل المسارات بدون Backend.

## تشغيل سريع بدون Firebase

```bash
flutter clean
flutter pub get
flutter run --dart-define=DEMO_MODE=true
```

اختر الدور وجرّب تسجيل Google المحلي أو أرسل طلب انضمام صنايعي. البيانات والطلبات والمحادثات تحفظ محليًا على الجهاز.

## التشغيل مع Firebase الحقيقي

1. أنشئ مشروع Firebase وأضف Android app بالـpackage التالي:

   ```text
   com.hetta.customer
   ```

2. نزّل ملف `google-services.json` الحقيقي وضعه هنا:

   ```text
   android/app/google-services.json
   ```

3. فعّل Google وEmail/Password داخل Authentication، ثم فعّل Realtime Database وCloud Messaging.
4. انشر القواعد من `firebase/database.rules.json`.
5. استورد `firebase/seed.json` إلى جذر Realtime Database.
6. أضف SHA-1 وSHA-256 لتطبيق Android داخل Firebase، ثم شغّل:

   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

التفاصيل خطوة بخطوة موجودة في [docs/FIREBASE_SETUP_AR.md](docs/FIREBASE_SETUP_AR.md).

يمكن أيضًا تمرير إعدادات Firebase كـDart defines، لكن وجود `google-services.json` مطلوب لتسليم إشعارات FCM في الخلفية على Android:

```bash
flutter run \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_DATABASE_URL=https://PROJECT-default-rtdb.firebaseio.com
```

## بيانات الدعم

أضف رقم وبريد دعم الشركة وقت التشغيل:

```bash
flutter run \
  --dart-define=SUPPORT_PHONE=+20XXXXXXXXXX \
  --dart-define=SUPPORT_EMAIL=support@example.com
```

## ملاحظة اشتراك الفني 50 جنيه

التطبيق لا يجمع اشتراك الفني بنفسه. هو يعرض فقط الفني الذي تكون بياناته:

```text
approvalStatus = approved
subscriptionActive = true
isActive = true
```

طلب الصنايعي يبدأ داخل `/provider_applications/{uid}` بحالة `pending`. تحصيل الاشتراك الشهري `50 ج.م` والقبول والنشر مسؤولية لوحة الإدارة أو Backend موثوق. قواعد قاعدة البيانات تمنع الصنايعي من قبول طلبه أو تفعيل اشتراكه بنفسه.

## هيكل المشروع

```text
lib/
  app/                 حقن الخدمات والـCubits وتشغيل الجلسة
  core/                الثيم، الراوتر، الإعدادات، والخدمات
  data/                بيانات وضع المعاينة
  features/            شاشات وCubits العميل والصنايعي
  models/              نماذج البيانات والتحويل من/إلى RTDB
  repositories/        Firebase وLocal implementations
firebase/
  database.rules.json  قواعد الأمان والفهارس
  seed.json            الأقسام والفنيون كبداية
functions/             نشر/إيقاف الصنايعي بعد قرار الإدارة
docs/                  دليل الربط والبنية وقائمة ما قبل النشر
design_reference/      صور التصميم المعتمدة
```

## Android

- Application ID: `com.hetta.customer`
- minSdk: `23`
- compileSdk وtargetSdk: `34` مع Android Build Tools `34.0.0` المستقرة.
- Java/Kotlin target وJDK التشغيل: `17`.
- Android Gradle Plugin: `8.5.1`، وGradle Wrapper: `8.7`.
- نسخة Release تستخدم مفتاح Debug حاليًا لتسهيل التشغيل فقط. أضف مفتاح الإنتاج قبل Google Play.
- لا ترفع `google-services.json` أو مفاتيح التوقيع إلى مستودع عام.

## قبل النشر

راجع [خريطة الشاشات](docs/SCREENS_AR.md)، [تقرير الفحص](docs/QA_REPORT_AR.md)، و[قائمة ما قبل النشر](docs/RELEASE_CHECKLIST_AR.md). أهم البنود: مفتاح توقيع Production، بيانات الدعم، نص قانوني معتمد، صور فنيين مملوكة أو مرخصة، اختبار قواعد Firebase، وحذف بيانات الـSeed التجريبية أو استبدال معرفات الفنيين بـFirebase Auth UIDs حقيقية.

خط Tajawal مرخص بموجب SIL Open Font License؛ الرخصة داخل `LICENSES/Tajawal-OFL.txt`.

## لو ظهر خطأ Gradle cache على Windows

أغلق Android Studio، وافتح PowerShell داخل مجلد المشروع ثم نفّذ كل سطر منفصلًا:

```powershell
cd android
.\gradlew --stop
cd ..
Remove-Item -Recurse -Force "$env:USERPROFILE\.gradle\caches\jars-9" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$env:USERPROFILE\.gradle\caches\transforms-4" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force ".dart_tool", "build", "android\.gradle" -ErrorAction SilentlyContinue
flutter clean
flutter pub get
flutter run
```

تأكد من `flutter doctor -v` أن Java المستخدمة هي 17، ومن Android Studio SDK Manager أن Android SDK Platform 34 وBuild Tools 34.0.0 مثبتان. لا تستخدم Build Tools `36.0.0-rc1` مع هذه النسخة.

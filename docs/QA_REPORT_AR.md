# تقرير فحص الحزمة

تم إجراء الفحوص التالية على المصدر الموجود في هذه الحزمة:

- تحليل نحوي وإعادة تنسيق لكل ملفات Dart وعددها 73 ملفًا، من ضمنها الاختبارات.
- التحقق من أن كل relative import يشير إلى ملف موجود.
- التحقق من أن كل package import معلن داخل `pubspec.yaml`.
- التحقق من وجود خطوط Tajawal الثلاثة المعلنة.
- تحليل ملفات YAML وJSON وAndroid XML بنجاح.
- فحص صياغة Cloud Function باستخدام `node --check` بنجاح.
- التحقق من أن Seed يحتوي 14 قسمًا و14 فنيًا، وأن كل فني مرتبط بقسم موجود وحالته صالحة للظهور.
- مراجعة يدوية لمسارات الراوتر واختيار الدور ودخول العميل بـGoogle وإنشاء/دخول حساب الصنايعي المستقل والمراجعة ولوحة الصنايعي والطلب والتتبع والشات والإلغاء والتقييم.

لم يكن Flutter SDK أو JDK صالحًا للتشغيل داخل بيئة تجهيز الحزمة، لذلك لم يتم الادعاء بتشغيل `flutter analyze` أو `flutter test` أو بناء APK هنا. نفّذ الأوامر التالية على جهاز التطوير قبل الاعتماد النهائي:

```bash
flutter --version
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --dart-define=DEMO_MODE=true
```

الإصدار المستهدف للمراجعة النهائية هو Flutter `3.24.3` وDart `3.5.3` مع JDK 17 وAGP `8.5.1` وGradle `8.7` وAndroid SDK/Build Tools 34 المستقرة. تم تثبيت إصدارات Android المتوافقة داخل `dependency_overrides` لتجنب حل plugins موجّهة إلى Flutter أحدث.

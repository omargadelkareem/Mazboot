# خريطة شاشات تطبيق العميل والصنايعي

| المسار | الشاشة | مصدر البيانات |
|---|---|---|
| `/splash` | البداية وفحص الجلسة | AuthService |
| `/onboarding` | التعريف بالتطبيق | GetStorage |
| `/role-selection` | اختيار حساب العميل أو حساب الصنايعي المستقل | AuthService |
| `/login` | دخول العميل بحساب Google | Firebase Auth / Google Sign-In |
| `/provider-login` | دخول الصنايعي بالموبايل وكلمة المرور | Firebase Email/Password Auth |
| `/provider-join` | إنشاء حساب الصنايعي وبيانات وصورة طلب الانضمام | ProviderApplicationCubit |
| `/provider-review` | حالة المراجعة والقبول والاشتراك | Realtime Database |
| `/provider/main` | لوحة الصنايعي بأربعة تبويبات | ProviderWorkspaceCubit |
| `/provider/orders` | جميع طلبات الصنايعي وحالاتها | ProviderWorkspaceCubit |
| `/provider/order/:orderId` | تفاصيل الطلب وتغيير الحالة | ProviderWorkspaceCubit |
| `/provider/chat/:orderId/:customerId` | محادثة الصنايعي مع العميل | ProviderChatCubit + RTDB |
| `/provider/edit-profile` | تعديل النبذة والخبرة والخدمات | ProviderWorkspaceCubit |
| `/location` | المحافظة والمنطقة وGPS | ProfileCubit + Geolocator |
| `/main` | الرئيسية الإبداعية | HomeCubit + ProfileCubit |
| `/categories` | كل الحرف والبحث | HomeCubit |
| `/technicians/:categoryId` | الفنيون والفرز والتصفية | HomeCubit + FavoritesCubit |
| `/technician/:technicianId` | ملف الفني وأعماله وتقييماته | Repository streams |
| `/request/:technicianId` | إنشاء الطلب والصورة والموعد | OrdersCubit + ImageService |
| `/tracking/:orderId` | حالة الطلب والإلغاء والاتصال | Realtime order stream |
| `/chat/:orderId/:technicianId` | محادثة الطلب والصور | ChatCubit + RTDB |
| تبويب طلباتي | الحالية والمكتملة والملغاة والتقييم | OrdersCubit |
| تبويب الرسائل | قائمة محادثات الطلبات | ConversationsCubit |
| تبويب حسابي | الحساب والإعدادات | ProfileCubit |
| `/edit-profile` | الاسم والصورة | ProfileCubit |
| `/addresses` | إضافة وتعديل وحذف واختيار عنوان | ProfileCubit |
| `/favorites` | الفنيون المحفوظون | FavoritesCubit |
| `/notifications` | الإشعارات والفتح إلى الطلب | NotificationsCubit |
| `/support` | الأسئلة الشائعة والتواصل | AppConfig |
| `/legal` | الخصوصية والشروط المبدئية | محتوى محلي |

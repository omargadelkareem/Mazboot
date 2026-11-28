import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الخصوصية والشروط')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: const <Widget>[
          _LegalNotice(),
          SizedBox(height: 18),
          _LegalSection(
            title: 'سياسة الخصوصية',
            paragraphs: <String>[
              'نجمع بيانات الحساب الأساسية ورقم الموبايل والموقع الذي يحدده العميل والعناوين وتفاصيل الطلبات؛ والهدف هو تشغيل الخدمة، إظهار الفنيين المناسبين، وتسهيل التواصل والمتابعة.',
              'قد تُحفظ الصور المرفقة بالطلب أو المحادثة بعد ضغطها. لا تضف صورًا أو معلومات لا تحتاجها الخدمة. بيانات الطلب تُشارك مع الفني المرتبط به فقط والجهات الإدارية المخولة.',
              'تُستخدم إشعارات الهاتف لإبلاغك بتغيّر حالة الطلب والرسائل المهمة. يمكنك التحكم في إذن الإشعارات من إعدادات الهاتف.',
              'يحق للمستخدم طلب تصحيح بياناته أو حذف حسابه وفق سياسة التشغيل والقوانين السارية، مع الاحتفاظ بما يلزم لتسوية الطلبات أو الالتزامات القانونية.',
            ],
          ),
          SizedBox(height: 20),
          _LegalSection(
            title: 'شروط الاستخدام',
            paragraphs: <String>[
              'مظبوط منصة تربط العميل بالفني. يجب كتابة بيانات طلب صحيحة واستخدام المحادثة باحترام وعدم استغلال المنصة في أنشطة مخالفة للقانون.',
              'لا يفرض التطبيق رسوم معاينة أو دفعًا مسبقًا. يجب الاتفاق على نطاق العمل والسعر وقطع الغيار قبل التنفيذ والاحتفاظ بالاتفاق داخل المحادثة.',
              'تقييم الفني يجب أن يعكس تجربة حقيقية مرتبطة بطلب مكتمل. قد تُحذف التقييمات المسيئة أو غير المرتبطة بخدمة حقيقية.',
              'تخضع الإلغاءات والاستردادات وسياسة الشكاوى لحالة الطلب وسياسة التشغيل المعلنة وقت الإطلاق.',
            ],
          ),
        ],
      ),
    );
  }
}

class _LegalNotice extends StatelessWidget {
  const _LegalNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.orangeSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.gavel_outlined, color: AppColors.orange),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'هذه صياغة تشغيلية مبدئية داخل المشروع، ويجب مراجعتها قانونيًا وإضافة بيانات الشركة وسياسات الإلغاء قبل نشر التطبيق للجمهور.',
              style: TextStyle(fontSize: 10, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({required this.title, required this.paragraphs});

  final String title;
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...paragraphs.map(
          (paragraph) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              paragraph,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.7,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

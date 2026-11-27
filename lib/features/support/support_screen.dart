import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/ui_utils.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const _questions = <({String question, String answer})>[
    (
      question: 'إزاي أطلب فني؟',
      answer:
          'اختار الحرفة، افتح ملف الفني المناسب، واضغط اطلب الخدمة ثم اكتب التفاصيل والموعد والعنوان.',
    ),
    (
      question: 'هل توجد رسوم معاينة أو دفع مسبق؟',
      answer:
          'لا. إرسال الطلب مجاني ولا توجد رسوم معاينة داخل التطبيق، والسعر النهائي يتحدد بالاتفاق مع الفني قبل التنفيذ.',
    ),
    (
      question: 'إزاي ألغي طلب؟',
      answer:
          'افتح الطلب الحالي واضغط طلب إلغاء الخدمة. إمكانية الإلغاء تعتمد على حالة الطلب وسياسة التشغيل.',
    ),
    (
      question: 'إزاي أتأكد إن الفني موثّق؟',
      answer:
          'علامة التوثيق تظهر في بطاقة الفني وملفه. لا يظهر للعملاء إلا الفني المقبول واشتراكه نشط.',
    ),
    (
      question: 'أعمل إيه لو حصل خلاف؟',
      answer:
          'احتفظ بالاتفاق داخل المحادثة ورقم الطلب، ثم تواصل مع الدعم موضحًا التفاصيل.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مركز المساعدة')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 27,
                  backgroundColor: AppColors.orange,
                  child: Icon(
                    Icons.support_agent_rounded,
                    color: Colors.white,
                    size: 29,
                  ),
                ),
                SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'إحنا هنا علشان نساعدك',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'راجع الأسئلة الشائعة أو تواصل مع فريق الدعم.',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'الأسئلة الشائعة',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: _questions
                  .map(
                    (item) => ExpansionTile(
                      title: Text(
                        item.question,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      children: <Widget>[
                        Text(
                          item.answer,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 18),
          Text('تواصل مع الدعم', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 9),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _launchSupport(context, type: _SupportType.phone),
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('اتصال'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _launchSupport(context, type: _SupportType.email),
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('بريد'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchSupport(
    BuildContext context, {
    required _SupportType type,
  }) async {
    final value = type == _SupportType.phone
        ? AppConfig.supportPhone
        : AppConfig.supportEmail;
    if (value.isEmpty) {
      UiUtils.showSnackBar(
        context,
        'بيانات الدعم لم تُضف بعد. أضف ${type == _SupportType.phone ? 'SUPPORT_PHONE' : 'SUPPORT_EMAIL'} في إعدادات التشغيل.',
      );
      return;
    }
    final uri = type == _SupportType.phone
        ? Uri(scheme: 'tel', path: value)
        : Uri(
            scheme: 'mailto',
            path: value,
            queryParameters: <String, String>{'subject': 'دعم Mazboot'},
          );
    final opened = await launchUrl(uri);
    if (!opened && context.mounted)
      UiUtils.showSnackBar(context, 'تعذر فتح وسيلة التواصل.');
  }
}

enum _SupportType { phone, email }

import 'package:get_storage/get_storage.dart';

import '../core/services/auth_service.dart';
import '../models/provider_application.dart';
import 'provider_application_repository.dart';

class LocalProviderApplicationRepository
    implements ProviderApplicationRepository {
  LocalProviderApplicationRepository({
    required this.authService,
    GetStorage? box,
  }) : _box = box ?? GetStorage();

  static const _storageKey = 'demo_provider_application';

  final AuthService authService;
  final GetStorage _box;

  @override
  bool get isDemo => true;

  @override
  Stream<ProviderApplication?> watchCurrentApplication() async* {
    yield await loadCurrentApplication();
  }

  @override
  Future<ProviderApplication?> loadCurrentApplication() async {
    final value = _box.read<Object?>(_storageKey);
    if (value is! Map) return null;
    final uid = value['applicantUid']?.toString() ?? 'demo-provider';
    final application = ProviderApplication.fromMap(
      uid,
      Map<Object?, Object?>.from(value),
    );
    return _approvedPreview(application);
  }

  @override
  Future<ProviderApplication> submit({
    required String name,
    required String phone,
    required String categoryId,
    required String governorate,
    required String area,
    required String photoBase64,
  }) async {
    final existing = await loadCurrentApplication();
    if (existing != null) {
      throw StateError('تم إرسال طلب انضمام بهذا الحساب من قبل');
    }
    final uid = authService.currentProviderUid ?? 'demo-provider';
    final now = DateTime.now().millisecondsSinceEpoch;
    final application = ProviderApplication(
      id: uid,
      applicantUid: uid,
      name: name,
      phone: phone,
      categoryId: categoryId,
      governorate: governorate,
      area: area,
      photoBase64: photoBase64,
      submittedAt: now,
      status: ProviderApplicationStatus.approved,
      reviewNote: 'تم القبول تلقائيًا داخل وضع المعاينة فقط.',
      subscriptionActive: true,
      published: true,
      subscriptionStartedAt: now,
      subscriptionExpiresAt: now + const Duration(days: 30).inMilliseconds,
      lastPaymentAt: now,
    );
    await _box.write(_storageKey, application.toMap());
    return application;
  }

  static ProviderApplication _approvedPreview(ProviderApplication application) {
    if (application.isFullyActive) return application;
    final now = DateTime.now().millisecondsSinceEpoch;
    return ProviderApplication(
      id: application.id,
      applicantUid: application.applicantUid,
      name: application.name,
      phone: application.phone,
      categoryId: application.categoryId,
      governorate: application.governorate,
      area: application.area,
      photoBase64: application.photoBase64,
      submittedAt: application.submittedAt,
      status: ProviderApplicationStatus.approved,
      reviewNote: 'تم القبول تلقائيًا داخل وضع المعاينة فقط.',
      subscriptionActive: true,
      monthlySubscriptionAmount: application.monthlySubscriptionAmount,
      published: true,
      subscriptionStartedAt: now,
      subscriptionExpiresAt: now + const Duration(days: 30).inMilliseconds,
      lastPaymentAt: now,
    );
  }
}

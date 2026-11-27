import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../core/config/app_config.dart';
import '../core/services/auth_service.dart';
import '../models/provider_application.dart';
import 'provider_application_repository.dart';

class FirebaseProviderApplicationRepository
    implements ProviderApplicationRepository {
  FirebaseProviderApplicationRepository({
    required this.authService,
    FirebaseDatabase? database,
  }) : _database =
           database ??
           (AppConfig.firebaseDatabaseUrl.isEmpty
               ? FirebaseDatabase.instance
               : FirebaseDatabase.instanceFor(
                   app: Firebase.app(),
                   databaseURL: AppConfig.firebaseDatabaseUrl,
                 ));

  final AuthService authService;
  final FirebaseDatabase _database;

  String get _uid {
    final uid = authService.currentProviderUid;
    if (uid == null) throw StateError('سجّل دخول بحساب الصنايعي أولًا');
    return uid;
  }

  DatabaseReference get _reference =>
      _database.ref('provider_applications/$_uid');

  @override
  bool get isDemo => false;

  @override
  Stream<ProviderApplication?> watchCurrentApplication() {
    return _reference.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return null;
      return ProviderApplication.fromMap(
        _uid,
        Map<Object?, Object?>.from(value),
      );
    });
  }

  @override
  Future<ProviderApplication?> loadCurrentApplication() async {
    final snapshot = await _reference.get();
    final value = snapshot.value;
    if (value is! Map) return null;
    return ProviderApplication.fromMap(_uid, Map<Object?, Object?>.from(value));
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
    final application = ProviderApplication(
      id: _uid,
      applicantUid: _uid,
      name: name,
      phone: phone,
      categoryId: categoryId,
      governorate: governorate,
      area: area,
      photoBase64: photoBase64,
      submittedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _reference.set(application.toMap());
    return application;
  }
}

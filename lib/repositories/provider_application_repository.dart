import '../models/provider_application.dart';

abstract class ProviderApplicationRepository {
  bool get isDemo;

  Stream<ProviderApplication?> watchCurrentApplication();

  Future<ProviderApplication?> loadCurrentApplication();

  Future<ProviderApplication> submit({
    required String name,
    required String phone,
    required String categoryId,
    required String governorate,
    required String area,
    required String photoBase64,
  });
}

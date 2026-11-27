import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import 'app/app.dart';
import 'core/services/auth_service.dart';
import 'core/services/firebase_bootstrap.dart';
import 'core/services/image_service.dart';
import 'core/services/location_service.dart';
import 'core/services/notification_service.dart';
import 'repositories/customer_repository.dart';
import 'repositories/firebase_customer_repository.dart';
import 'repositories/firebase_provider_application_repository.dart';
import 'repositories/local_customer_repository.dart';
import 'repositories/local_provider_application_repository.dart';
import 'repositories/firebase_provider_repository.dart';
import 'repositories/local_provider_repository.dart';
import 'repositories/provider_application_repository.dart';
import 'repositories/provider_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  final firebase = await FirebaseBootstrap.initialize();
  final authService = AuthService(firebaseReady: firebase.isReady);
  final CustomerRepository repository = firebase.isReady
      ? FirebaseCustomerRepository(authService: authService)
      : LocalCustomerRepository(authService: authService);
  final ProviderApplicationRepository providerApplicationRepository =
      firebase.isReady
      ? FirebaseProviderApplicationRepository(authService: authService)
      : LocalProviderApplicationRepository(authService: authService);
  final ProviderRepository providerRepository = firebase.isReady
      ? FirebaseProviderRepository(authService: authService)
      : LocalProviderRepository(authService: authService);
  final notificationService = NotificationService(
    firebaseReady: firebase.isReady,
  );
  try {
    await notificationService.initialize();
  } catch (_) {
    // The app remains usable when notification permission or native setup is unavailable.
  }
  runApp(
    MazbootApp(
      repository: repository,
      authService: authService,
      imageService: ImageService(),
      locationService: LocationService(),
      notificationService: notificationService,
      providerApplicationRepository: providerApplicationRepository,
      providerRepository: providerRepository,
      firebaseError: firebase.error,
    ),
  );
}

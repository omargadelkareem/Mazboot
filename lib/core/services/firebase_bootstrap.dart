import 'package:firebase_core/firebase_core.dart';

import '../config/app_config.dart';

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult({required this.isReady, this.error});

  final bool isReady;
  final Object? error;
}

abstract final class FirebaseBootstrap {
  static Future<FirebaseBootstrapResult> initialize() async {
    if (AppConfig.forceDemoMode) {
      return const FirebaseBootstrapResult(isReady: false);
    }
    try {
      if (Firebase.apps.isNotEmpty) {
        return const FirebaseBootstrapResult(isReady: true);
      }
      if (AppConfig.hasDartDefineFirebaseOptions) {
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: AppConfig.firebaseApiKey,
            appId: AppConfig.firebaseAppId,
            messagingSenderId: AppConfig.firebaseMessagingSenderId,
            projectId: AppConfig.firebaseProjectId,
            databaseURL: AppConfig.firebaseDatabaseUrl,
            storageBucket: AppConfig.firebaseStorageBucket.isEmpty
                ? null
                : AppConfig.firebaseStorageBucket,
          ),
        );
      } else {
        await Firebase.initializeApp();
      }
      return const FirebaseBootstrapResult(isReady: true);
    } catch (error) {
      return FirebaseBootstrapResult(isReady: false, error: error);
    }
  }
}

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum AppAccountRole { none, customer, provider, guest }

class AuthIdentity {
  const AuthIdentity({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.photoUrl,
    this.isGuest = false,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final bool isGuest;
}

class OtpSession {
  const OtpSession({
    required this.verificationId,
    this.resendToken,
    this.autoVerifiedUid,
  });

  final String verificationId;
  final int? resendToken;
  final String? autoVerifiedUid;
}

class AuthService {
  AuthService({
    required this.firebaseReady,
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseReady
           ? (firebaseAuth ?? FirebaseAuth.instance)
           : null,
       _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: <String>['email']);

  static const String providerEmailDomain = 'provider.hetta.app';

  final bool firebaseReady;
  final FirebaseAuth? _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final GetStorage _box = GetStorage();

  User? get _user => _firebaseAuth?.currentUser;

  AppAccountRole get currentRole {
    if (!firebaseReady) {
      return switch (_box.read<String>('auth_role')) {
        'customer' => AppAccountRole.customer,
        'provider' => AppAccountRole.provider,
        'guest' => AppAccountRole.guest,
        _ => AppAccountRole.none,
      };
    }
    final user = _user;
    if (user == null) return AppAccountRole.none;
    if (user.isAnonymous) return AppAccountRole.guest;
    if (isProviderEmail(user.email)) return AppAccountRole.provider;
    return AppAccountRole.customer;
  }

  bool get hasCustomerSession => currentRole == AppAccountRole.customer;

  bool get hasProviderSession => currentRole == AppAccountRole.provider;

  String? get rawUid {
    if (firebaseReady) return _user?.uid;
    if (!(_box.read<bool>('logged_in') ?? false)) return null;
    return _box.read<String>('auth_uid');
  }

  String? get currentUid => hasCustomerSession ? rawUid : null;

  String? get currentProviderUid => hasProviderSession ? rawUid : null;

  String get currentPhone {
    if (hasProviderSession) {
      return _box.read<String>('provider_phone') ?? '';
    }
    if (firebaseReady) return _user?.phoneNumber ?? '';
    return _box.read<String>('customer_phone') ?? '';
  }

  String get currentName {
    if (firebaseReady) return _user?.displayName ?? '';
    return hasProviderSession
        ? (_box.read<String>('provider_name') ?? '')
        : (_box.read<String>('customer_name') ?? '');
  }

  String get currentEmail {
    if (firebaseReady) return _user?.email ?? '';
    return hasProviderSession
        ? providerEmailForPhone(currentPhone)
        : (_box.read<String>('customer_email') ?? '');
  }

  String? get currentPhotoUrl {
    if (firebaseReady) return _user?.photoURL;
    return _box.read<String>('customer_photo_url');
  }

  bool get isGuest => currentRole == AppAccountRole.guest;

  Stream<String?> watchUid() {
    if (firebaseReady) {
      return _firebaseAuth!.authStateChanges().map((user) {
        if (user == null || user.isAnonymous || isProviderEmail(user.email)) {
          return null;
        }
        return user.uid;
      });
    }
    return Stream<String?>.value(currentUid);
  }

  Future<AuthIdentity> signInWithGoogle() async {
    if (!firebaseReady) {
      await _saveDemoIdentity(
        uid: 'demo-google-customer',
        role: AppAccountRole.customer,
      );
      await _box.write('customer_name', 'عميل مظبوط');
      await _box.write('customer_email', 'demo@mazboot.app');
      return const AuthIdentity(
        uid: 'demo-google-customer',
        name: 'عميل مظبوط',
        email: 'demo@mazboot.app',
      );
    }

    await _firebaseAuth!.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // A missing Google session is expected when switching from provider.
    }
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthException('تم إلغاء تسجيل الدخول بحساب Google');
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _firebaseAuth.signInWithCredential(credential);
    final user = result.user;
    if (user == null) {
      throw const AuthException('تعذر تسجيل الدخول بحساب Google');
    }
    await _box.write('selected_role', 'customer');
    return AuthIdentity(
      uid: user.uid,
      name: user.displayName ?? googleUser.displayName ?? 'عميل مظبوط',
      email: user.email ?? googleUser.email,
      phone: user.phoneNumber ?? '',
      photoUrl: user.photoURL ?? googleUser.photoUrl,
    );
  }

  Future<AuthIdentity> signInAsGuest() async {
    throw const AuthException('الدخول كضيف غير متاح. ادخل بحساب Google كعميل.');
  }

  Future<AuthIdentity> registerProvider({
    required String phone,
    required String password,
    required String name,
  }) async {
    final normalizedPhone = normalizeEgyptianPhone(phone);
    _validateProviderPassword(password);
    if (!firebaseReady) {
      await _saveDemoIdentity(
        uid: 'demo-provider',
        role: AppAccountRole.provider,
      );
      await _box.write('provider_phone', normalizedPhone);
      await _box.write('provider_name', name.trim());
      await _box.write('selected_role', 'provider');
      return AuthIdentity(
        uid: 'demo-provider',
        name: name.trim(),
        email: providerEmailForPhone(normalizedPhone),
        phone: normalizedPhone,
      );
    }

    await _clearFirebaseSession();
    UserCredential result;
    try {
      result = await _firebaseAuth!.createUserWithEmailAndPassword(
        email: providerEmailForPhone(normalizedPhone),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      if (error.code != 'email-already-in-use') rethrow;
      return signInProvider(phone: normalizedPhone, password: password);
    }
    final user = result.user;
    if (user == null) throw const AuthException('تعذر إنشاء حساب الصنايعي');
    if (name.trim().isNotEmpty) await user.updateDisplayName(name.trim());
    await _saveProviderSession(phone: normalizedPhone, name: name.trim());
    return AuthIdentity(
      uid: user.uid,
      name: name.trim(),
      email: user.email ?? providerEmailForPhone(normalizedPhone),
      phone: normalizedPhone,
    );
  }

  Future<AuthIdentity> signInProvider({
    required String phone,
    required String password,
  }) async {
    final normalizedPhone = normalizeEgyptianPhone(phone);
    _validateProviderPassword(password);
    if (!firebaseReady) {
      await _saveDemoIdentity(
        uid: 'demo-provider',
        role: AppAccountRole.provider,
      );
      await _box.write('provider_phone', normalizedPhone);
      await _box.write('provider_name', 'صنايعي مظبوط');
      await _box.write('selected_role', 'provider');
      return AuthIdentity(
        uid: 'demo-provider',
        name: 'صنايعي مظبوط',
        email: providerEmailForPhone(normalizedPhone),
        phone: normalizedPhone,
      );
    }

    await _clearFirebaseSession();
    final result = await _firebaseAuth!.signInWithEmailAndPassword(
      email: providerEmailForPhone(normalizedPhone),
      password: password,
    );
    final user = result.user;
    if (user == null || !isProviderEmail(user.email)) {
      await _firebaseAuth.signOut();
      throw const AuthException('هذا الحساب ليس حساب صنايعي');
    }
    await _saveProviderSession(
      phone: normalizedPhone,
      name: user.displayName ?? 'صنايعي مظبوط',
    );
    return AuthIdentity(
      uid: user.uid,
      name: user.displayName ?? 'صنايعي مظبوط',
      email: user.email ?? providerEmailForPhone(normalizedPhone),
      phone: normalizedPhone,
    );
  }

  Future<void> prepareForCustomer() async {
    await _box.write('selected_role', 'customer');
    if (currentRole == AppAccountRole.provider ||
        currentRole == AppAccountRole.guest) {
      await signOut(clearSelectedRole: false);
    }
  }

  Future<void> prepareForProvider() async {
    await _box.write('selected_role', 'provider');
    if (currentRole == AppAccountRole.customer ||
        currentRole == AppAccountRole.guest) {
      await signOut(clearSelectedRole: false);
    }
  }

  Future<OtpSession> sendOtp(String phone, {int? forceResendingToken}) async {
    if (!firebaseReady) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return const OtpSession(verificationId: 'demo-verification');
    }

    final completer = Completer<OtpSession>();
    await _firebaseAuth!.verifyPhoneNumber(
      phoneNumber: phone,
      forceResendingToken: forceResendingToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        try {
          final result = await _firebaseAuth.signInWithCredential(credential);
          if (!completer.isCompleted) {
            completer.complete(
              OtpSession(verificationId: '', autoVerifiedUid: result.user?.uid),
            );
          }
        } catch (error, stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        }
      },
      verificationFailed: (error) {
        if (!completer.isCompleted) completer.completeError(error);
      },
      codeSent: (verificationId, resendToken) {
        if (!completer.isCompleted) {
          completer.complete(
            OtpSession(
              verificationId: verificationId,
              resendToken: resendToken,
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) {
          completer.complete(OtpSession(verificationId: verificationId));
        }
      },
    );
    return completer.future.timeout(const Duration(seconds: 75));
  }

  Future<String> confirmOtp({
    required OtpSession session,
    required String code,
  }) async {
    if (!firebaseReady) {
      if (code != '1234') {
        throw const AuthException('رمز التحقق التجريبي هو 1234');
      }
      await _saveDemoIdentity(
        uid: 'demo-customer',
        role: AppAccountRole.customer,
      );
      return 'demo-customer';
    }
    if (session.autoVerifiedUid != null) return session.autoVerifiedUid!;
    final credential = PhoneAuthProvider.credential(
      verificationId: session.verificationId,
      smsCode: code,
    );
    final result = await _firebaseAuth!.signInWithCredential(credential);
    final uid = result.user?.uid;
    if (uid == null) {
      throw const AuthException('تعذر تسجيل الدخول، حاول مرة أخرى');
    }
    return uid;
  }

  Future<void> saveDemoPhone(String phone) =>
      _box.write('customer_phone', phone);

  Future<void> signOut({bool clearSelectedRole = true}) async {
    if (firebaseReady) {
      await _firebaseAuth!.signOut();
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Firebase sign-out is enough when no Google session exists.
      }
    }
    await _box.remove('logged_in');
    await _box.remove('auth_uid');
    await _box.remove('auth_role');
    await _box.remove('auth_method');
    await _box.remove('customer_phone');
    await _box.remove('customer_name');
    await _box.remove('customer_email');
    await _box.remove('customer_photo_url');
    await _box.remove('provider_phone');
    await _box.remove('provider_name');
    if (clearSelectedRole) await _box.remove('selected_role');
  }

  String friendlyError(Object error) {
    if (error is AuthException) return error.message;
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-phone-number' => 'رقم الموبايل غير صحيح',
        'invalid-verification-code' => 'رمز التحقق غير صحيح',
        'too-many-requests' => 'محاولات كثيرة، جرّب بعد شوية',
        'network-request-failed' => 'تأكد من اتصال الإنترنت وحاول مرة أخرى',
        'quota-exceeded' => 'تم تجاوز حد رسائل التحقق في Firebase',
        'email-already-in-use' =>
          'رقم الموبايل مسجل بالفعل. ارجع وسجّل دخول كصنايعي.',
        'wrong-password' ||
        'invalid-credential' ||
        'invalid-login-credentials' => 'رقم الموبايل أو كلمة المرور غير صحيحة',
        'user-not-found' => 'لا يوجد حساب صنايعي بهذا الرقم',
        'weak-password' => 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
        'account-exists-with-different-credential' =>
          'الحساب مرتبط بطريقة دخول أخرى',
        'operation-not-allowed' =>
          'فعّل Google وEmail/Password في Firebase Authentication',
        _ => error.message ?? 'حدث خطأ في تسجيل الدخول',
      };
    }
    return 'حدث خطأ غير متوقع، حاول مرة أخرى';
  }

  static String normalizeEgyptianPhone(String value) {
    var digits = _toWesternDigits(
      value,
    ).replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0020') && digits.length == 14) {
      digits = '0${digits.substring(4)}';
    } else if (digits.startsWith('20') && digits.length == 12) {
      digits = '0${digits.substring(2)}';
    }
    if (digits.length != 11 || !RegExp(r'^01[0125]\d{8}$').hasMatch(digits)) {
      throw const AuthException('اكتب رقم موبايل مصري صحيح من 11 رقمًا');
    }
    return '+2$digits';
  }

  static bool isValidEgyptianPhone(String value) {
    try {
      normalizeEgyptianPhone(value);
      return true;
    } on AuthException {
      return false;
    }
  }

  static String _toWesternDigits(String value) {
    const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
    const easternArabic = '۰۱۲۳۴۵۶۷۸۹';
    final output = StringBuffer();
    for (final character in value.split('')) {
      final arabicIndex = arabicIndic.indexOf(character);
      if (arabicIndex >= 0) {
        output.write(arabicIndex);
        continue;
      }
      final easternIndex = easternArabic.indexOf(character);
      output.write(easternIndex >= 0 ? easternIndex : character);
    }
    return output.toString();
  }

  static String providerEmailForPhone(String phone) {
    final normalized = normalizeEgyptianPhone(phone);
    final digits = normalized.replaceAll(RegExp(r'\D'), '');
    return '$digits@$providerEmailDomain';
  }

  static bool isProviderEmail(String? email) =>
      email?.toLowerCase().endsWith('@$providerEmailDomain') == true;

  Future<void> _clearFirebaseSession() async {
    if (_firebaseAuth?.currentUser != null) await _firebaseAuth!.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Switching roles may start without a Google session.
    }
  }

  Future<void> _saveProviderSession({
    required String phone,
    required String name,
  }) async {
    await _box.write('selected_role', 'provider');
    await _box.write('provider_phone', phone);
    await _box.write('provider_name', name);
  }

  Future<void> _saveDemoIdentity({
    required String uid,
    required AppAccountRole role,
  }) async {
    await _box.write('logged_in', true);
    await _box.write('auth_uid', uid);
    await _box.write('auth_role', role.name);
    await _box.write('auth_method', role.name);
  }

  static void _validateProviderPassword(String password) {
    if (password.length < 6) {
      throw const AuthException('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
    }
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}

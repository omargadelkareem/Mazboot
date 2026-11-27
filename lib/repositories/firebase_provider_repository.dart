import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../core/config/app_config.dart';
import '../core/services/auth_service.dart';
import '../models/chat_message.dart';
import '../models/provider_conversation.dart';
import '../models/service_order.dart';
import '../models/technician.dart';
import 'provider_repository.dart';

class FirebaseProviderRepository implements ProviderRepository {
  FirebaseProviderRepository({
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

  DatabaseReference get _root => _database.ref();

  @override
  bool get isDemo => false;

  @override
  String get currentUid {
    final uid = authService.currentProviderUid;
    if (uid == null) throw StateError('سجّل دخول بحساب الصنايعي أولًا');
    return uid;
  }

  @override
  Stream<Technician?> watchProfile() {
    return _root.child('public_providers/$currentUid').onValue.map((event) {
      final map = _map(event.snapshot.value);
      return map == null ? null : Technician.fromMap(currentUid, map);
    });
  }

  @override
  Stream<List<ServiceOrder>> watchOrders() {
    return _root
        .child('orders')
        .orderByChild('technicianId')
        .equalTo(currentUid)
        .onValue
        .map((event) {
          final values = _children(event.snapshot.value)
              .map((entry) => ServiceOrder.fromMap(entry.key, entry.value))
              .toList();
          values.sort(
            (first, second) => second.createdAt.compareTo(first.createdAt),
          );
          return values;
        });
  }

  @override
  Stream<ServiceOrder?> watchOrder(String orderId) {
    return _root.child('orders/$orderId').onValue.map((event) {
      final map = _map(event.snapshot.value);
      if (map == null || map['technicianId']?.toString() != currentUid) {
        return null;
      }
      return ServiceOrder.fromMap(orderId, map);
    });
  }

  @override
  Stream<List<ProviderConversation>> watchConversations() {
    return _root
        .child('chats')
        .orderByChild('technicianId')
        .equalTo(currentUid)
        .onValue
        .map((event) {
          final values = _children(event.snapshot.value)
              .map(
                (entry) => ProviderConversation.fromMap(entry.key, entry.value),
              )
              .toList();
          values.sort(
            (first, second) =>
                second.lastMessageAt.compareTo(first.lastMessageAt),
          );
          return values;
        });
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String orderId) {
    final chat = _root.child('chats/$orderId');
    unawaited(chat.child('technicianUnreadCount').set(0));
    return chat.child('messages').limitToLast(150).onValue.map((event) {
      final values = _children(
        event.snapshot.value,
      ).map((entry) => ChatMessage.fromMap(entry.key, entry.value)).toList();
      values.sort((first, second) => first.sentAt.compareTo(second.sentAt));
      return values;
    });
  }

  @override
  Future<void> setAvailability(bool available) {
    return _root
        .child('public_providers/$currentUid/isAvailable')
        .set(available);
  }

  @override
  Future<void> updateProfile({
    required String name,
    required String bio,
    required int experienceYears,
    required List<String> services,
  }) {
    return _root.child('public_providers/$currentUid').update(<String, Object?>{
      'name': name.trim(),
      'bio': bio.trim(),
      'experienceYears': experienceYears,
      'services': services,
    });
  }

  @override
  Future<void> updateOrderStatus(
    String orderId,
    ServiceOrderStatus status,
  ) async {
    final reference = _root.child('orders/$orderId');
    final snapshot = await reference.get();
    final map = _map(snapshot.value);
    if (map == null || map['technicianId']?.toString() != currentUid) {
      throw StateError('الطلب غير موجود أو لا يخص هذا الحساب');
    }
    final current = ServiceOrder.statusFromName(map['status']?.toString());
    if (!_canMove(current, status)) {
      throw StateError(
        'لا يمكن تغيير الطلب من ${current.label} إلى ${status.label}',
      );
    }
    await reference.update(<String, Object?>{
      'status': status.name,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> sendMessage({
    required String orderId,
    required String customerId,
    required String text,
    String? imageBase64,
  }) async {
    final chat = _root.child('chats/$orderId');
    final messageReference = chat.child('messages').push();
    final messageId = messageReference.key;
    if (messageId == null) throw StateError('تعذر إرسال الرسالة');
    final now = DateTime.now().millisecondsSinceEpoch;
    final message = ChatMessage(
      id: messageId,
      senderId: currentUid,
      text: text.trim(),
      sentAt: now,
      imageBase64: imageBase64,
    );
    await _root.update(<String, Object?>{
      'chats/$orderId/messages/$messageId': message.toMap(),
      'chats/$orderId/lastMessage': text.trim().isEmpty ? 'صورة' : text.trim(),
      'chats/$orderId/lastMessageAt': now,
      'chats/$orderId/technicianUnreadCount': 0,
      'chats/$orderId/customerUnreadCount': ServerValue.increment(1),
    });
  }

  @override
  Future<void> dispose() async {}

  static bool _canMove(ServiceOrderStatus current, ServiceOrderStatus next) {
    if (current == next) return true;
    return switch (current) {
      ServiceOrderStatus.sent =>
        next == ServiceOrderStatus.accepted ||
            next == ServiceOrderStatus.cancelled,
      ServiceOrderStatus.accepted =>
        next == ServiceOrderStatus.onTheWay ||
            next == ServiceOrderStatus.cancelled,
      ServiceOrderStatus.onTheWay =>
        next == ServiceOrderStatus.inProgress ||
            next == ServiceOrderStatus.cancelled,
      ServiceOrderStatus.inProgress => next == ServiceOrderStatus.completed,
      ServiceOrderStatus.completed || ServiceOrderStatus.cancelled => false,
    };
  }

  static Map<Object?, Object?>? _map(Object? value) {
    if (value is Map<Object?, Object?>) return value;
    if (value is Map) return Map<Object?, Object?>.from(value);
    return null;
  }

  static List<_MapEntry> _children(Object? value) {
    final map = _map(value);
    if (map == null) return const <_MapEntry>[];
    return map.entries
        .map((entry) {
          final child = _map(entry.value);
          return child == null ? null : _MapEntry(entry.key.toString(), child);
        })
        .whereType<_MapEntry>()
        .toList();
  }
}

class _MapEntry {
  const _MapEntry(this.key, this.value);

  final String key;
  final Map<Object?, Object?> value;
}

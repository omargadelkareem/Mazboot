import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../core/config/app_config.dart';
import '../core/services/auth_service.dart';
import '../models/address.dart';
import '../models/app_notification.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/customer_profile.dart';
import '../models/review.dart';
import '../models/service_category.dart';
import '../models/service_order.dart';
import '../models/technician.dart';
import 'customer_repository.dart';

class FirebaseCustomerRepository implements CustomerRepository {
  FirebaseCustomerRepository({
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
    final uid = authService.currentUid;
    if (uid == null) throw StateError('يجب تسجيل الدخول أولًا');
    return uid;
  }

  @override
  Stream<List<ServiceCategory>> watchCategories() {
    return _root.child('categories').onValue.map((event) {
      final categories =
          _children(event.snapshot.value)
              .map((entry) => ServiceCategory.fromMap(entry.key, entry.value))
              .where((category) => category.isActive)
              .toList()
            ..sort(
              (first, second) => first.sortOrder.compareTo(second.sortOrder),
            );
      return categories;
    });
  }

  @override
  Stream<List<Technician>> watchTechnicians() {
    return _root.child('public_providers').onValue.map((event) {
      final technicians =
          _children(event.snapshot.value)
              .map((entry) => Technician.fromMap(entry.key, entry.value))
              .where((technician) => technician.approvalStatus == 'approved')
              .toList()
            ..sort((first, second) => second.rating.compareTo(first.rating));
      return technicians;
    });
  }

  @override
  Future<Technician?> getTechnician(String id) async {
    final snapshot = await _root.child('public_providers/$id').get();
    final map = _map(snapshot.value);
    if (map == null) return null;
    final technician = Technician.fromMap(id, map);
    return technician.approvalStatus == 'approved' ? technician : null;
  }

  @override
  Stream<CustomerProfile?> watchProfile() {
    return _root.child('users/$currentUid').onValue.map((event) {
      final map = _map(event.snapshot.value);
      return map == null ? null : CustomerProfile.fromMap(currentUid, map);
    });
  }

  @override
  Future<CustomerProfile?> loadProfile() async {
    final snapshot = await _root.child('users/$currentUid').get();
    final map = _map(snapshot.value);
    return map == null ? null : CustomerProfile.fromMap(currentUid, map);
  }

  @override
  Future<void> saveProfile(CustomerProfile profile) {
    return _root.child('users/$currentUid').update(profile.toMap());
  }

  @override
  Future<void> saveFcmToken(String token) {
    return _root.child('users/$currentUid/fcmToken').set(token);
  }

  @override
  Stream<Set<String>> watchFavorites() {
    return _root.child('favorites/$currentUid').onValue.map((event) {
      return _children(event.snapshot.value)
          .where((entry) => entry.value['active'] == true)
          .map((entry) => entry.key)
          .toSet();
    });
  }

  @override
  Future<void> setFavorite(
    String technicianId, {
    required bool favorite,
  }) async {
    final reference = _root.child('favorites/$currentUid/$technicianId');
    if (!favorite) {
      await reference.remove();
      return;
    }
    await reference.set(<String, Object?>{
      'active': true,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Stream<List<ServiceOrder>> watchOrders() {
    return _root
        .child('orders')
        .orderByChild('customerId')
        .equalTo(currentUid)
        .onValue
        .map((event) => _parseOrders(event.snapshot.value));
  }

  @override
  Stream<ServiceOrder?> watchOrder(String orderId) {
    return _root.child('orders/$orderId').onValue.map((event) {
      final map = _map(event.snapshot.value);
      if (map == null || map['customerId']?.toString() != currentUid)
        return null;
      return ServiceOrder.fromMap(orderId, map);
    });
  }

  @override
  Future<ServiceOrder> createOrder(ServiceOrder draft) async {
    final reference = _root.child('orders').push();
    final orderId = reference.key;
    if (orderId == null) throw StateError('تعذر إنشاء رقم للطلب');
    final now = DateTime.now().millisecondsSinceEpoch;
    final order = ServiceOrder(
      id: orderId,
      technicianId: draft.technicianId,
      categoryId: draft.categoryId,
      customerId: currentUid,
      problem: draft.problem,
      address: draft.address,
      date: draft.date,
      time: draft.time,
      visitFee: draft.visitFee,
      status: ServiceOrderStatus.sent,
      createdAt: now,
      updatedAt: now,
      problemImageBase64: draft.problemImageBase64,
    );
    await reference.set(order.toMap());
    await _root.child('chats/$orderId').update(<String, Object?>{
      'customerId': currentUid,
      'technicianId': order.technicianId,
      'orderId': orderId,
      'lastMessage': 'تم إنشاء طلب جديد',
      'lastMessageAt': now,
      'customerUnreadCount': 0,
      'technicianUnreadCount': 1,
    });
    return order;
  }

  @override
  Future<void> requestCancellation(String orderId, String reason) {
    return _root
        .child('order_actions/$orderId/cancellationRequests/$currentUid')
        .set(<String, Object?>{
          'reason': reason,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'status': 'pending',
        });
  }

  @override
  Stream<List<Conversation>> watchConversations() {
    return _root
        .child('chats')
        .orderByChild('customerId')
        .equalTo(currentUid)
        .onValue
        .map((event) {
          final values = _children(event.snapshot.value)
              .map((entry) => Conversation.fromMap(entry.key, entry.value))
              .toList();
          values.sort((first, second) {
            final firstValue = _children(
              event.snapshot.value,
            ).where((entry) => entry.key == first.orderId).firstOrNull;
            final secondValue = _children(
              event.snapshot.value,
            ).where((entry) => entry.key == second.orderId).firstOrNull;
            final firstTime =
                (firstValue?.value['lastMessageAt'] as num?)?.toInt() ?? 0;
            final secondTime =
                (secondValue?.value['lastMessageAt'] as num?)?.toInt() ?? 0;
            return secondTime.compareTo(firstTime);
          });
          return values;
        });
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String orderId) {
    final chatReference = _root.child('chats/$orderId');
    unawaited(chatReference.child('customerUnreadCount').set(0));
    return chatReference.child('messages').limitToLast(150).onValue.map((
      event,
    ) {
      final messages =
          _children(event.snapshot.value)
              .map((entry) => ChatMessage.fromMap(entry.key, entry.value))
              .toList()
            ..sort((first, second) => first.sentAt.compareTo(second.sentAt));
      return messages;
    });
  }

  @override
  Future<void> sendMessage({
    required String orderId,
    required String technicianId,
    required String text,
    String? imageBase64,
  }) async {
    final messageReference = _root.child('chats/$orderId/messages').push();
    final messageId = messageReference.key;
    if (messageId == null) throw StateError('تعذر إرسال الرسالة');
    final now = DateTime.now().millisecondsSinceEpoch;
    final message = ChatMessage(
      id: messageId,
      senderId: currentUid,
      text: text,
      sentAt: now,
      imageBase64: imageBase64,
    );
    await _root.update(<String, Object?>{
      'chats/$orderId/messages/$messageId': message.toMap(),
      'chats/$orderId/lastMessage': text.isEmpty ? 'صورة' : text,
      'chats/$orderId/lastMessageAt': now,
      'chats/$orderId/customerUnreadCount': 0,
      'chats/$orderId/technicianUnreadCount': ServerValue.increment(1),
    });
  }

  @override
  Stream<List<TechnicianReview>> watchReviews(String technicianId) {
    return _root.child('reviews/$technicianId').onValue.map((event) {
      final reviews =
          _children(event.snapshot.value)
              .map((entry) => TechnicianReview.fromMap(entry.key, entry.value))
              .toList()
            ..sort(
              (first, second) => second.createdAt.compareTo(first.createdAt),
            );
      return reviews;
    });
  }

  @override
  Future<void> submitReview({
    required String orderId,
    required String technicianId,
    required String customerName,
    required int rating,
    required String comment,
  }) async {
    if (rating < 1 || rating > 5) throw ArgumentError.value(rating, 'rating');
    final orderSnapshot = await _root.child('orders/$orderId').get();
    final orderMap = _map(orderSnapshot.value);
    if (orderMap == null ||
        orderMap['customerId']?.toString() != currentUid ||
        orderMap['status']?.toString() != 'completed') {
      throw StateError('يمكن تقييم الطلبات المكتملة فقط');
    }
    final reviewId = orderId;
    final reviewReference = _root.child('reviews/$technicianId/$reviewId');
    if ((await reviewReference.get()).exists) {
      throw StateError('تم تقييم هذا الطلب من قبل');
    }
    await reviewReference.set(
      TechnicianReview(
        id: reviewId,
        orderId: orderId,
        customerId: currentUid,
        customerName: customerName,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ).toMap(),
    );
  }

  @override
  Stream<List<AppNotification>> watchNotifications() {
    return _root.child('notifications/$currentUid').onValue.map((event) {
      final notifications =
          _children(event.snapshot.value)
              .map((entry) => AppNotification.fromMap(entry.key, entry.value))
              .toList()
            ..sort(
              (first, second) => second.createdAt.compareTo(first.createdAt),
            );
      return notifications;
    });
  }

  @override
  Future<void> markNotificationRead(String notificationId) {
    return _root
        .child('notifications/$currentUid/$notificationId/isRead')
        .set(true);
  }

  @override
  Future<void> saveAddress(CustomerAddress address) async {
    if (address.isDefault) {
      final snapshot = await _root.child('users/$currentUid/addresses').get();
      final updates = <String, Object?>{};
      for (final entry in _children(snapshot.value)) {
        updates['users/$currentUid/addresses/${entry.key}/isDefault'] = false;
      }
      if (updates.isNotEmpty) await _root.update(updates);
    }
    await _root
        .child('users/$currentUid/addresses/${address.id}')
        .set(address.toMap());
  }

  @override
  Future<void> deleteAddress(String addressId) {
    return _root.child('users/$currentUid/addresses/$addressId').remove();
  }

  @override
  Future<void> dispose() async {}

  List<ServiceOrder> _parseOrders(Object? value) {
    final orders =
        _children(value)
            .map((entry) => ServiceOrder.fromMap(entry.key, entry.value))
            .toList()
          ..sort(
            (first, second) => second.createdAt.compareTo(first.createdAt),
          );
    return orders;
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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

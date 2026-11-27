import 'dart:async';

import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

import '../core/services/auth_service.dart';
import '../data/demo_data.dart';
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

class LocalCustomerRepository implements CustomerRepository {
  LocalCustomerRepository({required this.authService, GetStorage? box})
    : _box = box ?? GetStorage() {
    _load();
  }

  final AuthService authService;
  final GetStorage _box;
  final Uuid _uuid = const Uuid();
  final StreamController<void> _changes = StreamController<void>.broadcast();

  late CustomerProfile _profile;
  late List<ServiceOrder> _orders;
  late Set<String> _favorites;
  late List<CustomerAddress> _addresses;
  late Map<String, List<ChatMessage>> _messages;
  late Map<String, List<TechnicianReview>> _reviews;
  late List<AppNotification> _notifications;

  @override
  bool get isDemo => true;

  @override
  String get currentUid => authService.currentUid ?? 'demo-customer';

  @override
  Stream<List<ServiceCategory>> watchCategories() async* {
    yield DemoData.categories;
  }

  @override
  Stream<List<Technician>> watchTechnicians() async* {
    yield DemoData.technicians;
  }

  @override
  Future<Technician?> getTechnician(String id) async {
    for (final technician in DemoData.technicians) {
      if (technician.id == id) return technician;
    }
    return null;
  }

  @override
  Stream<CustomerProfile?> watchProfile() async* {
    yield _profileWithAddresses;
    yield* _changes.stream.map((_) => _profileWithAddresses);
  }

  @override
  Future<CustomerProfile?> loadProfile() async => _profileWithAddresses;

  @override
  Future<void> saveProfile(CustomerProfile profile) async {
    _profile = profile.copyWith(addresses: const <CustomerAddress>[]);
    await _box.write('demo_profile', _profile.toMap());
    _notify();
  }

  @override
  Future<void> saveFcmToken(String token) async {}

  @override
  Stream<Set<String>> watchFavorites() async* {
    yield Set<String>.from(_favorites);
    yield* _changes.stream.map((_) => Set<String>.from(_favorites));
  }

  @override
  Future<void> setFavorite(
    String technicianId, {
    required bool favorite,
  }) async {
    if (favorite) {
      _favorites.add(technicianId);
    } else {
      _favorites.remove(technicianId);
    }
    await _box.write('demo_favorites', _favorites.toList());
    _notify();
  }

  @override
  Stream<List<ServiceOrder>> watchOrders() async* {
    yield _sortedOrders;
    yield* _changes.stream.map((_) => _sortedOrders);
  }

  @override
  Stream<ServiceOrder?> watchOrder(String orderId) async* {
    ServiceOrder? findOrder() {
      for (final order in _orders) {
        if (order.id == orderId) return order;
      }
      return null;
    }

    yield findOrder();
    yield* _changes.stream.map((_) => findOrder());
  }

  @override
  Future<ServiceOrder> createOrder(ServiceOrder draft) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final order = ServiceOrder(
      id: 'HT-${_uuid.v4().substring(0, 8).toUpperCase()}',
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
    _orders.insert(0, order);
    _messages[order.id] = <ChatMessage>[
      ChatMessage(
        id: _uuid.v4(),
        senderId: 'system',
        text: 'تم إرسال طلبك للفني. هنبلغك فور ما يرد.',
        sentAt: now,
      ),
    ];
    _notifications.insert(
      0,
      AppNotification(
        id: _uuid.v4(),
        title: 'تم إنشاء الطلب',
        body: 'طلبك اتسجل بنجاح ورقمه ${order.id}',
        createdAt: now,
        orderId: order.id,
      ),
    );
    await _persistOrders();
    await _persistMessages();
    await _persistNotifications();
    _notify();
    return order;
  }

  @override
  Future<void> requestCancellation(String orderId, String reason) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    _orders = _orders.map((order) {
      if (order.id != orderId) return order;
      return order.copyWith(
        status: ServiceOrderStatus.cancelled,
        cancellationReason: reason,
        updatedAt: now,
      );
    }).toList();
    _notifications.insert(
      0,
      AppNotification(
        id: _uuid.v4(),
        title: 'تم إلغاء الطلب',
        body: 'تم تسجيل إلغاء الطلب $orderId في وضع المعاينة.',
        createdAt: now,
        orderId: orderId,
      ),
    );
    await _persistOrders();
    await _persistNotifications();
    _notify();
  }

  @override
  Stream<List<Conversation>> watchConversations() async* {
    yield _conversationList;
    yield* _changes.stream.map((_) => _conversationList);
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String orderId) async* {
    List<ChatMessage> current() =>
        List<ChatMessage>.from(_messages[orderId] ?? const []);

    yield current();
    yield* _changes.stream.map((_) => current());
  }

  @override
  Future<void> sendMessage({
    required String orderId,
    required String technicianId,
    required String text,
    String? imageBase64,
  }) async {
    final message = ChatMessage(
      id: _uuid.v4(),
      senderId: currentUid,
      text: text,
      imageBase64: imageBase64,
      sentAt: DateTime.now().millisecondsSinceEpoch,
      seen: true,
    );
    _messages.putIfAbsent(orderId, () => <ChatMessage>[]).add(message);
    await _persistMessages();
    _notify();
  }

  @override
  Stream<List<TechnicianReview>> watchReviews(String technicianId) async* {
    List<TechnicianReview> current() {
      final values = List<TechnicianReview>.from(
        _reviews[technicianId] ?? const [],
      );
      values.sort(
        (first, second) => second.createdAt.compareTo(first.createdAt),
      );
      return values;
    }

    yield current();
    yield* _changes.stream.map((_) => current());
  }

  @override
  Future<void> submitReview({
    required String orderId,
    required String technicianId,
    required String customerName,
    required int rating,
    required String comment,
  }) async {
    final order = _orders.where((item) => item.id == orderId).firstOrNull;
    if (order == null || order.status != ServiceOrderStatus.completed) {
      throw StateError('يمكن تقييم الطلبات المكتملة فقط');
    }
    final existing =
        _reviews[technicianId]?.any((item) => item.orderId == orderId) ?? false;
    if (existing) throw StateError('تم تقييم هذا الطلب من قبل');
    _reviews
        .putIfAbsent(technicianId, () => <TechnicianReview>[])
        .add(
          TechnicianReview(
            id: _uuid.v4(),
            orderId: orderId,
            customerId: currentUid,
            customerName: customerName,
            rating: rating,
            comment: comment,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    await _persistReviews();
    _notify();
  }

  @override
  Stream<List<AppNotification>> watchNotifications() async* {
    List<AppNotification> current() {
      final values = List<AppNotification>.from(_notifications);
      values.sort(
        (first, second) => second.createdAt.compareTo(first.createdAt),
      );
      return values;
    }

    yield current();
    yield* _changes.stream.map((_) => current());
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    _notifications = _notifications.map((notification) {
      if (notification.id != notificationId) return notification;
      return AppNotification(
        id: notification.id,
        title: notification.title,
        body: notification.body,
        createdAt: notification.createdAt,
        orderId: notification.orderId,
        isRead: true,
      );
    }).toList();
    await _persistNotifications();
    _notify();
  }

  @override
  Future<void> saveAddress(CustomerAddress address) async {
    if (address.isDefault) {
      _addresses = _addresses
          .map(
            (item) => CustomerAddress(
              id: item.id,
              label: item.label,
              details: item.details,
              governorate: item.governorate,
              area: item.area,
              latitude: item.latitude,
              longitude: item.longitude,
            ),
          )
          .toList();
    }
    final index = _addresses.indexWhere((item) => item.id == address.id);
    if (index == -1) {
      _addresses.add(address);
    } else {
      _addresses[index] = address;
    }
    await _persistAddresses();
    _notify();
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    _addresses.removeWhere((item) => item.id == addressId);
    await _persistAddresses();
    _notify();
  }

  @override
  Future<void> dispose() => _changes.close();

  CustomerProfile get _profileWithAddresses => _profile.copyWith(
    phone: authService.currentPhone.isEmpty
        ? _profile.phone
        : authService.currentPhone,
    addresses: List<CustomerAddress>.from(_addresses),
  );

  List<ServiceOrder> get _sortedOrders {
    final values = List<ServiceOrder>.from(_orders);
    values.sort((first, second) => second.createdAt.compareTo(first.createdAt));
    return values;
  }

  List<Conversation> get _conversationList {
    final values = <Conversation>[];
    for (final order in _orders) {
      final messages = _messages[order.id];
      if (messages == null || messages.isEmpty) continue;
      final last = messages.last;
      values.add(
        Conversation(
          orderId: order.id,
          technicianId: order.technicianId,
          lastMessage: last.text.isEmpty ? 'صورة' : last.text,
          time: _timeLabel(last.sentAt),
          unreadCount: 0,
        ),
      );
    }
    values.sort((first, second) {
      final firstMessages = _messages[first.orderId] ?? const <ChatMessage>[];
      final secondMessages = _messages[second.orderId] ?? const <ChatMessage>[];
      final firstTime = firstMessages.isEmpty ? 0 : firstMessages.last.sentAt;
      final secondTime = secondMessages.isEmpty
          ? 0
          : secondMessages.last.sentAt;
      return secondTime.compareTo(firstTime);
    });
    return values;
  }

  void _load() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final profileMap = _objectMap(_box.read<Object?>('demo_profile'));
    _profile = profileMap == null
        ? CustomerProfile(
            uid: 'demo-customer',
            name: 'أحمد محمد',
            phone: authService.currentPhone,
            governorate: 'القاهرة',
            area: 'مدينة نصر',
            createdAt: now,
          )
        : CustomerProfile.fromMap('demo-customer', profileMap);

    _addresses = _parseMapList(
      _box.read<Object?>('demo_addresses'),
      (map) =>
          CustomerAddress.fromMap(map['id']?.toString() ?? _uuid.v4(), map),
    );
    if (_addresses.isEmpty) {
      _addresses = const <CustomerAddress>[
        CustomerAddress(
          id: 'home',
          label: 'المنزل',
          details: 'شارع مصطفى النحاس، عمارة 18، الدور الثالث',
          governorate: 'القاهرة',
          area: 'مدينة نصر',
          isDefault: true,
        ),
      ];
    }

    final storedOrders = _parseMapList(
      _box.read<Object?>('demo_orders'),
      (map) => ServiceOrder.fromMap(map['id']?.toString() ?? '', map),
    );
    if (storedOrders.isEmpty) {
      _orders = DemoData.orders.indexed.map((entry) {
        final item = entry.$2;
        return ServiceOrder(
          id: item.id,
          technicianId: item.technicianId,
          categoryId: item.categoryId,
          customerId: 'demo-customer',
          problem: item.problem,
          address: item.address,
          date: item.date,
          time: item.time,
          visitFee: item.visitFee,
          status: item.status,
          createdAt: now - (entry.$1 * const Duration(days: 12).inMilliseconds),
          updatedAt: now,
        );
      }).toList();
    } else {
      _orders = storedOrders;
    }

    _favorites = Set<String>.from(
      (_box.read<List<dynamic>>('demo_favorites') ?? const <dynamic>[]).map(
        (item) => item.toString(),
      ),
    );
    _messages = _loadMessages();
    if (_messages.isEmpty) {
      _messages = <String, List<ChatMessage>>{
        DemoData.orders.first.id: <ChatMessage>[
          ChatMessage(
            id: _uuid.v4(),
            senderId: 'mohamed-ali',
            text: 'أهلًا بحضرتك، وصلتني تفاصيل الطلب.',
            sentAt: now - const Duration(minutes: 12).inMilliseconds,
          ),
          ChatMessage(
            id: _uuid.v4(),
            senderId: 'demo-customer',
            text: 'العطل في كهرباء المطبخ.',
            sentAt: now - const Duration(minutes: 9).inMilliseconds,
            seen: true,
          ),
          ChatMessage(
            id: _uuid.v4(),
            senderId: 'mohamed-ali',
            text: 'تمام، أنا في الطريق وحوصل خلال 18 دقيقة.',
            sentAt: now - const Duration(minutes: 3).inMilliseconds,
          ),
        ],
        DemoData.orders[1].id: <ChatMessage>[
          ChatMessage(
            id: _uuid.v4(),
            senderId: 'ahmed-gamal',
            text: 'تم تأكيد الموعد يا فندم.',
            sentAt: now - const Duration(days: 1).inMilliseconds,
          ),
        ],
      };
    }
    _reviews = _loadReviews();
    _notifications = _parseMapList(
      _box.read<Object?>('demo_notifications'),
      (map) =>
          AppNotification.fromMap(map['id']?.toString() ?? _uuid.v4(), map),
    );
    if (_notifications.isEmpty) {
      _notifications = <AppNotification>[
        AppNotification(
          id: _uuid.v4(),
          title: 'الفني في الطريق',
          body: 'محمد علي متجه لموقعك ومن المتوقع وصوله خلال 18 دقيقة.',
          createdAt: now - const Duration(minutes: 3).inMilliseconds,
          orderId: DemoData.orders.first.id,
        ),
        AppNotification(
          id: _uuid.v4(),
          title: 'تم قبول طلبك',
          body: 'أحمد جمال وافق على طلب السباكة في الموعد المحدد.',
          createdAt: now - const Duration(hours: 5).inMilliseconds,
          orderId: DemoData.orders[1].id,
          isRead: true,
        ),
      ];
    }
  }

  Map<String, List<ChatMessage>> _loadMessages() {
    final root = _objectMap(_box.read<Object?>('demo_messages'));
    if (root == null) return <String, List<ChatMessage>>{};
    return root.map((key, value) {
      return MapEntry(
        key.toString(),
        _parseMapList(
          value,
          (map) =>
              ChatMessage.fromMap(map['id']?.toString() ?? _uuid.v4(), map),
        ),
      );
    });
  }

  Map<String, List<TechnicianReview>> _loadReviews() {
    final root = _objectMap(_box.read<Object?>('demo_reviews'));
    if (root == null) return <String, List<TechnicianReview>>{};
    return root.map((key, value) {
      return MapEntry(
        key.toString(),
        _parseMapList(
          value,
          (map) => TechnicianReview.fromMap(
            map['id']?.toString() ?? _uuid.v4(),
            map,
          ),
        ),
      );
    });
  }

  Future<void> _persistOrders() {
    return _box.write(
      'demo_orders',
      _orders
          .map((item) => <String, Object?>{'id': item.id, ...item.toMap()})
          .toList(),
    );
  }

  Future<void> _persistMessages() {
    return _box.write(
      'demo_messages',
      _messages.map(
        (key, value) => MapEntry(
          key,
          value
              .map((item) => <String, Object?>{'id': item.id, ...item.toMap()})
              .toList(),
        ),
      ),
    );
  }

  Future<void> _persistReviews() {
    return _box.write(
      'demo_reviews',
      _reviews.map(
        (key, value) => MapEntry(
          key,
          value
              .map((item) => <String, Object?>{'id': item.id, ...item.toMap()})
              .toList(),
        ),
      ),
    );
  }

  Future<void> _persistNotifications() {
    return _box.write(
      'demo_notifications',
      _notifications
          .map(
            (item) => <String, Object?>{
              'id': item.id,
              'title': item.title,
              'body': item.body,
              'createdAt': item.createdAt,
              if (item.orderId != null) 'orderId': item.orderId,
              'isRead': item.isRead,
            },
          )
          .toList(),
    );
  }

  Future<void> _persistAddresses() {
    return _box.write(
      'demo_addresses',
      _addresses
          .map((item) => <String, Object?>{'id': item.id, ...item.toMap()})
          .toList(),
    );
  }

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  static Map<Object?, Object?>? _objectMap(Object? value) {
    if (value is Map<Object?, Object?>) return value;
    if (value is Map) return Map<Object?, Object?>.from(value);
    return null;
  }

  static List<T> _parseMapList<T>(
    Object? value,
    T Function(Map<Object?, Object?> map) parser,
  ) {
    if (value is! List) return <T>[];
    return value
        .map(_objectMap)
        .whereType<Map<Object?, Object?>>()
        .map(parser)
        .toList();
  }

  static String _timeLabel(int milliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute ${date.hour >= 12 ? 'م' : 'ص'}';
    }
    return '${date.day}/${date.month}';
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

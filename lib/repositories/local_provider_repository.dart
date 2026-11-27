import 'dart:async';

import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

import '../core/services/auth_service.dart';
import '../models/chat_message.dart';
import '../models/provider_conversation.dart';
import '../models/service_order.dart';
import '../models/technician.dart';
import 'provider_repository.dart';

class LocalProviderRepository implements ProviderRepository {
  LocalProviderRepository({required this.authService, GetStorage? box})
    : _box = box ?? GetStorage() {
    _load();
  }

  final AuthService authService;
  final GetStorage _box;
  final Uuid _uuid = const Uuid();
  final StreamController<void> _changes = StreamController<void>.broadcast();

  late Technician _profile;
  late List<ServiceOrder> _orders;
  late Map<String, List<ChatMessage>> _messages;

  @override
  bool get isDemo => true;

  @override
  String get currentUid => authService.currentProviderUid ?? 'demo-provider';

  @override
  Stream<Technician?> watchProfile() async* {
    yield _profile;
    yield* _changes.stream.map((_) => _profile);
  }

  @override
  Stream<List<ServiceOrder>> watchOrders() async* {
    yield _sortedOrders;
    yield* _changes.stream.map((_) => _sortedOrders);
  }

  @override
  Stream<ServiceOrder?> watchOrder(String orderId) async* {
    ServiceOrder? find() {
      for (final order in _orders) {
        if (order.id == orderId) return order;
      }
      return null;
    }

    yield find();
    yield* _changes.stream.map((_) => find());
  }

  @override
  Stream<List<ProviderConversation>> watchConversations() async* {
    yield _conversations;
    yield* _changes.stream.map((_) => _conversations);
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String orderId) async* {
    List<ChatMessage> current() =>
        List<ChatMessage>.from(_messages[orderId] ?? const <ChatMessage>[]);

    yield current();
    yield* _changes.stream.map((_) => current());
  }

  @override
  Future<void> setAvailability(bool available) async {
    _profile = _profile.copyWith(isAvailable: available);
    await _persistProfile();
    _notify();
  }

  @override
  Future<void> updateProfile({
    required String name,
    required String bio,
    required int experienceYears,
    required List<String> services,
  }) async {
    _profile = _profile.copyWith(
      name: name.trim(),
      bio: bio.trim(),
      experienceYears: experienceYears,
      services: services,
    );
    await _persistProfile();
    _notify();
  }

  @override
  Future<void> updateOrderStatus(
    String orderId,
    ServiceOrderStatus status,
  ) async {
    final index = _orders.indexWhere((item) => item.id == orderId);
    if (index == -1) throw StateError('الطلب غير موجود');
    _orders[index] = _orders[index].copyWith(
      status: status,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _persistOrders();
    _notify();
  }

  @override
  Future<void> sendMessage({
    required String orderId,
    required String customerId,
    required String text,
    String? imageBase64,
  }) async {
    _messages
        .putIfAbsent(orderId, () => <ChatMessage>[])
        .add(
          ChatMessage(
            id: _uuid.v4(),
            senderId: currentUid,
            text: text.trim(),
            sentAt: DateTime.now().millisecondsSinceEpoch,
            imageBase64: imageBase64,
            seen: true,
          ),
        );
    await _persistMessages();
    _notify();
  }

  @override
  Future<void> dispose() => _changes.close();

  List<ServiceOrder> get _sortedOrders {
    final values = List<ServiceOrder>.from(_orders);
    values.sort((first, second) => second.createdAt.compareTo(first.createdAt));
    return values;
  }

  List<ProviderConversation> get _conversations {
    final values = <ProviderConversation>[];
    for (final order in _orders) {
      final messages = _messages[order.id] ?? const <ChatMessage>[];
      if (messages.isEmpty) continue;
      final last = messages.last;
      values.add(
        ProviderConversation(
          orderId: order.id,
          customerId: order.customerId,
          lastMessage: last.text.isEmpty ? 'صورة' : last.text,
          lastMessageAt: last.sentAt,
          unreadCount: 0,
        ),
      );
    }
    values.sort(
      (first, second) => second.lastMessageAt.compareTo(first.lastMessageAt),
    );
    return values;
  }

  void _load() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final profileMap = _objectMap(_box.read<Object?>('demo_provider_profile'));
    _profile = profileMap == null
        ? Technician(
            id: 'demo-provider',
            name: 'محمد الصنايعي',
            categoryId: 'electricity',
            profession: 'فني كهرباء',
            imageUrl: '',
            rating: 4.8,
            reviewsCount: 27,
            completedJobs: 46,
            distanceKm: 0,
            visitFee: 0,
            isAvailable: true,
            isVerified: true,
            experienceYears: 7,
            bio: 'فني متخصص في صيانة وتركيب كهرباء المنازل.',
            services: const <String>[
              'كشف الأعطال',
              'تركيب الإنارة',
              'تأسيس الكهرباء',
            ],
            portfolioUrls: const <String>[],
            phone: '+201000000000',
            governorate: 'القاهرة',
            area: 'مدينة نصر',
            approvalStatus: 'approved',
            subscriptionActive: true,
            isActive: true,
            subscriptionStartedAt: now - const Duration(days: 8).inMilliseconds,
            subscriptionExpiresAt:
                now + const Duration(days: 22).inMilliseconds,
            lastPaymentAt: now - const Duration(days: 8).inMilliseconds,
          )
        : Technician.fromMap('demo-provider', profileMap);

    final storedOrders = _mapList(_box.read<Object?>('demo_provider_orders'));
    _orders = storedOrders.isEmpty
        ? <ServiceOrder>[
            ServiceOrder(
              id: 'HT-PRO-1001',
              technicianId: 'demo-provider',
              customerId: 'demo-customer-1',
              categoryId: 'electricity',
              problem: 'الكهرباء بتفصل من لوحة الشقة كل شوية.',
              address: 'مدينة نصر، شارع أحمد فخري، عمارة 12',
              date: 'اليوم',
              time: '4:00 م - 6:00 م',
              visitFee: 0,
              status: ServiceOrderStatus.sent,
              createdAt: now - const Duration(minutes: 18).inMilliseconds,
              updatedAt: now - const Duration(minutes: 18).inMilliseconds,
            ),
            ServiceOrder(
              id: 'HT-PRO-1002',
              technicianId: 'demo-provider',
              customerId: 'demo-customer-2',
              categoryId: 'electricity',
              problem: 'تركيب نجفة جديدة ومراجعة مفتاح الكهرباء.',
              address: 'مصر الجديدة، شارع الحجاز، الدور الرابع',
              date: 'غدًا',
              time: '11:00 ص - 1:00 م',
              visitFee: 0,
              status: ServiceOrderStatus.accepted,
              createdAt: now - const Duration(hours: 5).inMilliseconds,
              updatedAt: now - const Duration(hours: 2).inMilliseconds,
            ),
            ServiceOrder(
              id: 'HT-PRO-0994',
              technicianId: 'demo-provider',
              customerId: 'demo-customer-3',
              categoryId: 'electricity',
              problem: 'تغيير مفاتيح وبرايز تالفة في الصالة.',
              address: 'العباسية، شارع رمسيس',
              date: '12 أغسطس',
              time: '2:00 م',
              visitFee: 0,
              status: ServiceOrderStatus.completed,
              createdAt: now - const Duration(days: 5).inMilliseconds,
              updatedAt: now - const Duration(days: 4).inMilliseconds,
            ),
          ]
        : storedOrders
              .map(
                (map) => ServiceOrder.fromMap(map['id']?.toString() ?? '', map),
              )
              .toList();

    final messageRoot = _objectMap(
      _box.read<Object?>('demo_provider_messages'),
    );
    _messages =
        messageRoot?.map((key, value) {
          final values = _mapList(value)
              .map(
                (map) => ChatMessage.fromMap(
                  map['id']?.toString() ?? _uuid.v4(),
                  map,
                ),
              )
              .toList();
          return MapEntry(key.toString(), values);
        }) ??
        <String, List<ChatMessage>>{};
    if (_messages.isEmpty) {
      _messages = <String, List<ChatMessage>>{
        'HT-PRO-1001': <ChatMessage>[
          ChatMessage(
            id: _uuid.v4(),
            senderId: 'demo-customer-1',
            text: 'مساء الخير، العطل بدأ من امبارح.',
            sentAt: now - const Duration(minutes: 15).inMilliseconds,
          ),
        ],
        'HT-PRO-1002': <ChatMessage>[
          ChatMessage(
            id: _uuid.v4(),
            senderId: 'demo-provider',
            text: 'تمام يا فندم، الموعد اتأكد.',
            sentAt: now - const Duration(hours: 2).inMilliseconds,
            seen: true,
          ),
        ],
      };
    }
  }

  Future<void> _persistProfile() =>
      _box.write('demo_provider_profile', _profile.toMap());

  Future<void> _persistOrders() => _box.write(
    'demo_provider_orders',
    _orders
        .map((item) => <String, Object?>{'id': item.id, ...item.toMap()})
        .toList(),
  );

  Future<void> _persistMessages() => _box.write(
    'demo_provider_messages',
    _messages.map(
      (key, value) => MapEntry(
        key,
        value
            .map((item) => <String, Object?>{'id': item.id, ...item.toMap()})
            .toList(),
      ),
    ),
  );

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  static Map<Object?, Object?>? _objectMap(Object? value) {
    if (value is Map<Object?, Object?>) return value;
    if (value is Map) return Map<Object?, Object?>.from(value);
    return null;
  }

  static List<Map<Object?, Object?>> _mapList(Object? value) {
    if (value is! List) return <Map<Object?, Object?>>[];
    return value.map(_objectMap).whereType<Map<Object?, Object?>>().toList();
  }
}

import '../models/chat_message.dart';
import '../models/provider_conversation.dart';
import '../models/service_order.dart';
import '../models/technician.dart';

abstract class ProviderRepository {
  bool get isDemo;

  String get currentUid;

  Stream<Technician?> watchProfile();

  Stream<List<ServiceOrder>> watchOrders();

  Stream<ServiceOrder?> watchOrder(String orderId);

  Stream<List<ProviderConversation>> watchConversations();

  Stream<List<ChatMessage>> watchMessages(String orderId);

  Future<void> setAvailability(bool available);

  Future<void> updateProfile({
    required String name,
    required String bio,
    required int experienceYears,
    required List<String> services,
  });

  Future<void> updateOrderStatus(String orderId, ServiceOrderStatus status);

  Future<void> sendMessage({
    required String orderId,
    required String customerId,
    required String text,
    String? imageBase64,
  });

  Future<void> dispose();
}

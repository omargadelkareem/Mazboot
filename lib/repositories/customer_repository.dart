import '../models/address.dart';
import '../models/app_notification.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/customer_profile.dart';
import '../models/review.dart';
import '../models/service_category.dart';
import '../models/service_order.dart';
import '../models/technician.dart';

abstract class CustomerRepository {
  bool get isDemo;

  String get currentUid;

  Stream<List<ServiceCategory>> watchCategories();

  Stream<List<Technician>> watchTechnicians();

  Future<Technician?> getTechnician(String id);

  Stream<CustomerProfile?> watchProfile();

  Future<CustomerProfile?> loadProfile();

  Future<void> saveProfile(CustomerProfile profile);

  Future<void> saveFcmToken(String token);

  Stream<Set<String>> watchFavorites();

  Future<void> setFavorite(String technicianId, {required bool favorite});

  Stream<List<ServiceOrder>> watchOrders();

  Stream<ServiceOrder?> watchOrder(String orderId);

  Future<ServiceOrder> createOrder(ServiceOrder draft);

  Future<void> requestCancellation(String orderId, String reason);

  Stream<List<Conversation>> watchConversations();

  Stream<List<ChatMessage>> watchMessages(String orderId);

  Future<void> sendMessage({
    required String orderId,
    required String technicianId,
    required String text,
    String? imageBase64,
  });

  Stream<List<TechnicianReview>> watchReviews(String technicianId);

  Future<void> submitReview({
    required String orderId,
    required String technicianId,
    required String customerName,
    required int rating,
    required String comment,
  });

  Stream<List<AppNotification>> watchNotifications();

  Future<void> markNotificationRead(String notificationId);

  Future<void> saveAddress(CustomerAddress address);

  Future<void> deleteAddress(String addressId);

  Future<void> dispose();
}

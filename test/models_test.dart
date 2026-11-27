import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hetta_customer/models/customer_profile.dart';
import 'package:hetta_customer/models/provider_application.dart';
import 'package:hetta_customer/models/service_category.dart';
import 'package:hetta_customer/models/service_order.dart';
import 'package:hetta_customer/models/technician.dart';
import 'package:hetta_customer/core/services/auth_service.dart';

void main() {
  group('ServiceOrder', () {
    test('round-trips Firebase map fields', () {
      const order = ServiceOrder(
        id: 'order-1',
        technicianId: 'provider-1',
        categoryId: 'electricity',
        customerId: 'customer-1',
        problem: 'عطل في لوحة الكهرباء',
        address: 'مدينة نصر، القاهرة',
        date: 'اليوم',
        time: '10:00 ص',
        visitFee: 0,
        status: ServiceOrderStatus.accepted,
        createdAt: 1000,
        updatedAt: 1200,
      );

      final decoded = ServiceOrder.fromMap(order.id, order.toMap());

      expect(decoded, order);
      expect(decoded.status.label, 'تم القبول');
    });

    test('accepts backend snake_case status values', () {
      expect(
        ServiceOrder.statusFromName('on_the_way'),
        ServiceOrderStatus.onTheWay,
      );
      expect(
        ServiceOrder.statusFromName('in_progress'),
        ServiceOrderStatus.inProgress,
      );
    });
  });

  group('Firebase-facing models', () {
    test('round-trips an approved provider application', () {
      const application = ProviderApplication(
        id: 'provider-1',
        applicantUid: 'provider-1',
        name: 'أحمد محمد',
        phone: '+201000000000',
        categoryId: 'electricity',
        governorate: 'القاهرة',
        area: 'مدينة نصر',
        photoBase64: 'base64-photo',
        submittedAt: 1000,
        status: ProviderApplicationStatus.approved,
        subscriptionActive: true,
        published: true,
        subscriptionStartedAt: 1100,
        subscriptionExpiresAt: 2200,
        lastPaymentAt: 1100,
      );

      final decoded = ProviderApplication.fromMap(
        application.id,
        application.toMap(),
      );

      expect(decoded, application);
      expect(decoded.isFullyActive, isTrue);
      expect(decoded.monthlySubscriptionAmount, 50);
    });

    test('provider accounts use a phone-derived private auth email', () {
      expect(
        AuthService.providerEmailForPhone('01000000000'),
        '201000000000@provider.hetta.app',
      );
      expect(
        AuthService.isProviderEmail('201000000000@provider.hetta.app'),
        isTrue,
      );
      expect(AuthService.isProviderEmail('customer@gmail.com'), isFalse);
    });

    test('provider availability controls receiving new orders', () {
      const unavailable = Technician(
        id: 'provider-1',
        name: 'فني حِتّة',
        categoryId: 'electricity',
        profession: 'كهربائي',
        imageUrl: '',
        rating: 5,
        reviewsCount: 1,
        completedJobs: 1,
        distanceKm: 0,
        visitFee: 0,
        isAvailable: false,
        isVerified: true,
        experienceYears: 3,
        bio: 'فني كهرباء منازل محترف',
        services: <String>['صيانة الكهرباء'],
        portfolioUrls: <String>[],
      );

      expect(unavailable.canReceiveOrders, isFalse);
      expect(unavailable.copyWith(isAvailable: true).canReceiveOrders, isTrue);
    });

    test('parses a service category safely', () {
      final category = ServiceCategory.fromMap(
        'electricity',
        <Object?, Object?>{
          'name': 'كهرباء',
          'subtitle': 'أعطال وتركيبات',
          'icon': 'electricity',
          'color': '#EAF4FB',
          'roomIds': <Object?>['living', 'kitchen'],
          'isActive': true,
          'sortOrder': 1,
        },
      );

      expect(category.name, 'كهرباء');
      expect(category.icon, Icons.bolt_rounded);
      expect(category.roomIds, contains('kitchen'));
    });

    test('builds a readable customer location label', () {
      const profile = CustomerProfile(
        uid: 'customer-1',
        name: 'أحمد',
        phone: '+201000000000',
        governorate: 'القاهرة',
        area: 'مدينة نصر',
      );

      expect(profile.locationLabel, 'القاهرة، مدينة نصر');
    });
  });
}

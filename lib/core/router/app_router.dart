import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../../features/addresses/addresses_screen.dart';
import '../../features/auth/google_login_screen.dart';
import '../../features/categories/categories_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/location/location_screen.dart';
import '../../features/main/main_shell.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/provider/provider_join_screen.dart';
import '../../features/provider/provider_login_screen.dart';
import '../../features/provider/provider_review_screen.dart';
import '../../features/provider/provider_chat_cubit.dart';
import '../../features/provider/provider_chat_screen.dart';
import '../../features/provider/provider_edit_profile_screen.dart';
import '../../features/provider/provider_order_details_screen.dart';
import '../../features/provider/provider_orders_screen.dart';
import '../../features/provider/provider_shell.dart';
import '../../repositories/provider_repository.dart';
import '../../features/request/create_request_screen.dart';
import '../../features/role/role_selection_screen.dart';
import '../../features/request/tracking_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/support/legal_screen.dart';
import '../../features/support/support_screen.dart';
import '../../features/technicians/technician_profile_screen.dart';
import '../../features/technicians/technicians_screen.dart';

abstract final class AppRouter {
  static AuthService? _authService;

  static void configure(AuthService authService) {
    _authService = authService;
  }

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: (_, state) {
      final customerSignedIn = _authService?.hasCustomerSession ?? false;
      final providerSignedIn = _authService?.hasProviderSession ?? false;
      final path = state.matchedLocation;
      final fullyPublic =
          path == '/splash' ||
          path == '/onboarding' ||
          path == '/role-selection' ||
          path == '/login' ||
          path == '/provider-login' ||
          path == '/provider-join';
      if (fullyPublic) return null;

      final providerArea =
          path == '/provider-review' ||
          path == '/provider/main' ||
          path == '/provider/orders' ||
          path == '/provider/edit-profile' ||
          path.startsWith('/provider/order/') ||
          path.startsWith('/provider/chat/');
      if (providerArea && !providerSignedIn) return '/provider-login';

      final customerArea =
          path == '/location' ||
          path == '/main' ||
          path == '/categories' ||
          path == '/favorites' ||
          path == '/addresses' ||
          path == '/edit-profile' ||
          path == '/notifications' ||
          path.startsWith('/technicians/') ||
          path.startsWith('/technician/') ||
          path.startsWith('/request/') ||
          path.startsWith('/tracking/') ||
          path.startsWith('/chat/');
      if (customerArea && !customerSignedIn) return '/role-selection';

      if ((path == '/support' || path == '/legal') &&
          !customerSignedIn &&
          !providerSignedIn) {
        return '/role-selection';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (_, __) => const RoleSelectionScreen(),
      ),
      GoRoute(path: '/login', builder: (_, __) => const GoogleLoginScreen()),
      GoRoute(
        path: '/provider-login',
        builder: (_, __) => const ProviderLoginScreen(),
      ),
      GoRoute(
        path: '/provider-join',
        builder: (_, __) => const ProviderJoinScreen(),
      ),
      GoRoute(
        path: '/provider-review',
        builder: (_, __) => const ProviderReviewScreen(),
      ),
      GoRoute(
        path: '/provider/main',
        builder: (_, __) => const ProviderShell(),
      ),
      GoRoute(
        path: '/provider/orders',
        builder: (_, __) => const ProviderOrdersScreen(standalone: true),
      ),
      GoRoute(
        path: '/provider/order/:orderId',
        builder: (_, state) => ProviderOrderDetailsScreen(
          orderId: state.pathParameters['orderId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/provider/edit-profile',
        builder: (_, __) => const ProviderEditProfileScreen(),
      ),
      GoRoute(
        path: '/provider/chat/:orderId/:customerId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          final customerId = state.pathParameters['customerId'] ?? '';
          return BlocProvider<ProviderChatCubit>(
            create: (_) => ProviderChatCubit(
              repository: context.read<ProviderRepository>(),
              orderId: orderId,
              customerId: customerId,
            ),
            child: ProviderChatScreen(orderId: orderId, customerId: customerId),
          );
        },
      ),
      GoRoute(path: '/location', builder: (_, __) => const LocationScreen()),
      GoRoute(path: '/main', builder: (_, __) => const MainShell()),
      GoRoute(
        path: '/categories',
        builder: (_, __) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/technicians/:categoryId',
        builder: (_, state) => TechniciansScreen(
          categoryId: state.pathParameters['categoryId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/technician/:technicianId',
        builder: (_, state) => TechnicianProfileScreen(
          technicianId: state.pathParameters['technicianId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/request/:technicianId',
        builder: (_, state) => CreateRequestScreen(
          technicianId: state.pathParameters['technicianId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/tracking/:orderId',
        builder: (_, state) =>
            TrackingScreen(orderId: state.pathParameters['orderId'] ?? ''),
      ),
      GoRoute(
        path: '/chat/:orderId/:technicianId',
        builder: (_, state) => ChatScreen(
          orderId: state.pathParameters['orderId'] ?? '',
          technicianId: state.pathParameters['technicianId'] ?? '',
        ),
      ),
      GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
      GoRoute(
        path: '/addresses',
        builder: (_, state) => AddressesScreen(
          selectionMode: state.uri.queryParameters['select'] == '1',
        ),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(path: '/support', builder: (_, __) => const SupportScreen()),
      GoRoute(path: '/legal', builder: (_, __) => const LegalScreen()),
    ],
  );
}

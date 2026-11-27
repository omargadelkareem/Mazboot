import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/constants/app_constants.dart';
import '../core/router/app_router.dart';
import '../core/services/auth_service.dart';
import '../core/services/image_service.dart';
import '../core/services/location_service.dart';
import '../core/services/notification_service.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/auth_cubit.dart';
import '../features/chat/conversations_cubit.dart';
import '../features/favorites/favorites_cubit.dart';
import '../features/home/home_cubit.dart';
import '../features/main/nav_cubit.dart';
import '../features/notifications/notifications_cubit.dart';
import '../features/orders/orders_cubit.dart';
import '../features/profile/profile_cubit.dart';
import '../features/provider/provider_application_cubit.dart';
import '../features/provider/provider_auth_cubit.dart';
import '../features/provider/provider_workspace_cubit.dart';
import '../repositories/customer_repository.dart';
import '../repositories/provider_application_repository.dart';
import '../repositories/provider_repository.dart';

class MazbootApp extends StatelessWidget {
  const MazbootApp({
    super.key,
    required this.repository,
    required this.authService,
    required this.imageService,
    required this.locationService,
    required this.notificationService,
    required this.providerApplicationRepository,
    required this.providerRepository,
    this.firebaseError,
  });

  final CustomerRepository repository;
  final AuthService authService;
  final ImageService imageService;
  final LocationService locationService;
  final NotificationService notificationService;
  final ProviderApplicationRepository providerApplicationRepository;
  final ProviderRepository providerRepository;
  final Object? firebaseError;

  @override
  Widget build(BuildContext context) {
    AppRouter.configure(authService);
    return MultiRepositoryProvider(
      providers: <RepositoryProvider<dynamic>>[
        RepositoryProvider<CustomerRepository>.value(value: repository),
        RepositoryProvider<AuthService>.value(value: authService),
        RepositoryProvider<ImageService>.value(value: imageService),
        RepositoryProvider<LocationService>.value(value: locationService),
        RepositoryProvider<NotificationService>.value(
          value: notificationService,
        ),
        RepositoryProvider<ProviderApplicationRepository>.value(
          value: providerApplicationRepository,
        ),
        RepositoryProvider<ProviderRepository>.value(value: providerRepository),
      ],
      child: MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<NavCubit>(create: (_) => NavCubit()),
          BlocProvider<HomeCubit>(create: (_) => HomeCubit(repository)),
          BlocProvider<AuthCubit>(
            create: (_) =>
                AuthCubit(authService: authService, repository: repository),
          ),
          BlocProvider<OrdersCubit>(create: (_) => OrdersCubit(repository)),
          BlocProvider<ProfileCubit>(create: (_) => ProfileCubit(repository)),
          BlocProvider<FavoritesCubit>(
            create: (_) => FavoritesCubit(repository),
          ),
          BlocProvider<ConversationsCubit>(
            create: (_) => ConversationsCubit(repository),
          ),
          BlocProvider<NotificationsCubit>(
            create: (_) => NotificationsCubit(repository),
          ),
          BlocProvider<ProviderApplicationCubit>(
            create: (_) => ProviderApplicationCubit(
              repository: providerApplicationRepository,
              authService: authService,
            ),
          ),
          BlocProvider<ProviderAuthCubit>(
            create: (_) => ProviderAuthCubit(
              authService: authService,
              repository: providerApplicationRepository,
            ),
          ),
          BlocProvider<ProviderWorkspaceCubit>(
            create: (_) => ProviderWorkspaceCubit(providerRepository),
          ),
        ],
        child: _SessionCoordinator(
          repository: repository,
          notificationService: notificationService,
          firebaseError: firebaseError,
        ),
      ),
    );
  }
}

class _SessionCoordinator extends StatefulWidget {
  const _SessionCoordinator({
    required this.repository,
    required this.notificationService,
    this.firebaseError,
  });

  final CustomerRepository repository;
  final NotificationService notificationService;
  final Object? firebaseError;

  @override
  State<_SessionCoordinator> createState() => _SessionCoordinatorState();
}

class _SessionCoordinatorState extends State<_SessionCoordinator> {
  StreamSubscription<String>? _notificationSubscription;
  String? _pendingOrderId;

  @override
  void initState() {
    super.initState();
    _pendingOrderId = widget.notificationService.takePendingOrderId();
    _notificationSubscription = widget.notificationService.orderClicks.listen((
      orderId,
    ) {
      _pendingOrderId = orderId;
      _openPendingOrder();
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          context.read<NavCubit>().select(0);
          context.read<OrdersCubit>().start();
          context.read<ProfileCubit>().start();
          context.read<FavoritesCubit>().start();
          context.read<ConversationsCubit>().start();
          context.read<NotificationsCubit>().start();
          unawaited(_saveNotificationToken());
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _openPendingOrder();
          });
        } else if (state.status == AuthStatus.unauthenticated) {
          unawaited(context.read<OrdersCubit>().stop());
          unawaited(context.read<ProfileCubit>().stop());
          unawaited(context.read<FavoritesCubit>().stop());
          unawaited(context.read<ConversationsCubit>().stop());
          unawaited(context.read<NotificationsCubit>().stop());
        }
      },
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        locale: const Locale('ar'),
        supportedLocales: const <Locale>[Locale('ar'), Locale('en')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
        builder: (context, child) {
          return Stack(
            children: <Widget>[
              child ?? const SizedBox.shrink(),
              if (widget.repository.isDemo)
                PositionedDirectional(
                  start: 12,
                  bottom: 94,
                  child: _DemoBadge(
                    firebaseUnavailable: widget.firebaseError != null,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveNotificationToken() async {
    try {
      await widget.notificationService.requestPermissions();
      final token = await widget.notificationService.token();
      if (token != null && token.isNotEmpty)
        await widget.repository.saveFcmToken(token);
    } catch (_) {
      // Token registration is best-effort and never blocks customer flows.
    }
  }

  void _openPendingOrder() {
    if (!mounted || _pendingOrderId == null) return;
    if (context.read<AuthCubit>().state.status != AuthStatus.authenticated) {
      return;
    }
    final orderId = _pendingOrderId!;
    _pendingOrderId = null;
    AppRouter.router.push('/tracking/$orderId');
  }
}

class _DemoBadge extends StatelessWidget {
  const _DemoBadge({required this.firebaseUnavailable});

  final bool firebaseUnavailable;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.72),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Text(
            firebaseUnavailable ? 'معاينة • Firebase غير متصل' : 'وضع المعاينة',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

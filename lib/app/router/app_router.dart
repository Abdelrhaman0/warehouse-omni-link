import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/orders/presentation/screens/home_orders_screen.dart';
import '../../features/orders/presentation/screens/order_details_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/safes/presentation/screens/safes_list_screen.dart';
import '../../features/safes/presentation/screens/safe_details_screen.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String orderDetails = '/order-details';
  static const String safes = '/safes';
  static const String safeDetails = '/safe-details';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );
      case login:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );
      case home:
        final initialIndex = settings.arguments is int
            ? settings.arguments as int
            : 1;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => HomeOrdersScreen(initialNavIndex: initialIndex),
        );
      case dashboard:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) {
            AuthCubit? authCubit;
            try {
              authCubit = context.read<AuthCubit>();
            } catch (_) {
              authCubit = null;
            }
            final authState = authCubit?.state;
            if (authState is Authenticated) {
              if (authState.user.canAccessDashboard) {
                return const HomeOrdersScreen(initialNavIndex: 0);
              } else {
                // Deny store keeper access to dashboard and redirect to safe operational orders home
                return const HomeOrdersScreen(initialNavIndex: 1);
              }
            }
            // Unauthenticated: redirect to login
            return const LoginScreen();
          },
        );
      case profile:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ProfileScreen(),
        );
      case orderDetails:
        final orderId = settings.arguments as int;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => OrderDetailsScreen(orderId: orderId),
        );
      case safes:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) {
            AuthCubit? authCubit;
            try {
              authCubit = context.read<AuthCubit>();
            } catch (_) {
              authCubit = null;
            }
            final authState = authCubit?.state;
            if (authState is Authenticated && authState.user.isSuperAdmin) {
              return const SafesListScreen();
            }
            return const HomeOrdersScreen(initialNavIndex: 1);
          },
        );
      case safeDetails:
        final safeId = settings.arguments as int;
        return MaterialPageRoute(
          settings: settings,
          builder: (context) {
            AuthCubit? authCubit;
            try {
              authCubit = context.read<AuthCubit>();
            } catch (_) {
              authCubit = null;
            }
            final authState = authCubit?.state;
            if (authState is Authenticated && authState.user.isSuperAdmin) {
              return SafeDetailsScreen(safeId: safeId);
            }
            return const HomeOrdersScreen(initialNavIndex: 1);
          },
        );
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );
    }
  }
}

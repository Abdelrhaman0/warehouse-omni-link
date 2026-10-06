import 'package:flutter/material.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/orders/presentation/screens/home_orders_screen.dart';
import '../../features/orders/presentation/screens/order_details_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String orderDetails = '/order-details';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeOrdersScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case orderDetails:
        final orderId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(orderId: orderId),
        );
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}

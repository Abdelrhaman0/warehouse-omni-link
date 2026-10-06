import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../core/localization/app_strings.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/auth/presentation/cubit/auth_state.dart';
import '../features/auth/presentation/widgets/session_expired_dialog.dart';
import '../features/orders/data/orders_repository.dart';
import '../features/orders/presentation/cubits/orders_cubit.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class OmniLinkWarehouseApp extends StatelessWidget {
  final AuthRepository authRepository;
  final OrdersRepository ordersRepository;

  const OmniLinkWarehouseApp({
    super.key,
    required this.authRepository,
    required this.ordersRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<OrdersRepository>.value(value: ordersRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(
            create: (context) => AuthCubit(authRepository: authRepository),
          ),
          BlocProvider<OrdersCubit>(
            create: (context) => OrdersCubit(ordersRepository: ordersRepository),
          ),
        ],
        child: MaterialApp(
          navigatorKey: AppRouter.navigatorKey,
          title: AppStrings.appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          // Arabic localization with native RTL layout
          locale: const Locale('ar'),
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: AppRouter.splash,
          onGenerateRoute: AppRouter.onGenerateRoute,
          builder: (context, child) {
            return BlocListener<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state is SessionExpired) {
                  final navContext = AppRouter.navigatorKey.currentContext ?? context;
                  SessionExpiredDialog.show(
                    navContext,
                    onLoginPressed: () {
                      AppRouter.navigatorKey.currentState?.pushNamedAndRemoveUntil(
                        AppRouter.login,
                        (route) => false,
                      );
                    },
                  );
                }
              },
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}

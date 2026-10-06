import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warehouse_store_keeper/app/router/app_router.dart';
import 'package:warehouse_store_keeper/core/constants/api_endpoints.dart';
import 'package:warehouse_store_keeper/core/localization/app_strings.dart';
import 'package:warehouse_store_keeper/core/network/auth_interceptor.dart';
import 'package:warehouse_store_keeper/core/network/dio_client.dart';
import 'package:warehouse_store_keeper/core/storage/secure_storage_service.dart';
import 'package:warehouse_store_keeper/features/auth/data/auth_remote_data_source.dart';
import 'package:warehouse_store_keeper/features/auth/data/auth_repository.dart';
import 'package:warehouse_store_keeper/features/auth/models/admin_user.dart';
import 'package:warehouse_store_keeper/features/auth/models/login_response.dart';
import 'package:warehouse_store_keeper/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:warehouse_store_keeper/features/auth/presentation/cubit/auth_state.dart';
import 'package:warehouse_store_keeper/features/auth/presentation/widgets/session_expired_dialog.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockAuthRepository extends Mock implements AuthRepository {}
class MockErrorInterceptorHandler extends Mock implements ErrorInterceptorHandler {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFlutterSecureStorage mockStorage;
  late SecureStorageService storageService;
  late AuthInterceptor interceptor;

  const sampleAdmin = AdminUser(
    id: '1',
    name: 'أمين المستودع',
    email: 'keeper@omni-link.net',
  );

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    storageService = SecureStorageService(storage: mockStorage);
  });

  group('Requirement 14 Test Suite: Global Session Expiration & Re-Login', () {
    // -------------------------------------------------------------------------
    // Test 1: Normal authenticated request
    // -------------------------------------------------------------------------
    test('Test 1 — Normal authenticated request: valid token attaches Bearer header and does not trigger session expired', () async {
      when(() => mockStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => 'valid_jwt_token_123');

      var unauthorizedCalled = false;
      interceptor = AuthInterceptor(
        storageService: storageService,
        onUnauthorized: () => unauthorizedCalled = true,
      );

      final options = RequestOptions(
        path: ApiEndpoints.orders('ar'),
        headers: {},
      );

      final handler = RequestInterceptorHandler();
      await interceptor.onRequest(options, handler);

      // Verify Bearer token attached
      expect(options.headers['Authorization'], 'Bearer valid_jwt_token_123');
      expect(interceptor.isHandlingSessionExpiration, isFalse);
      expect(unauthorizedCalled, isFalse);
    });

    // -------------------------------------------------------------------------
    // Test 2: Token expired (Authenticated request -> 401)
    // -------------------------------------------------------------------------
    test('Test 2 — Token expired: 401 on authenticated request clears auth data, triggers callback, and sets guard', () async {
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      var unauthorizedCalledCount = 0;
      interceptor = AuthInterceptor(
        storageService: storageService,
        onUnauthorized: () => unauthorizedCalledCount++,
      );

      final requestOptions = RequestOptions(
        path: ApiEndpoints.orders('ar'),
        headers: {'Authorization': 'Bearer expired_token'},
      );

      final dioError = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
          data: {'status': false, 'message': 'Unauthenticated.'},
        ),
      );

      final mockHandler = MockErrorInterceptorHandler();
      await interceptor.onError(dioError, mockHandler);
      verify(() => mockHandler.next(dioError)).called(1);

      // 1. Session expired detected
      expect(unauthorizedCalledCount, equals(1));
      expect(interceptor.isHandlingSessionExpiration, isTrue);

      // 2. Auth data cleared
      verify(() => mockStorage.delete(key: 'auth_token')).called(1);
      verify(() => mockStorage.delete(key: 'user_data')).called(1);
    });

    // -------------------------------------------------------------------------
    // Test 3: Multiple simultaneous 401 responses
    // -------------------------------------------------------------------------
    test('Test 3 — Multiple simultaneous 401 responses: handles only once, no duplicate calls or dialog loops', () async {
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      var unauthorizedCalledCount = 0;
      interceptor = AuthInterceptor(
        storageService: storageService,
        onUnauthorized: () => unauthorizedCalledCount++,
      );

      final requestOptionsA = RequestOptions(
        path: ApiEndpoints.orders('ar'),
        headers: {'Authorization': 'Bearer expired_token'},
      );
      final requestOptionsB = RequestOptions(
        path: ApiEndpoints.me('ar'),
        headers: {'Authorization': 'Bearer expired_token'},
      );
      final requestOptionsC = RequestOptions(
        path: ApiEndpoints.orderDetails('ar', 42),
        headers: {'Authorization': 'Bearer expired_token'},
      );

      final errA = DioException(
        requestOptions: requestOptionsA,
        response: Response(requestOptions: requestOptionsA, statusCode: 401),
      );
      final errB = DioException(
        requestOptions: requestOptionsB,
        response: Response(requestOptions: requestOptionsB, statusCode: 401),
      );
      final errC = DioException(
        requestOptions: requestOptionsC,
        response: Response(requestOptions: requestOptionsC, statusCode: 401),
      );

      final handlerA = MockErrorInterceptorHandler();
      final handlerB = MockErrorInterceptorHandler();
      final handlerC = MockErrorInterceptorHandler();

      // Fire 3 simultaneous 401 errors
      await Future.wait([
        interceptor.onError(errA, handlerA),
        interceptor.onError(errB, handlerB),
        interceptor.onError(errC, handlerC),
      ]);

      // Exactly ONE session expiration flow triggered
      expect(unauthorizedCalledCount, equals(1));
      expect(interceptor.isHandlingSessionExpiration, isTrue);

      // Exactly ONE clearing of auth storage
      verify(() => mockStorage.delete(key: 'auth_token')).called(1);
      verify(() => mockStorage.delete(key: 'user_data')).called(1);
    });

    // -------------------------------------------------------------------------
    // Test 4: Login after session expiration
    // -------------------------------------------------------------------------
    test('Test 4 — Login after expiration: restores authenticated state, resets guard, allows new requests', () async {
      final mockRemoteDataSource = MockAuthRemoteDataSource();

      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      final dioClient = DioClient(storageService: storageService);
      final authRepo = AuthRepositoryImpl(
        remoteDataSource: mockRemoteDataSource,
        storageService: storageService,
        dioClient: dioClient,
      );

      final authCubit = AuthCubit(authRepository: authRepo);

      // 1. Simulate 401 session expiration
      final requestOptions = RequestOptions(
        path: ApiEndpoints.orders('ar'),
        headers: {'Authorization': 'Bearer old_token'},
      );
      final mockHandler = MockErrorInterceptorHandler();
      await dioClient.authInterceptor.onError(
        DioException(
          requestOptions: requestOptions,
          response: Response(requestOptions: requestOptions, statusCode: 401),
        ),
        mockHandler,
      );

      // Verify Cubit entered SessionExpired
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(authCubit.state, isA<SessionExpired>());
      expect(dioClient.authInterceptor.isHandlingSessionExpiration, isTrue);

      // 2. User logs in again with fresh credentials
      when(() => mockRemoteDataSource.login(
            login: 'keeper@omni-link.net',
            password: 'password123',
          )).thenAnswer((_) async => const LoginResponse(
            status: true,
            message: 'تم تسجيل الدخول بنجاح',
            token: 'new_fresh_token_456',
            admin: sampleAdmin,
          ));

      await authCubit.login(login: 'keeper@omni-link.net', password: 'password123');

      // 3. Authenticated state restored & guard reset
      expect(authCubit.state, isA<Authenticated>());
      expect((authCubit.state as Authenticated).user.name, 'أمين المستودع');
      expect(dioClient.authInterceptor.isHandlingSessionExpiration, isFalse);

      // 4. Verify new token saved
      verify(() => mockStorage.write(key: 'auth_token', value: 'new_fresh_token_456')).called(1);

      await authCubit.close();
    });

    // -------------------------------------------------------------------------
    // Test 5: Public endpoint (401 on /login does not trigger session expiration)
    // -------------------------------------------------------------------------
    test('Test 5 — Public endpoint: 401 on /admin/auth/login does NOT trigger session expiration or clear auth data', () async {
      var unauthorizedCalled = false;
      interceptor = AuthInterceptor(
        storageService: storageService,
        onUnauthorized: () => unauthorizedCalled = true,
      );

      final requestOptions = RequestOptions(
        path: ApiEndpoints.login('ar'),
        headers: {},
      );

      final dioError = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
          data: {'status': false, 'message': 'بيانات الاعتماد غير صالحة'},
        ),
      );

      final mockHandler = MockErrorInterceptorHandler();
      await interceptor.onError(dioError, mockHandler);
      verify(() => mockHandler.next(dioError)).called(1);

      // Should NOT trigger session expiration
      expect(unauthorizedCalled, isFalse);
      expect(interceptor.isHandlingSessionExpiration, isFalse);
      verifyNever(() => mockStorage.delete(key: any(named: 'key')));
    });

    // -------------------------------------------------------------------------
    // Test 6: Back button & navigation stack protection
    // -------------------------------------------------------------------------
    testWidgets('Test 6 — Back button protection: user cannot dismiss dialog and navigation clears back stack', (WidgetTester tester) async {
      var loginNavigated = false;
      final mockAuthRepo = MockAuthRepository();
      when(() => mockAuthRepo.sessionExpiredStream).thenAnswer((_) => const Stream.empty());
      final authCubit = AuthCubit(authRepository: mockAuthRepo);

      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: MaterialApp(
            navigatorKey: AppRouter.navigatorKey,
            home: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      SessionExpiredDialog.show(
                        context,
                        onLoginPressed: () {
                          loginNavigated = true;
                          AppRouter.navigatorKey.currentState?.pushNamedAndRemoveUntil(
                            AppRouter.login,
                            (route) => false,
                          );
                        },
                      );
                    },
                    child: const Text('Simulate 401'),
                  ),
                ),
              ),
            ),
            onGenerateRoute: AppRouter.onGenerateRoute,
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Simulate 401'));
      await tester.pumpAndSettle();

      // Verify Session Expired UI is displayed in Arabic
      expect(find.text(AppStrings.sessionExpiredTitle), findsOneWidget);
      expect(find.text(AppStrings.sessionExpiredMessage), findsOneWidget);
      expect(find.text(AppStrings.sessionExpiredButton), findsOneWidget);

      // Verify duplicate dialog call does not open a second dialog
      final BuildContext dialogContext = tester.element(find.byType(SessionExpiredDialog));
      SessionExpiredDialog.show(dialogContext, onLoginPressed: () {});
      await tester.pumpAndSettle();
      expect(find.byType(SessionExpiredDialog), findsOneWidget);

      // Attempt Back button press (should be blocked by PopScope(canPop: false))
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      // Dialog is still visible and not popped
      expect(find.byType(SessionExpiredDialog), findsOneWidget);
      expect(loginNavigated, isFalse);

      // Tap "تسجيل الدخول" button
      await tester.tap(find.text(AppStrings.sessionExpiredButton));
      await tester.pumpAndSettle();

      // Dialog is closed and user is on LoginScreen
      expect(loginNavigated, isTrue);
      expect(find.text(AppStrings.loginTitle), findsOneWidget);

      // Verify user cannot press Back to return to previous screen
      final bool couldPop = AppRouter.navigatorKey.currentState?.canPop() ?? true;
      expect(couldPop, isFalse);

      await authCubit.close();
    });
  });
}

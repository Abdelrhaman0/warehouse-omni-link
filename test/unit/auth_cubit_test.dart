import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warehouse_store_keeper/core/error/failures.dart';
import 'package:warehouse_store_keeper/features/auth/data/auth_repository.dart';
import 'package:warehouse_store_keeper/features/auth/models/admin_user.dart';
import 'package:warehouse_store_keeper/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:warehouse_store_keeper/features/auth/presentation/cubit/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepo;
  late AuthCubit authCubit;

  const testAdmin = AdminUser(
    id: '1',
    name: 'Warehouse Keeper',
    email: 'keeper@omni-link.net',
    phone: '01000000000',
    role: 'Warehouse Store Keeper',
    status: 'active',
  );

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    when(() => mockAuthRepo.sessionExpiredStream).thenAnswer((_) => const Stream.empty());
    authCubit = AuthCubit(authRepository: mockAuthRepo);
  });

  group('AuthCubit - Session, Login, and Logout', () {
    test('checkAuthStatus emits Authenticated when active session exists', () async {
      when(() => mockAuthRepo.checkAuthStatus()).thenAnswer((_) async => testAdmin);

      await authCubit.checkAuthStatus();

      expect(authCubit.state, isA<Authenticated>());
      expect((authCubit.state as Authenticated).user, testAdmin);
    });

    test('checkAuthStatus emits Unauthenticated when no stored session exists', () async {
      when(() => mockAuthRepo.checkAuthStatus()).thenAnswer((_) async => null);

      await authCubit.checkAuthStatus();

      expect(authCubit.state, isA<Unauthenticated>());
    });

    test('login emits Authenticated upon successful credentials', () async {
      when(() => mockAuthRepo.login('keeper@omni-link.net', 'password123'))
          .thenAnswer((_) async => testAdmin);

      await authCubit.login(login: 'keeper@omni-link.net', password: 'password123');

      expect(authCubit.state, isA<Authenticated>());
      expect((authCubit.state as Authenticated).user.name, 'Warehouse Keeper');
    });

    test('login emits AuthFailure on invalid credentials or failure', () async {
      when(() => mockAuthRepo.login('keeper@omni-link.net', 'wrongpassword'))
          .thenThrow(const ServerFailure('بيانات الدخول غير صحيحة'));

      await authCubit.login(login: 'keeper@omni-link.net', password: 'wrongpassword');

      expect(authCubit.state, isA<AuthFailure>());
      expect((authCubit.state as AuthFailure).message, 'بيانات الدخول غير صحيحة');
    });

    test('logout clears session and emits Unauthenticated', () async {
      when(() => mockAuthRepo.logout()).thenAnswer((_) async {});

      await authCubit.logout();

      expect(authCubit.state, isA<Unauthenticated>());
      verify(() => mockAuthRepo.logout()).called(1);
    });

    test('handleUnauthorized emits SessionExpired and guards against duplicate emissions', () {
      authCubit.handleUnauthorized();

      expect(authCubit.state, isA<SessionExpired>());

      // Calling again should not re-emit
      authCubit.handleUnauthorized();
      expect(authCubit.state, isA<SessionExpired>());
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_store_keeper/core/error/failures.dart';
import 'package:warehouse_store_keeper/features/safes/data/safes_repository.dart';
import 'package:warehouse_store_keeper/features/safes/models/safe.dart';
import 'package:warehouse_store_keeper/features/safes/models/safe_responses.dart';
import 'package:warehouse_store_keeper/features/safes/models/safe_summary.dart';
import 'package:warehouse_store_keeper/features/safes/models/safe_transaction.dart';
import 'package:warehouse_store_keeper/features/safes/presentation/cubits/safe_details_cubit.dart';
import 'package:warehouse_store_keeper/features/safes/presentation/cubits/safe_operation_cubit.dart';
import 'package:warehouse_store_keeper/features/safes/presentation/cubits/safes_list_cubit.dart';
import 'package:warehouse_store_keeper/features/safes/presentation/cubits/safes_state.dart';

class MockSafesRepository implements SafesRepository {
  SafeListResponse? listResponse;
  SafeDetailsResponse? detailsResponse;
  SafeDetailsResponse? detailsPage2Response;
  SafeOperationResponse? createResponse;
  SafeOperationResponse? depositResponse;
  SafeOperationResponse? withdrawResponse;
  TransferResponse? transferResponse;

  Failure? throwFailure;
  Exception? throwException;

  int getSafesCallCount = 0;
  int getSafeDetailsCallCount = 0;
  int createSafeCallCount = 0;
  int depositCallCount = 0;
  int withdrawCallCount = 0;
  int transferCallCount = 0;

  @override
  Future<SafeListResponse> getSafes() async {
    getSafesCallCount++;
    if (throwFailure != null) throw throwFailure!;
    if (throwException != null) throw throwException!;
    return listResponse ??
        const SafeListResponse(status: true, message: 'OK', safes: []);
  }

  @override
  Future<SafeDetailsResponse> getSafeDetails(int safeId, {int page = 1}) async {
    getSafeDetailsCallCount++;
    if (throwFailure != null) throw throwFailure!;
    if (throwException != null) throw throwException!;
    if (page == 2 && detailsPage2Response != null) {
      return detailsPage2Response!;
    }
    return detailsResponse ??
        const SafeDetailsResponse(status: true, message: 'OK', transactions: []);
  }

  @override
  Future<SafeOperationResponse> createSafe(Map<String, dynamic> body) async {
    createSafeCallCount++;
    if (throwFailure != null) throw throwFailure!;
    if (throwException != null) throw throwException!;
    return createResponse ??
        const SafeOperationResponse(status: true, message: 'Created');
  }

  @override
  Future<SafeOperationResponse> deposit(int safeId, Map<String, dynamic> body) async {
    depositCallCount++;
    if (throwFailure != null) throw throwFailure!;
    if (throwException != null) throw throwException!;
    return depositResponse ??
        const SafeOperationResponse(status: true, message: 'Deposited');
  }

  @override
  Future<SafeOperationResponse> withdraw(int safeId, Map<String, dynamic> body) async {
    withdrawCallCount++;
    if (throwFailure != null) throw throwFailure!;
    if (throwException != null) throw throwException!;
    return withdrawResponse ??
        const SafeOperationResponse(status: true, message: 'Withdrawn');
  }

  @override
  Future<TransferResponse> transfer(Map<String, dynamic> body) async {
    transferCallCount++;
    if (throwFailure != null) throw throwFailure!;
    if (throwException != null) throw throwException!;
    return transferResponse ??
        const TransferResponse(status: true, message: 'Transferred');
  }
}

void main() {
  late MockSafesRepository mockRepository;

  setUp(() {
    mockRepository = MockSafesRepository();
  });

  const testSafe = Safe(
    id: 1,
    name: 'الخزنة الرئيسية',
    type: 'cash',
    balance: 10000.0,
    currency: 'EGP',
    isActive: true,
    canBeDeleted: false,
  );

  group('SafesListCubit Tests', () {
    test('initial state is SafesListInitial', () {
      final cubit = SafesListCubit(safesRepository: mockRepository);
      expect(cubit.state, const SafesListInitial());
      cubit.close();
    });

    test('loadSafes emits [SafesListLoading, SafesListLoaded] on success', () async {
      mockRepository.listResponse = const SafeListResponse(
        status: true,
        message: 'OK',
        safes: [testSafe],
        summary: SafeSummary(totalSafes: 1, activeSafes: 1, totalBalance: 10000.0),
      );

      final cubit = SafesListCubit(safesRepository: mockRepository);
      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const SafesListLoading(),
          const SafesListLoaded(
            safes: [testSafe],
            summary: SafeSummary(totalSafes: 1, activeSafes: 1, totalBalance: 10000.0),
          ),
        ]),
      );

      await cubit.loadSafes();
      await expectation;
      cubit.close();
    });

    test('loadSafes emits [SafesListLoading, SafesListError] on failure', () async {
      mockRepository.throwFailure = const ServerFailure('خطأ في الاتصال بالخادم');

      final cubit = SafesListCubit(safesRepository: mockRepository);
      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const SafesListLoading(),
          const SafesListError('خطأ في الاتصال بالخادم'),
        ]),
      );

      await cubit.loadSafes();
      await expectation;
      cubit.close();
    });
  });

  group('SafeDetailsCubit Tests', () {
    test('loadSafeDetails emits [SafeDetailsLoading, SafeDetailsLoaded]', () async {
      mockRepository.detailsResponse = const SafeDetailsResponse(
        status: true,
        message: 'OK',
        safe: testSafe,
        transactions: [],
        pagination: TransactionPagination(currentPage: 1, lastPage: 2, perPage: 15, total: 20),
      );

      final cubit = SafeDetailsCubit(safesRepository: mockRepository);
      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const SafeDetailsLoading(),
          const SafeDetailsLoaded(
            safe: testSafe,
            transactions: [],
            pagination: TransactionPagination(currentPage: 1, lastPage: 2, perPage: 15, total: 20),
          ),
        ]),
      );

      await cubit.loadSafeDetails(1);
      await expectation;
      cubit.close();
    });

    test('loadMoreTransactions appends next page transactions successfully', () async {
      const tx1 = SafeTransaction(
        id: 1,
        safeId: 1,
        type: 'deposit',
        isIncome: true,
        amount: 1000.0,
        fee: 0.0,
        netAmount: 1000.0,
        balanceBefore: 9000.0,
        balanceAfter: 10000.0,
      );
      const tx2 = SafeTransaction(
        id: 2,
        safeId: 1,
        type: 'withdraw',
        isIncome: false,
        amount: 500.0,
        fee: 0.0,
        netAmount: 500.0,
        balanceBefore: 10000.0,
        balanceAfter: 9500.0,
      );

      mockRepository.detailsResponse = const SafeDetailsResponse(
        status: true,
        message: 'OK',
        safe: testSafe,
        transactions: [tx1],
        pagination: TransactionPagination(currentPage: 1, lastPage: 2, perPage: 1, total: 2),
      );

      mockRepository.detailsPage2Response = const SafeDetailsResponse(
        status: true,
        message: 'OK',
        safe: testSafe,
        transactions: [tx2],
        pagination: TransactionPagination(currentPage: 2, lastPage: 2, perPage: 1, total: 2),
      );

      final cubit = SafeDetailsCubit(safesRepository: mockRepository);
      await cubit.loadSafeDetails(1);

      expect((cubit.state as SafeDetailsLoaded).transactions.length, 1);

      await cubit.loadMoreTransactions();

      final state = cubit.state as SafeDetailsLoaded;
      expect(state.transactions.length, 2);
      expect(state.transactions[1].id, 2);
      expect(state.pagination?.currentPage, 2);
      expect(state.isLoadingMoreTransactions, false);
      cubit.close();
    });
  });

  group('SafeOperationCubit Tests', () {
    test('deposit validates amount > 0', () async {
      final cubit = SafeOperationCubit(safesRepository: mockRepository);

      final result = await cubit.deposit(safeId: 1, amount: 0);

      expect(result, false);
      expect(cubit.state, const SafeOperationFailure('يجب أن يكون مبلغ الإيداع أكبر من صفر.'));
      expect(mockRepository.depositCallCount, 0);
      cubit.close();
    });

    test('withdraw validates amount > 0', () async {
      final cubit = SafeOperationCubit(safesRepository: mockRepository);

      final result = await cubit.withdraw(safeId: 1, amount: -10);

      expect(result, false);
      expect(cubit.state, const SafeOperationFailure('يجب أن يكون مبلغ السحب أكبر من صفر.'));
      expect(mockRepository.withdrawCallCount, 0);
      cubit.close();
    });

    test('transfer prevents transfer to same safe', () async {
      final cubit = SafeOperationCubit(safesRepository: mockRepository);

      final result = await cubit.transfer(
        fromSafeId: 1,
        toSafeId: 1,
        amount: 500,
      );

      expect(result, false);
      expect(cubit.state, const SafeOperationFailure('لا يمكن التحويل إلى نفس الخزنة.'));
      expect(mockRepository.transferCallCount, 0);
      cubit.close();
    });

    test('network failure triggers SafeOperationAmbiguous state', () async {
      mockRepository.throwFailure = const NetworkFailure('لا يوجد اتصال بالإنترنت');

      final cubit = SafeOperationCubit(safesRepository: mockRepository);

      final result = await cubit.deposit(safeId: 1, amount: 500);

      expect(result, false);
      expect(cubit.state, isA<SafeOperationAmbiguous>());
      cubit.close();
    });

    test('successful transfer emits [Submitting, Success]', () async {
      mockRepository.transferResponse = const TransferResponse(
        status: true,
        message: 'تم التحويل بنجاح',
      );

      final cubit = SafeOperationCubit(safesRepository: mockRepository);
      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const SafeOperationSubmitting(),
          const SafeOperationSuccess('تم التحويل بنجاح'),
        ]),
      );

      final result = await cubit.transfer(
        fromSafeId: 1,
        toSafeId: 2,
        amount: 1500,
      );

      expect(result, true);
      await expectation;
      cubit.close();
    });
  });
}

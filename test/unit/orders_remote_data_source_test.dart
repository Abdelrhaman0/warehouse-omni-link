import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warehouse_store_keeper/core/constants/api_endpoints.dart';
import 'package:warehouse_store_keeper/core/constants/app_constants.dart';
import 'package:warehouse_store_keeper/core/network/dio_client.dart';
import 'package:warehouse_store_keeper/core/storage/secure_storage_service.dart';
import 'package:warehouse_store_keeper/features/orders/data/orders_remote_data_source.dart';

class MockDio extends Mock implements Dio {}
class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockDio mockDio;
  late MockSecureStorageService mockStorage;
  late DioClient dioClient;
  late OrdersRemoteDataSourceImpl remoteDataSource;

  setUp(() {
    mockDio = MockDio();
    when(() => mockDio.interceptors).thenReturn(Interceptors());
    mockStorage = MockSecureStorageService();
    dioClient = DioClient(
      storageService: mockStorage,
      customDio: mockDio,
    );
    remoteDataSource = OrdersRemoteDataSourceImpl(dioClient);
  });

  group('OrdersRemoteDataSource - per_page & tab query parameters', () {
    const successResponseData = {
      'data': {
        'current_page': 1,
        'last_page': 5,
        'per_page': 30,
        'total': 150,
        'next_page_url': 'https://test.omni-link.net/api/ar/v1/admin/warehouse/orders?page=2',
        'prev_page_url': null,
        'data': [],
      }
    };

    test('matches backend curl sample: only per_page=30 on initial load without page or status', () async {
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((invocation) async {
        final queryParams = invocation.namedArguments[#queryParameters] as Map<String, dynamic>;
        expect(queryParams, {
          'per_page': AppConstants.defaultPerPage,
        });

        return Response<dynamic>(
          data: successResponseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: ApiEndpoints.orders('ar')),
        );
      });

      final result = await remoteDataSource.getOrders();

      expect(result.perPage, 30);
      expect(result.currentPage, 1);
      expect(result.lastPage, 5);
      expect(result.total, 150);
    });

    test('supports custom perPage and page values', () async {
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((invocation) async {
        final queryParams = invocation.namedArguments[#queryParameters] as Map<String, dynamic>;
        expect(queryParams['per_page'], 50);
        expect(queryParams['page'], 3);
        expect(queryParams['status'], 'confirmed');

        return Response<dynamic>(
          data: {
            'data': {
              'current_page': 3,
              'last_page': 10,
              'per_page': 50,
              'total': 500,
              'data': [],
            }
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ApiEndpoints.orders('ar')),
        );
      });

      final result = await remoteDataSource.getOrders(
        status: 'confirmed',
        page: 3,
        perPage: 50,
      );

      expect(result.perPage, 50);
      expect(result.currentPage, 3);
    });

    test('supports passing backend tab in queryParameters (pending, without_photos, with_photos, completed)', () async {
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((invocation) async {
        final queryParams = invocation.namedArguments[#queryParameters] as Map<String, dynamic>;
        expect(queryParams['tab'], 'without_photos');
        expect(queryParams['per_page'], AppConstants.defaultPerPage);

        return Response<dynamic>(
          data: successResponseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: ApiEndpoints.orders('ar')),
        );
      });

      final result = await remoteDataSource.getOrders(tab: 'without_photos');
      expect(result.currentPage, 1);
    });
  });
}

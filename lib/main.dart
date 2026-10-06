import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/network/dio_client.dart';
import 'core/network/authenticated_cache_manager.dart';
import 'core/storage/media_hash_storage.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/auth/data/auth_remote_data_source.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/orders/data/orders_remote_data_source.dart';
import 'features/orders/data/orders_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local storage initialization
  final sharedPreferences = await SharedPreferences.getInstance();
  final secureStorage = SecureStorageService();
  final mediaHashStorage = MediaHashStorage(sharedPreferences);

  // Network client with token injection & 401 unauthorized handling
  final dioClient = DioClient(
    storageService: secureStorage,
  );

  // Configure the authenticated image cache manager to inject the Bearer token
  // into all CachedNetworkImage requests (flutter_cache_manager uses its own
  // http client, separate from DioClient, so auth headers must be injected here).
  AuthenticatedCacheManager.configure(() => secureStorage.getAuthToken());

  // Auth Layer
  final authRemoteDataSource = AuthRemoteDataSourceImpl(dioClient);
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemoteDataSource,
    storageService: secureStorage,
    dioClient: dioClient,
  );

  // Orders Layer
  final ordersRemoteDataSource = OrdersRemoteDataSourceImpl(dioClient);
  final ordersRepository = OrdersRepositoryImpl(
    remoteDataSource: ordersRemoteDataSource,
    mediaHashStorage: mediaHashStorage,
  );

  runApp(
    OmniLinkWarehouseApp(
      authRepository: authRepository,
      ordersRepository: ordersRepository,
    ),
  );
}

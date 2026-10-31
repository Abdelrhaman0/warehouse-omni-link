import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/network/dio_client.dart';
import 'core/network/authenticated_cache_manager.dart';
import 'core/storage/media_hash_storage.dart';
import 'core/storage/pending_photos_storage.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/auth/data/auth_remote_data_source.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/orders/data/orders_remote_data_source.dart';
import 'features/orders/data/orders_repository.dart';
import 'features/safes/data/safes_remote_data_source.dart';
import 'features/safes/data/safes_repository.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    unawaited(_initializeFcmTokenLogging());
  } catch (error) {
    debugPrint('Firebase initialization failed: $error');
  }

  // Local storage initialization
  final sharedPreferences = await SharedPreferences.getInstance();
  final secureStorage = SecureStorageService();
  final mediaHashStorage = MediaHashStorage(sharedPreferences);
  final pendingPhotosStorage = PendingPhotosStorage(sharedPreferences);

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

  // Safes Layer
  final safesRemoteDataSource = SafesRemoteDataSourceImpl(dioClient);
  final safesRepository = SafesRepositoryImpl(
    remoteDataSource: safesRemoteDataSource,
  );

  runApp(
    OmniLinkWarehouseApp(
      authRepository: authRepository,
      ordersRepository: ordersRepository,
      safesRepository: safesRepository,
      pendingPhotosStorage: pendingPhotosStorage,
    ),
  );
}

Future<void> _initializeFcmTokenLogging() async {
  try {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    debugPrint('FCM notification permission: ${settings.authorizationStatus}');

    final token = await messaging.getToken();
    if (token == null) {
      debugPrint('FCM Registration Token: unavailable');
    } else {
      debugPrint('FCM Registration Token: $token');
    }

    messaging.onTokenRefresh.listen(
      (token) => debugPrint('FCM Registration Token (refreshed): $token'),
      onError: (Object error) {
        debugPrint('FCM token refresh failed: $error');
      },
    );
  } catch (error) {
    debugPrint('FCM token retrieval failed: $error');
  }
}

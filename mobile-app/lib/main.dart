import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'core/network/dio_client.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/phone_auth_bloc.dart';
import 'features/auth/presentation/pages/login_screen.dart';
import 'features/product_catalog/data/datasources/product_remote_data_source.dart';
import 'features/product_catalog/data/repositories/product_repository_impl.dart';
import 'features/product_catalog/domain/usecases/get_products_usecase.dart';
import 'features/product_catalog/domain/repositories/product_repository.dart';
import 'features/product_catalog/domain/entities/category.dart';
import 'features/product_catalog/domain/entities/product.dart';
import 'features/product_catalog/presentation/bloc/product_bloc.dart';
import 'features/product_catalog/presentation/bloc/product_event.dart';
import 'holmon/views/home.dart';
import 'holmon/views/vegetable_detail.dart';
import 'holmon/views/vegetables.dart';
import 'package:get/get.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'holmon/utils/myTheme.dart';
import 'features/cart/presentation/bloc/cart_bloc.dart';
import 'features/checkout/data/datasources/order_remote_data_source.dart';
import 'features/checkout/data/repositories/order_repository_impl.dart';
import 'features/checkout/domain/repositories/order_repository.dart';
import 'features/checkout/presentation/bloc/order_bloc.dart';
import 'holmon/utils/wishlist_manager.dart';
import 'features/auth/presentation/pages/role_selection_screen.dart';
import 'features/auth/presentation/pages/welcome_screen.dart';
import 'features/auth/presentation/pages/splash_screen.dart';
import 'features/auth/presentation/pages/role_dashboards.dart';
import 'features/auth/presentation/bloc/registration_bloc.dart';
import 'features/auth/presentation/pages/registration/customer_registration_screen.dart';
import 'features/auth/presentation/pages/registration/shopkeeper_registration_screen.dart';
import 'features/auth/presentation/pages/registration/rider_registration_screen.dart';
import 'features/auth/presentation/pages/registration/pending_approval_screen.dart';
import 'core/localization/language_bloc.dart';
import 'core/localization/language_event.dart';
import 'core/localization/language_state.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Failed to initialize Firebase: $e");
  }
  
  // Safe initialization of WishlistManager
  try {
    await WishlistManager.instance.init();
  } catch (e) {
    debugPrint("Failed to initialize WishlistManager: $e");
  }

  // Safe initialization of local hydrated storage for persistent state
  Storage? storage;
  try {
    storage = await HydratedStorage.build(
      storageDirectory: HydratedStorageDirectory((await getApplicationDocumentsDirectory()).path),
    );
    HydratedBloc.storage = storage;
  } catch (e) {
    debugPrint("Failed to initialize HydratedStorage: $e");
    // Fallback: Clear directory files if corrupted and retry
    try {
      final dir = await getApplicationDocumentsDirectory();
      final storageDir = Directory(dir.path);
      if (storageDir.existsSync()) {
        final files = storageDir.listSync();
        for (var file in files) {
          if (file is File && file.path.endsWith('.json')) {
            await file.delete();
          }
        }
      }
      storage = await HydratedStorage.build(
        storageDirectory: HydratedStorageDirectory(dir.path),
      );
      HydratedBloc.storage = storage;
    } catch (_) {
      HydratedBloc.storage = InMemoryStorage();
    }
  }

  // Ensure HydratedBloc.storage is never null to prevent runtime assertion crashes
  if (HydratedBloc.storage == null) {
    HydratedBloc.storage = InMemoryStorage();
  }

  // 1. Initialize secure storage
  const secureStorage = FlutterSecureStorage();

  // 2. Determine initial auth status and settings safely
  String? token;
  String? savedBaseUrl;
  String? savedEmail;
  String? savedThemeKey;
  String? savedRole;
  String? profileStatus;
  
  try {
    token = await secureStorage.read(key: 'jwt_access_token');
    savedBaseUrl = await secureStorage.read(key: 'api_base_url');
    savedEmail = await secureStorage.read(key: 'user_email');
    savedThemeKey = await secureStorage.read(key: 'theme_${savedEmail ?? "guest"}');
    savedRole = await secureStorage.read(key: 'user_role');
    profileStatus = await secureStorage.read(key: 'profile_status');
  } catch (e) {
    debugPrint("Secure storage initialization error: $e");
    // Try clearing all keys if keystore is corrupted
    try {
      await secureStorage.deleteAll();
    } catch (_) {}
  }

  final isAuthenticated = token != null && token.isNotEmpty;
  final initialBaseUrl = savedBaseUrl ?? 'https://grocery-backend.xpertraza13.workers.dev';

  // 3. Initialize core network dependency
  final dioClient = DioClient(baseUrl: initialBaseUrl);

  // 4. Initialize Auth feature dependencies
  final authRemoteDataSource = AuthRemoteDataSourceImpl(dio: dioClient.dio);
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemoteDataSource,
    secureStorage: secureStorage,
  );

  // 5. Initialize product catalog feature dependencies (Clean Architecture chain)
  final productRemoteDataSource = ProductRemoteDataSourceImpl(dio: dioClient.dio);
  final productRepository = ProductRepositoryImpl(remoteDataSource: productRemoteDataSource);
  final getProductsUseCase = GetProductsUseCase(productRepository);

  // 6. Initialize checkout feature dependencies
  final orderRemoteDataSource = OrderRemoteDataSourceImpl(dio: dioClient.dio);
  final orderRepository = OrderRepositoryImpl(remoteDataSource: orderRemoteDataSource);

  final initialTheme = AppThemes.getThemeByKey(savedThemeKey ?? 'organic_green');

  runApp(
    MyApp(
      getProductsUseCase: getProductsUseCase,
      productRepository: productRepository,
      authRepository: authRepository,
      orderRepository: orderRepository,
      dioClient: dioClient,
      secureStorage: secureStorage,
      isAuthenticated: isAuthenticated,
      initialTheme: initialTheme,
      savedRole: savedRole,
      profileStatus: profileStatus,
    ),
  );
}

class MyApp extends StatelessWidget {
  final GetProductsUseCase getProductsUseCase;
  final ProductRepository? productRepository;
  final AuthRepository? authRepository;
  final OrderRepository? orderRepository;
  final DioClient dioClient;
  final FlutterSecureStorage secureStorage;
  final bool isAuthenticated;
  final ThemeData initialTheme;
  final String? savedRole;
  final String? profileStatus;

  const MyApp({
    super.key,
    required this.getProductsUseCase,
    required this.dioClient,
    required this.secureStorage,
    required this.initialTheme,
    this.productRepository,
    this.authRepository,
    this.orderRepository,
    this.isAuthenticated = false,
    this.savedRole,
    this.profileStatus,
  });

  @override
  Widget build(BuildContext context) {
    final activeAuthRepo = authRepository ?? _MockAuthRepository();
    final activeProductRepo = productRepository ?? _MockProductRepository();
    final activeOrderRepo = orderRepository ?? _MockOrderRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ProductRepository>.value(value: activeProductRepo),
        RepositoryProvider<AuthRepository>.value(value: activeAuthRepo),
        RepositoryProvider<OrderRepository>.value(value: activeOrderRepo),
        RepositoryProvider<DioClient>.value(value: dioClient),
        RepositoryProvider<FlutterSecureStorage>.value(value: secureStorage),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<PhoneAuthBloc>(
            create: (context) => PhoneAuthBloc(authRepository: activeAuthRepo),
          ),
          BlocProvider<RegistrationBloc>(
            create: (context) => RegistrationBloc(authRepository: activeAuthRepo),
          ),
          BlocProvider<ProductBloc>(
            create: (context) => ProductBloc(
              getProductsUseCase: getProductsUseCase,
            )..add(const FetchProductsEvent()), // Pre-load products on startup
          ),
          BlocProvider<CartBloc>(
            create: (context) => CartBloc(),
          ),
          BlocProvider<OrderBloc>(
            create: (context) => OrderBloc(orderRepository: activeOrderRepo),
          ),
          BlocProvider<LanguageBloc>(
            create: (context) => LanguageBloc()..add(const LoadSavedLanguageEvent()),
          ),
        ],
        child: ThemeProvider(
          initTheme: initialTheme,
          builder: (context, myTheme) {
            Widget getInitialHome() {
              if (isAuthenticated) {
                if (profileStatus == 'incomplete') {
                  if (savedRole == 'shopkeeper') {
                    return const ShopkeeperRegistrationScreen();
                  } else if (savedRole == 'rider') {
                    return const RiderRegistrationScreen();
                  } else {
                    return const CustomerRegistrationScreen();
                  }
                } else if (profileStatus == 'pending') {
                  return const PendingApprovalScreen();
                } else {
                  if (savedRole == 'shopkeeper') {
                    return const ShopkeeperDashboard();
                  } else if (savedRole == 'rider') {
                    return const RiderDashboard();
                  } else {
                    return const CustomerDashboard();
                  }
                }
              } else {
                return const SplashScreen();
              }
            }

            return BlocBuilder<LanguageBloc, LanguageState>(
              builder: (context, langState) {
                return GetMaterialApp(
                  title: 'FreshCart Mobile App',
                  debugShowCheckedModeBanner: false,
                  theme: myTheme,
                  locale: langState.locale,
                  supportedLocales: const [
                    Locale('en'),
                    Locale('ur'),
                  ],
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  home: const SplashScreen(),
                  routes: {
                    '/home': (context) => HomeScreen(),
                    '/login': (context) => const LoginScreen(),
                    '/welcome': (context) => const RoleSelectionScreen(),
                    '/onboarding': (context) => const WelcomeScreen(),
                    '/customer_dashboard': (context) => const CustomerDashboard(),
                    '/shopkeeper_dashboard': (context) => const ShopkeeperDashboard(),
                    '/rider_dashboard': (context) => const RiderDashboard(),
                    '/customer_register': (context) => const CustomerRegistrationScreen(),
                    '/shopkeeper_register': (context) => const ShopkeeperRegistrationScreen(),
                    '/rider_register': (context) => const RiderRegistrationScreen(),
                    '/pending_approval': (context) => const PendingApprovalScreen(),
                    '/details': (context) => const VegetableDetailScreen(),
                    '/vegetables': (context) => const VegetablesScreen(),
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MockAuthRepository implements AuthRepository {
  final secureStorage = const FlutterSecureStorage();

  @override
  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String phone,
    required String location,
    required String password,
    String? role,
  }) async {
    if (role != null) {
      await secureStorage.write(key: 'user_role', value: role);
    }
    await secureStorage.write(key: 'profile_status', value: 'incomplete');
    return {
      'token': 'mock_token',
      'user': {
        'id': 1,
        'name': name,
        'email': email,
        'phone': phone,
        'location': location,
        'is_verified': true,
      },
      'profile_status': {
        'status': 'incomplete'
      }
    };
  }

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? role,
  }) async {
    if (role != null) {
      await secureStorage.write(key: 'user_role', value: role);
    }
    await secureStorage.write(key: 'profile_status', value: 'incomplete');
    return {
      'token': 'mock_token',
      'user': {
        'id': 1,
        'name': 'Mock User',
        'email': email,
        'phone': '1234567890',
        'location': 'Lahore, PK',
        'is_verified': true,
      },
      'profile_status': {
        'status': 'incomplete'
      }
    };
  }

  @override
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
    String? role,
  }) async {
    if (role != null) {
      await secureStorage.write(key: 'user_role', value: role);
    }
    await secureStorage.write(key: 'profile_status', value: 'incomplete');
    return {
      'token': 'mock_token',
      'user': {
        'id': 1,
        'name': 'Mock User',
        'email': email,
        'phone': '1234567890',
        'is_verified': true,
      },
      'profile_status': {
        'status': 'incomplete'
      }
    };
  }

  @override
  Future<void> requestOtp(String phoneNumber) async {}

  @override
  Future<void> saveToken(String token) async {
    await secureStorage.write(key: 'jwt_access_token', value: token);
  }

  @override
  Future<String?> getToken() async {
    return await secureStorage.read(key: 'jwt_access_token');
  }

  @override
  Future<String?> getRole() async {
    return await secureStorage.read(key: 'user_role') ?? 'customer';
  }

  @override
  Future<String?> getProfileStatusString() async {
    return await secureStorage.read(key: 'profile_status') ?? 'incomplete';
  }

  @override
  Future<void> clearToken() async {
    await secureStorage.delete(key: 'jwt_access_token');
    await secureStorage.delete(key: 'user_role');
    await secureStorage.delete(key: 'profile_status');
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
    required String location,
    String? password,
  }) async {
    await secureStorage.write(key: 'profile_status', value: 'complete');
    return {
      'user': {
        'id': 1,
        'name': name,
        'email': 'mock@user.com',
        'phone': phone,
        'location': location,
        'is_verified': true,
      }
    };
  }

  @override
  Future<Map<String, dynamic>> getProfileStatus() async {
    final status = await secureStorage.read(key: 'profile_status') ?? 'incomplete';
    return {
      'success': true,
      'profile_status': {
        'is_complete': status == 'complete',
        'status': status,
      }
    };
  }

  @override
  Future<Map<String, dynamic>> registerShop({
    required String shopName,
    required String shopAddress,
    required String mapLocation,
    required String cnic,
    required String openingTime,
    required String closingTime,
    String? imageUrl,
  }) async {
    await secureStorage.write(key: 'profile_status', value: 'pending');
    return {
      'success': true,
      'shop': {
        'id': 1,
        'shop_name': shopName,
        'status': 'pending',
      }
    };
  }

  @override
  Future<Map<String, dynamic>> registerRider({
    required String vehicleType,
    required String vehicleNumber,
    required String cnic,
    required String currentLocation,
  }) async {
    await secureStorage.write(key: 'profile_status', value: 'pending');
    return {
      'success': true,
      'rider': {
        'id': 1,
        'status': 'offline',
        'is_approved': false,
      }
    };
  }
}

class _MockProductRepository implements ProductRepository {
  @override
  Future<List<Product>> getProducts({
    required int page,
    required int limit,
    String? search,
    int? categoryId,
  }) async => [];

  @override
  Future<List<Category>> getCategories() async => [];

  @override
  Future<Product> createProduct({
    required String title,
    required String description,
    required double price,
    required double? salePrice,
    required String unit,
    required int stockQuantity,
    required int? categoryId,
    required String? imageUrl,
  }) async {
    return Product(
      id: 'mock_new_id',
      title: title,
      price: price,
      unit: unit,
      category: 'Fruits',
      imageUrl: imageUrl ?? '',
      stock: stockQuantity,
    );
  }
}

class _MockOrderRepository implements OrderRepository {
  @override
  Future<Map<String, dynamic>> placeOrder({
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required double totalAmount,
    required String paymentMethod,
  }) async => {};

  @override
  Future<List<dynamic>> getOrderHistory() async => [];

  @override
  Future<Map<String, dynamic>> getOrderById(int id) async => {};

  @override
  Future<Map<String, dynamic>> cancelOrder(int id, String reason) async => {};

  @override
  Future<void> deleteOrder(int id) async {}

  @override
  Future<Map<String, dynamic>> updateShopkeeperOrderStatus(int orderId, String action) async => {};

  @override
  Future<Map<String, dynamic>> updateRiderOrderStatus(int orderId, String action) async => {};

  @override
  Future<List<dynamic>> getOrderHistoryTimeline(int orderId) async => [];

  @override
  Future<Map<String, dynamic>> requestCodApproval({required int orderId, required double amount}) async => {
    'status': 'pending',
    'amount': amount,
    'order_id': orderId,
  };

  @override
  Future<Map<String, dynamic>?> getCodApprovalStatus(int orderId) async => {
    'status': 'approved',
    'order_id': orderId,
  };

  @override
  Future<double> getRiderCodLimit() async => 5000.0;
}

class InMemoryStorage implements Storage {
  final Map<String, dynamic> _data = {};

  @override
  dynamic read(String key) => _data[key];

  @override
  Future<void> write(String key, dynamic value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<void> clear() async => _data.clear();

  @override
  Future<void> close() async {}
}

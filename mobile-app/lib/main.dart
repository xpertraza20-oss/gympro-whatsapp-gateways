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
import 'features/auth/presentation/pages/welcome_screen.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WishlistManager.instance.init();

  // Initialize local hydrated storage for persistent state
  final storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory((await getApplicationDocumentsDirectory()).path),
  );
  HydratedBloc.storage = storage;

  // 1. Initialize secure storage
  const secureStorage = FlutterSecureStorage();

  // 2. Determine initial auth token
  final token = await secureStorage.read(key: 'jwt_access_token');
  final isAuthenticated = token != null && token.isNotEmpty;

  // Read saved base URL or fallback to default
  final savedBaseUrl = await secureStorage.read(key: 'api_base_url');
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

  final savedEmail = await secureStorage.read(key: 'user_email') ?? 'guest';
  final savedThemeKey = await secureStorage.read(key: 'theme_$savedEmail') ?? 'organic_green';
  final initialTheme = AppThemes.getThemeByKey(savedThemeKey);

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
        ],
        child: ThemeProvider(
          initTheme: initialTheme,
          builder: (context, myTheme) {
            return GetMaterialApp(
              title: 'FreshCart Mobile App',
              debugShowCheckedModeBanner: false,
              theme: myTheme,
              home: isAuthenticated ? HomeScreen() : const WelcomeScreen(),
              routes: {
                '/home': (context) => HomeScreen(),
                '/login': (context) => const LoginScreen(),
                '/welcome': (context) => const WelcomeScreen(),
                '/details': (context) => const VegetableDetailScreen(),
                '/vegetables': (context) => const VegetablesScreen(),
              },
            );
          },
        ),
      ),
    );
  }
}

class _MockAuthRepository implements AuthRepository {
  @override
  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String phone,
    required String location,
    required String password,
  }) async {
    return {
      'token': 'mock_token',
      'user': {
        'id': 1,
        'name': name,
        'email': email,
        'phone': phone,
        'location': location,
        'is_verified': true,
      }
    };
  }

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return {
      'token': 'mock_token',
      'user': {
        'id': 1,
        'name': 'Mock User',
        'email': email,
        'phone': '1234567890',
        'location': 'Lahore, PK',
        'is_verified': true,
      }
    };
  }

  @override
  Future<Map<String, dynamic>> verifyOtp({required String email, required String otp}) async {
    return {
      'token': 'mock_token',
      'user': {
        'id': 1,
        'name': 'Mock User',
        'email': email,
        'phone': '1234567890',
        'is_verified': true,
      }
    };
  }

  @override
  Future<void> requestOtp(String phoneNumber) async {}

  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<String?> getToken() async => null;

  @override
  Future<void> clearToken() async {}

  @override
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
    required String location,
    String? password,
  }) async {
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
}

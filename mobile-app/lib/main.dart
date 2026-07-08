import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/network/dio_client.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/phone_auth_bloc.dart';
import 'features/auth/presentation/pages/phone_input_screen.dart';
import 'features/product_catalog/data/datasources/product_remote_data_source.dart';
import 'features/product_catalog/data/repositories/product_repository_impl.dart';
import 'features/product_catalog/domain/usecases/get_products_usecase.dart';
import 'features/product_catalog/presentation/bloc/product_bloc.dart';
import 'features/product_catalog/presentation/bloc/product_event.dart';
import 'features/product_catalog/presentation/pages/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize secure storage
  const secureStorage = FlutterSecureStorage();

  // 2. Determine initial auth token
  final token = await secureStorage.read(key: 'jwt_access_token');
  final isAuthenticated = token != null && token.isNotEmpty;

  // 3. Initialize core network dependency
  // Use our production Render URL by default in the mobile client for testing
  final dioClient = DioClient(baseUrl: 'https://grocery-backend-2prq.onrender.com');

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

  runApp(
    MyApp(
      getProductsUseCase: getProductsUseCase,
      authRepository: authRepository,
      isAuthenticated: isAuthenticated,
    ),
  );
}

class MyApp extends StatelessWidget {
  final GetProductsUseCase getProductsUseCase;
  final AuthRepository? authRepository;
  final bool isAuthenticated;

  const MyApp({
    super.key,
    required this.getProductsUseCase,
    this.authRepository,
    this.isAuthenticated = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeAuthRepo = authRepository ?? _MockAuthRepository();

    return MultiBlocProvider(
      providers: [
        BlocProvider<PhoneAuthBloc>(
          create: (context) => PhoneAuthBloc(authRepository: activeAuthRepo),
        ),
        BlocProvider<ProductBloc>(
          create: (context) => ProductBloc(
            getProductsUseCase: getProductsUseCase,
          )..add(const FetchProductsEvent()), // Pre-load products on startup
        ),
      ],
      child: MaterialApp(
        title: 'FreshCart Mobile App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green, // Fix Colors.emerald missing in Flutter Swatch
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: isAuthenticated ? const HomeScreen() : const PhoneInputScreen(),
      ),
    );
  }
}

class _MockAuthRepository implements AuthRepository {
  @override
  Future<void> requestOtp(String phoneNumber) async {}
  @override
  Future<String> verifyOtp(String phoneNumber, String otp) async => 'mock_token';
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<String?> getToken() async => null;
  @override
  Future<void> clearToken() async {}
}

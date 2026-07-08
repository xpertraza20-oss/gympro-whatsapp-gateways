import 'package:flutter/material';
import 'package:flutter_bloc/flutter_bloc';
import 'core/network/dio_client.dart';
import 'features/product_catalog/data/datasources/product_remote_data_source.dart';
import 'features/product_catalog/data/repositories/product_repository_impl.dart';
import 'features/product_catalog/domain/usecases/get_products_usecase.dart';
import 'features/product_catalog/presentation/bloc/product_bloc.dart';
import 'features/product_catalog/presentation/pages/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize core network dependency
  final dioClient = DioClient();

  // 2. Initialize product catalog feature dependencies (Clean Architecture chain)
  final productRemoteDataSource = ProductRemoteDataSourceImpl(dio: dioClient.dio);
  final productRepository = ProductRepositoryImpl(remoteDataSource: productRemoteDataSource);
  final getProductsUseCase = GetProductsUseCase(productRepository);

  runApp(
    MyApp(getProductsUseCase: getProductsUseCase),
  );
}

class MyApp extends StatelessWidget {
  final GetProductsUseCase getProductsUseCase;

  const MyApp({
    super.key,
    required this.getProductsUseCase,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreshCart mobile catalog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.emerald,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      // Wrap application root with MultiBlocProvider / BlocProvider
      home: BlocProvider<ProductBloc>(
        create: (context) => ProductBloc(
          getProductsUseCase: getProductsUseCase,
        ),
        child: const HomeScreen(),
      ),
    );
  }
}

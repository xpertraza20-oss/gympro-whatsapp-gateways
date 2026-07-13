import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_app/core/network/dio_client.dart';
import 'package:grocery_app/features/product_catalog/domain/entities/product.dart';
import 'package:grocery_app/features/product_catalog/domain/entities/category.dart';
import 'package:grocery_app/features/product_catalog/domain/repositories/product_repository.dart';
import 'package:grocery_app/features/product_catalog/domain/usecases/get_products_usecase.dart';
import 'package:grocery_app/holmon/utils/myTheme.dart';
import 'package:grocery_app/main.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

// Mock Product Repository for testing
class MockProductRepository implements ProductRepository {
  @override
  Future<List<Product>> getProducts({
    required int page,
    required int limit,
    String? search,
    int? categoryId,
  }) async {
    return [
      const Product(
        id: 'mock-1',
        title: 'Mock Apple',
        price: 1.99,
        unit: 'each',
        category: 'Fruits',
        imageUrl: 'https://placeholder.com/apple.png',
        stock: 10,
      )
    ];
  }

  @override
  Future<List<Category>> getCategories() async {
    return [
      const Category(id: 1, name: 'Fruits', slug: 'fruits'),
      const Category(id: 2, name: 'Vegetables', slug: 'vegetables'),
    ];
  }
}

class MockStorage implements Storage {
  @override
  dynamic read(String key) => null;
  @override
  Future<void> write(String key, dynamic value) async {}
  @override
  Future<void> delete(String key) async {}
  @override
  Future<void> clear() async {}
  @override
  Future<void> close() async {}
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    HydratedBloc.storage = MockStorage();
  });

  testWidgets('Grocery App authenticated shell smoke test', (WidgetTester tester) async {
    final mockRepository = MockProductRepository();
    final getProductsUseCase = GetProductsUseCase(mockRepository);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MyApp(
        getProductsUseCase: getProductsUseCase,
        dioClient: DioClient(baseUrl: 'https://example.test'),
        secureStorage: const FlutterSecureStorage(),
        initialTheme: AppThemes.getThemeByKey('organic_green'),
        isAuthenticated: true,
      ),
    );

    // Trigger initial frame loads
    await tester.pump();

    // Verify the authenticated home shell is rendered.
    expect(find.text('Welcome back,'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
  });
}

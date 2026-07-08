import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_app/features/product_catalog/domain/entities/product.dart';
import 'package:grocery_app/features/product_catalog/domain/entities/category.dart';
import 'package:grocery_app/features/product_catalog/domain/repositories/product_repository.dart';
import 'package:grocery_app/features/product_catalog/domain/usecases/get_products_usecase.dart';
import 'package:grocery_app/main.dart';

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

void main() {
  testWidgets('Grocery App Catalog smoke test', (WidgetTester tester) async {
    final mockRepository = MockProductRepository();
    final getProductsUseCase = GetProductsUseCase(mockRepository);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MyApp(
        getProductsUseCase: getProductsUseCase,
        isAuthenticated: true,
      ),
    );

    // Trigger initial frame loads
    await tester.pump();

    // Verify AppBar title is rendered
    expect(find.text('FreshCart Catalog'), findsOneWidget);
    expect(find.text('Infinite Scroll & Clean Architecture'), findsOneWidget);
  });
}

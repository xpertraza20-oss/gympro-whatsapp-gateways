import '../entities/category.dart';
import '../repositories/product_repository.dart';

class GetCategoriesUseCase {
  final ProductRepository repository;

  GetCategoriesUseCase(this.repository);

  Future<List<Category>> call() async {
    return await repository.getCategories();
  }
}

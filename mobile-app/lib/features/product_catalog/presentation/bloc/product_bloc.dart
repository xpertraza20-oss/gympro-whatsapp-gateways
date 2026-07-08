import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_products_usecase.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductsUseCase getProductsUseCase;
  static const int _limit = 6; // Limit matching mock segment sizes

  ProductBloc({required this.getProductsUseCase}) : super(ProductInitial()) {
    on<FetchProductsEvent>(_onFetchProducts);
  }

  Future<void> _onFetchProducts(
    FetchProductsEvent event,
    Emitter<ProductState> emit,
  ) async {
    final currentState = state;

    // 1. Refresh logic
    if (event.isRefresh) {
      emit(ProductLoading());
      try {
        final products = await getProductsUseCase(page: 1, limit: _limit);
        emit(ProductLoaded(
          products: products,
          currentPage: 1,
          hasReachedMax: products.length < _limit,
          isPaginationLoading: false,
        ));
      } catch (err) {
        emit(ProductError(err.toString()));
      }
      return;
    }

    // 2. Initial page load logic (from Initial or Error states)
    if (currentState is ProductInitial || currentState is ProductError) {
      emit(ProductLoading());
      try {
        final products = await getProductsUseCase(page: 1, limit: _limit);
        emit(ProductLoaded(
          products: products,
          currentPage: 1,
          hasReachedMax: products.length < _limit,
          isPaginationLoading: false,
        ));
      } catch (err) {
        emit(ProductError(err.toString()));
      }
      return;
    }

    // 3. Paginated scroll loading logic (from Loaded state)
    if (currentState is ProductLoaded) {
      // Guard clauses to prevent duplicate network calls
      if (currentState.hasReachedMax || currentState.isPaginationLoading) return;

      // Set loading state in UI
      emit(currentState.copyWith(isPaginationLoading: true));

      try {
        final nextPage = currentState.currentPage + 1;
        final newProducts = await getProductsUseCase(page: nextPage, limit: _limit);

        if (newProducts.isEmpty) {
          emit(currentState.copyWith(
            hasReachedMax: true,
            isPaginationLoading: false,
          ));
        } else {
          emit(ProductLoaded(
            products: List.of(currentState.products)..addAll(newProducts),
            currentPage: nextPage,
            hasReachedMax: newProducts.length < _limit,
            isPaginationLoading: false,
          ));
        }
      } catch (err) {
        // Recover state and stop loading spinner
        emit(currentState.copyWith(isPaginationLoading: false));
      }
    }
  }
}

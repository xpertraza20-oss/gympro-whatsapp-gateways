import 'package:equatable/equatable.dart';
import '../../domain/entities/product.dart';

abstract class ProductState extends Equatable {
  const ProductState();
  
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<Product> products;
  final int currentPage;
  final bool hasReachedMax;
  final bool isPaginationLoading;

  const ProductLoaded({
    required this.products,
    required this.currentPage,
    required this.hasReachedMax,
    this.isPaginationLoading = false,
  });

  ProductLoaded copyWith({
    List<Product>? products,
    int? currentPage,
    bool? hasReachedMax,
    bool? isPaginationLoading,
  }) {
    return ProductLoaded(
      products: products ?? this.products,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isPaginationLoading: isPaginationLoading ?? this.isPaginationLoading,
    );
  }

  @override
  List<Object?> get props => [products, currentPage, hasReachedMax, isPaginationLoading];
}

class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class FetchProductsEvent extends ProductEvent {
  final bool isRefresh;
  final String? search;
  final int? categoryId;

  const FetchProductsEvent({
    this.isRefresh = false,
    this.search,
    this.categoryId,
  });

  @override
  List<Object?> get props => [isRefresh, search, categoryId];
}

import 'package:equatable/equatable.dart';
import '../../../product_catalog/domain/entities/product.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class AddToCartEvent extends CartEvent {
  final Product product;

  const AddToCartEvent(this.product);

  @override
  List<Object?> get props => [product];
}

class RemoveFromCartEvent extends CartEvent {
  final String productId;

  const RemoveFromCartEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}

class UpdateQuantityEvent extends CartEvent {
  final String productId;
  final int quantity;

  const UpdateQuantityEvent(this.productId, this.quantity);

  @override
  List<Object?> get props => [productId, quantity];
}

class ClearCartEvent extends CartEvent {
  const ClearCartEvent();
}

class ClearCartConflictEvent extends CartEvent {
  const ClearCartConflictEvent();
}

class ClearAndAddEvent extends CartEvent {
  final Product product;
  const ClearAndAddEvent(this.product);

  @override
  List<Object?> get props => [product];
}


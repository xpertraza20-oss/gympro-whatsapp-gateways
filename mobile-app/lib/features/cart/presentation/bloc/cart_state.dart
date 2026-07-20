import 'package:equatable/equatable.dart';
import '../../domain/entities/cart_item.dart';
import '../../../product_catalog/domain/entities/product.dart';


class CartState extends Equatable {
  final List<CartItem> items;
  final Product? pendingProduct;
  final String? conflictShopName;

  const CartState({
    required this.items,
    this.pendingProduct,
    this.conflictShopName,
  });

  int get totalItemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  CartState copyWith({
    List<CartItem>? items,
    Product? pendingProduct,
    String? conflictShopName,
    bool clearConflict = false,
  }) {
    return CartState(
      items: items ?? this.items,
      pendingProduct: clearConflict ? null : (pendingProduct ?? this.pendingProduct),
      conflictShopName: clearConflict ? null : (conflictShopName ?? this.conflictShopName),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory CartState.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List<dynamic>? ?? [];
    return CartState(
      items: list.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  @override
  List<Object?> get props => [items, pendingProduct, conflictShopName];
}

import 'package:equatable/equatable.dart';
import '../../../product_catalog/data/models/product_model.dart';
import '../../../product_catalog/domain/entities/product.dart';

class CartItem extends Equatable {
  final Product product;
  final int quantity;

  const CartItem({
    required this.product,
    required this.quantity,
  });

  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': (product is ProductModel) 
          ? (product as ProductModel).toJson() 
          : ProductModel(
              id: product.id,
              title: product.title,
              price: product.price,
              unit: product.unit,
              category: product.category,
              imageUrl: product.imageUrl,
              stock: product.stock,
              shopId: product.shopId,
              shopName: product.shopName,
            ).toJson(),
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
    );
  }

  @override
  List<Object?> get props => [product, quantity];
}

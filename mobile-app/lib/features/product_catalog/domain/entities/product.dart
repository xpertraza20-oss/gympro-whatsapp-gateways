import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String title;
  final double price;
  final String unit;
  final String category;
  final String imageUrl;
  final int stock;
  final String shopId;
  final String shopName;

  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.unit,
    required this.category,
    required this.imageUrl,
    required this.stock,
    this.shopId = '',
    this.shopName = '',
  });

  @override
  List<Object?> get props => [
        id,
        title,
        price,
        unit,
        category,
        imageUrl,
        stock,
        shopId,
        shopName,
      ];
}


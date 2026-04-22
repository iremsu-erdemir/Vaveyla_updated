import 'package:flutter_sweet_shop_app_ui/features/cart_feature/data/models/product_model.dart';

class RecommendationItem {
  const RecommendationItem({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.name,
    required this.shortDescription,
    required this.imagePath,
    required this.price,
    required this.saleUnit,
    required this.score,
  });

  final String id;
  final String restaurantId;
  final String? restaurantName;
  final String name;
  final String shortDescription;
  final String imagePath;
  final int price;
  final int saleUnit;
  final double score;

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      id: json['id']?.toString() ?? '',
      restaurantId: json['restaurantId']?.toString() ?? '',
      restaurantName: json['restaurantName']?.toString(),
      name: json['name']?.toString() ?? '',
      shortDescription: json['shortDescription']?.toString() ?? '',
      imagePath: json['imagePath']?.toString() ?? '',
      price: int.tryParse(json['price']?.toString() ?? '') ?? 0,
      saleUnit: int.tryParse(json['saleUnit']?.toString() ?? '') ?? 0,
      score: (json['score'] is num)
          ? (json['score'] as num).toDouble()
          : double.tryParse(json['score']?.toString() ?? '') ?? 0,
    );
  }

  ProductModel toProductModel() {
    return ProductModel.fromApiJson(<String, dynamic>{
      'id': id,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName ?? '',
      'name': name,
      'price': price,
      'rating': 0,
      'reviewCount': 0,
      'imagePath': imagePath,
      'saleUnit': saleUnit,
      'restaurantIsOpen': true,
    });
  }
}

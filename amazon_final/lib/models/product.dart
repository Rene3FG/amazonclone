import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int    id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final double price;
  final double? rating;
  final int?    ratingCount;
  final double? originalPrice;
  final int?    discountPercent;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.price,
    this.rating,
    this.ratingCount,
    this.originalPrice,
    this.discountPercent,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final price   = (json['price'] as num).toDouble();
    final isDeal  = (json['id'] as int) % 3 == 0;
    return Product(
      id:              json['id']          as int,
      title:           json['title']       as String,
      description:     json['description'] as String,
      category:        json['category']    as String,
      imageUrl:        json['image']       as String,
      price:           price,
      rating:          (json['rating']?['rate'] as num?)?.toDouble(),
      ratingCount:     json['rating']?['count'] as int?,
      originalPrice:   isDeal ? double.parse((price * 1.3).toStringAsFixed(2)) : null,
      discountPercent: isDeal ? 23 : null,
    );
  }

  String get formattedPrice         => '\$${price.toStringAsFixed(2)}';
  String get formattedOriginalPrice => '\$${originalPrice?.toStringAsFixed(2) ?? ''}';
  bool   get hasDiscount            => discountPercent != null;

  @override
  List<Object?> get props => [id, price, title];
}

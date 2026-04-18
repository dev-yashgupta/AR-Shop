import 'package:flutter/material.dart';

enum ARType { placement, tryOn }

class ProductColor {
  final String name;
  final String hex;

  ProductColor({required this.name, required this.hex});

  Color get color => Color(int.parse(hex.replaceFirst('#', '0xFF')));
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final String category;
  final String subCategory;
  final String? arModelPath;
  final String? tryOnImagePath;
  final String imageUrl;
  final List<ProductColor> colors;
  final Map<String, String> specs;
  final bool isAREnabled;
  final bool isTryOnEnabled;
  final ARType arType;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.category,
    required this.subCategory,
    this.arModelPath,
    this.tryOnImagePath,
    required this.imageUrl,
    required this.colors,
    required this.specs,
    required this.isAREnabled,
    this.isTryOnEnabled = false,
    required this.arType,
  });

  double get finalPrice => discountPrice ?? price;
  int get discountPercentage => discountPrice != null
      ? (((price - discountPrice!) / price) * 100).round()
      : 0;
}

import 'package:ar_shop/data/models/product_model.dart';
import 'package:hive/hive.dart';

part 'cart_item_model.g.dart';

@HiveType(typeId: 0)
class CartItem extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final double price;
  @HiveField(3)
  final String imageUrl;
  @HiveField(4)
  int quantity;
  @HiveField(5)
  final String? selectedColor;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
    this.selectedColor,
  });

  factory CartItem.fromProduct(Product product, {String? color}) {
    return CartItem(
      id: product.id,
      name: product.name,
      price: product.finalPrice,
      imageUrl: product.imageUrl,
      selectedColor: color,
    );
  }
}

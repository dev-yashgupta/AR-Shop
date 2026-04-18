import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ar_shop/data/models/cart_item_model.dart';
import 'package:ar_shop/data/models/product_model.dart';

class CartProvider with ChangeNotifier {
  static const String _boxName = 'cartBox';
  Box<CartItem>? _cartBox;

  CartProvider() {
    _initHive();
  }

  Future<void> _initHive() async {
    _cartBox = Hive.box<CartItem>(_boxName);
    notifyListeners();
  }

  List<CartItem> get items => _cartBox?.values.toList() ?? [];

  double get totalAmount {
    double total = 0.0;
    for (var item in items) {
      total += item.price * item.quantity;
    }
    return total;
  }

  int get itemCount => items.length;

  void addItem(Product product, {String? color}) {
    if (_cartBox == null) return;

    final existingIndex = items.indexWhere((item) => item.id == product.id && item.selectedColor == color);

    if (existingIndex >= 0) {
      final item = _cartBox!.getAt(existingIndex);
      if (item != null) {
        item.quantity += 1;
        item.save();
      }
    } else {
      _cartBox!.add(CartItem.fromProduct(product, color: color));
    }
    notifyListeners();
  }

  void removeItem(String id, String? color) {
    if (_cartBox == null) return;
    final index = items.indexWhere((item) => item.id == id && item.selectedColor == color);
    if (index >= 0) {
      _cartBox!.deleteAt(index);
      notifyListeners();
    }
  }

  void incrementQuantity(String id, String? color) {
    if (_cartBox == null) return;
    final index = items.indexWhere((item) => item.id == id && item.selectedColor == color);
    if (index >= 0) {
      final item = _cartBox!.getAt(index);
      if (item != null) {
        item.quantity += 1;
        item.save();
        notifyListeners();
      }
    }
  }

  void decrementQuantity(String id, String? color) {
    if (_cartBox == null) return;
    final index = items.indexWhere((item) => item.id == id && item.selectedColor == color);
    if (index >= 0) {
      final item = _cartBox!.getAt(index);
      if (item != null) {
        if (item.quantity > 1) {
          item.quantity -= 1;
          item.save();
        } else {
          _cartBox!.deleteAt(index);
        }
        notifyListeners();
      }
    }
  }

  void clearCart() {
    _cartBox?.clear();
    notifyListeners();
  }
}

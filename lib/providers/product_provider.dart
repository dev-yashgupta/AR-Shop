import 'package:flutter/material.dart';
import 'package:ar_shop/data/models/product_model.dart';
import 'package:ar_shop/data/dummy_products.dart';

class ProductProvider with ChangeNotifier {
  final List<Product> _products = dummyProducts;
  String _selectedCategory = "All";
  String _searchQuery = "";

  List<Product> get products {
    return _products.where((product) {
      final matchesCategory = _selectedCategory == "All" || product.category == _selectedCategory;
      final matchesSearch = product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<String> get categories {
    final cats = ["All"];
    cats.addAll(dummyProducts.map((p) => p.category).toSet().toList());
    return cats;
  }
}

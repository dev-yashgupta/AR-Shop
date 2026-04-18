import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ar_shop/app.dart';
import 'package:ar_shop/data/models/cart_item_model.dart';
import 'package:ar_shop/providers/product_provider.dart';
import 'package:ar_shop/providers/cart_provider.dart';
import 'package:ar_shop/providers/ar_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Adapters
  Hive.registerAdapter(CartItemAdapter());
  
  // Open Boxes
  await Hive.openBox<CartItem>('cartBox');
  await Hive.openBox<String>('arGalleryBox');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ARProvider()),
      ],
      child: const ARShopApp(),
    ),
  );
}

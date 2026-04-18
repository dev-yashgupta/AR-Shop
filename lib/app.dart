import 'package:flutter/material.dart';
import 'package:ar_shop/config/theme.dart';
import 'package:ar_shop/config/constants.dart';
import 'package:ar_shop/screens/home_screen.dart';
import 'package:ar_shop/screens/cart_screen.dart';
import 'package:ar_shop/screens/ar_gallery_screen.dart';

class ARShopApp extends StatelessWidget {
  const ARShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/cart': (context) => const CartScreen(),
        '/gallery': (context) => const ARGalleryScreen(),
      },
    );
  }
}

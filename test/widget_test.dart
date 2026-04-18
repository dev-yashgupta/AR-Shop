// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import 'package:ar_shop/app.dart';
import 'package:ar_shop/data/models/cart_item_model.dart';
import 'package:ar_shop/providers/ar_provider.dart';
import 'package:ar_shop/providers/cart_provider.dart';
import 'package:ar_shop/providers/product_provider.dart';

void main() {
  setUpAll(() async {
    Hive.init('test_hive');
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CartItemAdapter());
    }
    await Hive.openBox<CartItem>('cartBox');
    await Hive.openBox<String>('arGalleryBox');
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('App boots smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => ARProvider()),
        ],
        child: const ARShopApp(),
      ),
    );

    expect(find.byType(ARShopApp), findsOneWidget);
  });
}

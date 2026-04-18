import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ar_shop/config/constants.dart';
import 'package:ar_shop/data/models/product_model.dart';
import 'package:ar_shop/providers/cart_provider.dart';
import 'package:ar_shop/screens/ar_view_screen.dart';
import 'package:ar_shop/screens/ar_try_on_screen.dart';
import 'package:ar_shop/screens/model_viewer_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _selectedColorName;

  @override
  void initState() {
    super.initState();
    if (widget.product.colors.isNotEmpty) {
      _selectedColorName = widget.product.colors.first.name;
    }
  }

  Future<void> _checkPermissionAndNavigate(Widget screen) async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Camera permission is required for AR features.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: _buildProductInfo(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Image.network(
          widget.product.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200]),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (widget.product.isAREnabled)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              backgroundColor: AppColors.arAccent.withValues(alpha: 0.9),
              label: const Text("AR Enabled", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              avatar: const Icon(Icons.view_in_ar, color: Colors.white, size: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildProductInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryBadge(),
          const SizedBox(height: 8),
          Text(
            widget.product.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildPriceRow(),
          const SizedBox(height: 24),
          _buildARButtonsSection(),
          const SizedBox(height: 24),
          _buildColorsSection(),
          const SizedBox(height: 24),
          _buildDescriptionSection(),
          const SizedBox(height: 24),
          _buildSpecificationsSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        widget.product.category,
        style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPriceRow() {
    return Row(
      children: [
        Text(
          "\$${widget.product.finalPrice.toStringAsFixed(2)}",
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        if (widget.product.discountPrice != null) ...[
          const SizedBox(width: 12),
          Text(
            "\$${widget.product.price.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 18, color: Colors.grey, decoration: TextDecoration.lineThrough),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
            child: Text("${widget.product.discountPercentage}% OFF", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ],
    );
  }

  Widget _buildARButtonsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("🥽 Try with AR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (widget.product.arType == ARType.placement)
          _buildARButton(
            icon: Icons.view_in_ar,
            label: AppStrings.viewInYourRoom,
            subtitle: "Place this item in your space using AR",
            color: AppColors.placementBtn,
            onTap: () => _checkPermissionAndNavigate(ARViewScreen(product: widget.product)),
          ),
        if (widget.product.arType == ARType.tryOn)
          _buildARButton(
            icon: Icons.face,
            label: AppStrings.virtualTryOn,
            subtitle: "See how it looks on you",
            color: AppColors.tryOnBtn,
            onTap: () => _checkPermissionAndNavigate(ARTryOnScreen(product: widget.product)),
          ),
        if (widget.product.arModelPath != null) ...[
          const SizedBox(height: 12),
          _buildARButton(
            icon: Icons.threed_rotation,
            label: AppStrings.viewIn3D,
            subtitle: "Rotate & zoom the 3D model",
            color: AppColors.threeDViewBtn,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ModelViewerScreen(product: widget.product))),
          ),
        ],
      ],
    );
  }

  Widget _buildARButton({required IconData icon, required String label, required String subtitle, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildColorsSection() {
    if (widget.product.colors.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Colors", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: widget.product.colors.map((c) {
            final isSelected = _selectedColorName == c.name;
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => setState(() => _selectedColorName = c.name),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: AppColors.primary, width: 3) : Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(c.name, style: TextStyle(fontSize: 10, color: isSelected ? AppColors.primary : Colors.grey)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Description", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(widget.product.description, style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.5)),
      ],
    );
  }

  Widget _buildSpecificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Specifications", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...widget.product.specs.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(child: Text(entry.key, style: const TextStyle(color: Colors.grey))),
                Expanded(child: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Total Price", style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text("\$${widget.product.finalPrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<CartProvider>().addItem(widget.product, color: _selectedColorName);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Added to cart!"),
                      action: SnackBarAction(label: "VIEW CART", onPressed: () => Navigator.pushNamed(context, '/cart')),
                    ),
                  );
                },
                icon: const Icon(Icons.shopping_cart),
                label: const Text(AppStrings.addToCart, style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

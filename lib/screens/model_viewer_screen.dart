import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';
import 'package:ar_shop/config/constants.dart';
import 'package:ar_shop/data/models/product_model.dart';
import 'package:ar_shop/providers/cart_provider.dart';

class ModelViewerScreen extends StatefulWidget {
  final Product product;

  const ModelViewerScreen({super.key, required this.product});

  @override
  State<ModelViewerScreen> createState() => _ModelViewerScreenState();
}

class _ModelViewerScreenState extends State<ModelViewerScreen> {
  bool _autoRotate = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        actions: [
          IconButton(
            icon: Icon(_autoRotate ? Icons.pause : Icons.play_arrow),
            onPressed: () => setState(() => _autoRotate = !_autoRotate),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey[100],
              child: widget.product.arModelPath != null
                  ? ModelViewer(
                      src: widget.product.arModelPath!,
                      alt: "A 3D model of ${widget.product.name}",
                      ar: false,
                      autoRotate: _autoRotate,
                      cameraControls: true,
                      backgroundColor: const Color.fromARGB(255, 240, 240, 240),
                    )
                  : const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.view_in_ar_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text("No 3D model available for this product",
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
            ),
          ),
          _buildInstructionsRow(),
          _buildProductInfoRow(context),
        ],
      ),
    );
  }

  Widget _buildInstructionsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _instructionItem(Icons.touch_app, "Rotate"),
          _instructionItem(Icons.pinch, "Zoom"),
          _instructionItem(Icons.swipe, "Pan"),
        ],
      ),
    );
  }

  Widget _instructionItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  Widget _buildProductInfoRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("\$${widget.product.finalPrice.toStringAsFixed(2)}", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                context.read<CartProvider>().addItem(widget.product);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to cart!")));
              },
              icon: const Icon(Icons.shopping_cart),
              label: const Text("Add to Cart"),
            ),
          ],
        ),
      ),
    );
  }
}

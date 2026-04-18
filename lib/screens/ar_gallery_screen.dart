import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ar_shop/providers/ar_provider.dart';
import 'package:ar_shop/config/constants.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class ARGalleryScreen extends StatelessWidget {
  const ARGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.arGallery),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
            onPressed: () => _showClearGalleryDialog(context),
          ),
        ],
      ),
      body: Consumer<ARProvider>(
        builder: (context, arProvider, child) {
          if (arProvider.screenshotPaths.isEmpty) {
            return _buildEmptyState();
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemCount: arProvider.screenshotPaths.length,
            itemBuilder: (context, index) {
              final path = arProvider.screenshotPaths[index];
              return _buildGalleryItem(context, path, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "No AR screenshots yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Take screenshots in AR view to see them here",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryItem(BuildContext context, String path, int index) {
    return GestureDetector(
      onTap: () => _showFullImage(context, path, index),
      child: Hero(
        tag: path,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.view_in_ar, color: AppColors.arAccent, size: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String path, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  Share.shareXFiles([XFile(path)], text: "Look at my AR furniture placement!");
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () {
                  final arProvider = context.read<ARProvider>();
                  final currentIndex = arProvider.screenshotPaths.indexOf(path);
                  if (currentIndex >= 0) {
                    arProvider.deleteScreenshot(currentIndex);
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          body: Center(
            child: Hero(
              tag: path,
              child: Image.file(File(path)),
            ),
          ),
        ),
      ),
    );
  }

  void _showClearGalleryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear Gallery"),
        content: const Text("Delete all saved AR screenshots?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              context.read<ARProvider>().clearGallery();
              Navigator.pop(context);
            },
            child: const Text("Clear All", style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

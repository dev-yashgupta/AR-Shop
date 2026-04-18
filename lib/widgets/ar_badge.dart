import 'package:flutter/material.dart';
import 'package:ar_shop/config/constants.dart';
import 'package:ar_shop/data/models/product_model.dart';

class ARBadge extends StatelessWidget {
  final ARType arType;

  const ARBadge({super.key, required this.arType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            arType == ARType.placement ? Icons.view_in_ar : Icons.face,
            color: AppColors.arAccent,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            arType == ARType.placement ? "AR" : "Try On",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

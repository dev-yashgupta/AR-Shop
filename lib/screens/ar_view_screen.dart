import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_shop/config/constants.dart';
import 'package:ar_shop/data/models/product_model.dart';
import 'package:ar_shop/providers/ar_provider.dart';
import 'package:ar_shop/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class ARViewScreen extends StatefulWidget {
  final Product product;

  const ARViewScreen({super.key, required this.product});

  @override
  State<ARViewScreen> createState() => _ARViewScreenState();
}

class _ARViewScreenState extends State<ARViewScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;
  
  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];
  
  bool _isPlaneDetected = false;
  bool _isModelLoading = false;
  String _instructionText = "📱 Move your phone slowly to scan the floor or surface";
  String? _arErrorText;
  
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Screenshot(
        controller: _screenshotController,
        child: Stack(
          children: [
            ARView(
              onARViewCreated: onARViewCreated,
              planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
            ),
            _buildTopBar(),
            _buildInstructions(),
            if (_isModelLoading) _buildLoading(),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager!.onError = (error) {
      if (!mounted) return;
      setState(() {
        _arErrorText = error;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    };

    this.arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: true,
      handlePans: true,
      handleRotation: true,
    );
    this.arObjectManager!.onInitialize();

    this.arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTap;

    // Update instruction when planes start appearing
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isPlaneDetected) {
        setState(() {
          _instructionText = "✋ Tap on a detected surface to place the model";
        });
      }
    });
  }

  Future<void> onPlaneOrPointTap(List<ARHitTestResult> hitTestResults) async {
    if (widget.product.arModelPath == null || widget.product.arModelPath!.isEmpty) {
      arSessionManager?.onError?.call("This product has no AR model configured.");
      return;
    }

    final planeHit = hitTestResults
        .where((hitTestResult) => hitTestResult.type == ARHitTestResultType.plane)
        .cast<ARHitTestResult?>()
        .firstWhere((hit) => hit != null, orElse: () => null);

    if (planeHit == null) {
      arSessionManager?.onError?.call("No plane detected yet. Move the phone slowly and try again.");
      return;
    }

    final manager = arAnchorManager;
    final objectManager = arObjectManager;
    if (manager == null || objectManager == null) {
      arSessionManager?.onError?.call("AR managers are not ready yet. Please retry.");
      return;
    }

    final newAnchor = ARPlaneAnchor(transformation: planeHit.worldTransform);
    final didAddAnchor = await manager.addAnchor(newAnchor);
    if (didAddAnchor != true) {
      arSessionManager?.onError?.call("Selected anchor could not be added.");
      return;
    }

    anchors.add(newAnchor);
    if (mounted) {
      setState(() {
        _isModelLoading = true;
      });
    }

    final newNode = ARNode(
      type: NodeType.webGLB,
      uri: widget.product.arModelPath!,
      scale: vector.Vector3(0.5, 0.5, 0.5),
      position: vector.Vector3(0, 0, 0),
      rotation: vector.Vector4(1, 0, 0, 0),
    );

    final didAddNodeToAnchor = await objectManager.addNode(newNode, planeAnchor: newAnchor);
    if (didAddNodeToAnchor == true) {
      nodes.add(newNode);
      if (mounted) {
        setState(() {
          _isModelLoading = false;
          _isPlaneDetected = true;
          _instructionText = "✅ Object placed! Use gestures to move, rotate or scale.";
          _arErrorText = null;
        });
      }

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _instructionText = "");
      });
      return;
    }

    arSessionManager?.onError?.call("Selected node could not be added to anchor.");
    if (mounted) {
      setState(() {
        _isModelLoading = false;
      });
    }
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.product.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _resetAR,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetAR() {
    if (arAnchorManager != null) {
      for (var anchor in anchors) {
        arAnchorManager!.removeAnchor(anchor);
      }
    }
    anchors.clear();
    nodes.clear();
    setState(() {
      _isPlaneDetected = false;
      _isModelLoading = false;
      _arErrorText = null;
      _instructionText = "📱 Move your phone slowly to scan the floor or surface";
    });
  }

  Widget _buildInstructions() {
    if (_instructionText.isEmpty) return const SizedBox();
    return Positioned(
      bottom: 180,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isPlaneDetected)
              const Icon(Icons.phone_android, color: AppColors.arAccent, size: 32),
            const SizedBox(height: 8),
            Text(
              _instructionText,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            if (_arErrorText != null) ...[
              const SizedBox(height: 8),
              Text(
                _arErrorText!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      color: Colors.black26,
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.arAccent),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.transparent],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTransformBtn(Icons.remove, _decreaseScale),
                const SizedBox(width: 16),
                _buildTransformBtn(Icons.rotate_right, _rotateModel),
                const SizedBox(width: 16),
                _buildTransformBtn(Icons.add, _increaseScale),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionBtn(Icons.camera_alt, "Capture", _takeScreenshot),
                _buildActionBtn(Icons.share, "Share", _shareAR),
                _buildActionBtn(Icons.shopping_cart, "Add to Cart", _addToCart, color: AppColors.arAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransformBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, VoidCallback onTap, {Color color = Colors.white}) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: color, size: 28),
          onPressed: onTap,
        ),
        Text(label, style: TextStyle(color: color, fontSize: 10)),
      ],
    );
  }

  void _increaseScale() {
    if (nodes.isNotEmpty) {
      final lastNode = nodes.last;
      final current = lastNode.scale;
      lastNode.scale = vector.Vector3(
        current.x + 0.1,
        current.y + 0.1,
        current.z + 0.1,
      );
    }
  }

  void _decreaseScale() {
    if (nodes.isNotEmpty) {
      final lastNode = nodes.last;
      final current = lastNode.scale;
      if (current.x > 0.15) {
        lastNode.scale = vector.Vector3(
          current.x - 0.1,
          current.y - 0.1,
          current.z - 0.1,
        );
      }
    }
  }

  void _rotateModel() {
    if (nodes.isNotEmpty) {
      final lastNode = nodes.last;
      final currentAngles = lastNode.eulerAngles;
      lastNode.eulerAngles = vector.Vector3(
        currentAngles.x,
        currentAngles.y + 0.785,
        currentAngles.z,
      );
    }
  }

  Future<void> _takeScreenshot() async {
    final image = await _screenshotController.capture();
    if (image != null) {
      final result = await ImageGallerySaverPlus.saveImage(image);
      if (result['isSuccess']) {
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = '${directory.path}/ar_screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(image);
        
        if (mounted) {
          context.read<ARProvider>().addScreenshot(imagePath);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Screenshot saved to gallery!")),
          );
        }
      }
    }
  }

  Future<void> _shareAR() async {
    final image = await _screenshotController.capture();
    if (image != null) {
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/share_ar.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(image);
      
      await Share.shareXFiles([XFile(imagePath)], text: "Check out this ${widget.product.name} in my room!");
    }
  }

  void _addToCart() {
    context.read<CartProvider>().addItem(widget.product);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Added to cart!")),
    );
  }
}

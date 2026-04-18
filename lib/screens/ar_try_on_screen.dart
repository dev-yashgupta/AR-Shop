import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';
import 'package:ar_shop/config/constants.dart';
import 'package:ar_shop/data/models/product_model.dart';
import 'package:ar_shop/providers/cart_provider.dart';
import 'package:ar_shop/providers/ar_provider.dart';
import 'package:ar_shop/providers/product_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class ARTryOnScreen extends StatefulWidget {
  final Product product;

  const ARTryOnScreen({super.key, required this.product});

  @override
  State<ARTryOnScreen> createState() => _ARTryOnScreenState();
}

class _ARTryOnScreenState extends State<ARTryOnScreen> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isBusy = false;
  List<Face> _faces = [];
  late Product _currentProduct;
  
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _initializeCamera();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableContours: true,
        enableClassification: false,
        enableTracking: true,
        minFaceSize: 0.15,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      debugPrint("No cameras available");
      return;
    }
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;
      await _cameraController!.startImageStream(_processCameraImage);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  void _processCameraImage(CameraImage image) async {
    if (_isBusy) return;
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    _isBusy = true;

    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final camera = _cameraController!.description;
      final imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;
      final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

      final inputImageData = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
      final faces = await _faceDetector!.processImage(inputImage);

      if (mounted) {
        setState(() {
          _faces = faces;
        });
      }
    } catch (e) {
      debugPrint("Face Detection Error: $e");
    } finally {
      _isBusy = false;
    }
  }

  @override
  void dispose() {
    _isBusy = false;
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      _cameraController!.stopImageStream();
    }
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Screenshot(
        controller: _screenshotController,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(_cameraController!),
            if (_faces.isNotEmpty) _buildGlassesOverlay(),
            if (_faces.isEmpty) _buildNoFaceDetectedOverlay(),
            _buildTopBar(),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassesOverlay() {
    if (_currentProduct.tryOnImagePath == null) return const SizedBox();
    final face = _faces.first;
    final leftEye  = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    if (leftEye == null || rightEye == null) return const SizedBox();

    final screenSize  = MediaQuery.of(context).size;
    final previewSize = _cameraController!.value.previewSize!;
    final isFront     = _cameraController!.description.lensDirection == CameraLensDirection.front;

    // Camera image coords → screen coords
    // previewSize.width  = image height (landscape sensor)
    // previewSize.height = image width  (landscape sensor)
    double scaleX = screenSize.width  / previewSize.height;
    double scaleY = screenSize.height / previewSize.width;

    double mapX(double x) {
      final scaled = x * scaleX;
      return isFront ? screenSize.width - scaled : scaled;
    }
    double mapY(double y) => y * scaleY;

    final lx = mapX(leftEye.position.x.toDouble());
    final ly = mapY(leftEye.position.y.toDouble());
    final rx = mapX(rightEye.position.x.toDouble());
    final ry = mapY(rightEye.position.y.toDouble());

    // Centre between eyes
    final cx = (lx + rx) / 2;
    final cy = (ly + ry) / 2;

    // Eye-to-eye distance in screen pixels
    final eyeDist = (rx - lx).abs();

    // Glasses image is 800×280 — width covers ~2.8× eye distance for a natural fit
    final glassesW = (eyeDist * 2.8).clamp(90.0, screenSize.width * 0.85);
    // Maintain 800:280 aspect ratio
    final glassesH = glassesW * (280 / 800);

    // Head tilt angle (Z rotation) — negate for front camera mirror
    final tiltRad = ((face.headEulerAngleZ ?? 0) * (3.14159265 / 180)) * (isFront ? 1 : -1);

    return Positioned(
      left: cx - glassesW / 2,
      // Shift up slightly so bridge sits on nose, not below eyes
      top:  cy - glassesH * 0.55,
      child: Transform.rotate(
        angle: tiltRad,
        child: Image.asset(
          _currentProduct.tryOnImagePath!,
          width:  glassesW,
          height: glassesH,
          fit: BoxFit.fill,
          errorBuilder: (_, __, ___) => SizedBox(
            width: glassesW, height: glassesH,
            child: const Center(
              child: Icon(Icons.remove_red_eye, color: Colors.white70, size: 32),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoFaceDetectedOverlay() {
    return Container(
      color: Colors.black45,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.face, color: AppColors.arAccent, size: 64),
            SizedBox(height: 16),
            Text(
              "Position your face in the camera",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
              child: Row(
                children: [
                  const Icon(Icons.face, color: AppColors.arAccent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _currentProduct.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 40), // Placeholder for balance
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.transparent],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Column(
          children: [
            _buildGlassesSwitcher(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionBtn(Icons.camera_alt, "Capture", _takeScreenshot),
                _buildActionBtn(Icons.share, "Share", _shareTryOn),
                _buildActionBtn(Icons.shopping_cart, "Add to Cart", _addToCart, color: AppColors.arAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassesSwitcher() {
    // Filter all glasses products — use Consumer to safely read inside build
    final glasses = context.watch<ProductProvider>().products.where((p) => p.isTryOnEnabled).toList();
    
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: glasses.length,
        itemBuilder: (context, index) {
          final product = glasses[index];
          final isSelected = _currentProduct.id == product.id;
          return GestureDetector(
            onTap: () => setState(() => _currentProduct = product),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.arAccent.withValues(alpha: 0.2) : Colors.black45,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.arAccent : Colors.white24,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    product.imageUrl,
                    height: 40,
                    errorBuilder: (c, e, s) => const Icon(Icons.remove_red_eye, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name.split(' ').last,
                    style: TextStyle(color: isSelected ? AppColors.arAccent : Colors.white, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
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

  Future<void> _takeScreenshot() async {
    final image = await _screenshotController.capture();
    if (image != null) {
      final result = await ImageGallerySaverPlus.saveImage(image);
      if (result['isSuccess']) {
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = '${directory.path}/tryon_screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(image);
        
        if (mounted) {
          context.read<ARProvider>().addScreenshot(imagePath);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Try-On saved to gallery!")));
        }
      }
    }
  }

  Future<void> _shareTryOn() async {
    final image = await _screenshotController.capture();
    if (image != null) {
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/share_tryon.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(image);
      await Share.shareXFiles([XFile(imagePath)], text: "How do these ${_currentProduct.name} look on me?");
    }
  }

  void _addToCart() {
    context.read<CartProvider>().addItem(_currentProduct);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to cart!")));
  }
}

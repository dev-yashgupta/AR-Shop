# AR Shop — Augmented Reality Shopping App

A full-featured AR shopping app built with Flutter that lets users **try before they buy** using Augmented Reality. Place furniture in your room, virtually try on glasses, and view products in interactive 3D — all from your phone.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots & Screens](#screenshots--screens)
- [AR Technology](#ar-technology)
- [Product Catalog](#product-catalog)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Dependencies](#dependencies)
- [Data Models](#data-models)
- [State Management](#state-management)
- [Screens & Navigation](#screens--navigation)
- [Permissions](#permissions)
- [Build & Run](#build--run)
- [Release APK](#release-apk)
- [Known Limitations](#known-limitations)

---

## Overview

AR Shop bridges the gap between online shopping and the physical experience of trying a product. Instead of guessing whether a sofa fits your living room or whether sunglasses suit your face, users can:

- **Place furniture** in their real environment using ARCore plane detection
- **Try on glasses** live using the front camera and ML face detection
- **Spin and zoom** any product in a full 3D viewer
- **Save and share** AR screenshots to a personal gallery

The app targets Android (API 28+) and is built entirely in Flutter/Dart with a clean Provider-based architecture.

---

## Features

### AR Placement (Furniture & Decor)
- Real-time horizontal and vertical plane detection via ARCore
- Tap any detected surface to place a 3D model
- Scale up/down with on-screen controls
- Rotate model 45° per tap
- Reset placement and re-scan at any time
- Capture screenshot of the AR scene

### Virtual Try-On (Eyewear)
- Live front-camera feed with real-time face detection
- Eye landmark tracking (left eye, right eye positions)
- Glasses overlay auto-scales to eye distance
- Head tilt tracking — overlay rotates with your head
- Switch between all 6 glasses styles without leaving the screen
- Capture and save try-on photos

### 3D Model Viewer
- Interactive WebGL-based 3D viewer (model-viewer)
- Auto-rotate toggle
- Full camera controls — rotate, zoom, pan
- Works for all furniture products

### Shopping Cart
- Add products with selected color variant
- Increment / decrement quantities
- Persistent cart storage (survives app restarts via Hive)
- Clear cart with confirmation dialog
- Checkout demo flow

### AR Gallery
- All captured AR and try-on screenshots saved locally
- Full-screen image viewer with Hero animation
- Share individual photos
- Delete individual or all screenshots

### Product Browsing
- Grid layout with AR/Try-On badge indicators
- Category filter chips (All, Furniture, Lighting, Decor, Eyewear)
- Real-time search by product name
- Discount percentage badges
- Product detail page with specs, colors, and all AR options

---

## Screenshots & Screens

| Screen | Description |
|---|---|
| Home | Product grid with search, category filter, AR banner |
| Product Detail | Full info, color picker, AR action buttons, specs |
| AR View | ARCore placement — scan floor, tap to place model |
| AR Try-On | Front camera + face detection + glasses overlay |
| 3D Viewer | Interactive model-viewer with rotate/zoom/pan |
| Cart | Item list, quantity controls, total, checkout |
| AR Gallery | Grid of saved AR screenshots with share/delete |

---

## AR Technology

### Furniture Placement — ARCore
The app uses `ar_flutter_plugin_2` which wraps Google ARCore on Android.

**How it works:**
1. `ARView` widget initialises an ARCore session
2. `PlaneDetectionConfig.horizontalAndVertical` scans for flat surfaces
3. When the user taps a detected plane, an `ARPlaneAnchor` is created at the hit point
4. An `ARNode` of type `NodeType.webGLB` loads the `.glb` model from a remote URL
5. The node is attached to the anchor so it stays fixed in world space
6. Scale and rotation are applied via `Vector3` / `Vector3` euler angles

**3D Models** are hosted on the Khronos glTF Sample Models repository and loaded over HTTPS at runtime. No local model files are bundled.

### Virtual Try-On — ML Kit Face Detection
The try-on screen uses `google_mlkit_face_detection` with the front camera.

**Pipeline:**
1. `CameraController` streams `CameraImage` frames from the front camera
2. Each frame is converted to `InputImage` with correct rotation metadata
3. `FaceDetector` runs with `enableLandmarks: true` and `enableTracking: true`
4. `FaceLandmarkType.leftEye` and `rightEye` positions are extracted
5. Camera image coordinates are mapped to screen coordinates accounting for:
   - Sensor orientation vs display orientation
   - Front camera X-axis mirror flip
   - Preview size vs screen size scaling
6. Eye distance determines glasses width (2.8× eye distance)
7. `headEulerAngleZ` drives `Transform.rotate` for head tilt tracking
8. Glasses PNG overlay is rendered as a `Positioned` widget on top of `CameraPreview`

### 3D Viewer — model-viewer
Uses `model_viewer_plus` which embeds Google's `<model-viewer>` web component inside a `WebView`. Supports:
- glTF Binary (`.glb`) format
- Auto-rotate animation
- Camera orbit controls
- Custom background color

---

## Product Catalog

### Furniture (10 products)
| ID | Name | Category | 3D Model |
|---|---|---|---|
| fur_001 | Modern Lounge Chair | Furniture / Chairs | SheenChair.glb |
| fur_002 | 3-Seater Leather Sofa | Furniture / Sofas | GlamVelvetSofa.glb |
| fur_003 | Oak Dining Table | Furniture / Tables | ToyCar.glb |
| fur_004 | Minimalist Floor Lamp | Lighting / Floor Lamps | IridescenceLamp.glb |
| fur_005 | Industrial Bookshelf | Furniture / Storage | ReciprocatingSaw.glb |
| fur_006 | Entertainment TV Stand | Furniture / TV Stands | BoxTextured.glb |
| fur_007 | Platform Bed Frame | Furniture / Beds | SheenChair.glb |
| fur_008 | Standing Office Desk | Furniture / Desks | BoomBox.glb |
| fur_009 | Ceramic Plant Pot Set | Decor / Plant Pots | Avocado.glb |
| fur_010 | Handwoven Area Rug | Decor / Rugs | TextureCoordinateTest.glb |

### Eyewear (6 products)
| ID | Name | Style | Try-On Asset |
|---|---|---|---|
| gls_001 | Classic Aviator | Sunglasses | aviator.png |
| gls_002 | Retro Round Frames | Optical | round.png |
| gls_003 | Bold Wayfarer | Sunglasses | wayfarer.png |
| gls_004 | Cat Eye Elegance | Optical | cateye.png |
| gls_005 | Sport Wraparound | Sport | sport.png |
| gls_006 | Oversized Glamour | Sunglasses | oversized.png |

All 3D model URLs are verified working. All product images are sourced from Unsplash (topic-specific, not random placeholders).

---

## Architecture

```
Presentation Layer  →  Screens + Widgets
State Layer         →  Provider (ChangeNotifier)
Data Layer          →  Dummy data + Hive persistence
```

The app follows a simple **unidirectional data flow**:

```
User Action → Provider method → State update → Widget rebuild
```

No backend or API — all product data is defined in `lib/data/dummy_products.dart`. Cart and AR gallery are persisted locally with Hive.

---

## Project Structure

```
lib/
├── main.dart                    # Entry point — Hive init, Provider setup
├── app.dart                     # MaterialApp, theme, routes
│
├── config/
│   ├── constants.dart           # AppColors, AppStrings
│   └── theme.dart               # Material 3 theme, Poppins font
│
├── data/
│   ├── dummy_products.dart      # 16 product definitions
│   └── models/
│       ├── product_model.dart   # Product, ProductColor, ARType
│       ├── cart_item_model.dart # CartItem (Hive HiveObject)
│       └── cart_item_model.g.dart # Hive generated adapter
│
├── providers/
│   ├── product_provider.dart    # Product list, category filter, search
│   ├── cart_provider.dart       # Cart CRUD, quantity, total
│   └── ar_provider.dart         # AR screenshot gallery (Hive)
│
├── screens/
│   ├── home_screen.dart         # Product grid, search, categories
│   ├── product_detail_screen.dart # Detail view, AR buttons, color picker
│   ├── ar_view_screen.dart      # ARCore placement screen
│   ├── ar_try_on_screen.dart    # Face detection try-on screen
│   ├── model_viewer_screen.dart # 3D model viewer
│   ├── cart_screen.dart         # Shopping cart
│   └── ar_gallery_screen.dart   # Saved AR screenshots
│
├── widgets/
│   ├── product_card.dart        # Grid card with AR badge
│   ├── ar_badge.dart            # AR / Try-On indicator chip
│   ├── category_chip.dart       # Filter chip
│   └── quantity_button.dart     # +/- quantity control
│
└── utils/
    └── helpers.dart             # Price formatting, discount string

assets/
├── models/                      # (empty — models loaded from URLs)
├── tryons/                      # 6 glasses PNG overlays
│   ├── aviator.png
│   ├── round.png
│   ├── wayfarer.png
│   ├── cateye.png
│   ├── sport.png
│   └── oversized.png
├── images/
│   ├── products/                # (empty — images loaded from Unsplash URLs)
│   └── banners/
└── animations/                  # Lottie animation files

android/
├── app/
│   ├── build.gradle.kts         # compileSdk 36, signing config, minSdk 28
│   ├── proguard-rules.pro       # R8 keep rules for AR/ML plugins
│   └── src/main/
│       └── AndroidManifest.xml  # Permissions, ARCore optional metadata
├── build.gradle.kts             # Root — subproject compileSdk override
└── key.properties               # Signing credentials (gitignored)
```

---

## Dependencies

### Core
| Package | Version | Purpose |
|---|---|---|
| `flutter` | SDK | UI framework |
| `provider` | ^6.1.1 | State management |
| `google_fonts` | ^6.1.0 | Poppins font family |

### AR & Camera
| Package | Version | Purpose |
|---|---|---|
| `ar_flutter_plugin_2` | ^0.0.3 | ARCore plane detection & model placement |
| `model_viewer_plus` | ^1.7.0 | WebGL 3D model viewer |
| `google_mlkit_face_detection` | ^0.9.0 | Real-time face landmark detection |
| `camera` | ^0.10.5+9 | Camera stream for try-on |

### Storage & Data
| Package | Version | Purpose |
|---|---|---|
| `hive` | ^2.2.3 | Local NoSQL database |
| `hive_flutter` | ^1.1.0 | Hive Flutter integration |
| `path_provider` | ^2.1.2 | App document/temp directories |

### Media & Sharing
| Package | Version | Purpose |
|---|---|---|
| `screenshot` | ^3.0.0 | Capture AR scene as image |
| `image_gallery_saver_plus` | ^4.0.1 | Save screenshots to device gallery |
| `share_plus` | ^7.2.1 | Share images via system share sheet |

### Utilities
| Package | Version | Purpose |
|---|---|---|
| `permission_handler` | ^11.4.0 | Runtime camera permission requests |
| `lottie` | ^2.7.0 | Lottie animation support |
| `intl` | ^0.19.0 | Number/currency formatting |
| `vector_math` | any | 3D vector math for AR node transforms |
| `cupertino_icons` | ^1.0.6 | iOS-style icons |

### Dev Dependencies
| Package | Version | Purpose |
|---|---|---|
| `hive_generator` | ^2.0.1 | Code generation for Hive adapters |
| `build_runner` | ^2.4.8 | Dart code generation runner |
| `flutter_lints` | ^3.0.0 | Lint rules |

---

## Data Models

### Product
```dart
class Product {
  final String id;           // e.g. "fur_001", "gls_003"
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final String category;     // "Furniture", "Eyewear", "Decor", "Lighting"
  final String subCategory;
  final String? arModelPath; // HTTPS URL to .glb file (furniture only)
  final String? tryOnImagePath; // Asset path to PNG overlay (glasses only)
  final String imageUrl;     // Unsplash HTTPS URL
  final List<ProductColor> colors;
  final Map<String, String> specs;
  final bool isAREnabled;
  final bool isTryOnEnabled;
  final ARType arType;       // ARType.placement | ARType.tryOn
}
```

### ARType Enum
```dart
enum ARType {
  placement,  // Furniture — uses ARCore + glTF model
  tryOn,      // Glasses — uses ML Kit + PNG overlay
}
```

### CartItem (Hive)
```dart
@HiveType(typeId: 0)
class CartItem extends HiveObject {
  String id;
  String name;
  double price;
  String imageUrl;
  int quantity;
  String? selectedColor;
}
```

---

## State Management

Three `ChangeNotifier` providers registered at app root:

### ProductProvider
- Holds the full product list from `dummyProducts`
- Exposes filtered list based on `selectedCategory` and `searchQuery`
- Methods: `setCategory()`, `setSearchQuery()`

### CartProvider
- Reads/writes `CartItem` objects to Hive `cartBox`
- Handles duplicate detection by `id + selectedColor`
- Methods: `addItem()`, `removeItem()`, `incrementQuantity()`, `decrementQuantity()`, `clearCart()`
- Computed: `totalAmount`, `itemCount`

### ARProvider
- Stores screenshot file paths in Hive `arGalleryBox`
- Methods: `addScreenshot()`, `deleteScreenshot()`, `clearGallery()`
- Deletes physical files on disk when removing entries

---

## Screens & Navigation

```
HomeScreen
    └── ProductDetailScreen
            ├── ARViewScreen          (ARType.placement)
            ├── ARTryOnScreen         (ARType.tryOn)
            └── ModelViewerScreen     (arModelPath != null)

HomeScreen (AppBar)
    ├── CartScreen
    └── ARGalleryScreen
```

Navigation uses `Navigator.push` with `MaterialPageRoute` throughout. Named routes (`/cart`, `/gallery`) are also registered for SnackBar action shortcuts.

---

## Permissions

| Permission | Platform | When Requested |
|---|---|---|
| `CAMERA` | Android | Before opening AR View or Try-On screen |
| `INTERNET` | Android | Always (for model URLs and product images) |
| `READ_MEDIA_IMAGES` | Android 13+ (API 33+) | Saving screenshots to gallery |
| `WRITE_EXTERNAL_STORAGE` | Android ≤ 12 (API ≤ 32) | Saving screenshots to gallery |
| `READ_EXTERNAL_STORAGE` | Android ≤ 12 (API ≤ 32) | Reading saved images |

ARCore is declared as **optional** (`android:required="false"`) so the app installs on non-ARCore devices — AR placement simply won't be available on those devices.

---

## Build & Run

### Requirements
- Flutter 3.x (tested on 3.41.6)
- Dart 3.x
- Android SDK 36
- Android NDK (version from flutter.ndkVersion)
- Java 17+
- Device: Android 9.0+ (API 28+) for AR features

### Setup
```bash
# Clone the repo
git clone <repo-url>
cd ar_shop

# Install dependencies
flutter pub get

# Run on connected device (debug)
flutter run
```

### Regenerate Hive Adapters (if models change)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Release APK

### Signing Setup
The release keystore is at `android/app/ar_shop_release.jks` and credentials are in `android/key.properties` (gitignored).

`android/key.properties`:
```
storePassword=<your-password>
keyPassword=<your-password>
keyAlias=ar_shop
storeFile=ar_shop_release.jks
```

### Build
```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Build Split APKs (smaller download per ABI)
```bash
flutter build apk --release --split-per-abi
```

This produces separate APKs for `arm64-v8a`, `armeabi-v7a`, and `x86_64`.

---

## Known Limitations

| Area | Limitation |
|---|---|
| AR Placement | Requires ARCore-compatible device (most Android phones from 2018+) |
| AR Placement | 3D models are loaded over network — requires internet connection |
| Try-On accuracy | Face landmark mapping is approximate; accuracy varies with lighting and camera angle |
| Try-On assets | Glasses overlays are vector-drawn PNGs — not photorealistic renders |
| 3D Models | Using Khronos glTF sample models as stand-ins — not actual product models |
| Product data | All product data is hardcoded in `dummy_products.dart` — no backend |
| Cart | No real payment or checkout integration — demo only |
| iOS | Not configured — ARKit setup and iOS signing required for iOS builds |
| Minification | R8 minification disabled in release build due to AR/ML plugin compatibility |

---

## Color Palette

| Name | Hex | Usage |
|---|---|---|
| Primary | `#6C63FF` | Buttons, selected states, prices |
| Secondary | `#FF6584` | Try-On button, accents |
| AR Accent | `#00CEFF` | AR badges, icons |
| Success | `#00B894` | 3D View button |
| Error | `#FF7675` | Delete actions |
| Background | `#F8F9FA` | App background |
| Surface | `#FFFFFF` | Cards, sheets |

---

## License

This project is for educational and demonstration purposes.  
3D models are from the [Khronos glTF Sample Models](https://github.com/KhronosGroup/glTF-Sample-Models) repository (licensed under CC BY 4.0).  
Product images are from [Unsplash](https://unsplash.com) (Unsplash License).

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

class ARProvider with ChangeNotifier {
  static const String _boxName = 'arGalleryBox';
  Box<String>? _galleryBox;

  ARProvider() {
    _initHive();
  }

  Future<void> _initHive() async {
    _galleryBox = await Hive.openBox<String>(_boxName);
    notifyListeners();
  }

  List<String> get screenshotPaths => _galleryBox?.values.toList() ?? [];

  void addScreenshot(String path) {
    _galleryBox?.add(path);
    notifyListeners();
  }

  void deleteScreenshot(int index) {
    final path = _galleryBox?.getAt(index);
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
      _galleryBox?.deleteAt(index);
      notifyListeners();
    }
  }

  void clearGallery() {
    for (var path in screenshotPaths) {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    _galleryBox?.clear();
    notifyListeners();
  }
}

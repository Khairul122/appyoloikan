import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import '../models/detection_result.dart';
import '../utils/constants.dart';

enum MLPackage {
  flutterVision,
  ultralytics,
}

abstract class MLInferenceService {
  Future<void> loadModel();
  Future<List<DetectionResult>> detectObjects(File imageFile);
  void dispose();
}


class FlutterVisionService implements MLInferenceService {
  FlutterVision? _vision;
  bool _isModelLoaded = false;

  @override
  Future<void> loadModel() async {
    try {
      _vision = FlutterVision();
      await _vision!.loadYoloModel(
        modelPath: AppConstants.modelPath,
        modelVersion: "yolov8",
        numThreads: 4,
        useGpu: false,
        labels: AppConstants.labelsPath,
      );
      _isModelLoaded = true;
      debugPrint('FlutterVision YOLOv8n model loaded successfully');
    } catch (e) {
      debugPrint('FlutterVision model loading failed: $e');
      throw Exception('Failed to load FlutterVision model: $e');
    }
  }

  @override
  Future<List<DetectionResult>> detectObjects(File imageFile) async {
    if (!_isModelLoaded || _vision == null) {
      throw Exception('Model not loaded');
    }

    try {
      final results = await _vision!.yoloOnImage(
        bytesList: await imageFile.readAsBytes(),
        imageHeight: 640,
        imageWidth: 640,
        iouThreshold: 0.5,
        confThreshold: 0.1,
        classThreshold: 0.1,
      );

      return results.map<DetectionResult>((result) {
        final box = result['box'] as List<dynamic>;
        return DetectionResult(
          boundingBox: Rect.fromLTWH(
            (box[0] as num).toDouble(),
            (box[1] as num).toDouble(),
            (box[2] as num).toDouble(),
            (box[3] as num).toDouble(),
          ),
          className: result['tag'] as String,
          confidence: (box[4] as num).toDouble(),
          classIndex: results.indexOf(result),
        );
      }).toList();
    } catch (e) {
      debugPrint('FlutterVision detection error: $e');
      throw Exception('Detection failed: $e');
    }
  }

  @override
  void dispose() {
    _vision?.closeYoloModel();
    _vision = null;
    _isModelLoaded = false;
  }
}

class UltralyticsService implements MLInferenceService {
  bool _isModelLoaded = false;

  @override
  Future<void> loadModel() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _isModelLoaded = true;
      debugPrint('Ultralytics YOLO model loaded successfully (placeholder)');
    } catch (e) {
      debugPrint('Ultralytics model loading failed: $e');
      throw Exception('Failed to load Ultralytics model: $e');
    }
  }

  @override
  Future<List<DetectionResult>> detectObjects(File imageFile) async {
    if (!_isModelLoaded) {
      throw Exception('Model not loaded');
    }

    try {
      // Placeholder implementation
      // This would use actual Ultralytics YOLO inference
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Return empty results for now
      return [];
    } catch (e) {
      debugPrint('Ultralytics detection error: $e');
      throw Exception('Detection failed: $e');
    }
  }

  @override
  void dispose() {
    _isModelLoaded = false;
  }
}

class MLInferenceManager {
  static MLInferenceService? _currentService;
  static MLPackage _currentPackage = MLPackage.flutterVision;

  static MLInferenceService get service {
    _currentService ??= _createService(_currentPackage);
    return _currentService!;
  }

  static Future<void> switchPackage(MLPackage package) async {
    if (_currentPackage == package && _currentService != null) return;

    _currentService?.dispose();
    _currentService = null;
    _currentPackage = package;
    _currentService = _createService(package);
    await _currentService!.loadModel();
  }

  static MLInferenceService _createService(MLPackage package) {
    switch (package) {
      case MLPackage.flutterVision:
        return FlutterVisionService();
      case MLPackage.ultralytics:
        return UltralyticsService();
    }
  }

  static Future<void> initialize([MLPackage? package]) async {
    if (package != null) {
      await switchPackage(package);
    } else {
      await service.loadModel();
    }
  }

  static void dispose() {
    _currentService?.dispose();
    _currentService = null;
  }
}
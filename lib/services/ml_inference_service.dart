import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import '../models/detection_result.dart';
import '../models/enhanced_detection_result.dart';
import '../utils/constants.dart';
import 'enhanced_detection_service.dart';

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
  static EnhancedDetectionService? _enhancedService;

  static MLInferenceService get service {
    _currentService ??= _createService(_currentPackage);
    return _currentService!;
  }

  static EnhancedDetectionService get enhancedService {
    _enhancedService ??= EnhancedDetectionService();
    return _enhancedService!;
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

    // Initialize enhanced detection service
    debugPrint('Initializing enhanced detection service...');
  }

  // Enhanced detection methods
  static Future<List<EnhancedDetectionResult>> detectWithEnhancedAnalysis(
    File imageFile, {
    bool useAdvancedAnalysis = true,
    bool enableRealtimeMode = false,
  }) async {
    try {
      // First, perform basic YOLO detection
      List<DetectionResult> basicDetections = await service.detectObjects(imageFile);

      if (basicDetections.isEmpty) {
        debugPrint('No objects detected, returning empty enhanced results');
        return [];
      }

      List<EnhancedDetectionResult> enhancedResults = [];

      // Configure enhanced service settings
      enhancedService.enableRealtimeMode = enableRealtimeMode;
      enhancedService.enableAdvancedAnalysis = useAdvancedAnalysis;

      // Process each detection with enhanced analysis
      for (DetectionResult detection in basicDetections) {
        try {
          EnhancedDetectionResult enhancedResult = await enhancedService.detectWithMediaAnalysis(
            imageFile,
            detection,
            useAdvancedAnalysis: useAdvancedAnalysis,
          );
          enhancedResults.add(enhancedResult);
        } catch (e) {
          debugPrint('Error in enhanced analysis for detection ${detection.className}: $e');
          // Continue with other detections even if one fails
        }
      }

      debugPrint('Enhanced analysis completed for ${enhancedResults.length} detections');
      return enhancedResults;

    } catch (e) {
      debugPrint('Error in enhanced detection: $e');
      throw Exception('Enhanced detection failed: $e');
    }
  }

  // Batch enhanced detection
  static Future<List<EnhancedDetectionResult>> detectBatchEnhanced(
    List<File> imageFiles, {
    bool useAdvancedAnalysis = true,
    int? batchSize,
  }) async {
    try {
      List<List<DetectionResult>> allBasicDetections = [];

      // Perform basic detection on all images first
      for (File imageFile in imageFiles) {
        List<DetectionResult> detections = await service.detectObjects(imageFile);
        allBasicDetections.add(detections);
      }

      List<EnhancedDetectionResult> allEnhancedResults = [];

      // Process each image with enhanced analysis
      for (int i = 0; i < imageFiles.length; i++) {
        File imageFile = imageFiles[i];
        List<DetectionResult> basicDetections = allBasicDetections[i];

        if (basicDetections.isNotEmpty) {
          for (DetectionResult detection in basicDetections) {
            try {
              EnhancedDetectionResult enhancedResult = await enhancedService.detectWithMediaAnalysis(
                imageFile,
                detection,
                useAdvancedAnalysis: useAdvancedAnalysis,
              );
              allEnhancedResults.add(enhancedResult);
            } catch (e) {
              debugPrint('Error in enhanced batch analysis for image ${i + 1}: $e');
            }
          }
        }
      }

      return allEnhancedResults;

    } catch (e) {
      debugPrint('Error in batch enhanced detection: $e');
      throw Exception('Batch enhanced detection failed: $e');
    }
  }

  // Quick detection with basic confidence analysis only
  static Future<List<EnhancedDetectionResult>> detectQuick(
    File imageFile,
  ) async {
    return await detectWithEnhancedAnalysis(
      imageFile,
      useAdvancedAnalysis: false,
      enableRealtimeMode: true,
    );
  }

  // Performance monitoring
  static Map<String, dynamic> getPerformanceMetrics() {
    return {
      'ml_package': _currentPackage.toString(),
      'ml_service_loaded': _currentService != null,
      'enhanced_service_loaded': _enhancedService != null,
      'enhanced_service_metrics': _enhancedService?.getPerformanceMetrics() ?? {},
      'enhanced_service_status': _enhancedService?.getSystemStatus() ?? {},
    };
  }

  // Settings management for enhanced detection
  static void updateEnhancedSettings({
    bool? enableAdvancedAnalysis,
    bool? enableCaching,
    Duration? analysisTimeout,
    bool? enableRealtimeMode,
  }) {
    enhancedService.updateSettings(
      enableAdvancedAnalysis: enableAdvancedAnalysis,
      enableCaching: enableCaching,
      analysisTimeout: analysisTimeout,
      enableRealtimeMode: enableRealtimeMode,
    );
  }

  // Session management
  static List<EnhancedDetectionResult> getSessionHistory() {
    return enhancedService.getSessionHistory();
  }

  static Map<String, dynamic> getSessionStatistics() {
    return enhancedService.getSessionStatistics();
  }

  static void clearSessionHistory() {
    enhancedService.clearSessionHistory();
  }

  // Cache management
  static void clearCache() {
    enhancedService.clearCache();
  }

  static Map<String, dynamic> getCacheStatus() {
    return enhancedService.getCacheStatus();
  }

  // Export functionality
  static Map<String, dynamic> exportResults() {
    return enhancedService.exportResults();
  }

  static void dispose() {
    _currentService?.dispose();
    _currentService = null;
    _enhancedService?.dispose();
    _enhancedService = null;
    debugPrint('MLInferenceManager disposed');
  }
}
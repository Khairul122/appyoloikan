import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../models/detection_result.dart';
import '../utils/constants.dart';

class MLService {
  static final MLService _instance = MLService._internal();
  factory MLService() => _instance;
  MLService._internal();

  bool _isModelLoaded = false;

  Future<void> loadModel() async {
    try {
      _isModelLoaded = true;
      await _loadLabels();
      debugPrint('ML Service initialized: $_isModelLoaded');
    } catch (e) {
      throw Exception('Failed to load model: $e');
    }
  }

  Future<void> _loadLabels() async {
    await AppConstants.loadLabels();
  }

  Future<List<DetectionResult>> detectObjects(List<int> imageBytes) async {
    if (!_isModelLoaded) {
      throw Exception('Model not loaded');
    }

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      debugPrint('ML Service placeholder - no detections');
      return <DetectionResult>[];
    } catch (e) {
      debugPrint('ML Service detection error: $e');
      throw Exception('Detection failed: $e');
    }
  }

  List<DetectionResult> _applyNMS(List<DetectionResult> detections) {
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    final selected = <DetectionResult>[];
    final suppressed = <bool>[];
    
    for (int i = 0; i < detections.length; i++) {
      suppressed.add(false);
    }

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;
      
      selected.add(detections[i]);
      
      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;
        
        final iou = _calculateIoU(detections[i].boundingBox, detections[j].boundingBox);
        if (iou > AppConstants.iouThreshold) {
          suppressed[j] = true;
        }
      }
    }

    return selected;
  }

  double _calculateIoU(Rect box1, Rect box2) {
    final intersection = box1.intersect(box2);
    if (intersection.isEmpty) return 0.0;
    
    final intersectionArea = intersection.width * intersection.height;
    final unionArea = (box1.width * box1.height) + (box2.width * box2.height) - intersectionArea;
    
    return intersectionArea / unionArea;
  }

  void dispose() {
    _isModelLoaded = false;
  }
}
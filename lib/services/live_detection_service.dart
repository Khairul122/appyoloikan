import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_vision/flutter_vision.dart';
import '../models/detection_result.dart';
import '../utils/constants.dart';

class LiveDetectionService {
  static final LiveDetectionService _instance = LiveDetectionService._internal();
  factory LiveDetectionService() => _instance;
  LiveDetectionService._internal();

  StreamController<List<Map<String, dynamic>>>? _detectionController;
  FlutterVision? _vision;
  
  bool _isProcessing = false;
  bool _isActive = false;
  bool _isInitialized = false;

  Stream<List<Map<String, dynamic>>> get detectionStream {
    _detectionController ??= StreamController<List<Map<String, dynamic>>>.broadcast();
    return _detectionController!.stream;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _vision = FlutterVision();
      await _vision!.loadYoloModel(
        labels: AppConstants.labelsPath,
        modelPath: AppConstants.modelPath,
        modelVersion: "yolov8",
        numThreads: 4,
        useGpu: false,
      );
      
      _detectionController ??= StreamController<List<Map<String, dynamic>>>.broadcast();
      _isActive = true;
      _isInitialized = true;
      
      debugPrint('Live detection service initialized successfully');
    } catch (e) {
      debugPrint('Live detection service initialization failed: $e');
      throw Exception('Failed to initialize live detection service: $e');
    }
  }

  Future<void> processFrame(CameraImage cameraImage) async {
    if (_isProcessing || !_isActive || !_isInitialized || _vision == null) return;
    
    _isProcessing = true;
    
    try {
      final result = await _vision!.yoloOnFrame(
        bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage.height,
        imageWidth: cameraImage.width,
        iouThreshold: AppConstants.iouThreshold,
        confThreshold: AppConstants.confidenceThreshold,
        classThreshold: AppConstants.confidenceThreshold,
      );
      
      if (_isActive && _detectionController != null) {
        _detectionController!.add(result);
      }
    } catch (e) {
      debugPrint('Detection processing error: $e');
      if (_isActive && _detectionController != null) {
        _detectionController!.add([]);
      }
    } finally {
      _isProcessing = false;
    }
  }

  void pause() {
    _isActive = false;
  }

  void resume() {
    _isActive = true;
  }

  void dispose() {
    _isActive = false;
    _isProcessing = false;
    _isInitialized = false;
    
    _detectionController?.close();
    _detectionController = null;
    
    _vision?.closeYoloModel();
    _vision = null;
  }
}
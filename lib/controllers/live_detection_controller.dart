import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/detection_result.dart';
import '../services/live_detection_service.dart';
import '../utils/constants.dart';

class LiveDetectionController extends GetxController {
  CameraController? cameraController;
  final LiveDetectionService _detectionService = LiveDetectionService();
  
  final RxBool isInitialized = false.obs;
  final RxBool isDetecting = false.obs;
  final RxBool isFlashOn = false.obs;
  final RxList<DetectionResult> detections = <DetectionResult>[].obs;
  final RxString currentDetection = ''.obs;
  final RxDouble currentConfidence = 0.0.obs;
  final RxString error = ''.obs;

  StreamSubscription<List<DetectionResult>>? _detectionSubscription;

  @override
  void onInit() {
    super.onInit();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      error.value = '';
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await cameraController!.initialize();
      await _detectionService.initialize();
      
      _setupDetectionListener();
      
      isInitialized.value = true;
      startDetection();
    } catch (e) {
      error.value = 'Camera initialization failed: $e';
      debugPrint('Camera initialization error: $e');
    }
  }

  void _setupDetectionListener() {
    _detectionSubscription = _detectionService.detectionStream.listen(
      (results) {
        detections.value = results;
        
        if (results.isNotEmpty) {
          final bestDetection = results.first;
          currentDetection.value = bestDetection.className;
          currentConfidence.value = bestDetection.confidence;
        } else {
          currentDetection.value = '';
          currentConfidence.value = 0.0;
        }
      },
      onError: (e) {
        debugPrint('Detection stream error: $e');
        error.value = 'Detection error: $e';
      },
    );
  }

  void startDetection() {
    if (!isInitialized.value) return;
    if (cameraController!.value.isStreamingImages) return;

    try {
      cameraController!.startImageStream((CameraImage image) {
        _detectionService.addImageFrame(image);
      });
      
      _detectionService.resume();
      isDetecting.value = true;
      error.value = '';
    } catch (e) {
      error.value = 'Failed to start detection: $e';
      debugPrint('Start detection error: $e');
    }
  }

  void stopDetection() {
    if (cameraController?.value.isStreamingImages == true) {
      cameraController?.stopImageStream();
    }
    _detectionService.pause();
    isDetecting.value = false;
  }

  void pauseDetection() {
    _detectionService.pause();
    isDetecting.value = false;
  }

  void resumeDetection() {
    if (isInitialized.value) {
      _detectionService.resume();
      if (!cameraController!.value.isStreamingImages) {
        startDetection();
      } else {
        isDetecting.value = true;
      }
    }
  }

  Future<void> toggleFlash() async {
    if (!isInitialized.value) return;
    
    try {
      if (isFlashOn.value) {
        await cameraController!.setFlashMode(FlashMode.off);
        isFlashOn.value = false;
      } else {
        await cameraController!.setFlashMode(FlashMode.torch);
        isFlashOn.value = true;
      }
    } catch (e) {
      debugPrint('Flash toggle error: $e');
      error.value = 'Flash toggle failed: $e';
    }
  }

  Future<void> takePicture() async {
    if (!isInitialized.value) return;

    try {
      stopDetection();
      final XFile picture = await cameraController!.takePicture();
      
      Get.toNamed('/result', arguments: {
        'imagePath': picture.path,
        'detections': detections.toList(),
      });
    } catch (e) {
      debugPrint('Take picture error: $e');
      error.value = 'Failed to take picture: $e';
      resumeDetection();
    }
  }

  @override
  void onClose() {
    stopDetection();
    _detectionSubscription?.cancel();
    _detectionService.dispose();
    cameraController?.dispose();
    super.onClose();
  }
}
import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import '../models/detection_result.dart';
import '../services/live_detection_service.dart';
import '../utils/constants.dart';

class LiveDetectionController extends GetxController {
  CameraController? cameraController;
  final LiveDetectionService _detectionService = LiveDetectionService();
  final FlutterTts _flutterTts = FlutterTts();
  
  final RxBool isInitialized = false.obs;
  final RxBool isDetecting = false.obs;
  final RxBool isFlashOn = false.obs;
  final RxList<Map<String, dynamic>> detections = <Map<String, dynamic>>[].obs;
  final RxString currentDetection = ''.obs;
  final RxDouble currentConfidence = 0.0.obs;
  final RxString error = ''.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _detectionSubscription;
  String? _lastAnnouncedDetection;

  @override
  void onInit() {
    super.onInit();
    _initializeTts();
    initializeCamera();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("id-ID");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
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
        final filteredResults = results.where((result) {
          final box = result["box"] as List<dynamic>;
          final confidence = (box[4] ?? 0.0).toDouble();
          return confidence > 0.5;
        }).toList();
        
        detections.value = filteredResults;
        
        if (filteredResults.isNotEmpty) {
          final bestDetection = filteredResults.first;
          final tag = bestDetection['tag'] ?? '';
          final confidence = (bestDetection['box'][4] ?? 0.0).toDouble();
          
          currentDetection.value = tag;
          currentConfidence.value = confidence;
    
          if (tag != _lastAnnouncedDetection && tag.isNotEmpty) {
            _announceDetection(tag);
            _lastAnnouncedDetection = tag;
          }
        } else {
          currentDetection.value = '';
          currentConfidence.value = 0.0;
          _lastAnnouncedDetection = null;
        }
      },
      onError: (e) {
        debugPrint('Detection stream error: $e');
        error.value = 'Detection error: $e';
      },
    );
  }

  Future<void> _announceDetection(String fishName) async {
    try {
      await _flutterTts.speak("$fishName terdeteksi");
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  void startDetection() {
    if (!isInitialized.value) return;
    if (cameraController!.value.isStreamingImages) return;

    try {
      cameraController!.startImageStream((CameraImage image) {
        _detectionService.processFrame(image);
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
    if (cameraController == null) return;

    try {
      debugPrint('Taking picture...');
      
      pauseDetection();
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (cameraController?.value.isStreamingImages == true) {
        await cameraController!.stopImageStream();
      }
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      final XFile picture = await cameraController!.takePicture();
      debugPrint('Picture taken successfully: ${picture.path}');
      
      await Future.delayed(const Duration(milliseconds: 200));
      
      Get.toNamed('/upload', arguments: {
        'imagePath': picture.path,
        'fromLiveDetection': true,
      })?.then((_) {
        if (Get.currentRoute.contains('/live')) {
          resumeDetection();
        }
      });
      
    } catch (e) {
      debugPrint('Take picture error: $e');
      error.value = 'Failed to take picture: $e';
      await Future.delayed(const Duration(milliseconds: 500));
      if (Get.currentRoute.contains('/live')) {
        resumeDetection();
      }
    }
  }

  @override
  void onClose() {
    stopDetection();
    _detectionSubscription?.cancel();
    _detectionService.dispose();
    _flutterTts.stop();
    cameraController?.dispose();
    super.onClose();
  }
}
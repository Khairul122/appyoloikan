import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/detection_result.dart';
import '../services/ml_service.dart';
import '../utils/constants.dart';

class FishCameraController extends GetxController {
  CameraController? cameraController;
  final MLService _mlService = MLService();
  
  final RxBool isInitialized = false.obs;
  final RxBool isDetecting = false.obs;
  final RxBool isFlashOn = false.obs;
  final RxList<DetectionResult> detections = <DetectionResult>[].obs;
  final RxString currentDetection = ''.obs;
  final RxDouble currentConfidence = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await cameraController!.initialize();
      await _mlService.loadModel();
      
      isInitialized.value = true;
      startImageStream();
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  void startImageStream() {
    if (cameraController?.value.isInitialized != true) return;
    if (cameraController!.value.isStreamingImages) return;

    cameraController!.startImageStream((CameraImage image) {
      if (!isDetecting.value) {
        isDetecting.value = true;
        _processImage(image);
      }
    });
  }

  void stopImageStream() {
    if (cameraController?.value.isStreamingImages == true) {
      cameraController?.stopImageStream();
    }
    isDetecting.value = false;
  }

  Future<void> _processImage(CameraImage cameraImage) async {
    try {
      final imageBytes = await _convertCameraImage(cameraImage);
      final results = await _mlService.detectObjects(imageBytes);
      
      final filteredResults = results.where(
        (result) => result.confidence >= AppConstants.confidenceThreshold
      ).toList();
      
      detections.value = filteredResults;
      
      if (filteredResults.isNotEmpty) {
        final bestDetection = filteredResults.first;
        currentDetection.value = bestDetection.className;
        currentConfidence.value = bestDetection.confidence;
      } else {
        currentDetection.value = '';
        currentConfidence.value = 0.0;
      }
    } catch (e) {
      debugPrint('Detection error: $e');
    } finally {
      isDetecting.value = false;
    }
  }

  Future<Uint8List> _convertCameraImage(CameraImage cameraImage) async {
    if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      return _convertYUV420ToRGB(cameraImage);
    } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      return _convertBGRA8888ToRGB(cameraImage);
    } else {
      throw UnsupportedError('Unsupported image format');
    }
  }

  Uint8List _convertYUV420ToRGB(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    
    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    final vPlane = cameraImage.planes[2];
    
    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;
    
    final rgbBytes = Uint8List(width * height * 3);
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yPlane.bytesPerRow + x;
        final uvIndex = (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2);
        
        final yValue = yBuffer[yIndex];
        final uValue = uBuffer[uvIndex];
        final vValue = vBuffer[uvIndex];
        
        final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
        final g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).clamp(0, 255).toInt();
        final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();
        
        final rgbIndex = (y * width + x) * 3;
        rgbBytes[rgbIndex] = r;
        rgbBytes[rgbIndex + 1] = g;
        rgbBytes[rgbIndex + 2] = b;
      }
    }
    
    return rgbBytes;
  }

  Uint8List _convertBGRA8888ToRGB(CameraImage cameraImage) {
    final bytes = cameraImage.planes[0].bytes;
    final rgbBytes = Uint8List(bytes.length ~/ 4 * 3);
    
    for (int i = 0, j = 0; i < bytes.length; i += 4, j += 3) {
      rgbBytes[j] = bytes[i + 2];
      rgbBytes[j + 1] = bytes[i + 1];
      rgbBytes[j + 2] = bytes[i];
    }
    
    return rgbBytes;
  }

  Future<void> toggleFlash() async {
    if (cameraController?.value.isInitialized != true) return;
    
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
    }
  }

  Future<void> takePicture() async {
    if (cameraController?.value.isInitialized != true) return;

    try {
      stopImageStream();
      final XFile picture = await cameraController!.takePicture();
      Get.toNamed('/result', arguments: {
        'imagePath': picture.path,
        'detections': detections.toList(),
      });
    } catch (e) {
      debugPrint('Take picture error: $e');
      startImageStream();
    }
  }

  void pauseDetection() {
    stopImageStream();
  }

  void resumeDetection() {
    if (!cameraController!.value.isStreamingImages) {
      startImageStream();
    }
  }

  @override
  void onClose() {
    cameraController?.dispose();
    _mlService.dispose();
    super.onClose();
  }
}
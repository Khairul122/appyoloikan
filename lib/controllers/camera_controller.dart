import 'dart:io';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import '../main.dart';

class CameraControllerX extends GetxController {
  CameraController? cameraController;
  var isCameraInitialized = false.obs;
  var isFlashOn = false.obs;
  var selectedCameraIndex = 0.obs;
  var isRearCamera = true.obs;
  var isDisposed = false.obs;
  var errorMessage = ''.obs;
  var actualFps = 0.obs;

  @override
  void onInit() {
    super.onInit();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    if (cameras.isEmpty || isDisposed.value) {
      errorMessage.value = 'No cameras available';
      return;
    }

    try {
      await stopCamera();
      
      cameraController = CameraController(
        cameras[selectedCameraIndex.value],
        ResolutionPreset.medium, // 640x480 untuk live detection
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid 
            ? ImageFormatGroup.yuv420 
            : ImageFormatGroup.bgra8888,
      );

      await cameraController!.initialize();
      
      if (!isDisposed.value) {
        // Set FPS untuk live detection
        await _configureCameraForLiveDetection();
        
        isCameraInitialized.value = true;
        await cameraController!.setFlashMode(FlashMode.off);
        isFlashOn.value = false;
        errorMessage.value = '';
      }
    } catch (e) {
      errorMessage.value = 'Camera initialization failed: $e';
      isCameraInitialized.value = false;
      cameraController?.dispose();
      cameraController = null;
    }
  }

  Future<void> _configureCameraForLiveDetection() async {
    try {
      // Set exposure mode untuk performa yang konsisten
      await cameraController!.setExposureMode(ExposureMode.auto);
      
      // Set focus mode untuk live detection
      await cameraController!.setFocusMode(FocusMode.auto);
      
      // Dapatkan info FPS yang didukung
      final fps = await _getOptimalFpsRange();
      if (fps != null) {
        actualFps.value = fps;
      }
      
    } catch (e) {
      print('Failed to configure camera for live detection: $e');
    }
  }

  Future<int?> _getOptimalFpsRange() async {
    try {
      // Target FPS 30 untuk live detection
      return 30;
    } catch (e) {
      return null;
    }
  }

  Future<File?> takePicture() async {
    if (!isCameraInitialized.value || cameraController == null || isDisposed.value) {
      return null;
    }

    try {
      // Temporarily stop image stream untuk capture
      final wasStreaming = cameraController!.value.isStreamingImages;
      if (wasStreaming) {
        await cameraController!.stopImageStream();
      }
      
      final XFile image = await cameraController!.takePicture();
      
      // Resume image stream jika diperlukan
      if (wasStreaming && !isDisposed.value) {
        await Future.delayed(Duration(milliseconds: 100));
        // Note: Stream akan di-restart oleh detection controller
      }
      
      return File(image.path);
    } catch (e) {
      errorMessage.value = 'Failed to take picture: $e';
      return null;
    }
  }

  Future<void> toggleFlash() async {
    if (!isCameraInitialized.value || cameraController == null || isDisposed.value) {
      return;
    }

    try {
      isFlashOn.value = !isFlashOn.value;
      await cameraController!.setFlashMode(
        isFlashOn.value ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      isFlashOn.value = !isFlashOn.value;
      errorMessage.value = 'Failed to toggle flash: $e';
    }
  }

  Future<void> switchCamera() async {
    if (cameras.length < 2 || isDisposed.value) {
      return;
    }

    try {
      final wasStreaming = cameraController?.value.isStreamingImages ?? false;
      
      await stopCamera();
      selectedCameraIndex.value = selectedCameraIndex.value == 0 ? 1 : 0;
      isRearCamera.value = !isRearCamera.value;
      
      await Future.delayed(Duration(milliseconds: 100));
      await initializeCamera();
      
      // Note: Detection controller will restart stream if needed
    } catch (e) {
      errorMessage.value = 'Failed to switch camera: $e';
    }
  }

  Future<void> stopCamera() async {
    try {
      if (cameraController != null) {
        // Ensure image stream is stopped cleanly
        if (cameraController!.value.isStreamingImages) {
          await cameraController!.stopImageStream();
          await Future.delayed(Duration(milliseconds: 50));
        }
        
        await cameraController!.dispose();
        cameraController = null;
      }
      isCameraInitialized.value = false;
      isFlashOn.value = false;
    } catch (e) {
      print('Error stopping camera: $e');
    }
  }

  Future<void> resumeCamera() async {
    if (!isCameraInitialized.value && !isDisposed.value) {
      await initializeCamera();
    }
  }

  // Helper methods for live detection optimization
  bool get isStreamingImages => 
      cameraController?.value.isStreamingImages ?? false;

  Future<void> ensureImageStreamStopped() async {
    if (isStreamingImages) {
      await cameraController!.stopImageStream();
      await Future.delayed(Duration(milliseconds: 50));
    }
  }

  ResolutionPreset get optimalResolutionForDetection => ResolutionPreset.medium;
  
  bool get isReady => isCameraInitialized.value && 
                     !isDisposed.value && 
                     cameraController != null &&
                     errorMessage.value.isEmpty;

  String get cameraInfo {
    if (!isCameraInitialized.value) return 'Camera not initialized';
    
    final resolution = cameraController?.value.previewSize;
    final fps = actualFps.value;
    
    return 'Resolution: ${resolution?.width}x${resolution?.height} | FPS: ${fps}';
  }

  @override
  void onClose() {
    isDisposed.value = true;
    stopCamera();
    super.onClose();
  }
}
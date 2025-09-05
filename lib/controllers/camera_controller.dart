import 'dart:io';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import '../main.dart';
import '../utils/constants.dart';

class CameraControllerX extends GetxController {
  CameraController? cameraController;
  var isCameraInitialized = false.obs;
  var isFlashOn = false.obs;
  var selectedCameraIndex = 0.obs;
  var isRearCamera = true.obs;
  var isDisposed = false.obs;
  var errorMessage = ''.obs;
  var actualFps = 0.obs;

  bool _isInitializing = false;
  bool _isDisposing = false;
  bool _isStreamStarting = false;
  bool _isStreamStopping = false;

  @override
  void onInit() {
    super.onInit();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    if (_isInitializing || isDisposed.value) return;
    
    _isInitializing = true;
    try {
      if (cameras.isEmpty) {
        errorMessage.value = AppConstants.errorCameraNotAvailable;
        return;
      }

      await _safeStopCamera();
      
      cameraController = CameraController(
        cameras[selectedCameraIndex.value],
        AppConstants.cameraResolution,
        enableAudio: AppConstants.enableAudio,
        imageFormatGroup: AppConstants.imageFormatGroup,
      );

      await cameraController!.initialize();
      
      if (!isDisposed.value) {
        await _configureCameraForLiveDetection();
        isCameraInitialized.value = true;
        await cameraController!.setFlashMode(FlashMode.off);
        isFlashOn.value = false;
        errorMessage.value = '';
      }
    } catch (e) {
      errorMessage.value = '${AppConstants.errorCameraNotAvailable}: $e';
      isCameraInitialized.value = false;
      if (cameraController != null) {
        await cameraController!.dispose();
        cameraController = null;
      }
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _configureCameraForLiveDetection() async {
    try {
      await cameraController!.setExposureMode(ExposureMode.auto);
      await cameraController!.setFocusMode(FocusMode.auto);
      await cameraController!.setFlashMode(FlashMode.off);
      actualFps.value = 15;
    } catch (e) {
      print('Failed to configure camera: $e');
    }
  }

  Future<void> _safeStopCamera() async {
    if (cameraController != null) {
      try {
        await ensureImageStreamStopped();
        await cameraController!.dispose();
      } catch (e) {
        print('Error during camera stop: $e');
      } finally {
        cameraController = null;
        isCameraInitialized.value = false;
      }
    }
  }

  Future<File?> takePicture() async {
    if (!isCameraInitialized.value || cameraController == null || isDisposed.value) {
      return null;
    }

    try {
      final wasStreaming = cameraController!.value.isStreamingImages;
      if (wasStreaming) {
        await ensureImageStreamStopped();
      }
      
      final XFile image = await cameraController!.takePicture();
      
      if (wasStreaming && !isDisposed.value) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      
      return File(image.path);
    } catch (e) {
      errorMessage.value = '${AppConstants.errorPredictionFailed}: $e';
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
    if (cameras.length < 2 || isDisposed.value || _isInitializing) {
      return;
    }

    try {
      await _safeStopCamera();
      selectedCameraIndex.value = selectedCameraIndex.value == 0 ? 1 : 0;
      isRearCamera.value = !isRearCamera.value;
      
      await Future.delayed(Duration(milliseconds: 100));
      await initializeCamera();
    } catch (e) {
      errorMessage.value = '${AppConstants.errorCameraNotAvailable}: $e';
    }
  }

  Future<void> startImageStreamSafe(Function(CameraImage) onImage) async {
    if (_isStreamStarting || _isStreamStopping || !isCameraInitialized.value || cameraController == null) {
      return;
    }

    _isStreamStarting = true;
    try {
      while (_isStreamStopping) {
        await Future.delayed(Duration(milliseconds: 10));
      }

      if (!cameraController!.value.isStreamingImages && !isDisposed.value) {
        await cameraController!.startImageStream(onImage);
      }
    } catch (e) {
      print('Error starting image stream: $e');
    } finally {
      _isStreamStarting = false;
    }
  }

  Future<void> stopImageStreamSafe() async {
    if (_isStreamStopping || !isCameraInitialized.value || cameraController == null) {
      return;
    }

    _isStreamStopping = true;
    try {
      if (cameraController!.value.isStreamingImages) {
        await cameraController!.stopImageStream();
        await Future.delayed(Duration(milliseconds: 50));
      }
    } catch (e) {
      print('Error stopping image stream: $e');
    } finally {
      _isStreamStopping = false;
    }
  }

  Future<void> stopCamera() async {
    if (_isDisposing) return;
    
    _isDisposing = true;
    try {
      await _safeStopCamera();
      isFlashOn.value = false;
    } finally {
      _isDisposing = false;
    }
  }

  Future<void> resumeCamera() async {
    if (!isCameraInitialized.value && !isDisposed.value && !_isInitializing) {
      await initializeCamera();
    }
  }

  bool get isStreamingImages => 
      cameraController?.value.isStreamingImages ?? false;

  Future<void> ensureImageStreamStopped() async {
    await stopImageStreamSafe();
  }

  ResolutionPreset get optimalResolutionForDetection => AppConstants.cameraResolution;
  
  bool get isReady => isCameraInitialized.value && 
                     !isDisposed.value && 
                     cameraController != null &&
                     errorMessage.value.isEmpty &&
                     !_isInitializing &&
                     !_isDisposing;

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
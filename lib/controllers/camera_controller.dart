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

  @override
  void onInit() {
    super.onInit();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    if (cameras.isEmpty || isDisposed.value) {
      print('No cameras available or controller disposed');
      return;
    }

    try {
      await stopCamera();
      
      cameraController = CameraController(
        cameras[selectedCameraIndex.value],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid 
            ? ImageFormatGroup.yuv420 
            : ImageFormatGroup.bgra8888,
      );

      await cameraController!.initialize();
      
      if (!isDisposed.value) {
        isCameraInitialized.value = true;
        
        await cameraController!.setFlashMode(FlashMode.off);
        isFlashOn.value = false;
        
        print('Camera initialized successfully');
      }
    } catch (e) {
      print('Camera initialization error: $e');
      isCameraInitialized.value = false;
      cameraController?.dispose();
      cameraController = null;
    }
  }

  Future<File?> takePicture() async {
    if (!isCameraInitialized.value || cameraController == null || isDisposed.value) {
      return null;
    }

    try {
      final XFile image = await cameraController!.takePicture();
      return File(image.path);
    } catch (e) {
      print('Error taking picture: $e');
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
      print('Error toggling flash: $e');
      isFlashOn.value = !isFlashOn.value;
    }
  }

  Future<void> switchCamera() async {
    if (cameras.length < 2 || isDisposed.value) {
      return;
    }

    try {
      await stopCamera();
      
      selectedCameraIndex.value = selectedCameraIndex.value == 0 ? 1 : 0;
      isRearCamera.value = !isRearCamera.value;
      
      await Future.delayed(Duration(milliseconds: 100));
      await initializeCamera();
    } catch (e) {
      print('Error switching camera: $e');
    }
  }

  Future<void> stopCamera() async {
    try {
      if (cameraController != null) {
        if (cameraController!.value.isStreamingImages) {
          await cameraController!.stopImageStream();
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

  @override
  void onClose() {
    isDisposed.value = true;
    stopCamera();
    super.onClose();
  }
}
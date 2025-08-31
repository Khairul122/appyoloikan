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

  @override
  void onInit() {
    super.onInit();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    if (cameras.isEmpty) {
      print('No cameras available');
      return;
    }

    try {
      cameraController = CameraController(
        cameras[selectedCameraIndex.value],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await cameraController!.initialize();
      isCameraInitialized.value = true;
    } catch (e) {
      print('Camera initialization error: $e');
      isCameraInitialized.value = false;
    }
  }

  Future<File?> takePicture() async {
    if (!isCameraInitialized.value || cameraController == null) {
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
    if (!isCameraInitialized.value || cameraController == null) {
      return;
    }

    try {
      isFlashOn.value = !isFlashOn.value;
      await cameraController!.setFlashMode(
        isFlashOn.value ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      print('Error toggling flash: $e');
    }
  }

  Future<void> switchCamera() async {
    if (cameras.length < 2) {
      return;
    }

    try {
      selectedCameraIndex.value = selectedCameraIndex.value == 0 ? 1 : 0;
      isRearCamera.value = !isRearCamera.value;
      
      await cameraController?.dispose();
      await initializeCamera();
    } catch (e) {
      print('Error switching camera: $e');
    }
  }

  Future<void> stopCamera() async {
    if (cameraController != null) {
      await cameraController!.dispose();
      isCameraInitialized.value = false;
    }
  }

  Future<void> resumeCamera() async {
    if (!isCameraInitialized.value) {
      await initializeCamera();
    }
  }

  @override
  void onClose() {
    cameraController?.dispose();
    super.onClose();
  }
}
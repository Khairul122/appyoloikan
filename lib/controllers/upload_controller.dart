import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/detection_result.dart';
import '../services/ml_inference_service.dart';
import '../utils/constants.dart';
  
class UploadController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  
  final RxBool isLoading = false.obs;
  final RxBool isModelLoaded = false.obs;
  final Rxn<File> selectedImage = Rxn<File>();
  final RxList<DetectionResult> detections = <DetectionResult>[].obs;
  final RxString error = ''.obs;
  final Rx<MLPackage> selectedPackage = MLPackage.flutterVision.obs;
  
  List<String> _labels = [];

  @override
  void onInit() {
    super.onInit();
    _initializeModel();
    _checkForCapturedImage();
  }

  void _checkForCapturedImage() {
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      final imagePath = arguments['imagePath'] as String?;
      final fromLiveDetection = arguments['fromLiveDetection'] as bool? ?? false;
      
      if (imagePath != null && fromLiveDetection) {
        Future.delayed(const Duration(milliseconds: 500), () {
          selectedImage.value = File(imagePath);
          Future.delayed(const Duration(milliseconds: 300), () {
            _detectObjects();
          });
        });
      }
    }
  }

  Future<void> _initializeModel() async {
    try {
      isLoading.value = true;
      await Future.delayed(const Duration(milliseconds: 100));
      
      await MLInferenceManager.initialize(selectedPackage.value);
      await _loadLabels();
      
      isModelLoaded.value = true;
      debugPrint('${selectedPackage.value.name} model loaded successfully');
    } catch (e) {
      error.value = 'Failed to load model: $e';
      debugPrint('Model loading error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadLabels() async {
    _labels = await AppConstants.loadLabels();
    debugPrint('Loaded ${_labels.length} labels: $_labels');
  }

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        selectedImage.value = File(image.path);
        await _detectObjects();
      }
    } catch (e) {
      error.value = 'Failed to pick image: $e';
      debugPrint('Image picking error: $e');
    }
  }

  Future<void> pickImageFromCamera() async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        await Future.delayed(const Duration(milliseconds: 300));
        selectedImage.value = File(image.path);
        await Future.delayed(const Duration(milliseconds: 200));
        await _detectObjects();
      }
    } catch (e) {
      error.value = 'Failed to take picture: $e';
      debugPrint('Camera error: $e');
    }
  }

  Future<void> _detectObjects() async {
    if (selectedImage.value == null || !isModelLoaded.value) {
      debugPrint('Cannot detect: selectedImage=${selectedImage.value != null}, modelLoaded=${isModelLoaded.value}');
      return;
    }

    try {
      isLoading.value = true;
      error.value = '';
      detections.clear();

      debugPrint('Starting ${selectedPackage.value.name} detection process...');
      
      final results = await MLInferenceManager.service.detectObjects(selectedImage.value!);
      
      debugPrint('${selectedPackage.value.name} inference complete. Found ${results.length} detections');
      
      for (int i = 0; i < results.length; i++) {
        final detection = results[i];
        debugPrint('Detection $i: ${detection.className} (${(detection.confidence * 100).toStringAsFixed(1)}%)');
      }
      
      if (results.isNotEmpty) {
        results.sort((a, b) => b.confidence.compareTo(a.confidence));
        final bestDetection = results.first;
        detections.value = [bestDetection];
        debugPrint('Best detection: ${bestDetection.className} (${(bestDetection.confidence * 100).toStringAsFixed(1)}%)');
      } else {
        detections.value = [];
        error.value = 'No fish detected in the image';
        debugPrint('No detections found');
      }
    } catch (e) {
      error.value = 'Detection failed: $e';
      debugPrint('Detection error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> retryDetection() async {
    if (selectedImage.value != null) {
      await _detectObjects();
    }
  }

  void clearSelection() {
    selectedImage.value = null;
    detections.clear();
    error.value = '';
  }

  void showImageSourceDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text(
          'Select Image Source',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              subtitle: const Text('Choose from gallery'),
              onTap: () {
                Get.back();
                pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              subtitle: const Text('Take a new photo'),
              onTap: () {
                Get.back();
                pickImageFromCamera();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> switchMLPackage(MLPackage package) async {
    try {
      isLoading.value = true;
      isModelLoaded.value = false;
      selectedPackage.value = package;
      
      await MLInferenceManager.switchPackage(package);
      isModelLoaded.value = true;
      
      debugPrint('Switched to ${package.name} successfully');
      
      if (selectedImage.value != null) {
        await _detectObjects();
      }
    } catch (e) {
      error.value = 'Failed to switch package: $e';
      debugPrint('Package switch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    MLInferenceManager.dispose();
    super.onClose();
  }
}
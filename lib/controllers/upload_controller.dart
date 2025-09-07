import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/detection_result.dart';
import '../services/inference_isolate.dart';
import '../utils/constants.dart';

class UploadController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  
  final RxBool isLoading = false.obs;
  final RxBool isModelLoaded = false.obs;
  final Rxn<File> selectedImage = Rxn<File>();
  final RxList<DetectionResult> detections = <DetectionResult>[].obs;
  final RxString error = ''.obs;
  
  List<String> _labels = [];

  @override
  void onInit() {
    super.onInit();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    try {
      isLoading.value = true;
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      await InferenceIsolate.initialize();
      await _loadLabels();
      isModelLoaded.value = true;
    } catch (e) {
      error.value = 'Failed to load model: $e';
      debugPrint('Model loading error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labelsData = await rootBundle.loadString('lib/assets/models/labels.txt');
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
      debugPrint('Loaded ${_labels.length} labels: $_labels');
    } catch (e) {
      _labels = AppConstants.fishClasses;
      debugPrint('Using default labels: $_labels');
    }
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
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        selectedImage.value = File(image.path);
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

      debugPrint('Starting detection process...');
      final imageBytes = await selectedImage.value!.readAsBytes();
      debugPrint('Image loaded: ${imageBytes.length} bytes');
      
      debugPrint('Running inference with ${_labels.length} labels...');
      final results = await InferenceIsolate.runInference(
        imageBytes: imageBytes,
        labels: _labels,
        isLiveDetection: false,
      );
      
      debugPrint('Inference complete. Found ${results.length} detections');
      for (int i = 0; i < results.length; i++) {
        final detection = results[i];
        debugPrint('Detection $i: ${detection.className} (${(detection.confidence * 100).toStringAsFixed(1)}%)');
      }
      
      // For upload, show only the highest confidence detection
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

  @override
  void onClose() {
    InferenceIsolate.dispose();
    super.onClose();
  }
}
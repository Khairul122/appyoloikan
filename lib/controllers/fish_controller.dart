import 'dart:io';
import 'package:get/get.dart';
import '../models/prediction_result.dart';
import '../services/ml_service.dart';
import '../services/image_service.dart';
import '../utils/constants.dart';

class FishController extends GetxController {
  final MLService _mlService = MLService.instance;
  final ImageService _imageService = ImageService.instance;

  var isModelLoading = false.obs;
  var isModelLoaded = false.obs;
  var isPredicting = false.obs;
  var currentImage = Rxn<File>();
  var predictionResults = <PredictionResult>[].obs;
  var recentImages = <File>[].obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadModel();
    loadRecentImages();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _imageService.initialize();
  }

  Future<void> loadModel() async {
    try {
      isModelLoading.value = true;
      errorMessage.value = '';
      
      final success = await _mlService.loadModel();
      isModelLoaded.value = success;
      
      if (!success) {
        errorMessage.value = AppConstants.errorModelNotLoaded;
      }
    } catch (e) {
      errorMessage.value = '${AppConstants.errorModelNotLoaded}: $e';
      isModelLoaded.value = false;
    } finally {
      isModelLoading.value = false;
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      final image = await _imageService.pickImageFromGallery();
      if (image != null) {
        final isValid = await _imageService.validateImageFile(image);
        if (isValid) {
          currentImage.value = image;
          await predictImage(image);
        } else {
          Get.snackbar('Error', AppConstants.errorImageNotFound);
        }
      }
    } catch (e) {
      errorMessage.value = '${AppConstants.errorImageNotFound}: $e';
      Get.snackbar('Error', AppConstants.errorImageNotFound);
    }
  }

  Future<void> pickImageFromCamera() async {
    try {
      final image = await _imageService.pickImageFromCamera();
      if (image != null) {
        final isValid = await _imageService.validateImageFile(image);
        if (isValid) {
          currentImage.value = image;
          await predictImage(image);
        } else {
          Get.snackbar('Error', AppConstants.errorImageNotFound);
        }
      }
    } catch (e) {
      errorMessage.value = '${AppConstants.errorCameraNotAvailable}: $e';
      Get.snackbar('Error', AppConstants.errorCameraNotAvailable);
    }
  }

  Future<void> predictImage(File imageFile) async {
    if (!isModelLoaded.value) {
      Get.snackbar('Error', AppConstants.errorModelNotLoaded);
      return;
    }

    try {
      isPredicting.value = true;
      errorMessage.value = '';
      predictionResults.clear();

      final results = await _mlService.predict(imageFile);
      predictionResults.assignAll(results.map((result) => PredictionResult.fromMap(result)).toList());

      final savedImage = await _imageService.saveImageToLocalStorage(imageFile);
      if (savedImage != null) {
        recentImages.insert(0, savedImage);
        if (recentImages.length > AppConstants.maxStoredImages) {
          final oldImage = recentImages.removeLast();
          _imageService.deleteImage(oldImage);
        }
      }

      if (results.isEmpty) {
        Get.snackbar('Info', AppConstants.errorNoResults);
      } else {
        final topResult = results.first;
        final displayName = (topResult['label'] as String)
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
            .join(' ');
        final confidencePercentage = '${((topResult['confidence'] as double) * 100).toStringAsFixed(1)}%';
        
        Get.snackbar(
          'Detection Result', 
          '$displayName ($confidencePercentage)',
          duration: Duration(seconds: 3),
        );
      }
    } catch (e) {
      errorMessage.value = '${AppConstants.errorPredictionFailed}: $e';
      Get.snackbar('Error', AppConstants.errorPredictionFailed);
    } finally {
      isPredicting.value = false;
    }
  }

  Future<void> loadRecentImages() async {
    try {
      final images = await _imageService.getStoredImages();
      recentImages.assignAll(images);
    } catch (e) {
      print('Error loading recent images: $e');
    }
  }

  Future<void> deleteImage(File imageFile) async {
    try {
      final success = await _imageService.deleteImage(imageFile);
      if (success) {
        recentImages.remove(imageFile);
        if (currentImage.value?.path == imageFile.path) {
          currentImage.value = null;
          predictionResults.clear();
        }
        Get.snackbar('Success', AppConstants.successImageDeleted);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete image');
    }
  }

  Future<void> clearAllImages() async {
    try {
      await _imageService.clearAllImages();
      recentImages.clear();
      currentImage.value = null;
      predictionResults.clear();
      Get.snackbar('Success', 'All images cleared');
    } catch (e) {
      Get.snackbar('Error', 'Failed to clear images');
    }
  }

  void selectImage(File imageFile) {
    currentImage.value = imageFile;
    predictImage(imageFile);
  }

  void clearCurrentPrediction() {
    currentImage.value = null;
    predictionResults.clear();
    errorMessage.value = '';
  }

  @override
  void onClose() {
    _mlService.dispose();
    super.onClose();
  }
}
import 'dart:io';
import 'package:get/get.dart';
import '../models/prediction_result.dart';
import '../services/ml_service.dart';
import '../services/image_service.dart';

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
  }

  Future<void> loadModel() async {
    try {
      isModelLoading.value = true;
      errorMessage.value = '';
      
      final success = await _mlService.loadModel();
      isModelLoaded.value = success;
      
      if (!success) {
        errorMessage.value = 'Failed to load ML model';
      }
    } catch (e) {
      errorMessage.value = 'Error loading model: $e';
      isModelLoaded.value = false;
    } finally {
      isModelLoading.value = false;
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      final image = await _imageService.pickImageFromGallery();
      if (image != null) {
        currentImage.value = image;
        await predictImage(image);
      }
    } catch (e) {
      errorMessage.value = 'Error picking image: $e';
      Get.snackbar('Error', 'Failed to pick image from gallery');
    }
  }

  Future<void> pickImageFromCamera() async {
    try {
      final image = await _imageService.pickImageFromCamera();
      if (image != null) {
        currentImage.value = image;
        await predictImage(image);
      }
    } catch (e) {
      errorMessage.value = 'Error taking photo: $e';
      Get.snackbar('Error', 'Failed to take photo');
    }
  }

  Future<void> predictImage(File imageFile) async {
    if (!isModelLoaded.value) {
      Get.snackbar('Error', 'Model is not loaded yet');
      return;
    }

    try {
      isPredicting.value = true;
      errorMessage.value = '';
      predictionResults.clear();

      final results = await _mlService.predict(imageFile);
      predictionResults.assignAll(results);

      final savedImage = await _imageService.saveImageToLocalStorage(imageFile);
      if (savedImage != null) {
        recentImages.insert(0, savedImage);
        if (recentImages.length > 10) {
          final oldImage = recentImages.removeLast();
          _imageService.deleteImage(oldImage);
        }
      }

      if (results.isEmpty) {
        Get.snackbar('Info', 'No fish detected in the image');
      } else {
        final topResult = results.first;
        Get.snackbar(
          'Detection Result', 
          '${topResult.displayName} (${topResult.confidencePercentage})',
          duration: Duration(seconds: 3),
        );
      }
    } catch (e) {
      errorMessage.value = 'Prediction failed: $e';
      Get.snackbar('Error', 'Failed to analyze image');
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
        Get.snackbar('Success', 'Image deleted');
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
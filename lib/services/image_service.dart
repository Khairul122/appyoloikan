import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../utils/constants.dart';

class ImageService {
  static ImageService? _instance;
  static ImageService get instance => _instance ??= ImageService._();
  
  ImageService._();

  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: AppConstants.maxImageWidth,
        maxHeight: AppConstants.maxImageHeight,
        imageQuality: AppConstants.imageQuality,
      );
      
      return image != null ? File(image.path) : null;
    } catch (e) {
      return null;
    }
  }

  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: AppConstants.maxImageWidth,
        maxHeight: AppConstants.maxImageHeight,
        imageQuality: AppConstants.imageQuality,
      );
      
      return image != null ? File(image.path) : null;
    } catch (e) {
      return null;
    }
  }

  Future<File?> saveImageToLocalStorage(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/fish_images');
      
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final String fileName = 'fish_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = path.join(imagesDir.path, fileName);
      
      final File savedImage = await imageFile.copy(filePath);
      return savedImage;
    } catch (e) {
      return null;
    }
  }

  Future<List<File>> getStoredImages() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/fish_images');
      
      if (!await imagesDir.exists()) {
        return [];
      }

      final List<FileSystemEntity> files = imagesDir.listSync();
      final List<File> imageFiles = files
          .where((file) => file is File && _isImageFile(file.path))
          .cast<File>()
          .toList();

      imageFiles.sort((a, b) => 
          b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      return imageFiles;
    } catch (e) {
      return [];
    }
  }

  bool _isImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.bmp'].contains(extension);
  }

  Future<bool> deleteImage(File imageFile) async {
    try {
      if (await imageFile.exists()) {
        await imageFile.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> clearAllImages() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/fish_images');
      
      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
      }
    } catch (e) {
      print('Error clearing images: $e');
    }
  }

  Future<int> getStoredImagesCount() async {
    try {
      final images = await getStoredImages();
      return images.length;
    } catch (e) {
      return 0;
    }
  }

  Future<double> getStoredImagesSize() async {
    try {
      final images = await getStoredImages();
      double totalSize = 0;
      
      for (final image in images) {
        final stat = await image.stat();
        totalSize += stat.size;
      }
      
      return totalSize / (1024 * 1024);
    } catch (e) {
      return 0;
    }
  }
}
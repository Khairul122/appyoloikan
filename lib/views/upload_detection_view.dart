import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/upload_controller.dart';
import '../widgets/detection_overlay.dart';
import '../utils/app_colors.dart';

class UploadDetectionView extends StatelessWidget {
  const UploadDetectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UploadController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'lib/assets/images/logo.png',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.set_meal,
                    color: AppColors.surface,
                    size: 28,
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Upload Detection',
              style: TextStyle(
                color: AppColors.surface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
        ),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.surface,
          ),
        ),
      ),
      body: Obx(() {
        if (!controller.isModelLoaded.value && controller.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading model...',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (controller.selectedImage.value == null) ...[
                _buildUploadSection(controller),
              ] else ...[
                _buildImageSection(controller),
                const SizedBox(height: 20),
                if (controller.isLoading.value)
                  _buildLoadingSection()
                else if (controller.detections.isNotEmpty)
                  _buildDetectionResults(controller)
                else if (controller.error.isNotEmpty)
                  _buildErrorSection(controller),
              ],
            ],
          ),
        );
      }),
      floatingActionButton: Obx(() {
        if (controller.selectedImage.value == null) {
          return FloatingActionButton.extended(
            onPressed: controller.showImageSourceDialog,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surface,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Select Image'),
          );
        }
        return FloatingActionButton(
          onPressed: controller.clearSelection,
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.surface,
          child: const Icon(Icons.refresh),
        );
      }),
    );
  }

  Widget _buildUploadSection(UploadController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.border,
                width: 2,
                style: BorderStyle.solid,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 80,
                  color: AppColors.textLight,
                ),
                SizedBox(height: 16),
                Text(
                  'Upload Image',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Select an image to detect fish',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildOptionButton(
                icon: Icons.photo_library,
                label: 'Gallery',
                onPressed: controller.pickImageFromGallery,
              ),
              const SizedBox(width: 20),
              _buildOptionButton(
                icon: Icons.camera_alt,
                label: 'Camera',
                onPressed: controller.pickImageFromCamera,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 120,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(UploadController controller) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              controller.selectedImage.value!,
              width: double.infinity,
              height: 400,
              fit: BoxFit.contain, // Changed from cover to contain
            ),
          ),
          if (controller.detections.isNotEmpty)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FutureBuilder<Size>(
                  future: _getImageSize(controller.selectedImage.value!),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return DetectionOverlay(
                          detections: controller.detections,
                          imageSize: snapshot.data!,
                          screenSize: Size(constraints.maxWidth, 400),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: 16),
          Text(
            'Detecting fish in the image...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionResults(UploadController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detection Results',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...controller.detections.map((detection) =>
            DetectionInfoCard(detection: detection)),
      ],
    );
  }

  Widget _buildErrorSection(UploadController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            controller.error.value,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.error,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: controller.retryDetection,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Retry Detection'),
          ),
        ],
      ),
    );
  }

  Future<Size> _getImageSize(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return Size(
      frame.image.width.toDouble(),
      frame.image.height.toDouble(),
    );
  }
}
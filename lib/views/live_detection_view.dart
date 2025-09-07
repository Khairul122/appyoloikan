import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import '../controllers/live_detection_controller.dart';
import '../widgets/detection_overlay.dart';
import '../utils/app_colors.dart';

class LiveDetectionView extends StatefulWidget {
  const LiveDetectionView({super.key});

  @override
  State<LiveDetectionView> createState() => _LiveDetectionViewState();
}

class _LiveDetectionViewState extends State<LiveDetectionView> with WidgetsBindingObserver {
  late LiveDetectionController controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = Get.put(LiveDetectionController());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Get.delete<LiveDetectionController>();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.isInitialized.value) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        controller.stopDetection();
        break;
      case AppLifecycleState.resumed:
        controller.resumeDetection();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.surface,
          ),
        ),
        title: const Text(
          'Live Detection',
          style: TextStyle(
            color: AppColors.surface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Obx(() => IconButton(
                onPressed: controller.toggleFlash,
                icon: Icon(
                  controller.isFlashOn.value
                      ? Icons.flash_on
                      : Icons.flash_off,
                  color: AppColors.surface,
                ),
              )),
        ],
      ),
      body: Obx(() {
        if (!controller.isInitialized.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  controller.error.value.isNotEmpty 
                      ? controller.error.value 
                      : 'Initializing camera...',
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (controller.error.value.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.initializeCamera(),
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          );
        }

        return Stack(
          children: [
            SizedBox.expand(
              child: CameraPreview(controller.cameraController!),
            ),
            if (controller.detections.isNotEmpty)
              Positioned.fill(
                child: DetectionOverlay(
                  detections: controller.detections,
                  imageSize: Size(
                    controller.cameraController!.value.previewSize!.height,
                    controller.cameraController!.value.previewSize!.width,
                  ),
                  screenSize: MediaQuery.of(context).size,
                ),
              ),
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: DetectionInfoCard(
                detection: controller.detections.isNotEmpty
                    ? controller.detections.first
                    : null,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: Icons.pause,
                      onPressed: controller.pauseDetection,
                      backgroundColor: AppColors.warning,
                    ),
                    _buildCaptureButton(
                      onPressed: controller.takePicture,
                    ),
                    _buildControlButton(
                      icon: Icons.play_arrow,
                      onPressed: controller.resumeDetection,
                      backgroundColor: AppColors.success,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 80,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Obx(() => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: controller.isDetecting.value
                                ? AppColors.success
                                : AppColors.textLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          controller.isDetecting.value
                              ? 'Detecting'
                              : 'Paused',
                          style: const TextStyle(
                            color: AppColors.surface,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: AppColors.surface,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildCaptureButton({
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(
          Icons.camera_alt,
          color: AppColors.primary,
          size: 32,
        ),
      ),
    );
  }
}
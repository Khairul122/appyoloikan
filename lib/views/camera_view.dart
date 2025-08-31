import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import '../controllers/camera_controller.dart';
import '../controllers/fish_controller.dart';

class CameraView extends StatelessWidget {
  final CameraControllerX cameraController = Get.find<CameraControllerX>();
  final FishController fishController = Get.find<FishController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Kamera'),
        actions: [
          Obx(() => IconButton(
            icon: Icon(
              cameraController.isFlashOn.value 
                ? Icons.flash_on 
                : Icons.flash_off,
            ),
            onPressed: cameraController.toggleFlash,
          )),
          IconButton(
            icon: Icon(Icons.flip_camera_ios),
            onPressed: cameraController.switchCamera,
          ),
        ],
      ),
      body: Obx(() {
        if (!cameraController.isCameraInitialized.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Menginisialisasi kamera...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            Positioned.fill(
              child: CameraPreview(cameraController.cameraController!),
            ),
            
            _buildOverlayFrame(),
            
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomControls(),
            ),
            
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: _buildInstructions(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildOverlayFrame() {
    return Center(
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.green, width: 3),
                    left: BorderSide(color: Colors.green, width: 3),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.green, width: 3),
                    right: BorderSide(color: Colors.green, width: 3),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.green, width: 3),
                    left: BorderSide(color: Colors.green, width: 3),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.green, width: 3),
                    right: BorderSide(color: Colors.green, width: 3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.camera_alt,
            color: Colors.white,
            size: 24,
          ),
          SizedBox(height: 8),
          Text(
            'Posisikan ikan dalam frame',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            'Pastikan pencahayaan cukup dan ikan terlihat jelas',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () {
              Get.back();
              fishController.pickImageFromGallery();
            },
            icon: Icon(
              Icons.photo_library,
              color: Colors.white,
              size: 28,
            ),
          ),
          
          Obx(() => GestureDetector(
            onTap: fishController.isPredicting.value 
              ? null 
              : _captureImage,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                color: fishController.isPredicting.value 
                  ? Colors.grey 
                  : Colors.transparent,
              ),
              child: fishController.isPredicting.value
                ? Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    Icons.camera,
                    color: Colors.white,
                    size: 32,
                  ),
            ),
          )),
          
          IconButton(
            onPressed: cameraController.switchCamera,
            icon: Icon(
              Icons.flip_camera_ios,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureImage() async {
    try {
      final imageFile = await cameraController.takePicture();
      if (imageFile != null) {
        await cameraController.stopCamera();
        
        Get.back();
        fishController.currentImage.value = imageFile;
        await fishController.predictImage(imageFile);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal mengambil foto: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
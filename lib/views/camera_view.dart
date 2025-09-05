import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import '../controllers/camera_controller.dart';
import '../controllers/fish_controller.dart';
import '../utils/constants.dart';

class CameraView extends StatefulWidget {
  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> 
    with WidgetsBindingObserver {
  
  final CameraControllerX cameraController = Get.find<CameraControllerX>();
  final FishController fishController = Get.find<FishController>();
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    
    if (state == AppLifecycleState.paused) {
      cameraController.stopImageStreamSafe();
    } else if (state == AppLifecycleState.resumed) {
      if (!cameraController.isCameraInitialized.value) {
        cameraController.initializeCamera();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _safeGoBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text('Kamera'),
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: _safeGoBack,
      ),
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
    );
  }

  Widget _buildBody() {
    return Obx(() {
      if (!cameraController.isCameraInitialized.value) {
        return _buildLoadingView();
      }

      if (cameraController.errorMessage.value.isNotEmpty) {
        return _buildErrorView();
      }

      return _buildCameraView();
    });
  }

  Widget _buildLoadingView() {
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

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            SizedBox(height: 16),
            Text(
              'Camera Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              cameraController.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => cameraController.initializeCamera(),
              child: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            _buildCameraPreview(constraints),
            _buildOverlayFrame(constraints),
            _buildInstructions(constraints),
            _buildBottomControls(constraints),
          ],
        );
      },
    );
  }

  Widget _buildCameraPreview(BoxConstraints constraints) {
    return Positioned.fill(
      child: CameraPreview(cameraController.cameraController!),
    );
  }

  Widget _buildOverlayFrame(BoxConstraints constraints) {
    final frameSize = constraints.maxWidth * 0.7;
    return Center(
      child: Container(
        width: frameSize,
        height: frameSize,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: _buildFrameCorners(),
      ),
    );
  }

  Widget _buildFrameCorners() {
    const cornerLength = 30.0;
    return Stack(
      children: [
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            width: cornerLength,
            height: cornerLength,
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
            width: cornerLength,
            height: cornerLength,
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
            width: cornerLength,
            height: cornerLength,
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
            width: cornerLength,
            height: cornerLength,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.green, width: 3),
                right: BorderSide(color: Colors.green, width: 3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions(BoxConstraints constraints) {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.camera_alt, color: Colors.white, size: 24),
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
      ),
    );
  }

  Widget _buildBottomControls(BoxConstraints constraints) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
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
            _buildControlButton(
              icon: Icons.photo_library,
              onPressed: () async {
                await _safeGoBack();
                fishController.pickImageFromGallery();
              },
            ),
            _buildCaptureButton(),
            _buildControlButton(
              icon: Icons.flip_camera_ios,
              onPressed: cameraController.switchCamera,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 28),
    );
  }

  Widget _buildCaptureButton() {
    return Obx(() => GestureDetector(
      onTap: fishController.isPredicting.value ? null : _captureImage,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
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
          : Icon(Icons.camera, color: Colors.white, size: 32),
      ),
    ));
  }

  Future<void> _captureImage() async {
    if (_isDisposed || !cameraController.isReady) return;

    try {
      final imageFile = await cameraController.takePicture();
      if (imageFile != null && !_isDisposed) {
        await _safeGoBack();
        fishController.currentImage.value = imageFile;
        await fishController.predictImage(imageFile);
      }
    } catch (e) {
      if (!_isDisposed) {
        Get.snackbar(
          'Error',
          '${AppConstants.errorPredictionFailed}: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> _safeGoBack() async {
    if (_isDisposed) return;
    
    try {
      await cameraController.stopImageStreamSafe();
      if (!_isDisposed && mounted) {
        Get.back();
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import '../controllers/camera_controller.dart';
import '../controllers/live_detection_controller.dart';
import '../utils/constants.dart';
import '../widgets/detection_overlay.dart';
import '../models/detection_result.dart';

class LiveDetectionView extends StatefulWidget {
  @override
  _LiveDetectionViewState createState() => _LiveDetectionViewState();
}

class _LiveDetectionViewState extends State<LiveDetectionView> 
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  
  final CameraControllerX cameraController = Get.find<CameraControllerX>();
  late final LiveDetectionController detectionController;
  bool _isInitializing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    if (!Get.isRegistered<LiveDetectionController>()) {
      Get.put(LiveDetectionController());
    }
    detectionController = Get.find<LiveDetectionController>();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCamera();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (Get.isRegistered<LiveDetectionController>()) {
      detectionController.stopDetection();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      detectionController.stopDetection();
    } else if (state == AppLifecycleState.resumed) {
      if (mounted) {
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            _initializeCamera();
          }
        });
      }
    }
  }

  Future<void> _initializeCamera() async {
    if (_isInitializing) return;
    
    _isInitializing = true;
    try {
      if (!cameraController.isCameraInitialized.value) {
        await cameraController.initializeCamera();
        await Future.delayed(Duration(milliseconds: 200));
      }
    } catch (e) {
      print('Camera initialization error: $e');
    } finally {
      if (mounted) {
        _isInitializing = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text('Live Detection'),
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () async {
          await detectionController.stopDetection();
          Get.back();
        },
      ),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      if (!cameraController.isCameraInitialized.value || _isInitializing) {
        return _buildLoadingView();
      }

      if (!detectionController.isReady) {
        return _buildModelErrorView();
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
            'Loading camera...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildModelErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, color: Colors.red, size: 64),
          SizedBox(height: 16),
          Text(
            'Detection Model Error',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          SizedBox(height: 8),
          Obx(() => Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              detectionController.errorMessage.value,
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          )),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Get.back(),
            child: Text('Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            _buildCameraPreview(),
            _buildInfoPanel(constraints),
            _buildDetectionOverlay(constraints),
            _buildDetectionCard(constraints),
            _buildControls(constraints),
          ],
        );
      },
    );
  }

  Widget _buildCameraPreview() {
    return Positioned.fill(
      child: CameraPreview(cameraController.cameraController!),
    );
  }

  Widget _buildInfoPanel(BoxConstraints constraints) {
    return Positioned(
      top: 20,
      left: 16,
      right: 16,
      child: Obx(() {
        return Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              _buildStatusIndicator(),
              SizedBox(width: 8),
              _buildStatusText(),
              Spacer(),
              _buildFpsCounter(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatusIndicator() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: detectionController.isDetectionActive.value 
            ? Colors.green 
            : Colors.red,
        shape: BoxShape.circle,
        boxShadow: detectionController.isDetectionActive.value 
            ? [BoxShadow(color: Colors.green, blurRadius: 4, spreadRadius: 1)]
            : null,
      ),
    );
  }

  Widget _buildStatusText() {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: Text(
        detectionController.isDetectionActive.value ? 'DETECTING' : 'STOPPED',
        key: ValueKey(detectionController.isDetectionActive.value),
        style: TextStyle(
          color: Colors.white, 
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildFpsCounter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Obx(() => Text(
        '${detectionController.fps.value} FPS',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      )),
    );
  }

  Widget _buildDetectionCard(BoxConstraints constraints) {
    return Positioned(
      bottom: 120,
      left: 16,
      right: 16,
      child: Obx(() {
        final detection = detectionController.currentDetection.value;
        
        return AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: detection == null 
            ? (detectionController.isDetectionActive.value 
                ? _buildSearchingCard() 
                : SizedBox.shrink())
            : _buildDetectionFoundCard(detection),
        );
      }),
    );
  }

  Widget _buildSearchingCard() {
    return Container(
      key: ValueKey('searching'),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Searching for fish...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionFoundCard(DetectionResult detection) {
    return Container(
      key: ValueKey('detection_${detection.label}'),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDetectionHeader(detection),
          SizedBox(height: 12),
          _buildConfidenceBar(detection),
        ],
      ),
    );
  }

  Widget _buildDetectionHeader(DetectionResult detection) {
    return Row(
      children: [
        Icon(Icons.check_circle, color: Colors.white, size: 24),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            detection.displayName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            detection.confidencePercentage,
            style: TextStyle(
              color: Colors.green,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceBar(DetectionResult detection) {
    return Container(
      width: double.infinity,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: detection.confidence,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildDetectionOverlay(BoxConstraints constraints) {
    return Positioned.fill(
      child: Obx(() {
        final detection = detectionController.currentDetection.value;
        
        return AnimatedSwitcher(
          duration: Duration(milliseconds: 200),
          child: detection == null
              ? SizedBox.shrink()
              : CustomPaint(
                  painter: DetectionPainter(detection: detection),
                  child: Container(),
                ),
        );
      }),
    );
  }

  Widget _buildControls(BoxConstraints constraints) {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildClearButton(),
            SizedBox(width: 20),
            _buildToggleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return FloatingActionButton(
      mini: true,
      heroTag: "clear_detection_btn",
      onPressed: detectionController.clearDetection,
      backgroundColor: Colors.orange[600],
      child: Icon(Icons.clear, color: Colors.white),
    );
  }

  Widget _buildToggleButton() {
    return Obx(() => FloatingActionButton.extended(
      heroTag: "toggle_detection_btn",
      onPressed: _toggleDetection,
      backgroundColor: detectionController.isDetectionActive.value
          ? Colors.red[600]
          : Colors.green[600],
      icon: Icon(
        detectionController.isDetectionActive.value
            ? Icons.stop
            : Icons.play_arrow,
        color: Colors.white,
      ),
      label: Text(
        detectionController.isDetectionActive.value
            ? 'Stop'
            : 'Start',
        style: TextStyle(color: Colors.white),
      ),
    ));
  }

  Future<void> _toggleDetection() async {
    if (!detectionController.isReady) {
      Get.snackbar('Error', AppConstants.errorModelNotLoaded);
      return;
    }

    if (!cameraController.isReady) {
      Get.snackbar('Error', AppConstants.errorCameraNotAvailable);
      return;
    }

    try {
      if (detectionController.isDetectionActive.value) {
        await detectionController.stopDetection();
      } else {
        final cameraControllerInstance = cameraController.cameraController;
        if (cameraControllerInstance != null) {
          await detectionController.startDetection(cameraControllerInstance);
        } else {
          Get.snackbar('Error', 'Camera controller is not initialized');
        }
      }
    } catch (e) {
      Get.snackbar('Error', '${AppConstants.errorPredictionFailed}: $e');
    }
  }
}
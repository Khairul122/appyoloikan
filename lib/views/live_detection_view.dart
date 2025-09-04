import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import '../controllers/camera_controller.dart';
import '../controllers/live_detection_controller.dart';

class LiveDetectionView extends StatefulWidget {
  @override
  _LiveDetectionViewState createState() => _LiveDetectionViewState();
}

class _LiveDetectionViewState extends State<LiveDetectionView> 
    with WidgetsBindingObserver {
  
  final CameraControllerX cameraController = Get.find<CameraControllerX>();
  late final LiveDetectionController detectionController;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    if (!Get.isRegistered<LiveDetectionController>()) {
      Get.put(LiveDetectionController());
    }
    detectionController = Get.find<LiveDetectionController>();
    
    _initializeDetection();
  }

  @override
  void dispose() {
    print('LiveDetectionView disposing...');
    _isDisposed = true;
    
    WidgetsBinding.instance.removeObserver(this);
    
    if (Get.isRegistered<LiveDetectionController>()) {
      detectionController.stopDetection();
    }
    
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    
    if (state == AppLifecycleState.paused) {
      detectionController.stopDetection();
    }
  }

  void _initializeDetection() async {
    try {
      if (_isDisposed) return;
      
      await detectionController.initializeModel();
      
      if (!_isDisposed && !cameraController.isCameraInitialized.value) {
        await cameraController.initializeCamera();
      }
    } catch (e) {
      print('Initialization error: $e');
    }
  }

  void _safeGoBack() {
    if (_isDisposed) return;
    
    try {
      detectionController.stopDetection();
      Future.delayed(Duration(milliseconds: 200), () {
        if (!_isDisposed && mounted && Get.context != null) {
          Get.back();
        }
      });
    } catch (e) {
      print('Error going back: $e');
      if (!_isDisposed && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _safeGoBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text('Live Detection'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: _safeGoBack,
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      if (!cameraController.isCameraInitialized.value) {
        return _buildLoadingView();
      }

      if (!detectionController.isModelLoaded.value) {
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
            'Model Loading Failed',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            detectionController.errorMessage.value,
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _safeGoBack,
            child: Text('Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        // Camera Preview
        Positioned.fill(
          child: CameraPreview(cameraController.cameraController!),
        ),
        
        // Info Panel
        Positioned(
          top: 20,
          left: 16,
          right: 16,
          child: _buildInfoPanel(),
        ),
        
        // Detection Overlay
        Positioned.fill(
          child: _buildDetectionOverlay(),
        ),
        
        // Controls
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: _buildControls(),
        ),
      ],
    );
  }

  Widget _buildInfoPanel() {
    return Obx(() {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: detectionController.isDetectionActive.value 
                        ? Colors.green 
                        : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  detectionController.isDetectionActive.value ? 'DETECTING' : 'STOPPED',
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${detectionController.fps.value} FPS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            if (detectionController.hasDetections) ...[
              SizedBox(height: 12),
              Text(
                'Detections:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              ...detectionController.detectionResults.take(3).map((detection) {
                return Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 6),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        color: Colors.green,
                        size: 8,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          detection.displayName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          detection.confidencePercentage,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ] else if (detectionController.isDetectionActive.value) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Searching for fish...',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildDetectionOverlay() {
    return Obx(() {
      if (!detectionController.hasDetections) {
        return SizedBox.shrink();
      }

      return CustomPaint(
        painter: _DetectionPainter(detectionController.detectionResults),
        child: Container(),
      );
    });
  }

  Widget _buildControls() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Clear button with unique hero tag
          FloatingActionButton(
            mini: true,
            heroTag: "clear_detection_btn",
            onPressed: detectionController.clearDetections,
            backgroundColor: Colors.orange[600],
            child: Icon(Icons.clear, color: Colors.white),
          ),
          
          SizedBox(width: 20),
          
          // Start/Stop button with unique hero tag
          Obx(() => FloatingActionButton.extended(
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
          )),
        ],
      ),
    );
  }

  void _toggleDetection() {
    if (_isDisposed) return;
    
    if (!detectionController.isModelLoaded.value) {
      Get.snackbar('Error', 'Model not loaded');
      return;
    }

    if (!cameraController.isCameraInitialized.value) {
      Get.snackbar('Error', 'Camera not ready');
      return;
    }

    try {
      if (detectionController.isDetectionActive.value) {
        detectionController.stopDetection();
      } else {
        detectionController.startDetection(cameraController.cameraController!);
      }
    } catch (e) {
      print('Toggle detection error: $e');
      Get.snackbar('Error', 'Failed to toggle detection');
    }
  }
}

class _DetectionPainter extends CustomPainter {
  final List<dynamic> detections;

  _DetectionPainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty) return;
    
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    for (final detection in detections.take(3)) {
      final rect = Rect.fromLTWH(
        detection.x.toDouble().clamp(0.0, size.width - 20),
        detection.y.toDouble().clamp(0.0, size.height - 20),
        detection.width.toDouble().clamp(20.0, size.width),
        detection.height.toDouble().clamp(20.0, size.height),
      );

      canvas.drawRect(rect, paint);
      _drawCorners(canvas, rect, paint);
      _drawLabel(canvas, detection, rect);
    }
  }

  void _drawCorners(Canvas canvas, Rect rect, Paint paint) {
    final cornerLength = 15.0;
    
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(cornerLength, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(0, cornerLength), paint);
    
    canvas.drawLine(rect.topRight, rect.topRight + Offset(-cornerLength, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + Offset(0, cornerLength), paint);
    
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(cornerLength, 0), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(0, -cornerLength), paint);
    
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(-cornerLength, 0), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(0, -cornerLength), paint);
  }

  void _drawLabel(Canvas canvas, dynamic detection, Rect rect) {
    final textSpan = TextSpan(
      text: '${detection.displayName}\n${detection.confidencePercentage}',
      style: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final labelRect = Rect.fromLTWH(
      rect.left,
      rect.top - textPainter.height - 8,
      textPainter.width + 12,
      textPainter.height + 8,
    );

    final labelPaint = Paint()..color = Colors.green;
    canvas.drawRect(labelRect, labelPaint);
    textPainter.paint(canvas, Offset(labelRect.left + 6, labelRect.top + 4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
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
    if (state == AppLifecycleState.paused) {
      detectionController.stopDetection();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  void _initializeCamera() async {
    try {
      if (!cameraController.isCameraInitialized.value) {
        await cameraController.initializeCamera();
      }
    } catch (e) {
      print('Camera initialization error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Live Detection'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            detectionController.stopDetection();
            Get.back();
          },
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      if (!cameraController.isCameraInitialized.value) {
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
    return Stack(
      children: [
        Positioned.fill(
          child: CameraPreview(cameraController.cameraController!),
        ),
        
        Positioned(
          top: 20,
          left: 16,
          right: 16,
          child: _buildInfoPanel(),
        ),
        
        Positioned.fill(
          child: _buildDetectionOverlay(),
        ),
        
        Positioned(
          bottom: 120,
          left: 16,
          right: 16,
          child: _buildDetectionCard(),
        ),
        
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
        child: Row(
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
      );
    });
  }

  Widget _buildDetectionCard() {
    return Obx(() {
      final detection = detectionController.currentDetection.value;
      
      if (detection == null) {
        if (detectionController.isDetectionActive.value) {
          return Container(
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
        return SizedBox.shrink();
      }

      return Container(
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
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 24,
                ),
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
            ),
            SizedBox(height: 12),
            Container(
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
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDetectionOverlay() {
    return Obx(() {
      final detection = detectionController.currentDetection.value;
      
      if (detection == null) {
        return SizedBox.shrink();
      }

      return CustomPaint(
        painter: _DetectionPainter(detection, cameraController.cameraController!.value.previewSize!),
        child: Container(),
      );
    });
  }

  Widget _buildControls() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            mini: true,
            heroTag: "clear_detection_btn",
            onPressed: detectionController.clearDetection,
            backgroundColor: Colors.orange[600],
            child: Icon(Icons.clear, color: Colors.white),
          ),
          
          SizedBox(width: 20),
          
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
    if (!detectionController.isReady) {
      Get.snackbar('Error', 'Detection not ready');
      return;
    }

    if (!cameraController.isReady) {
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
      Get.snackbar('Error', 'Failed to toggle detection: $e');
    }
  }
}

class _DetectionPainter extends CustomPainter {
  final dynamic detection;
  final Size previewSize;

  _DetectionPainter(this.detection, this.previewSize);

  @override
  void paint(Canvas canvas, Size size) {
    if (detection == null) return;
    
    try {
      final scaleX = size.width / previewSize.width;
      final scaleY = size.height / previewSize.height;
      
      final x = detection.x * scaleX;
      final y = detection.y * scaleY;
      final width = detection.width * scaleX;
      final height = detection.height * scaleY;
      
      final rect = Rect.fromLTWH(x, y, width, height);

      final confidence = detection.confidence.toDouble();
      final color = _getConfidenceColor(confidence);

      final fillPaint = Paint()
        ..color = color.withOpacity(0.2)
        ..style = PaintingStyle.fill;

      final strokePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, strokePaint);
      
      _drawLabel(canvas, detection, rect, color);
      
    } catch (e) {
      print('Error drawing detection: $e');
    }
  }

  void _drawLabel(Canvas canvas, dynamic detection, Rect rect, Color color) {
    final textSpan = TextSpan(
      children: [
        TextSpan(
          text: detection.displayName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: '\n${detection.confidencePercentage}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final labelRect = Rect.fromLTWH(
      rect.left,
      (rect.top - textPainter.height - 12).clamp(0, rect.top),
      textPainter.width + 16,
      textPainter.height + 12,
    );

    final labelPaint = Paint()
      ..color = color;

    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, Radius.circular(6)),
      labelPaint,
    );

    textPainter.paint(canvas, Offset(labelRect.left + 8, labelRect.top + 6));
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.7) return Colors.lightGreen;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
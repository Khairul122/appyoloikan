import 'dart:async';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import '../models/detection_result.dart';
import '../services/live_detection_service.dart';
import 'dart:ui' show Size;

class LiveDetectionController extends GetxController {
  final LiveDetectionService _detectionService = LiveDetectionService.instance;
  
  Size? previewSize;
  var isDetectionActive = false.obs;
  var isDetecting = false.obs;
  var currentDetection = Rxn<DetectionResult>();
  var fps = 0.obs;
  var errorMessage = ''.obs;
  var isModelLoaded = false.obs;

  Timer? _fpsTimer;
  CameraController? _cameraController;
  int _frameCount = 0;
  int _processedFrames = 0;
  bool _isProcessing = false;

  static const int _frameSkip = 3;
  int _frameCounter = 0;

  @override
  void onInit() {
    super.onInit();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      final success = await _detectionService.loadModel();
      if (success) {
        isModelLoaded.value = true;
        errorMessage.value = '';
      } else {
        isModelLoaded.value = false;
        errorMessage.value = 'Failed to load detection model';
      }
    } catch (e) {
      isModelLoaded.value = false;
      errorMessage.value = 'Error loading model: $e';
    }
  }

  Future<void> startDetection(CameraController cameraController) async {
    if (!isModelLoaded.value || isDetectionActive.value) {
      return;
    }

    try {
      await stopDetection();

      _cameraController = cameraController;
      final ps = _cameraController!.value.previewSize;
      if (ps != null) {
        previewSize = Size(ps.width, ps.height);
      }
      
      isDetectionActive.value = true;
      errorMessage.value = '';
      _frameCount = 0;
      _processedFrames = 0;
      _frameCounter = 0;
      _isProcessing = false;
      currentDetection.value = null;

      _startFpsCounter();
      await _startImageStream();
    } catch (e) {
      errorMessage.value = 'Failed to start detection: $e';
      isDetectionActive.value = false;
    }
  }

  Future<void> _startImageStream() async {
    if (_cameraController == null) return;

    try {
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
        await Future.delayed(Duration(milliseconds: 50));
      }

      await _cameraController!.startImageStream(_onFrame);
    } catch (e) {
      errorMessage.value = 'Failed to start image stream: $e';
    }
  }

  void _onFrame(CameraImage cameraImage) async {
    if (!isDetectionActive.value || _isProcessing) return;

    _frameCount++;
    _frameCounter++;

    if (_frameCounter % _frameSkip != 0) return;

    _processFrame(cameraImage);
  }

  void _processFrame(CameraImage cameraImage) async {
    if (_isProcessing || !isDetectionActive.value) return;

    _isProcessing = true;
    isDetecting.value = true;

    try {
      final result = await _detectionService.detectFromCameraData({
        'width': cameraImage.width,
        'height': cameraImage.height,
        'format': cameraImage.format.group.index,
        'planes': cameraImage.planes
            .map((plane) => {
                  'bytes': plane.bytes,
                  'bytesPerRow': plane.bytesPerRow,
                  'bytesPerPixel': plane.bytesPerPixel,
                })
            .toList(),
      });

      if (isDetectionActive.value) {
        if (result != null) {
          final detection = DetectionResult(
            label: result['label'] as String,
            confidence: result['confidence'] as double,
            classIndex: result['classIndex'] as int,
            x: result['x'] as double,
            y: result['y'] as double,
            width: result['width'] as double,
            height: result['height'] as double,
          );

          currentDetection.value = detection;
          _processedFrames++;
        } else {
          currentDetection.value = null;
        }
      }
    } catch (e) {
      if (isDetectionActive.value) {
        errorMessage.value = 'Detection error: $e';
      }
    } finally {
      isDetecting.value = false;
      _isProcessing = false;
    }
  }

  Future<void> stopDetection() async {
    isDetectionActive.value = false;
    isDetecting.value = false;
    _isProcessing = false;

    try {
      if (_cameraController != null && _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
        await Future.delayed(Duration(milliseconds: 50));
      }
    } catch (e) {
      print('Error stopping image stream: $e');
    }

    _fpsTimer?.cancel();
    _fpsTimer = null;
    _cameraController = null;

    currentDetection.value = null;
    fps.value = 0;
    _frameCount = 0;
    _processedFrames = 0;
    _frameCounter = 0;
  }

  void _startFpsCounter() {
    _frameCount = 0;
    _processedFrames = 0;
    _fpsTimer?.cancel();
    _fpsTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (isDetectionActive.value) {
        fps.value = _processedFrames;
        _frameCount = 0;
        _processedFrames = 0;
      } else {
        timer.cancel();
      }
    });
  }

  void clearDetection() {
    currentDetection.value = null;
  }

  void toggleDetection() {
    if (isDetectionActive.value) {
      stopDetection();
    } else if (_cameraController != null) {
      startDetection(_cameraController!);
    }
  }

  bool get hasDetection => currentDetection.value != null;
  DetectionResult? get topDetection => currentDetection.value;
  bool get isReady => isModelLoaded.value && errorMessage.value.isEmpty;

  @override
  void onClose() {
    stopDetection();
    _detectionService.dispose();
    super.onClose();
  }
}
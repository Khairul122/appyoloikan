import 'dart:async';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import '../models/detection_result.dart';
import '../services/live_detection_service.dart';

class LiveDetectionController extends GetxController {
  final LiveDetectionService _detectionService = LiveDetectionService.instance;
  
  var isDetectionActive = false.obs;
  var isDetecting = false.obs;
  var detectionResults = <DetectionResult>[].obs;
  var fps = 0.obs;
  var errorMessage = ''.obs;
  var isModelLoaded = false.obs;
  
  Timer? _fpsTimer;
  CameraController? _cameraController;
  int _frameCount = 0;
  int _skipCount = 0;
  bool _isProcessing = false;
  
  static const int _skipFrames = 15;

  @override
  void onInit() {
    super.onInit();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      print('Loading detection model...');
      final success = await _detectionService.loadModel();
      if (success) {
        isModelLoaded.value = true;
        errorMessage.value = '';
        print('Detection model loaded successfully');
      } else {
        isModelLoaded.value = false;
        errorMessage.value = 'Failed to load detection model';
        print('Failed to load detection model');
      }
    } catch (e) {
      isModelLoaded.value = false;
      errorMessage.value = 'Error loading model: $e';
      print('Error loading detection model: $e');
    }
  }

  void startDetection(CameraController cameraController) {
    if (!isModelLoaded.value) {
      Get.snackbar('Error', 'Model not loaded yet');
      return;
    }
    
    try {
      stopDetection();
      
      _cameraController = cameraController;
      isDetectionActive.value = true;
      errorMessage.value = '';
      _frameCount = 0;
      _skipCount = 0;
      _isProcessing = false;
      
      _startFpsCounter();
      _startImageStream();
      
      print('Detection started');
      
    } catch (e) {
      errorMessage.value = 'Failed to start detection: $e';
      isDetectionActive.value = false;
      print('Error starting detection: $e');
    }
  }

  void _startImageStream() {
    if (_cameraController == null) return;
    
    try {
      _cameraController!.startImageStream((CameraImage image) {
        _skipCount++;
        
        if (_skipCount < _skipFrames || _isProcessing || !isDetectionActive.value) {
          return;
        }
        
        _skipCount = 0;
        _processFrame(image);
      });
    } catch (e) {
      errorMessage.value = 'Failed to start image stream: $e';
      print('Error starting image stream: $e');
    }
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
        'planes': cameraImage.planes.map((plane) => {
          'bytes': plane.bytes,
          'bytesPerRow': plane.bytesPerRow,
          'bytesPerPixel': plane.bytesPerPixel,
        }).toList(),
      });
      
      if (isDetectionActive.value && result.isNotEmpty) {
        final detections = result.map((r) => DetectionResult(
          label: r['label'] as String,
          confidence: r['confidence'] as double,
          classIndex: r['classIndex'] as int,
          x: r['x'] as double,
          y: r['y'] as double,
          width: r['width'] as double,
          height: r['height'] as double,
        )).toList();
        
        detectionResults.assignAll(detections);
        _frameCount++;
      }
      
    } catch (e) {
      if (isDetectionActive.value) {
        print('Detection error: $e');
      }
    } finally {
      isDetecting.value = false;
      _isProcessing = false;
    }
  }

  void stopDetection() {
    isDetectionActive.value = false;
    isDetecting.value = false;
    _isProcessing = false;
    
    try {
      _cameraController?.stopImageStream();
    } catch (e) {
      print('Error stopping image stream: $e');
    }
    
    _fpsTimer?.cancel();
    _fpsTimer = null;
    _cameraController = null;
    
    detectionResults.clear();
    fps.value = 0;
    _frameCount = 0;
    _skipCount = 0;
    
    print('Detection stopped');
  }

  void _startFpsCounter() {
    _frameCount = 0;
    _fpsTimer?.cancel();
    _fpsTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (isDetectionActive.value) {
        fps.value = _frameCount;
        _frameCount = 0;
      } else {
        timer.cancel();
      }
    });
  }

  void clearDetections() {
    detectionResults.clear();
  }

  void toggleDetection() {
    if (isDetectionActive.value) {
      stopDetection();
    } else if (_cameraController != null) {
      startDetection(_cameraController!);
    }
  }

  bool get hasDetections => detectionResults.isNotEmpty;
  DetectionResult? get topDetection => detectionResults.isNotEmpty ? detectionResults.first : null;
  int get detectionsCount => detectionResults.length;
  bool get isReady => isModelLoaded.value && errorMessage.value.isEmpty;

  @override
  void onClose() {
    stopDetection();
    _detectionService.dispose();
    super.onClose();
  }
}
import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
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
  
  static const int _skipFrames = 60;

  Future<void> initializeModel() async {
    try {
      if (isModelLoaded.value) return;
      
      final success = await _detectionService.loadModel();
      isModelLoaded.value = success;
      if (!success) {
        errorMessage.value = 'Failed to load detection model';
      }
    } catch (e) {
      errorMessage.value = 'Error initializing model: $e';
    }
  }

  void startDetection(CameraController cameraController) {
    if (!isModelLoaded.value) return;
    
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
      
    } catch (e) {
      errorMessage.value = 'Failed to start detection: $e';
      isDetectionActive.value = false;
    }
  }

  void _startImageStream() {
    if (_cameraController == null) return;
    
    _cameraController!.startImageStream((CameraImage image) {
      _skipCount++;
      
      if (_skipCount < _skipFrames || _isProcessing || !isDetectionActive.value) {
        return;
      }
      
      _skipCount = 0;
      _processFrameWithIsolate(image);
    });
  }

  void _processFrameWithIsolate(CameraImage cameraImage) async {
    if (_isProcessing || !isDetectionActive.value) return;
    
    _isProcessing = true;
    isDetecting.value = true;
    
    try {
      final result = await Isolate.run(() => _isolateDetection({
        'width': cameraImage.width,
        'height': cameraImage.height,
        'format': cameraImage.format.group.index,
        'planes': cameraImage.planes.map((plane) => {
          'bytes': plane.bytes,
          'bytesPerRow': plane.bytesPerRow,
          'bytesPerPixel': plane.bytesPerPixel,
        }).toList(),
      }));
      
      if (isDetectionActive.value && result != null && result.isNotEmpty) {
        final detections = result.map((r) => DetectionResult(
          label: r['label'],
          confidence: r['confidence'],
          classIndex: r['classIndex'],
          x: r['x'],
          y: r['y'],
          width: r['width'],
          height: r['height'],
        )).toList();
        
        detectionResults.assignAll(detections);
        _frameCount++;
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

  static Future<List<Map<String, dynamic>>?> _isolateDetection(Map<String, dynamic> data) async {
    try {
      final service = LiveDetectionService.instance;
      if (!service.isModelLoaded) {
        await service.loadModel();
      }
      
      return await service.detectFromCameraData(data);
    } catch (e) {
      return null;
    }
  }

  void stopDetection() {
    isDetectionActive.value = false;
    isDetecting.value = false;
    _isProcessing = false;
    
    try {
      _cameraController?.stopImageStream();
    } catch (e) {
    }
    
    _fpsTimer?.cancel();
    _fpsTimer = null;
    
    _cameraController = null;
    
    detectionResults.clear();
    fps.value = 0;
    _frameCount = 0;
    _skipCount = 0;
    
    Future.delayed(Duration(milliseconds: 100), () {
    });
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

  bool get hasDetections => detectionResults.isNotEmpty;
  
  DetectionResult? get topDetection => 
      detectionResults.isNotEmpty ? detectionResults.first : null;

  @override
  void onClose() {
    stopDetection();
    _detectionService.dispose();
    super.onClose();
  }
}
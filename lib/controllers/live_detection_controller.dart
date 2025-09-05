import 'dart:async';
import 'dart:collection';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import '../models/detection_result.dart';
import '../services/live_detection_service.dart';
import '../utils/constants.dart';
import 'dart:ui' show Size;
import 'dart:isolate';

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
  int _frameCounter = 0;
  
  final Queue<CameraImage> _frameQueue = Queue<CameraImage>();
  bool _isProcessingFrame = false;
  Timer? _processingTimer;
  Completer<void>? _stopCompleter;

  @override
  void onInit() {
    super.onInit();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      isModelLoaded.value = false;
      final success = await _detectionService.loadModel();
      if (success) {
        isModelLoaded.value = true;
        errorMessage.value = '';
      } else {
        isModelLoaded.value = false;
        errorMessage.value = AppConstants.errorModelNotLoaded;
      }
    } catch (e) {
      isModelLoaded.value = false;
      errorMessage.value = '${AppConstants.errorModelNotLoaded}: $e';
    }
  }

  Future<void> startDetection(CameraController cameraController) async {
    if (!isModelLoaded.value || isDetectionActive.value) {
      return;
    }

    try {
      await stopDetection();

      _cameraController = cameraController;
      final ps = cameraController.value.previewSize;
      if (ps != null) {
        previewSize = Size(ps.width, ps.height);
      }
      
      _resetCounters();
      isDetectionActive.value = true;
      errorMessage.value = '';
      currentDetection.value = null;

      _startFpsCounter();
      _startProcessingTimer();
      await _startImageStream();
    } catch (e) {
      errorMessage.value = '${AppConstants.errorPredictionFailed}: $e';
      isDetectionActive.value = false;
    }
  }

  void _resetCounters() {
    _frameCount = 0;
    _processedFrames = 0;
    _frameCounter = 0;
    _isProcessingFrame = false;
    _frameQueue.clear();
  }

  Future<void> _startImageStream() async {
    if (_cameraController == null) return;

    try {
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
        await Future.delayed(Duration(milliseconds: 100));
      }

      await _cameraController!.startImageStream(_onFrame);
    } catch (e) {
      errorMessage.value = '${AppConstants.errorCameraNotAvailable}: $e';
      await stopDetection();
    }
  }

  void _onFrame(CameraImage cameraImage) {
    if (!isDetectionActive.value) return;

    _frameCount++;
    _frameCounter++;

    if (_frameCounter % AppConstants.frameStride != 0) return;

    if (_frameQueue.length < 2) {
      _frameQueue.add(cameraImage);
    } else {
      if (_frameQueue.isNotEmpty) {
        _frameQueue.removeFirst();
      }
      _frameQueue.add(cameraImage);
    }
  }

  void _startProcessingTimer() {
    _processingTimer?.cancel();
    _processingTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!isDetectionActive.value) {
        timer.cancel();
        return;
      }
      _processQueuedFrames();
    });
  }

  void _processQueuedFrames() async {
    if (_isProcessingFrame || _frameQueue.isEmpty || !isDetectionActive.value) {
      return;
    }

    _isProcessingFrame = true;
    isDetecting.value = true;

    try {
      final cameraImage = _frameQueue.removeFirst();
      
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
        errorMessage.value = '${AppConstants.errorPredictionFailed}: $e';
      }
    } finally {
      isDetecting.value = false;
      _isProcessingFrame = false;
    }
  }

  Future<void> stopDetection() async {
    if (!isDetectionActive.value && _stopCompleter == null) return;
    
    if (_stopCompleter != null) {
      return _stopCompleter!.future;
    }
    
    _stopCompleter = Completer<void>();
    
    try {
      isDetectionActive.value = false;
      isDetecting.value = false;
      _isProcessingFrame = false;

      _processingTimer?.cancel();
      _processingTimer = null;

      _frameQueue.clear();

      if (_cameraController != null && _cameraController!.value.isStreamingImages) {
        try {
          await _cameraController!.stopImageStream();
          await Future.delayed(Duration(milliseconds: 100));
        } catch (e) {
          print('Error stopping image stream: $e');
        }
      }

      _fpsTimer?.cancel();
      _fpsTimer = null;
      _cameraController = null;

      currentDetection.value = null;
      fps.value = 0;
      _resetCounters();
      
      _stopCompleter!.complete();
    } catch (e) {
      _stopCompleter!.completeError(e);
    } finally {
      _stopCompleter = null;
    }
  }

  void _startFpsCounter() {
    _fpsTimer?.cancel();
    _fpsTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (isDetectionActive.value) {
        fps.value = _processedFrames;
        _processedFrames = 0;
      } else {
        timer.cancel();
      }
    });
  }

  void clearDetection() {
    currentDetection.value = null;
  }

  Future<void> toggleDetection() async {
    if (isDetectionActive.value) {
      await stopDetection();
    } else if (_cameraController != null) {
      await startDetection(_cameraController!);
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
import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '../models/detection_result.dart';
import '../utils/constants.dart';
import 'inference_isolate.dart';

class LiveDetectionService {
  static final LiveDetectionService _instance = LiveDetectionService._internal();
  factory LiveDetectionService() => _instance;
  LiveDetectionService._internal();

  StreamController<List<DetectionResult>>? _detectionController;
  StreamController<CameraImage>? _imageController;
  StreamSubscription? _imageSubscription;
  
  bool _isProcessing = false;
  bool _isActive = false;
  int _frameSkipCount = 0;
  int _totalFrameCount = 0;
  DateTime _lastInferenceTime = DateTime.now();
  List<String> _labels = [];
  
  static const int _frameSkipThreshold = 5;
  static const int _maxInferencePerSecond = 8;

  Stream<List<DetectionResult>> get detectionStream {
    _detectionController ??= StreamController<List<DetectionResult>>.broadcast();
    return _detectionController!.stream;
  }

  Future<void> initialize() async {
    await InferenceIsolate.initialize();
    await _loadLabels();
    
    _imageController = StreamController<CameraImage>.broadcast();
    _detectionController ??= StreamController<List<DetectionResult>>.broadcast();
    
    _imageSubscription = _imageController!.stream.listen(_processImageFrame);
    _isActive = true;
  }

  Future<void> _loadLabels() async {
    try {
      final labelsData = await rootBundle.loadString('lib/assets/models/labels.txt');
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
    } catch (e) {
      _labels = AppConstants.fishClasses;
    }
  }

  void addImageFrame(CameraImage image) {
    if (!_isActive || _imageController == null) return;
    
    _totalFrameCount++;
    
    final now = DateTime.now();
    final timeSinceLastInference = now.difference(_lastInferenceTime).inMilliseconds;
    final minIntervalMs = 1000 ~/ _maxInferencePerSecond;
    
    if (_isProcessing || timeSinceLastInference < minIntervalMs) {
      return;
    }
    
    _frameSkipCount++;
    if (_frameSkipCount >= _frameSkipThreshold) {
      _frameSkipCount = 0;
      _lastInferenceTime = now;
      _imageController!.add(image);
    }
  }

  Future<void> _processImageFrame(CameraImage cameraImage) async {
    if (_isProcessing || !_isActive) return;
    
    _isProcessing = true;
    
    try {
      final imageBytes = await _convertCameraImageToJpeg(cameraImage);
      
      final results = await InferenceIsolate.runInference(
        imageBytes: imageBytes,
        labels: _labels,
        isLiveDetection: true,
      );
      
      final filteredResults = results.where(
        (result) => result.confidence >= AppConstants.confidenceThreshold
      ).toList();
      
      if (_isActive && _detectionController != null) {
        _detectionController!.add(filteredResults);
      }
    } catch (e) {
      debugPrint('Detection processing error: $e');
      if (_isActive && _detectionController != null) {
        _detectionController!.add([]);
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<Uint8List> _convertCameraImageToJpeg(CameraImage cameraImage) async {
    try {
      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420ToJpeg(cameraImage);
      } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888ToJpeg(cameraImage);
      } else {
        throw UnsupportedError('Unsupported image format: ${cameraImage.format.group}');
      }
    } catch (e) {
      debugPrint('Image conversion error: $e');
      rethrow;
    }
  }

  Uint8List _convertYUV420ToJpeg(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    
    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    final vPlane = cameraImage.planes[2];
    
    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;
    
    final image = img.Image(width: width, height: height);
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yPlane.bytesPerRow + x;
        final uvIndex = (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2);
        
        if (yIndex >= yBuffer.length || uvIndex >= uBuffer.length || uvIndex >= vBuffer.length) {
          continue;
        }
        
        final yValue = yBuffer[yIndex].toInt();
        final uValue = uBuffer[uvIndex].toInt();
        final vValue = vBuffer[uvIndex].toInt();
        
        final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
        final g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).clamp(0, 255).toInt();
        final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();
        
        image.setPixelRgb(x, y, r, g, b);
      }
    }
    
    return Uint8List.fromList(img.encodeJpg(image));
  }

  Uint8List _convertBGRA8888ToJpeg(CameraImage cameraImage) {
    final bytes = cameraImage.planes[0].bytes;
    final width = cameraImage.width;
    final height = cameraImage.height;
    
    final image = img.Image(width: width, height: height);
    
    for (int i = 0, pixelIndex = 0; i < bytes.length && pixelIndex < width * height; i += 4, pixelIndex++) {
      final x = pixelIndex % width;
      final y = pixelIndex ~/ width;
      
      final r = bytes[i + 2];
      final g = bytes[i + 1];
      final b = bytes[i];
      
      image.setPixelRgb(x, y, r, g, b);
    }
    
    return Uint8List.fromList(img.encodeJpg(image));
  }

  void pause() {
    _isActive = false;
  }

  void resume() {
    _isActive = true;
    _frameSkipCount = 0;
  }

  void dispose() {
    _isActive = false;
    _isProcessing = false;
    
    _imageSubscription?.cancel();
    _imageSubscription = null;
    
    _imageController?.close();
    _imageController = null;
    
    _detectionController?.close();
    _detectionController = null;
    
    InferenceIsolate.dispose();
    
    _frameSkipCount = 0;
    _totalFrameCount = 0;
  }
}
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/detection_result.dart';
import '../utils/constants.dart';

class MLService {
  static final MLService _instance = MLService._internal();
  factory MLService() => _instance;
  MLService._internal();

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isModelLoaded = false;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(AppConstants.modelPath);
      await _loadLabels();
      _isModelLoaded = true;
    } catch (e) {
      throw Exception('Failed to load model: $e');
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labelsData = await rootBundle.loadString('lib/assets/models/labels.txt');
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
    } catch (e) {
      _labels = AppConstants.fishClasses;
    }
  }

  Future<List<DetectionResult>> detectObjects(Uint8List imageBytes) async {
    if (!_isModelLoaded || _interpreter == null) {
      throw Exception('Model not loaded');
    }

    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    final resizedImage = img.copyResize(
      image,
      width: AppConstants.uploadImageSize,
      height: AppConstants.uploadImageSize,
    );

    final input = _preprocessImage(resizedImage);
    final output = _runInference(input);
    
    return _postprocessOutput(
      output[0],
      image.width.toDouble(),
      image.height.toDouble(),
    );
  }

  Float32List _preprocessImage(img.Image image) {
    final input = Float32List(1 * AppConstants.uploadImageSize * AppConstants.uploadImageSize * 3);
    int pixelIndex = 0;

    for (int y = 0; y < AppConstants.uploadImageSize; y++) {
      for (int x = 0; x < AppConstants.uploadImageSize; x++) {
        final pixel = image.getPixel(x, y);
        input[pixelIndex++] = pixel.r / 255.0;
        input[pixelIndex++] = pixel.g / 255.0;
        input[pixelIndex++] = pixel.b / 255.0;
      }
    }

    return input;
  }

  List<List<List<double>>> _runInference(Float32List input) {
    final inputTensor = input.reshape([1, AppConstants.uploadImageSize, AppConstants.uploadImageSize, 3]);
    
    final outputTensor = List.generate(1, (_) => 
      List.generate(14, (_) => List.filled(8400, 0.0)));
    
    _interpreter!.run(inputTensor, outputTensor);
    return outputTensor;
  }

  List<DetectionResult> _postprocessOutput(
    List<List<double>> output,
    double originalWidth,
    double originalHeight,
  ) {
    final detections = <DetectionResult>[];
    final numClasses = _labels.length;
    const numDetections = 8400;

    for (int i = 0; i < numDetections; i++) {
      final centerX = output[0][i];
      final centerY = output[1][i];
      final width = output[2][i];
      final height = output[3][i];
      final objectConfidence = output[4][i];

      if (objectConfidence < AppConstants.confidenceThreshold) continue;

      double maxClassConfidence = 0.0;
      int maxClassIndex = 0;

      for (int j = 0; j < numClasses; j++) {
        final classConfidence = output[5 + j][i];
        if (classConfidence > maxClassConfidence) {
          maxClassConfidence = classConfidence;
          maxClassIndex = j;
        }
      }

      final finalConfidence = objectConfidence * maxClassConfidence;
      if (finalConfidence < AppConstants.confidenceThreshold) continue;

      final scaleX = originalWidth / AppConstants.uploadImageSize;
      final scaleY = originalHeight / AppConstants.uploadImageSize;

      final left = (centerX - width / 2) * scaleX;
      final top = (centerY - height / 2) * scaleY;
      final right = (centerX + width / 2) * scaleX;
      final bottom = (centerY + height / 2) * scaleY;

      detections.add(DetectionResult(
        boundingBox: Rect.fromLTRB(left, top, right, bottom),
        className: maxClassIndex < _labels.length ? _labels[maxClassIndex] : 'Unknown',
        confidence: finalConfidence,
        classIndex: maxClassIndex,
      ));
    }

    return _applyNMS(detections);
  }

  List<DetectionResult> _applyNMS(List<DetectionResult> detections) {
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    final selected = <DetectionResult>[];
    final suppressed = <bool>[];
    
    for (int i = 0; i < detections.length; i++) {
      suppressed.add(false);
    }

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;
      
      selected.add(detections[i]);
      
      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;
        
        final iou = _calculateIoU(detections[i].boundingBox, detections[j].boundingBox);
        if (iou > AppConstants.iouThreshold) {
          suppressed[j] = true;
        }
      }
    }

    return selected;
  }

  double _calculateIoU(Rect box1, Rect box2) {
    final intersection = box1.intersect(box2);
    if (intersection.isEmpty) return 0.0;
    
    final intersectionArea = intersection.width * intersection.height;
    final unionArea = (box1.width * box1.height) + (box2.width * box2.height) - intersectionArea;
    
    return intersectionArea / unionArea;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
  }
}
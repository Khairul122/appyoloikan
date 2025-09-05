import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/constants.dart';

class LiveDetectionService {
  static LiveDetectionService? _instance;
  static LiveDetectionService get instance => _instance ??= LiveDetectionService._();
  
  LiveDetectionService._();

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isModelLoaded = false;
  List<int> _inputShape = [];
  List<int> _outputShape = [];
  
  List<List<List<List<double>>>>? _reusableInput;
  dynamic _reusableOutput;

  bool get isModelLoaded => _isModelLoaded;

  Future<bool> loadModel() async {
    try {
      if (_isModelLoaded) return true;
      
      _labels = await AppConstants.loadLabels();
      
      final options = InterpreterOptions()
        ..threads = AppConstants.threads
        ..useNnApiForAndroid = false;
      
      _interpreter = await Interpreter.fromAsset(AppConstants.modelPath, options: options);
      
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      _inputShape = inputTensor.shape;
      _outputShape = outputTensor.shape;
      
      _prepareReusableTensors();
      _isModelLoaded = true;
      return true;
      
    } catch (e) {
      _isModelLoaded = false;
      return false;
    }
  }

  void _prepareReusableTensors() {
    final batchSize = _inputShape[0];
    final height = _inputShape[1];
    final width = _inputShape[2];
    final channels = _inputShape[3];
    
    _reusableInput = List.generate(batchSize, (_) =>
      List.generate(height, (_) =>
        List.generate(width, (_) =>
          List.filled(channels, 0.0)
        )
      )
    );
    
    _reusableOutput = _allocTensorByShape(_outputShape);
  }

  dynamic _allocTensorByShape(List<int> shape) {
    if (shape.isEmpty) return 0.0;
    if (shape.length == 1) {
      return List<double>.filled(shape[0], 0.0);
    }
    return List.generate(shape[0], (_) => _allocTensorByShape(shape.sublist(1)));
  }

  Future<Map<String, dynamic>?> detectFromCameraData(Map<String, dynamic> data) async {
    if (!_isModelLoaded || _interpreter == null) return null;

    try {
      final width = data['width'] as int;
      final height = data['height'] as int;
      final planes = data['planes'] as List;
      
      if (planes.isEmpty) return null;
      
      final yBytes = planes[0]['bytes'] as Uint8List;
      
      _fillInputTensor(yBytes, width, height);
      _interpreter!.run(_reusableInput as Object, _reusableOutput);
      
      return _processSingleOutput(width, height);
      
    } catch (e) {
      return null;
    }
  }

  void _fillInputTensor(Uint8List bytes, int width, int height) {
    final modelWidth = _inputShape[2];
    final modelHeight = _inputShape[1];
    final channels = _inputShape[3];
    
    final stepX = width / modelWidth;
    final stepY = height / modelHeight;
    
    for (int h = 0; h < modelHeight; h++) {
      final sourceY = (h * stepY).round().clamp(0, height - 1);
      
      for (int w = 0; w < modelWidth; w++) {
        final sourceX = (w * stepX).round().clamp(0, width - 1);
        final index = sourceY * width + sourceX;
        
        if (index < bytes.length) {
          final pixel = bytes[index] / 255.0;
          
          if (channels == 3) {
            _reusableInput![0][h][w][0] = pixel;
            _reusableInput![0][h][w][1] = pixel;
            _reusableInput![0][h][w][2] = pixel;
          } else {
            _reusableInput![0][h][w][0] = pixel;
          }
        }
      }
    }
  }

  Map<String, dynamic>? _processSingleOutput(int imageWidth, int imageHeight) {
    try {
      dynamic detections = _reusableOutput;
      
      if (_reusableOutput is List && _reusableOutput.isNotEmpty) {
        if (_reusableOutput[0] is List) {
          detections = _reusableOutput[0];
        }
      }
      
      if (detections is! List) return null;
      
      Map<String, dynamic>? bestDetection;
      double bestConfidence = 0.0;
      
      for (int i = 0; i < detections.length && i < 300; i++) {
        final det = detections[i];
        
        if (det is! List || det.length < 6) continue;
        
        try {
          final confidence = det[4].toDouble();
          final classId = det[5].round();
          
          if (confidence >= AppConstants.confidenceThreshold && 
              classId >= 0 && classId < _labels.length && 
              confidence > bestConfidence) {
            final xCenter = det[0].toDouble();
            final yCenter = det[1].toDouble(); 
            final width = det[2].toDouble();
            final height = det[3].toDouble();
            
            final x = (xCenter - width / 2);
            final y = (yCenter - height / 2);
            final w = width;
            final h = height;
            
            bestDetection = {
              'label': _labels[classId],
              'confidence': confidence,
              'classIndex': classId,
              'x': x,
              'y': y,
              'width': w,
              'height': h,
            };
            bestConfidence = confidence;
          }
        } catch (e) {
          continue;
        }
      }
      
      return bestDetection;
      
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    try {
      _interpreter?.close();
      _interpreter = null;
      _isModelLoaded = false;
      _labels.clear();
      _reusableInput = null;
      _reusableOutput = null;
    } catch (e) {
      print('Error disposing service: $e');
    }
  }
}
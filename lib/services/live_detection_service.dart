import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/detection_result.dart';
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
  List<String> get labels => _labels;

  Future<bool> loadModel() async {
    try {
      if (_isModelLoaded) return true;
      
      try {
        final modelBytes = await rootBundle.load(AppConstants.modelPath);
        if (modelBytes.lengthInBytes == 0) return false;
      } catch (e) {
        return false;
      }
      
      _interpreter?.close();
      
      final options = InterpreterOptions()
        ..threads = 1
        ..useNnApiForAndroid = false;
      
      _interpreter = await Interpreter.fromAsset(AppConstants.modelPath, options: options);
      
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      _inputShape = inputTensor.shape;
      _outputShape = outputTensor.shape;
      
      _reusableInput = _prepareReusableInput();
      _reusableOutput = _prepareReusableOutput();
      
      try {
        final labelsData = await rootBundle.loadString(AppConstants.labelsPath);
        
        if (AppConstants.labelsPath.endsWith('.json')) {
          final jsonData = json.decode(labelsData);
          if (jsonData is List) {
            _labels = jsonData.cast<String>();
          } else if (jsonData is Map && jsonData.containsKey('labels')) {
            _labels = (jsonData['labels'] as List).cast<String>();
          } else if (jsonData is Map && jsonData.containsKey('names')) {
            final names = jsonData['names'] as Map;
            _labels = List.generate(names.length, (i) => names[i.toString()] ?? 'unknown');
          }
        } else {
          _labels = labelsData.split('\n')
              .map((label) => label.trim())
              .where((label) => label.isNotEmpty && !label.startsWith('#'))
              .toList();
        }
        
        if (_labels.isEmpty) return false;
      } catch (e) {
        return false;
      }
      
      _isModelLoaded = true;
      return true;
    } catch (e) {
      _isModelLoaded = false;
      return false;
    }
  }

  List<List<List<List<double>>>> _prepareReusableInput() {
    final batchSize = _inputShape[0];
    final height = _inputShape[1];
    final width = _inputShape[2];
    final channels = _inputShape[3];
    
    return List.generate(batchSize, (_) =>
      List.generate(height, (_) =>
        List.generate(width, (_) =>
          List.filled(channels, 0.0)
        )
      )
    );
  }

  dynamic _prepareReusableOutput() {
    return _allocTensorByShape(_outputShape);
  }

  dynamic _allocTensorByShape(List<int> shape) {
    if (shape.isEmpty) return 0.0;
    if (shape.length == 1) {
      return List<double>.filled(shape[0], 0.0);
    }
    return List.generate(shape[0], (_) => _allocTensorByShape(shape.sublist(1)));
  }

  Future<List<Map<String, dynamic>>> detectFromCameraData(Map<String, dynamic> data) async {
    if (!_isModelLoaded || _interpreter == null) return [];

    try {
      final width = data['width'] as int;
      final height = data['height'] as int;
      final format = data['format'] as int;
      final planes = data['planes'] as List;
      
      final yBytes = planes[0]['bytes'] as Uint8List;
      
      _fillInputFromBytes(yBytes, width, height);
      
      _interpreter!.run(_reusableInput as Object, _reusableOutput);
      
      return _processOutputToMap(width, height);
    } catch (e) {
      return [];
    }
  }

  void _fillInputFromBytes(Uint8List bytes, int width, int height) {
    final modelWidth = _inputShape[2];
    final modelHeight = _inputShape[1];
    final channels = _inputShape[3];
    
    final stepX = width / modelWidth;
    final stepY = height / modelHeight;
    
    for (int h = 0; h < modelHeight; h++) {
      for (int w = 0; w < modelWidth; w++) {
        final sourceX = (w * stepX).round();
        final sourceY = (h * stepY).round();
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

  List<Map<String, dynamic>> _processOutputToMap(int imageWidth, int imageHeight) {
    List<Map<String, dynamic>> results = [];
    
    try {
      List<List<double>> detections;
      
      if (_reusableOutput is List && _reusableOutput.isNotEmpty && _reusableOutput[0] is List) {
        detections = (_reusableOutput[0] as List).map<List<double>>((row) => (row as List).cast<double>()).toList();
      } else {
        return results;
      }

      for (final det in detections.take(50)) {
        if (det.length >= 6) {
          final confidence = det[4];
          final classId = det[5].round();
          
          if (confidence > 0.6 && classId >= 0 && classId < _labels.length) {
            final xCenter = det[0];
            final yCenter = det[1];
            final width = det[2];
            final height = det[3];
            
            final x = (xCenter - width / 2) * imageWidth;
            final y = (yCenter - height / 2) * imageHeight;
            final w = width * imageWidth;
            final h = height * imageHeight;
            
            results.add({
              'label': _labels[classId],
              'confidence': confidence,
              'classIndex': classId,
              'x': x,
              'y': y,
              'width': w,
              'height': h,
            });
          }
        }
      }

      results.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
      return results.take(3).toList();
    } catch (e) {
      return [];
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
    }
  }
}
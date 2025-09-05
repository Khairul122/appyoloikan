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
      print('Loading live detection model...');
      
      if (_isModelLoaded) {
        print('Model already loaded');
        return true;
      }
      
      // Load labels
      _labels = await AppConstants.loadLabels();
      if (_labels.isEmpty) {
        print('Using fallback labels');
        _labels = [
          'ikan_baramundi',
          'ikan_belanak_merah',
          'ikan_cakalang',
          'ikan_kakap_putih',
          'ikan_kembung',
          'ikan_sarden'
        ];
      }
      print('Labels loaded: ${_labels.length}');
      
      // Load model with simple options
      final options = InterpreterOptions()
        ..threads = 1
        ..useNnApiForAndroid = false;
      
      try {
        _interpreter = await Interpreter.fromAsset(AppConstants.modelPath, options: options);
        print('Interpreter created successfully');
      } catch (e) {
        print('Failed to create interpreter: $e');
        return false;
      }
      
      // Get tensor shapes
      try {
        final inputTensor = _interpreter!.getInputTensor(0);
        final outputTensor = _interpreter!.getOutputTensor(0);
        _inputShape = inputTensor.shape;
        _outputShape = outputTensor.shape;
        
        print('Input shape: $_inputShape');
        print('Output shape: $_outputShape');
      } catch (e) {
        print('Failed to get tensor shapes: $e');
        return false;
      }
      
      // Prepare reusable tensors
      try {
        _prepareReusableTensors();
        print('Reusable tensors prepared');
      } catch (e) {
        print('Failed to prepare tensors: $e');
        return false;
      }
      
      _isModelLoaded = true;
      print('Live detection model loaded successfully');
      return true;
      
    } catch (e) {
      print('Error loading live detection model: $e');
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

  Future<List<Map<String, dynamic>>> detectFromCameraData(Map<String, dynamic> data) async {
    if (!_isModelLoaded || _interpreter == null) {
      print('Model not loaded for detection');
      return [];
    }

    try {
      final width = data['width'] as int;
      final height = data['height'] as int;
      final planes = data['planes'] as List;
      final yBytes = planes[0]['bytes'] as Uint8List;
      
      // Fill input tensor
      _fillInputTensor(yBytes, width, height);
      
      // Run inference
      _interpreter!.run(_reusableInput as Object, _reusableOutput);
      
      // Process output
      return _processOutput(width, height);
      
    } catch (e) {
      print('Detection error: $e');
      return [];
    }
  }

  void _fillInputTensor(Uint8List bytes, int width, int height) {
    final modelWidth = _inputShape[2];
    final modelHeight = _inputShape[1];
    final channels = _inputShape[3];
    
    final stepX = width / modelWidth;
    final stepY = height / modelHeight;
    
    for (int h = 0; h < modelHeight; h++) {
      for (int w = 0; w < modelWidth; w++) {
        final sourceX = (w * stepX).round().clamp(0, width - 1);
        final sourceY = (h * stepY).round().clamp(0, height - 1);
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

  List<Map<String, dynamic>> _processOutput(int imageWidth, int imageHeight) {
    final results = <Map<String, dynamic>>[];
    
    try {
      List<List<double>> detections;
      
      if (_reusableOutput is List && _reusableOutput.isNotEmpty && _reusableOutput[0] is List) {
        detections = (_reusableOutput[0] as List).map<List<double>>((row) => (row as List).cast<double>()).toList();
      } else {
        return results;
      }

      for (final det in detections.take(50)) {
        if (det.length >= 6) {
          final xCenter = det[0];
          final yCenter = det[1];
          final width = det[2];
          final height = det[3];
          final confidence = det[4];
          final classId = det[5].round();
          
          if (confidence > 0.5 && classId >= 0 && classId < _labels.length) {
            final x = (xCenter - width / 2) * imageWidth;
            final y = (yCenter - height / 2) * imageHeight;
            final w = width * imageWidth;
            final h = height * imageHeight;
            
            if (x >= 0 && y >= 0 && w > 10 && h > 10) {
              results.add({
                'label': _labels[classId],
                'confidence': confidence,
                'classIndex': classId,
                'x': x.clamp(0.0, imageWidth.toDouble()),
                'y': y.clamp(0.0, imageHeight.toDouble()),
                'width': w.clamp(10.0, imageWidth.toDouble()),
                'height': h.clamp(10.0, imageHeight.toDouble()),
              });
            }
          }
        }
      }

      results.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
      return results.take(3).toList();
      
    } catch (e) {
      print('Error processing output: $e');
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
      print('Live detection service disposed');
    } catch (e) {
      print('Error disposing live detection service: $e');
    }
  }
}
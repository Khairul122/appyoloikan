import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/prediction_result.dart';
import '../utils/constants.dart';

class MLService {
  static MLService? _instance;
  static MLService get instance => _instance ??= MLService._();
  
  MLService._();

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isModelLoaded = false;
  
  List<int> _inputShape = [];
  List<int> _outputShape = [];

  bool get isModelLoaded => _isModelLoaded;
  List<String> get labels => _labels;
  int get classCount => _labels.length;

  Future<bool> loadModel() async {
    try {
      print('Loading model...');
      
      final modelExists = await AppConstants.checkModelExists();
      if (!modelExists) {
        print('Model file not found');
        return false;
      }
      
      _labels = await AppConstants.loadLabels();
      if (_labels.isEmpty) {
        print('No labels loaded');
        return false;
      }
      print('Labels loaded: ${_labels.length} classes');
      
      final options = InterpreterOptions()
        ..threads = 2
        ..useNnApiForAndroid = false;
      
      _interpreter = await Interpreter.fromAsset(AppConstants.modelPath, options: options);
      
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      _inputShape = inputTensor.shape;
      _outputShape = outputTensor.shape;
      
      print('Model loaded successfully');
      print('Input: $_inputShape, Output: $_outputShape');
      
      _isModelLoaded = true;
      return true;
    } catch (e) {
      print('Model loading failed: $e');
      _isModelLoaded = false;
      return false;
    }
  }

  Future<List<PredictionResult>> predict(File imageFile) async {
    if (!_isModelLoaded || _interpreter == null) {
      throw Exception('Model not loaded');
    }
    
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      
      final input = _prepareTensor4D(image);
      final output = _prepareOutputTensor();
      
      _interpreter!.run(input, output);
      
      return _processDetectionOutput(output);
    } catch (e) {
      throw Exception('Prediction failed: $e');
    }
  }

  List<List<List<List<double>>>> _prepareTensor4D(img.Image image) {
    final batchSize = _inputShape[0];
    final height = _inputShape[1];
    final width = _inputShape[2];
    final channels = _inputShape[3];
    
    final resizedImage = img.copyResize(
      image, 
      width: width, 
      height: height, 
      interpolation: img.Interpolation.linear
    );
    
    final tensor4D = <List<List<List<double>>>>[];
    for (int b = 0; b < batchSize; b++) {
      final batchData = <List<List<double>>>[];
      for (int h = 0; h < height; h++) {
        final rowData = <List<double>>[];
        for (int w = 0; w < width; w++) {
          final pixel = resizedImage.getPixel(w, h);
          final pixelData = <double>[];
          
          if (channels == 3) {
            pixelData.add(pixel.r / 255.0);
            pixelData.add(pixel.g / 255.0);
            pixelData.add(pixel.b / 255.0);
          } else if (channels == 1) {
            final gray = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b) / 255.0;
            pixelData.add(gray);
          }
          rowData.add(pixelData);
        }
        batchData.add(rowData);
      }
      tensor4D.add(batchData);
    }
    
    return tensor4D;
  }

  dynamic _allocTensorByShape(List<int> shape) {
    if (shape.isEmpty) return 0.0;
    if (shape.length == 1) {
      return List<double>.filled(shape[0], 0.0);
    }
    return List.generate(shape[0], (_) => _allocTensorByShape(shape.sublist(1)));
  }

  dynamic _prepareOutputTensor() {
    return _allocTensorByShape(_outputShape);
  }

  List<PredictionResult> _processDetectionOutput(dynamic output) {
    List<PredictionResult> results = [];
    
    try {
      dynamic detections = output;
      
      if (output is List && output.isNotEmpty) {
        if (output[0] is List) {
          detections = output[0];
        }
      }
      
      if (detections is List && detections.isNotEmpty && detections[0] is List) {
        final detectionsList = detections as List<List<dynamic>>;
        
        for (int i = 0; i < detectionsList.length; i++) {
          final detection = detectionsList[i];
          
          if (detection.length >= 6) {
            final confidence = detection[4].toDouble();
            final classId = detection[5].round();
            
            if (confidence > AppConstants.confidenceThreshold && 
                classId >= 0 && classId < _labels.length) {
              results.add(PredictionResult(
                label: _labels[classId],
                confidence: confidence,
                index: classId,
              ));
            }
          }
        }
      }
      
      results.sort((a, b) => b.confidence.compareTo(a.confidence));
      return results.take(AppConstants.maxResults).toList();
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
    } catch (e) {
      print('Error disposing ML service: $e');
    }
  }
}
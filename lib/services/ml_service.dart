import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
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
      print('Loading model from: ${AppConstants.modelPath}');
      try {
        final modelBytes = await rootBundle.load(AppConstants.modelPath);
        print('Model file found, size: ${modelBytes.lengthInBytes} bytes');
        if (modelBytes.lengthInBytes == 0) {
          print('Model file is empty');
          return false;
        }
      } catch (e) {
        print('Model file not found: $e');
        return false;
      }
      _interpreter = await Interpreter.fromAsset(AppConstants.modelPath);
      print('Interpreter loaded');
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      _inputShape = inputTensor.shape;
      _outputShape = outputTensor.shape;
      print('Input shape: $_inputShape');
      print('Output shape: $_outputShape');
      try {
        final labelsData = await rootBundle.loadString(AppConstants.labelsPath);
        _labels = labelsData.split('\n').map((label) => label.trim()).where((label) => label.isNotEmpty && !label.startsWith('#')).toList();
        print('Labels loaded: ${_labels.length} classes');
        print('Sample labels: ${_labels.take(3).toList()}');
        if (_labels.isEmpty) {
          print('No labels found');
          return false;
        }
      } catch (e) {
        print('Failed to load labels: $e');
        return false;
      }
      _isModelLoaded = true;
      print('Model loaded successfully!');
      return true;
    } catch (e) {
      print('Failed to load model: $e');
      _isModelLoaded = false;
      return false;
    }
  }

  Future<List<PredictionResult>> predict(File imageFile) async {
    if (!_isModelLoaded || _interpreter == null) {
      throw Exception('Model not loaded');
    }
    try {
      print('Starting prediction...');
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      print('Original image: ${image.width}x${image.height}');
      final input = _prepareTensor4D(image);
      final output = _prepareOutputTensor();
      print('4D Tensor prepared');
      print('Output tensor prepared');
      final stopwatch = Stopwatch()..start();
      _interpreter!.run(input, output);
      stopwatch.stop();
      print('Inference completed in ${stopwatch.elapsedMilliseconds}ms');
      final results = _processDetectionOutput(output);
      print('Found ${results.length} predictions');
      return results;
    } catch (e) {
      print('Prediction failed: $e');
      throw Exception('Prediction failed: $e');
    }
  }

  List<List<List<List<double>>>> _prepareTensor4D(img.Image image) {
    final batchSize = _inputShape[0];
    final height = _inputShape[1];
    final width = _inputShape[2];
    final channels = _inputShape[3];
    print('Preparing 4D tensor: [$batchSize, $height, $width, $channels]');
    final resizedImage = img.copyResize(image, width: width, height: height, interpolation: img.Interpolation.linear);
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
    print('4D tensor created successfully');
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
    print('Allocating output tensor with exact shape: $_outputShape');
    return _allocTensorByShape(_outputShape);
  }

  List<PredictionResult> _processDetectionOutput(dynamic output) {
    List<PredictionResult> results = [];
    try {
      print('Processing detection output...');
      List<List<double>> detections;
      if (output is List && output.isNotEmpty && output[0] is List && (output[0] as List).isNotEmpty && (output[0] as List).first is List) {
        detections = (output[0] as List).map<List<double>>((row) => (row as List).cast<double>()).toList();
        print('Detected 3D output; using first batch. Rows: ${detections.length}');
      } else if (output is List) {
        detections = output.map<List<double>>((row) => (row as List).cast<double>()).toList();
        print('Detected 2D output. Rows: ${detections.length}');
      } else {
        print('Unsupported output structure: ${output.runtimeType}');
        return results;
      }
      for (final det in detections) {
        if (det.length >= 6) {
          final confidence = det[4];
          final classId = det[5].round();
          if (confidence > AppConstants.confidenceThreshold && classId >= 0 && classId < _labels.length) {
            results.add(PredictionResult(label: _labels[classId], confidence: confidence, index: classId));
          }
        } else if (det.length == _labels.length) {
          for (int j = 0; j < det.length; j++) {
            final confidence = det[j];
            if (confidence > AppConstants.confidenceThreshold) {
              results.add(PredictionResult(label: _labels[j], confidence: confidence, index: j));
            }
          }
          break;
        }
      }
      results.sort((a, b) => b.confidence.compareTo(a.confidence));
      for (int i = 0; i < results.length && i < 3; i++) {
        final r = results[i];
        print('${i + 1}. ${r.displayName}: ${r.confidencePercentage}');
      }
      return results.take(AppConstants.maxResults).toList();
    } catch (e) {
      print('Error processing detection output: $e');
      return [];
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
    print('ML Service disposed');
  }
}

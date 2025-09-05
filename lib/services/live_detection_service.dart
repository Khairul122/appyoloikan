import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/constants.dart';
import 'dart:developer' as developer;

class LiveDetectionService {
  static LiveDetectionService? _instance;
  static LiveDetectionService get instance =>
      _instance ??= LiveDetectionService._();

  LiveDetectionService._();

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isModelLoaded = false;
  List<int> _inputShape = [];
  List<int> _outputShape = [];

  List<List<List<List<double>>>>? _reusableInput;
  dynamic _reusableOutput;
  Uint8List? _rgbBytes;
  late int _modelInputWidth;
  late int _modelInputHeight;

  bool get isModelLoaded => _isModelLoaded;

  Future<bool> loadModel() async {
    try {
      if (_isModelLoaded) return true;

      _labels = await AppConstants.loadLabels();

      final options = InterpreterOptions()
        ..threads = AppConstants.threads
        ..useNnApiForAndroid = false;

      _interpreter =
          await Interpreter.fromAsset(AppConstants.modelPath, options: options);

      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      _inputShape = inputTensor.shape;
      _outputShape = outputTensor.shape;

      _modelInputWidth = _inputShape[2];
      _modelInputHeight = _inputShape[1];

      _prepareReusableTensors();
      _isModelLoaded = true;

      developer.log(
          'Model loaded successfully. Input shape: $_inputShape, Output shape: $_outputShape');
      return true;
    } catch (e) {
      _isModelLoaded = false;
      developer.log('Error loading model: $e', error: e);
      return false;
    }
  }

  void _prepareReusableTensors() {
    try {
      final batchSize = _inputShape[0];
      final height = _inputShape[1];
      final width = _inputShape[2];
      final channels = _inputShape[3];

      _reusableInput = List.generate(
          batchSize,
          (_) => List.generate(height,
              (_) => List.generate(width, (_) => List.filled(channels, 0.0))));

      _reusableOutput = _allocTensorByShape(_outputShape);
      _rgbBytes = Uint8List(_modelInputWidth * _modelInputHeight * 3);
    } catch (e) {
      developer.log('Error preparing tensors: $e', error: e);
      throw Exception('Failed to prepare tensors: $e');
    }
  }

  dynamic _allocTensorByShape(List<int> shape) {
    try {
      if (shape.isEmpty) return 0.0;
      if (shape.length == 1) {
        return List<double>.filled(shape[0], 0.0);
      }
      return List.generate(
          shape[0], (_) => _allocTensorByShape(shape.sublist(1)));
    } catch (e) {
      developer.log('Error allocating tensor: $e', error: e);
      throw Exception('Failed to allocate tensor: $e');
    }
  }

  Future<Map<String, dynamic>?> detectFromCameraData(
      Map<String, dynamic> data) async {
    if (!_isModelLoaded || _interpreter == null) {
      developer.log('Model not loaded or interpreter null');
      return null;
    }

    try {
      final width = (data['width'] as int?) ?? 0;
      final height = (data['height'] as int?) ?? 0;
      final planes = data['planes'] as List<dynamic>?;

      if (planes == null || planes.isEmpty) {
        developer.log('No planes provided in camera data');
        return null;
      }

      if (width <= 0 || height <= 0) {
        developer.log('Invalid width or height: width=$width, height=$height');
        return null;
      }

      final firstPlane = planes[0];
      if (firstPlane == null) {
        developer.log('First plane is null');
        return null;
      }

      final yBytes = firstPlane['bytes'] as Uint8List?;
      if (yBytes == null || yBytes.isEmpty) {
        developer.log('Y-plane bytes are null or empty');
        return null;
      }

      _fillInputTensorOptimized(yBytes, width, height);

      _interpreter!.run(_reusableInput as Object, _reusableOutput);

      return _processSingleOutputOptimized(width, height);
    } catch (e, stackTrace) {
      developer.log('Error during detection: $e',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  void _fillInputTensorOptimized(Uint8List bytes, int width, int height) {
    try {
      if (_inputShape.isEmpty || _reusableInput == null) {
        throw Exception('Input shape or tensor not initialized');
      }

      final channels = _inputShape[3];
      final stepX = width / _modelInputWidth;
      final stepY = height / _modelInputHeight;

      if (channels <= 0) {
        throw Exception('Invalid channel count: $channels');
      }

      // Reset tensor
      for (int h = 0; h < _modelInputHeight; h++) {
        for (int w = 0; w < _modelInputWidth; w++) {
          for (int c = 0; c < channels; c++) {
            _reusableInput![0][h][w][c] = 0.0;
          }
        }
      }

      for (int h = 0; h < _modelInputHeight; h++) {
        final sourceY = (h * stepY).round().clamp(0, height - 1);
        final rowStart = sourceY * width;

        for (int w = 0; w < _modelInputWidth; w++) {
          final sourceX = (w * stepX).round().clamp(0, width - 1);
          final index = rowStart + sourceX;

          if (index >= 0 && index < bytes.length) {
            final normalizedPixel = (bytes[index] & 0xFF) / 255.0;

            if (channels == 3) {
              _reusableInput![0][h][w][0] = normalizedPixel;
              _reusableInput![0][h][w][1] = normalizedPixel;
              _reusableInput![0][h][w][2] = normalizedPixel;
            } else {
              _reusableInput![0][h][w][0] = normalizedPixel;
            }
          } else {
            _reusableInput![0][h][w][0] = 0.0;
            if (channels == 3) {
              _reusableInput![0][h][w][1] = 0.0;
              _reusableInput![0][h][w][2] = 0.0;
            }
          }
        }
      }
    } catch (e, stackTrace) {
      developer.log('Error filling input tensor: $e',
          error: e, stackTrace: stackTrace);
      throw Exception('Failed to fill input tensor: $e');
    }
  }

  Map<String, dynamic>? _processSingleOutputOptimized(
      int imageWidth, int imageHeight) {
    try {
      dynamic detections = _reusableOutput;

      if (_reusableOutput == null) {
        developer.log('Reusable output is null');
        return null;
      }

      if (_reusableOutput is List && _reusableOutput.isNotEmpty) {
        detections = _reusableOutput[0];
      }

      if (detections is! List) {
        developer.log('Invalid detection format: ${detections.runtimeType}');
        return null;
      }

      Map<String, dynamic>? bestDetection;
      double bestConfidence = AppConstants.confidenceThreshold;

      final maxDetections = detections.length > 100 ? 100 : detections.length;

      for (int i = 0; i < maxDetections; i++) {
        final det = detections[i];

        if (det is! List || det.length < 6) {
          continue;
        }

        try {
          final confidence = (det[4] as num).toDouble();

          if (confidence < bestConfidence ||
              confidence.isNaN ||
              confidence.isInfinite) {
            continue;
          }

          final classId = (det[5] as num).round();

          if (classId < 0 || classId >= _labels.length) {
            continue;
          }

          final xCenter = (det[0] as num).toDouble();
          final yCenter = (det[1] as num).toDouble();
          final width = (det[2] as num).toDouble();
          final height = (det[3] as num).toDouble();

          if (xCenter.isNaN ||
              yCenter.isNaN ||
              width.isNaN ||
              height.isNaN ||
              xCenter.isInfinite ||
              yCenter.isInfinite ||
              width.isInfinite ||
              height.isInfinite ||
              xCenter < 0 ||
              xCenter > 1 ||
              yCenter < 0 ||
              yCenter > 1 ||
              width <= 0 ||
              height <= 0 ||
              width > 1 ||
              height > 1) {
            continue;
          }

          final x = (xCenter - width / 2).clamp(0.0, 1.0);
          final y = (yCenter - height / 2).clamp(0.0, 1.0);
          final w = width.clamp(0.0, 1.0 - x);
          final h = height.clamp(0.0, 1.0 - y);

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
        } catch (e) {
          developer.log('Error processing detection $i: $e', error: e);
          continue;
        }
      }

      if (bestDetection != null) {
        developer.log(
            'Best detection found: ${bestDetection['label']} (${bestDetection['confidence']})');
      }

      return bestDetection;
    } catch (e, stackTrace) {
      developer.log('Error processing output: $e',
          error: e, stackTrace: stackTrace);
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
      _rgbBytes = null;

      developer.log('LiveDetectionService disposed successfully');
    } catch (e) {
      developer.log('Error disposing service: $e', error: e);
    }
  }
}

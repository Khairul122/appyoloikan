import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../models/detection_result.dart';
import '../utils/constants.dart';

class InferenceIsolate {
  static SendPort? _sendPort;
  static Isolate? _isolate;
  static bool _isInitialized = false;
  static Uint8List? _modelBuffer;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    _modelBuffer = await rootBundle.load(AppConstants.modelPath).then((data) => data.buffer.asUint8List());
    
    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntryPoint, {
      'sendPort': receivePort.sendPort,
      'modelBuffer': _modelBuffer,
    });
    _sendPort = await receivePort.first;
    _isInitialized = true;
  }

  static Future<List<DetectionResult>> runInference({
    required Uint8List imageBytes,
    required List<String> labels,
    required bool isLiveDetection,
  }) async {
    if (!_isInitialized) await initialize();
    
    final responsePort = ReceivePort();
    _sendPort!.send({
      'imageBytes': imageBytes,
      'labels': labels,
      'responsePort': responsePort.sendPort,
      'isLive': isLiveDetection,
    });
    
    final result = await responsePort.first;
    if (result is String) {
      throw Exception(result);
    }
    
    return (result as List).map((data) => DetectionResult.fromJson(data)).toList();
  }

  static void dispose() {
    _isolate?.kill();
    _isolate = null;
    _sendPort = null;
    _isInitialized = false;
  }

  static void _isolateEntryPoint(Map<String, dynamic> initData) async {
    final sendPort = initData['sendPort'] as SendPort;
    final modelBuffer = initData['modelBuffer'] as Uint8List;
    
    final port = ReceivePort();
    sendPort.send(port.sendPort);
    
    Interpreter? interpreter;
    
    await for (final message in port) {
      try {
        if (interpreter == null) {
          try {
            interpreter = Interpreter.fromBuffer(modelBuffer,
              options: InterpreterOptions()..threads = 4,
            );
          } catch (e) {
            interpreter = Interpreter.fromBuffer(modelBuffer);
          }
        }
        
        final imageBytes = message['imageBytes'] as Uint8List;
        final labels = message['labels'] as List<String>;
        final responsePort = message['responsePort'] as SendPort;
        final isLive = message['isLive'] as bool;
        
        final inputSize = isLive ? AppConstants.inputImageSize : AppConstants.uploadImageSize;
        final results = await _processInference(interpreter, imageBytes, labels, inputSize, isLive);
        
        responsePort.send(results.map((r) => r.toJson()).toList());
      } catch (e) {
        try {
          final responsePort = message['responsePort'] as SendPort;
          responsePort.send('Inference error: $e');
        } catch (sendError) {
          print('Failed to send error: $sendError');
        }
      }
    }
  }

  static Future<List<DetectionResult>> _processInference(
    Interpreter interpreter,
    Uint8List imageBytes,
    List<String> labels,
    int inputSize,
    bool isLive,
  ) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('Failed to decode image');
    
    final resizedImage = img.copyResize(image, width: inputSize, height: inputSize);
    final input = _preprocessImage(resizedImage, inputSize);
    
    final outputTensor = List.generate(1, (_) => 
      List.generate(14, (_) => List.filled(8400, 0.0)));
    
    final inputTensor = input.reshape([1, inputSize, inputSize, 3]);
    interpreter.run(inputTensor, outputTensor);
    
    return _postprocessOutput(outputTensor[0], labels, 
      image.width.toDouble(), image.height.toDouble(), inputSize, isLive);
  }

  static Float32List _preprocessImage(img.Image image, int size) {
    final input = Float32List(1 * size * size * 3);
    int pixelIndex = 0;

    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final pixel = image.getPixel(x, y);
        input[pixelIndex++] = pixel.r / 255.0;
        input[pixelIndex++] = pixel.g / 255.0;
        input[pixelIndex++] = pixel.b / 255.0;
      }
    }

    return input;
  }

  static List<DetectionResult> _postprocessOutput(
    List<List<double>> output,
    List<String> labels,
    double originalWidth,
    double originalHeight,
    int inputSize,
    bool isLive,
  ) {
    final detections = <DetectionResult>[];
    const numClasses = 9; // Fixed: model has 9 classes (14 - 5 = 9)
    const numDetections = 8400;

    for (int i = 0; i < numDetections; i++) {
      final centerX = output[0][i];
      final centerY = output[1][i];
      final width = output[2][i];
      final height = output[3][i];
      final objectConfidence = output[4][i];

      if (!isLive && objectConfidence < 0.01) continue; // Very low threshold for upload
      if (isLive && objectConfidence < AppConstants.confidenceThreshold) continue;

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
      if (!isLive && finalConfidence < 0.01) continue; // Very low threshold for upload
      if (isLive && finalConfidence < AppConstants.confidenceThreshold) continue;

      final scaleX = originalWidth / inputSize;
      final scaleY = originalHeight / inputSize;

      final left = (centerX - width / 2) * scaleX;
      final top = (centerY - height / 2) * scaleY;
      final right = (centerX + width / 2) * scaleX;
      final bottom = (centerY + height / 2) * scaleY;

      detections.add(DetectionResult(
        boundingBox: Rect.fromLTRB(left, top, right, bottom),
        className: maxClassIndex < labels.length ? labels[maxClassIndex] : 'Unknown',
        confidence: finalConfidence,
        classIndex: maxClassIndex,
      ));
    }

    return _applyNMS(detections);
  }

  static List<DetectionResult> _applyNMS(List<DetectionResult> detections) {
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

  static double _calculateIoU(Rect box1, Rect box2) {
    final intersection = box1.intersect(box2);
    if (intersection.isEmpty) return 0.0;
    
    final intersectionArea = intersection.width * intersection.height;
    final unionArea = (box1.width * box1.height) + (box2.width * box2.height) - intersectionArea;
    
    return intersectionArea / unionArea;
  }
}
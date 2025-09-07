import 'package:flutter/services.dart';

class AppConstants {
  static const String appName = 'Fish Detector';
  static const String modelPath = 'lib/assets/models/best.tflite';
  static const String labelsPath = 'lib/assets/models/labels.txt';
  static const String splashAnimationPath = 'lib/assets/animations/splash.json';
  
  static const double confidenceThreshold = 0.1;
  static const double iouThreshold = 0.5;
  static const int inputImageSize = 640; // Standardize to model export size
  static const int uploadImageSize = 640;
  
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 300);
  
  static const double borderRadius = 12.0;
  static const double cardElevation = 8.0;
  static const double iconSize = 24.0;
  static const double buttonHeight = 56.0;
  
  static const List<String> fishClasses = [
    'ikan_baramundi',
    'ikan_belanak_merah', 
    'ikan_cakalang',
    'ikan_kakap_putih',
    'ikan_kembung',
    'ikan_sarden',
  ];

  static Future<List<String>> loadLabels() async {
    try {
      final labelsData = await rootBundle.loadString(labelsPath);
      return labelsData.split('\n').where((label) => label.isNotEmpty).toList();
    } catch (e) {
      return fishClasses;
    }
  }
}
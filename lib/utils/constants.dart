import 'dart:convert';
import 'package:flutter/services.dart';

class AppConstants {
  static const String appName = 'AppYoloIkan';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Klasifikasi Jenis Ikan dengan YOLOv11';
  
  static const String modelPath = 'lib/assets/models/best.tflite';
  static const String labelsPath = 'lib/assets/models/labels.json';
  static const int inputSize = 640;
  static const double confidenceThreshold = 0.25;
  static const int maxResults = 5;
  
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  
  static const double maxImageWidth = 1920;
  static const double maxImageHeight = 1080;
  static const int imageQuality = 85;
  static const int maxStoredImages = 10;
  
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double buttonHeight = 48.0;
  
  static const String keyFirstRun = 'first_run';
  static const String keyModelLoaded = 'model_loaded';
  static const String keyLastModelUpdate = 'last_model_update';
  
  static const String logoPath = 'lib/assets/images/logo.png';
  static const String fishIconPath = 'lib/assets/images/fish_icon.png';
  static const String splashBgPath = 'lib/assets/images/splash_bg.png';
  static const String loadingAnimationPath = 'lib/assets/animations/loading.json';
  static const String loadingDotsPath = 'lib/assets/animations/loading_dots.json';
  
  static const String errorModelNotLoaded = 'Model belum dimuat';
  static const String errorImageNotFound = 'Gambar tidak ditemukan';
  static const String errorCameraNotAvailable = 'Kamera tidak tersedia';
  static const String errorPredictionFailed = 'Gagal melakukan prediksi';
  static const String errorNoResults = 'Tidak ada hasil prediksi';
  
  static const String successImageSaved = 'Gambar berhasil disimpan';
  static const String successImageDeleted = 'Gambar berhasil dihapus';
  static const String successModelLoaded = 'Model berhasil dimuat';

  static Future<List<String>> loadLabels() async {
    try {
      final labelsData = await rootBundle.loadString(labelsPath);
      final jsonData = json.decode(labelsData) as Map<String, dynamic>;
      
      if (jsonData.containsKey('names')) {
        final names = jsonData['names'] as Map<String, dynamic>;
        List<String> labels = [];
        List<String> sortedKeys = names.keys.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
        for (String key in sortedKeys) {
          labels.add(names[key] as String);
        }
        return labels;
      }
      
      else if (jsonData.containsKey('ikan')) {
        final ikanList = jsonData['ikan'] as List<dynamic>;
        return ikanList.cast<String>();
      }
      
      else if (jsonData.containsKey('labels')) {
        final labelsList = jsonData['labels'] as List<dynamic>;
        return labelsList.cast<String>();
      }
      
      else if (jsonData.containsKey('classes')) {
        final classesList = jsonData['classes'] as List<dynamic>;
        return classesList.cast<String>();
      }
      
      else {
        final keys = jsonData.keys.toList();
        if (keys.isNotEmpty) {
          final firstKey = keys.first;
          final value = jsonData[firstKey];
          
          if (value is List) {
            return (value as List<dynamic>).cast<String>();
          }
          
          if (value is Map) {
            final mapValues = value as Map<String, dynamic>;
            List<String> labels = [];
            List<String> sortedKeys = mapValues.keys.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
            for (String key in sortedKeys) {
              labels.add(mapValues[key] as String);
            }
            return labels;
          }
        }
      }
      
      return [];
    } catch (e) {
      print('Error loading labels: $e');
      return [
        'ikan_baramundi',
        'ikan_belanak_merah',
        'ikan_cakalang',
        'ikan_kakap_putih',
        'ikan_kembung',
        'ikan_sarden'
      ];
    }
  }

  static Future<bool> checkModelExists() async {
    try {
      final modelData = await rootBundle.load(modelPath);
      return modelData.lengthInBytes > 0;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> checkLabelsExists() async {
    try {
      await rootBundle.loadString(labelsPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getModelInfo() async {
    try {
      final modelExists = await checkModelExists();
      final labelsExists = await checkLabelsExists();
      final labels = await loadLabels();
      
      return {
        'modelExists': modelExists,
        'labelsExists': labelsExists,
        'labelsCount': labels.length,
        'labels': labels,
      };
    } catch (e) {
      return {
        'modelExists': false,
        'labelsExists': false,
        'labelsCount': 0,
        'labels': [],
        'error': e.toString(),
      };
    }
  }
}
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';

class AppConstants {
  static const String appName = 'AppYoloIkan';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Klasifikasi Jenis Ikan dengan YOLOv11';
  
  static const String modelPath = 'lib/assets/models/best.tflite';
  static const String labelsPath = 'lib/assets/models/labels.txt';
  
  static const int inputSize = 320;
  static const double confidenceThreshold = 0.15;
  static const double iouThreshold = 0.45;
  static const int maxResults = 5;
  static const int threads = 2;
  
  static const int frameStride = 5;
  static const int maxLatencyHistorySize = 10;
  static const int minBoundingBoxSize = 50;
  
  static const ResolutionPreset cameraResolution = ResolutionPreset.medium;
  static const bool enableAudio = false;
  
  static const double maxImageWidth = 1920;
  static const double maxImageHeight = 1080;
  static const int imageQuality = 85;
  static const int maxStoredImages = 10;
  
  static const String keyFirstRun = 'first_run';
  static const String keyModelLoaded = 'model_loaded';
  static const String keyLastModelUpdate = 'last_model_update';
  
  static const String errorModelNotLoaded = 'Model belum dimuat';
  static const String errorImageNotFound = 'Gambar tidak ditemukan';
  static const String errorCameraNotAvailable = 'Kamera tidak tersedia';
  static const String errorPredictionFailed = 'Gagal melakukan prediksi';
  static const String errorNoResults = 'Tidak ada hasil prediksi';
  
  static const String successImageSaved = 'Gambar berhasil disimpan';
  static const String successImageDeleted = 'Gambar berhasil dihapus';
  static const String successModelLoaded = 'Model berhasil dimuat';

  static List<String> get defaultLabels => [
    'ikan_baramundi',
    'ikan_belanak_merah',
    'ikan_cakalang', 
    'ikan_kakap_putih',
    'ikan_kembung',
    'ikan_sarden'
  ];

  static ImageFormatGroup get imageFormatGroup {
    try {
      return Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888;
    } catch (e) {
      return ImageFormatGroup.bgra8888;
    }
  }

  static Future<List<String>> loadLabels() async {
    try {
      final labelsData = await rootBundle.loadString(labelsPath);
      final lines = labelsData.split('\n');
      List<String> labels = [];
      
      for (String line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isNotEmpty) {
          labels.add(trimmedLine);
        }
      }
      
      return labels.isNotEmpty ? labels : defaultLabels;
    } catch (e) {
      return defaultLabels;
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

  static Future<Map<String, dynamic>> getModelInfo() async {
    try {
      final modelExists = await checkModelExists();
      final labels = await loadLabels();
      
      return {
        'modelExists': modelExists,
        'labelsCount': labels.length,
        'labels': labels,
      };
    } catch (e) {
      return {
        'modelExists': false,
        'labelsCount': 0,
        'labels': defaultLabels,
        'error': e.toString(),
      };
    }
  }
}
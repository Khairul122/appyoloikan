class AppConstants {
  static const String appName = 'AppYoloIkan';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Klasifikasi Jenis Ikan dengan YOLOv11';
  
  static const String modelPath = 'lib/assets/models/best.tflite';
  static const String labelsPath = 'lib/assets/models/labels.txt';
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
  
  // Fixed asset paths - remove 'lib/' prefix
  static const String logoPath = 'assets/images/logo.png';
  static const String fishIconPath = 'assets/images/fish_icon.png';
  static const String splashBgPath = 'assets/images/splash_bg.png';
  static const String loadingAnimationPath = 'assets/animations/loading.json';
  static const String loadingDotsPath = 'assets/animations/loading_dots.json';
  
  static const String errorModelNotLoaded = 'Model belum dimuat';
  static const String errorImageNotFound = 'Gambar tidak ditemukan';
  static const String errorCameraNotAvailable = 'Kamera tidak tersedia';
  static const String errorPredictionFailed = 'Gagal melakukan prediksi';
  static const String errorNoResults = 'Tidak ada hasil prediksi';
  
  static const String successImageSaved = 'Gambar berhasil disimpan';
  static const String successImageDeleted = 'Gambar berhasil dihapus';
  static const String successModelLoaded = 'Model berhasil dimuat';
}
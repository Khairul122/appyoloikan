import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:exif/exif.dart';
import '../models/enhanced_detection_result.dart';

class MetadataAnalysisService {
  static const List<String> supportedImageFormats = ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp', '.tiff'];

  Future<MediaMetadata> analyzeMetadata(File imageFile) async {
    // Extract EXIF data
    Map<String, String> exifData = await _extractExifData(imageFile);

    // Analyze file characteristics
    Map<String, dynamic> fileCharacteristics = await _analyzeFileCharacteristics(imageFile);

    // Determine media properties
    bool isPhotograph = _checkIfPhotograph(exifData, fileCharacteristics);
    bool isDigitalCreation = _checkIfDigitalCreation(exifData, fileCharacteristics);
    String compressionType = _identifyCompression(fileCharacteristics);
    List<String> sourceIndicators = _identifySource(exifData, fileCharacteristics);

    return MediaMetadata(
      isPhotograph: isPhotograph,
      isDigitalCreation: isDigitalCreation,
      compressionType: compressionType,
      sourceIndicators: sourceIndicators,
      exifData: exifData,
      fileCharacteristics: fileCharacteristics,
    );
  }

  Future<MetadataAnalysis> analyzeMetadataDetailed(File imageFile) async {
    MediaMetadata metadata = await analyzeMetadata(imageFile);

    String sourceType = _determineSourceType(metadata);
    double metadataConfidence = _calculateMetadataConfidence(metadata);

    return MetadataAnalysis(
      metadata: metadata,
      sourceType: sourceType,
      metadataConfidence: metadataConfidence,
    );
  }

  Future<Map<String, String>> _extractExifData(File imageFile) async {
    try {
      Uint8List imageBytes = await imageFile.readAsBytes();
      Map<String, dynamic>? exifData = await readExifFromBytes(imageBytes);

      if (exifData == null) return {};

      // Flatten EXIF data to string map
      Map<String, String> flattenedData = {};
      _flattenExifData(exifData, flattenedData);

      return flattenedData;
    } catch (e) {
      debugPrint('Error extracting EXIF data: $e');
      return {};
    }
  }

  void _flattenExifData(Map<String, dynamic> data, Map<String, String> result, [String prefix = '']) {
    data.forEach((key, value) {
      String newKey = prefix.isNotEmpty ? '$prefix.$key' : key;

      if (value is Map) {
        _flattenExifData(value as Map<String, dynamic>, result, '$newKey');
      } else if (value != null) {
        result[newKey] = value.toString();
      }
    });
  }

  Future<Map<String, dynamic>> _analyzeFileCharacteristics(File imageFile) async {
    try {
      Uint8List imageBytes = await imageFile.readAsBytes();

      // Basic file info
      String fileName = path.basename(imageFile.path);
      String fileExtension = path.extension(imageFile.path).toLowerCase();
      int fileSize = imageBytes.length;

      // Image format analysis
      String format = _detectImageFormat(imageBytes);

      // Compression analysis
      Map<String, dynamic> compressionInfo = _analyzeCompression(imageBytes, format);

      // File naming patterns
      Map<String, bool> namingPatterns = _analyzeNamingPatterns(fileName);

      // Creation and modification times
      DateTime creationTime = await imageFile.lastModified();
      DateTime accessTime = DateTime.now();

      return {
        'file_name': fileName,
        'file_extension': fileExtension,
        'file_size': fileSize,
        'format': format,
        'compression_info': compressionInfo,
        'naming_patterns': namingPatterns,
        'creation_time': creationTime.toIso8601String(),
        'access_time': accessTime.toIso8601String(),
        'is_recent': accessTime.difference(creationTime).inDays < 30,
        'file_size_category': _categorizeFileSize(fileSize),
      };
    } catch (e) {
      debugPrint('Error analyzing file characteristics: $e');
      return {};
    }
  }

  String _detectImageFormat(Uint8List bytes) {
    if (bytes.length < 4) return 'unknown';

    // Check file signatures
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return 'JPEG';
    } else if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'PNG';
    } else if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) {
      return 'WEBP';
    } else if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
      return 'GIF';
    } else if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return 'BMP';
    } else if (bytes.length >= 8 &&
               bytes[0] == 0x49 && bytes[1] == 0x49 && bytes[2] == 0x2A && bytes[3] == 0x00) {
      return 'TIFF';
    } else {
      return 'unknown';
    }
  }

  Map<String, dynamic> _analyzeCompression(Uint8List bytes, String format) {
    Map<String, dynamic> compressionInfo = {};

    switch (format) {
      case 'JPEG':
        compressionInfo = _analyzeJPEGCompression(bytes);
        break;
      case 'PNG':
        compressionInfo = _analyzePNGCompression(bytes);
        break;
      case 'WEBP':
        compressionInfo = _analyzeWebPCompression(bytes);
        break;
      default:
        compressionInfo = {'compression_level': 'unknown'};
    }

    return compressionInfo;
  }

  Map<String, dynamic> _analyzeJPEGCompression(Uint8List bytes) {
    // Look for JPEG quality indicators
    Map<String, dynamic> info = {
      'compression_type': 'JPEG',
      'has_quantization_tables': false,
      'estimated_quality': 'unknown',
    };

    // Scan for quantization tables (DQT markers)
    for (int i = 0; i < bytes.length - 1; i++) {
      if (bytes[i] == 0xFF && bytes[i + 1] == 0xDB) {
        info['has_quantization_tables'] = true;
        break;
      }
    }

    // Estimate quality based on file size and markers
    if (info['has_quantization_tables']) {
      info['estimated_quality'] = 'medium_to_high';
    }

    return info;
  }

  Map<String, dynamic> _analyzePNGCompression(Uint8List bytes) {
    return {
      'compression_type': 'PNG',
      'is_lossless': true,
      'has_transparency': bytes.length > 50 && bytes[49] > 0,
      'color_type': _analyzePNGColorType(bytes),
    };
  }

  String _analyzePNGColorType(Uint8List bytes) {
    if (bytes.length < 30) return 'unknown';

    int colorType = bytes[26]; // Byte 26 contains color type

    switch (colorType) {
      case 0: return 'grayscale';
      case 2: return 'RGB';
      case 3: return 'palette';
      case 4: return 'grayscale_alpha';
      case 6: return 'RGBA';
      default: return 'unknown';
    }
  }

  Map<String, dynamic> _analyzeWebPCompression(Uint8List bytes) {
    bool isLossless = bytes.length > 15 &&
                      bytes[8] == 0x4C && bytes[9] == 0x4F && bytes[10] == 0x53 && bytes[11] == 0x53 && // 'LOSS'
                      bytes[12] == 0x4C && bytes[13] == 0x45 && bytes[14] == 0x53 && bytes[15] == 0x53; // 'LESS'

    return {
      'compression_type': 'WebP',
      'is_lossless': isLossless,
      'format_type': isLossless ? 'lossless' : 'lossy',
    };
  }

  Map<String, bool> _analyzeNamingPatterns(String fileName) {
    return {
      'has_date_pattern': _hasDatePattern(fileName),
      'has_camera_pattern': _hasCameraPattern(fileName),
      'has_software_pattern': _hasSoftwarePattern(fileName),
      'has_numeric_prefix': _hasNumericPrefix(fileName),
      'has_uuid_pattern': _hasUUIDPattern(fileName),
      'has_web_pattern': _hasWebPattern(fileName),
      'is_screenshot': _isScreenshotName(fileName),
    };
  }

  bool _hasDatePattern(String fileName) {
    RegExp datePattern = RegExp(r'\d{4}[-_]\d{2}[-_]\d{2}|IMG_\d{8}|DSC_\d{8}');
    return datePattern.hasMatch(fileName);
  }

  bool _hasCameraPattern(String fileName) {
    RegExp cameraPattern = RegExp(r'IMG|DSC|PIC|PHOTO|CAM|SNAP');
    return cameraPattern.hasMatch(fileName.toUpperCase());
  }

  bool _hasSoftwarePattern(String fileName) {
    RegExp softwarePattern = RegExp(r'Adobe|Photoshop|Illustrator|GIMP|Canva|Figma');
    return softwarePattern.hasMatch(fileName);
  }

  bool _hasNumericPrefix(String fileName) {
    RegExp numericPattern = RegExp(r'^\d+[-_]?');
    return numericPattern.hasMatch(fileName);
  }

  bool _hasUUIDPattern(String fileName) {
    RegExp uuidPattern = RegExp(r'[a-f0-9]{8}(-[a-f0-9]{4}){3}-[a-f0-9]{12}', caseSensitive: false);
    return uuidPattern.hasMatch(fileName);
  }

  bool _hasWebPattern(String fileName) {
    RegExp webPattern = RegExp(r'download|web|online|screenshot|capture');
    return webPattern.hasMatch(fileName.toLowerCase());
  }

  bool _isScreenshotName(String fileName) {
    RegExp screenshotPattern = RegExp(r'Screenshot|Screen Shot|screencapture|capture');
    return screenshotPattern.hasMatch(fileName);
  }

  String _categorizeFileSize(int fileSize) {
    if (fileSize < 100 * 1024) { // < 100KB
      return 'small';
    } else if (fileSize < 1024 * 1024) { // < 1MB
      return 'medium';
    } else if (fileSize < 5 * 1024 * 1024) { // < 5MB
      return 'large';
    } else {
      return 'very_large';
    }
  }

  bool _checkIfPhotograph(Map<String, String> exifData, Map<String, dynamic> fileCharacteristics) {
    int photoIndicators = 0;

    // Check for camera-related EXIF data
    if (exifData.containsKey('Image Make') || exifData.containsKey('Image Model')) {
      photoIndicators++;
    }

    if (exifData.containsKey('EXIF DateTimeOriginal') || exifData.containsKey('Image DateTime')) {
      photoIndicators++;
    }

    if (exifData.containsKey('EXIF ISOSpeedRatings')) {
      photoIndicators++;
    }

    if (exifData.containsKey('EXIF FNumber') || exifData.containsKey('EXIF ExposureTime')) {
      photoIndicators++;
    }

    // Check for camera software
    String? software = exifData['Image Software'];
    if (software != null && _isCameraSoftware(software)) {
      photoIndicators++;
    }

    // Check file naming patterns
    if (fileCharacteristics['naming_patterns']?['has_camera_pattern'] == true) {
      photoIndicators++;
    }

    if (fileCharacteristics['naming_patterns']?['has_date_pattern'] == true) {
      photoIndicators++;
    }

    // Check compression
    String? compressionType = fileCharacteristics['compression_info']?['compression_type'];
    if (compressionType == 'JPEG' || compressionType == 'HEIF') {
      photoIndicators++;
    }

    return photoIndicators >= 2;
  }

  bool _isCameraSoftware(String software) {
    List<String> cameraSoftware = [
      'Camera', 'iPhone', 'Samsung', 'Huawei', 'Xiaomi', 'OnePlus', 'Pixel',
      'Canon', 'Nikon', 'Sony', 'Fujifilm', 'Olympus', 'Panasonic',
      'LG', 'Motorola', 'OPPO', 'Vivo', 'Realme'
    ];

    return cameraSoftware.any((name) => software.toLowerCase().contains(name.toLowerCase()));
  }

  bool _checkIfDigitalCreation(Map<String, String> exifData, Map<String, dynamic> fileCharacteristics) {
    int digitalIndicators = 0;

    // Check for design software in EXIF
    String? software = exifData['Image Software'];
    if (software != null && _isDesignSoftware(software)) {
      digitalIndicators++;
    }

    // Check for copyright information
    if (exifData.containsKey('Image Copyright') || exifData.containsKey('Image Artist')) {
      digitalIndicators++;
    }

    // Check file naming patterns
    if (fileCharacteristics['naming_patterns']?['has_software_pattern'] == true) {
      digitalIndicators++;
    }

    if (fileCharacteristics['naming_patterns']?['has_uuid_pattern'] == true) {
      digitalIndicators++;
    }

    if (fileCharacteristics['naming_patterns']?['is_screenshot'] == true) {
      digitalIndicators++;
    }

    // Check compression format
    Map<String, dynamic>? compressionInfo = fileCharacteristics['compression_info'];
    if (compressionInfo != null) {
      if (compressionInfo['compression_type'] == 'PNG' && compressionInfo['is_lossless'] == true) {
        digitalIndicators++;
      }
      if (compressionInfo['compression_type'] == 'WebP') {
        digitalIndicators++;
      }
    }

    // Check for web-related patterns
    if (fileCharacteristics['naming_patterns']?['has_web_pattern'] == true) {
      digitalIndicators++;
    }

    return digitalIndicators >= 2;
  }

  bool _isDesignSoftware(String software) {
    List<String> designSoftware = [
      'Adobe Photoshop', 'Adobe Illustrator', 'Adobe Lightroom', 'Adobe Creative Cloud',
      'GIMP', 'Inkscape', 'Krita', 'Paint.NET', 'CorelDRAW',
      'Canva', 'Figma', 'Sketch', 'Affinity', 'Procreate',
      'Blender', 'Maya', '3ds Max', 'Cinema 4D'
    ];

    return designSoftware.any((name) => software.toLowerCase().contains(name.toLowerCase()));
  }

  String _identifyCompression(Map<String, dynamic> fileCharacteristics) {
    Map<String, dynamic>? compressionInfo = fileCharacteristics['compression_info'];
    String? compressionType = compressionInfo?['compression_type'];

    if (compressionType != null) {
      switch (compressionType) {
        case 'JPEG':
          return 'JPEG';
        case 'PNG':
          return 'PNG';
        case 'WEBP':
          return 'WebP';
        case 'GIF':
          return 'GIF';
        case 'BMP':
          return 'BMP';
        case 'TIFF':
          return 'TIFF';
        default:
          return 'Unknown';
      }
    }

    return 'Unknown';
  }

  List<String> _identifySource(Map<String, String> exifData, Map<String, dynamic> fileCharacteristics) {
    List<String> sources = [];

    // Camera source
    if (exifData.containsKey('Image Make') || exifData.containsKey('Image Model')) {
      sources.add('camera');
    }

    // Phone camera
    String? software = exifData['Image Software'];
    if (software != null && _isPhoneSoftware(software)) {
      sources.add('phone_camera');
    }

    // Digital art software
    if (software != null && _isDesignSoftware(software)) {
      sources.add('digital_art_software');
    }

    // Screenshot
    if (fileCharacteristics['naming_patterns']?['is_screenshot'] == true) {
      sources.add('screenshot');
    }

    // Download/web
    if (fileCharacteristics['naming_patterns']?['has_web_pattern'] == true) {
      sources.add('web_download');
    }

    // Professional camera
    if (_isProfessionalCamera(exifData)) {
      sources.add('professional_camera');
    }

    // Scanned image
    if (_isScannedImage(exifData, fileCharacteristics)) {
      sources.add('scanner');
    }

    return sources;
  }

  bool _isPhoneSoftware(String software) {
    List<String> phoneSoftware = [
      'iPhone', 'Android', 'Samsung', 'Huawei', 'Xiaomi', 'OnePlus',
      'Pixel', 'LG', 'Motorola', 'OPPO', 'Vivo', 'Realme'
    ];

    return phoneSoftware.any((name) => software.toLowerCase().contains(name.toLowerCase()));
  }

  bool _isProfessionalCamera(Map<String, String> exifData) {
    String? make = exifData['Image Make'];
    String? model = exifData['Image Model'];

    List<String> professionalBrands = ['Canon', 'Nikon', 'Sony', 'Fujifilm', 'Olympus', 'Panasonic'];

    if (make != null && professionalBrands.any((brand) => make.contains(brand))) {
      return true;
    }

    if (model != null) {
      // Check for professional model indicators
      List<String> professionalModelPatterns = [
        r'\d+D', r'\d+Mark', r'EOS \d', r'X-Pro', r'X-T\d+', r'Z\d+', r'A7', r'Alpha \d'
      ];

      return professionalModelPatterns.any((pattern) => RegExp(pattern).hasMatch(model));
    }

    return false;
  }

  bool _isScannedImage(Map<String, String> exifData, Map<String, dynamic> fileCharacteristics) {
    // Check for scanner-related metadata
    if (exifData.containsKey('Scanner Model') || exifData.containsKey('Scanner Make')) {
      return true;
    }

    // Check for high resolution typical of scans
    Map<String, dynamic>? compressionInfo = fileCharacteristics['compression_info'];
    if (compressionInfo?['compression_type'] == 'TIFF' &&
        fileCharacteristics['file_size_category'] == 'very_large') {
      return true;
    }

    return false;
  }

  String _determineSourceType(MediaMetadata metadata) {
    if (metadata.isPhotograph && !metadata.isDigitalCreation) {
      return 'photograph';
    } else if (!metadata.isPhotograph && metadata.isDigitalCreation) {
      return 'digital_creation';
    } else if (metadata.isPhotograph && metadata.isDigitalCreation) {
      return 'digitized_photograph';
    } else {
      return 'unknown';
    }
  }

  double _calculateMetadataConfidence(MediaMetadata metadata) {
    double confidence = 0.0;

    // Confidence based on source indicators
    if (metadata.sourceIndicators.isNotEmpty) {
      confidence += 0.3;

      // Higher confidence for multiple consistent indicators
      if (metadata.sourceIndicators.length > 1) {
        confidence += 0.1;
      }
    }

    // Confidence based on EXIF data richness
    int exifDataCount = metadata.exifData.length;
    if (exifDataCount > 10) {
      confidence += 0.2;
    } else if (exifDataCount > 5) {
      confidence += 0.1;
    }

    // Confidence based on file characteristics
    if (metadata.fileCharacteristics['compression_info'] != null) {
      confidence += 0.1;
    }

    // Confidence based on naming patterns
    Map<String, bool> namingPatterns = metadata.fileCharacteristics['naming_patterns'] ?? {};
    int patternMatches = namingPatterns.values.where((match) => match).length;
    confidence += patternMatches * 0.05;

    // Confidence based on clear source identification
    if (metadata.isPhotograph || metadata.isDigitalCreation) {
      confidence += 0.3;
    }

    return confidence.clamp(0.0, 1.0);
  }

  // Advanced metadata analysis
  Future<AdvancedMetadataAnalysis> performAdvancedAnalysis(File imageFile) async {
    MediaMetadata metadata = await analyzeMetadata(imageFile);

    // Analyze image source credibility
    SourceCredibility credibility = _analyzeSourceCredibility(metadata);

    // Check for manipulation indicators
    ManipulationIndicators manipulation = _detectManipulationIndicators(metadata);

    // Analyze creation timeline
    CreationTimeline timeline = _analyzeCreationTimeline(metadata);

    // Determine quality indicators
    QualityIndicators quality = _analyzeQualityIndicators(metadata);

    // Calculate overall confidence
    double overallConfidence = _calculateOverallMetadataConfidence(
      metadata, credibility, manipulation, quality
    );

    return AdvancedMetadataAnalysis(
      metadata: metadata,
      sourceCredibility: credibility,
      manipulationIndicators: manipulation,
      creationTimeline: timeline,
      qualityIndicators: quality,
      overallConfidence: overallConfidence,
      analysisTimestamp: DateTime.now(),
    );
  }

  SourceCredibility _analyzeSourceCredibility(MediaMetadata metadata) {
    double credibilityScore = 0.0;
    List<String> credibilityFactors = [];

    // Camera metadata increases credibility
    if (metadata.sourceIndicators.contains('camera')) {
      credibilityScore += 0.3;
      credibilityFactors.add('camera_metadata');
    }

    // Professional camera increases credibility
    if (metadata.sourceIndicators.contains('professional_camera')) {
      credibilityScore += 0.2;
      credibilityFactors.add('professional_equipment');
    }

    // Original file name patterns increase credibility
    Map<String, bool> namingPatterns = metadata.fileCharacteristics['naming_patterns'] ?? {};
    if (namingPatterns['has_date_pattern'] == true || namingPatterns['has_camera_pattern'] == true) {
      credibilityScore += 0.1;
      credibilityFactors.add('original_naming');
    }

    // Rich EXIF data increases credibility
    if (metadata.exifData.length > 15) {
      credibilityScore += 0.2;
      credibilityFactors.add('rich_metadata');
    }

    // Recent creation time
    if (metadata.fileCharacteristics['is_recent'] == true) {
      credibilityScore += 0.1;
      credibilityFactors.add('recent_creation');
    }

    // No manipulation software detected
    if (!metadata.isDigitalCreation) {
      credibilityScore += 0.1;
      credibilityFactors.add('no_software_modification');
    }

    CredibilityLevel level;
    if (credibilityScore >= 0.8) {
      level = CredibilityLevel.high;
    } else if (credibilityScore >= 0.5) {
      level = CredibilityLevel.medium;
    } else if (credibilityScore >= 0.3) {
      level = CredibilityLevel.low;
    } else {
      level = CredibilityLevel.very_low;
    }

    return SourceCredibility(
      score: credibilityScore.clamp(0.0, 1.0),
      level: level,
      factors: credibilityFactors,
    );
  }

  ManipulationIndicators _detectManipulationIndicators(MediaMetadata metadata) {
    int manipulationScore = 0;
    List<String> indicators = [];

    // Design software detection
    if (metadata.isDigitalCreation) {
      manipulationScore += 3;
      indicators.add('digital_software_detected');
    }

    // Web download indicators
    if (metadata.sourceIndicators.contains('web_download')) {
      manipulationScore += 2;
      indicators.add('web_download_detected');
    }

    // Screenshot indicators
    if (metadata.sourceIndicators.contains('screenshot')) {
      manipulationScore += 2;
      indicators.add('screenshot_detected');
    }

    // Unusual file naming
    Map<String, bool> namingPatterns = metadata.fileCharacteristics['naming_patterns'] ?? {};
    if (namingPatterns['has_uuid_pattern'] == true) {
      manipulationScore += 1;
      indicators.add('generated_naming');
    }

    // Missing camera metadata for apparent photograph
    if (metadata.isPhotograph && metadata.sourceIndicators.contains('camera') == false) {
      manipulationScore += 1;
      indicators.add('missing_camera_metadata');
    }

    ManipulationLikelihood likelihood;
    if (manipulationScore >= 5) {
      likelihood = ManipulationLikelihood.very_likely;
    } else if (manipulationScore >= 3) {
      likelihood = ManipulationLikelihood.likely;
    } else if (manipulationScore >= 1) {
      likelihood = ManipulationLikelihood.possible;
    } else {
      likelihood = ManipulationLikelihood.unlikely;
    }

    return ManipulationIndicators(
      score: manipulationScore,
      likelihood: likelihood,
      indicators: indicators,
    );
  }

  CreationTimeline _analyzeCreationTimeline(MediaMetadata metadata) {
    DateTime? creationTime;
    DateTime? modificationTime;
    String? originalSoftware;
    String? currentSoftware;

    // Extract dates from EXIF
    if (metadata.exifData.containsKey('EXIF DateTimeOriginal')) {
      creationTime = _parseExifDate(metadata.exifData['EXIF DateTimeOriginal']!);
    } else if (metadata.exifData.containsKey('Image DateTime')) {
      creationTime = _parseExifDate(metadata.exifData['Image DateTime']!);
    }

    // Extract file modification time
    if (metadata.fileCharacteristics.containsKey('creation_time')) {
      modificationTime = DateTime.parse(metadata.fileCharacteristics['creation_time']);
    }

    // Extract software information
    if (metadata.exifData.containsKey('Image Software')) {
      originalSoftware = metadata.exifData['Image Software'];
    }

    // Calculate age
    DateTime now = DateTime.now();
    int ageInDays = creationTime != null ? now.difference(creationTime).inDays : -1;

    // Determine era
    CreationEra era;
    if (ageInDays < 0) {
      era = CreationEra.unknown;
    } else if (ageInDays < 30) {
      era = CreationEra.recent;
    } else if (ageInDays < 365) {
      era = CreationEra.this_year;
    } else if (ageInDays < 365 * 5) {
      era = CreationEra.last_few_years;
    } else {
      era = CreationEra.older;
    }

    return CreationTimeline(
      creationTime: creationTime,
      modificationTime: modificationTime,
      originalSoftware: originalSoftware,
      currentSoftware: currentSoftware,
      ageInDays: ageInDays,
      era: era,
      timeConsistency: creationTime != null && modificationTime != null
          ? modificationTime.difference(creationTime).inDays < 30
          : false,
    );
  }

  DateTime? _parseExifDate(String dateString) {
    try {
      // EXIF date format: YYYY:MM:DD HH:MM:SS
      List<String> parts = dateString.split(':');
      if (parts.length >= 3) {
        String normalized = '${parts[0]}-${parts[1]}-${parts[2]} ${parts.sublist(3).join(':')}';
        return DateTime.parse(normalized);
      } else {
        throw FormatException('Invalid EXIF date format: $dateString');
      }
    } catch (e) {
      debugPrint('Error parsing EXIF date: $e');
      return null;
    }
  }

  QualityIndicators _analyzeQualityIndicators(MediaMetadata metadata) {
    double qualityScore = 0.0;
    List<String> qualityFactors = [];

    // File size indicator
    String sizeCategory = metadata.fileCharacteristics['file_size_category'] ?? 'medium';
    if (sizeCategory == 'very_large') {
      qualityScore += 0.3;
      qualityFactors.add('large_file_size');
    } else if (sizeCategory == 'large') {
      qualityScore += 0.2;
      qualityFactors.add('moderate_file_size');
    }

    // Format quality
    String compressionType = metadata.compressionType;
    if (compressionType == 'PNG') {
      qualityScore += 0.2;
      qualityFactors.add('lossless_format');
    } else if (compressionType == 'TIFF') {
      qualityScore += 0.3;
      qualityFactors.add('professional_format');
    }

    // Metadata completeness
    if (metadata.exifData.length > 20) {
      qualityScore += 0.2;
      qualityFactors.add('complete_metadata');
    } else if (metadata.exifData.length > 10) {
      qualityScore += 0.1;
      qualityFactors.add('partial_metadata');
    }

    // Source reliability
    if (metadata.sourceIndicators.contains('professional_camera')) {
      qualityScore += 0.3;
      qualityFactors.add('professional_source');
    }

    QualityLevel level;
    if (qualityScore >= 0.8) {
      level = QualityLevel.high;
    } else if (qualityScore >= 0.5) {
      level = QualityLevel.medium;
    } else if (qualityScore >= 0.3) {
      level = QualityLevel.low;
    } else {
      level = QualityLevel.very_low;
    }

    return QualityIndicators(
      score: qualityScore.clamp(0.0, 1.0),
      level: level,
      factors: qualityFactors,
    );
  }

  double _calculateOverallMetadataConfidence(
    MediaMetadata metadata,
    SourceCredibility credibility,
    ManipulationIndicators manipulation,
    QualityIndicators quality,
  ) {
    // Weighted combination of different confidence factors
    double baseConfidence = credibility.score * 0.4;
    double manipulationPenalty = manipulation.likelihood == ManipulationLikelihood.very_likely ? 0.3 :
                                 manipulation.likelihood == ManipulationLikelihood.likely ? 0.2 :
                                 manipulation.likelihood == ManipulationLikelihood.possible ? 0.1 : 0.0;
    double qualityBonus = quality.score * 0.3;

    double overallConfidence = baseConfidence - manipulationPenalty + qualityBonus;

    // Additional factors
    if (metadata.sourceIndicators.isNotEmpty) {
      overallConfidence += 0.1;
    }

    if (metadata.exifData.isNotEmpty) {
      overallConfidence += 0.1;
    }

    return overallConfidence.clamp(0.0, 1.0);
  }
}

// Supporting classes for advanced analysis
class AdvancedMetadataAnalysis {
  final MediaMetadata metadata;
  final SourceCredibility sourceCredibility;
  final ManipulationIndicators manipulationIndicators;
  final CreationTimeline creationTimeline;
  final QualityIndicators qualityIndicators;
  final double overallConfidence;
  final DateTime analysisTimestamp;

  AdvancedMetadataAnalysis({
    required this.metadata,
    required this.sourceCredibility,
    required this.manipulationIndicators,
    required this.creationTimeline,
    required this.qualityIndicators,
    required this.overallConfidence,
    required this.analysisTimestamp,
  });
}

class SourceCredibility {
  final double score;
  final CredibilityLevel level;
  final List<String> factors;

  SourceCredibility({
    required this.score,
    required this.level,
    required this.factors,
  });
}

enum CredibilityLevel {
  very_low,
  low,
  medium,
  high,
  very_high,
}

class ManipulationIndicators {
  final int score;
  final ManipulationLikelihood likelihood;
  final List<String> indicators;

  ManipulationIndicators({
    required this.score,
    required this.likelihood,
    required this.indicators,
  });
}

enum ManipulationLikelihood {
  unlikely,
  possible,
  likely,
  very_likely,
}

class CreationTimeline {
  final DateTime? creationTime;
  final DateTime? modificationTime;
  final String? originalSoftware;
  final String? currentSoftware;
  final int ageInDays;
  final CreationEra era;
  final bool timeConsistency;

  CreationTimeline({
    required this.creationTime,
    required this.modificationTime,
    required this.originalSoftware,
    required this.currentSoftware,
    required this.ageInDays,
    required this.era,
    required this.timeConsistency,
  });
}

enum CreationEra {
  unknown,
  recent,
  this_year,
  last_few_years,
  older,
}

class QualityIndicators {
  final double score;
  final QualityLevel level;
  final List<String> factors;

  QualityIndicators({
    required this.score,
    required this.level,
    required this.factors,
  });
}

enum QualityLevel {
  very_low,
  low,
  medium,
  high,
  very_high,
}
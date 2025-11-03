import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/enhanced_detection_result.dart';
import '../models/detection_result.dart';
import 'comprehensive_analysis_service.dart';
import 'ml_inference_service.dart';
import 'classical_cv_service.dart';

class EnhancedDetectionService {
  final ComprehensiveAnalysisService _analysisService = ComprehensiveAnalysisService();

  // Performance monitoring
  final Map<String, Duration> _performanceMetrics = {};
  final List<EnhancedDetectionResult> _sessionHistory = [];
  static const int maxSessionHistory = 100;

  // Settings
  bool _enableAdvancedAnalysis = true;
  bool _enableCaching = true;
  Duration _analysisTimeout = const Duration(seconds: 10);
  bool _enableRealtimeMode = false;

  // Getters
  bool get enableAdvancedAnalysis => _enableAdvancedAnalysis;
  bool get enableCaching => _enableCaching;
  Duration get analysisTimeout => _analysisTimeout;
  bool get enableRealtimeMode => _enableRealtimeMode;

  // Setters
  set enableAdvancedAnalysis(bool value) => _enableAdvancedAnalysis = value;
  set enableCaching(bool value) => _enableCaching = value;
  set analysisTimeout(Duration value) => _analysisTimeout = value;
  set enableRealtimeMode(bool value) => _enableRealtimeMode = value;

  // Main detection method
  Future<EnhancedDetectionResult> detectWithMediaAnalysis(
    File imageFile,
    DetectionResult fishDetection, {
    bool? useAdvancedAnalysis,
    Duration? timeout,
    bool? useCache,
  }) async {
    Stopwatch stopwatch = Stopwatch()..start();

    try {
      useAdvancedAnalysis ??= _enableAdvancedAnalysis;
      useCache ??= _enableCaching;
      timeout ??= _analysisTimeout;

      debugPrint('Starting enhanced detection analysis...');
      debugPrint('Advanced analysis: $useAdvancedAnalysis');
      debugPrint('Caching enabled: $useCache');
      debugPrint('Realtime mode: $_enableRealtimeMode');

      EnhancedDetectionResult result;

      if (_enableRealtimeMode && !useAdvancedAnalysis) {
        // Fast real-time analysis
        result = await _analysisService.analyzeRealTime(
          imageFile,
          fishDetection,
          maxProcessingTime: const Duration(milliseconds: 500),
        );
      } else if (useAdvancedAnalysis) {
        // Full comprehensive analysis
        result = await _analysisService.analyzeImage(
          imageFile,
          fishDetection,
          useCache: useCache,
          timeout: timeout,
        );
      } else {
        // Basic analysis (confidence + simple visual analysis)
        result = await _performBasicAnalysis(imageFile, fishDetection);
      }

      // Add to session history
      _addToSessionHistory(result);

      // Record performance metrics
      _performanceMetrics['enhanced_detection'] = stopwatch.elapsed;
      debugPrint('Enhanced detection completed in: ${stopwatch.elapsedMilliseconds}ms');

      return result;

    } catch (e) {
      stopwatch.stop();
      _performanceMetrics['enhanced_detection_error'] = stopwatch.elapsed;
      debugPrint('Error in enhanced detection: $e');

      // Return fallback result
      return _createFallbackResult(fishDetection, e);
    } finally {
      stopwatch.stop();
    }
  }

  // Batch detection for multiple images
  Future<List<EnhancedDetectionResult>> detectBatch(
    List<File> imageFiles,
    List<DetectionResult> fishDetections, {
    bool useAdvancedAnalysis = true,
    Duration timeout = const Duration(seconds: 30),
    int? batchSize,
  }) async {
    if (imageFiles.length != fishDetections.length) {
      throw ArgumentError('Image files and detections must have the same length');
    }

    batchSize ??= _enableRealtimeMode ? 10 : 5;
    List<EnhancedDetectionResult> allResults = [];

    debugPrint('Starting batch detection for ${imageFiles.length} images...');
    debugPrint('Batch size: $batchSize');

    Stopwatch totalStopwatch = Stopwatch()..start();

    for (int i = 0; i < imageFiles.length; i += batchSize) {
      int end = (i + batchSize).clamp(0, imageFiles.length);
      List<File> batchImages = imageFiles.sublist(i, end);
      List<DetectionResult> batchDetections = fishDetections.sublist(i, end);

      debugPrint('Processing batch ${i ~/ batchSize + 1}: ${batchImages.length} images');

      try {
        List<EnhancedDetectionResult> batchResults = await _processBatch(
          batchImages,
          batchDetections,
          useAdvancedAnalysis,
          timeout,
        );

        allResults.addAll(batchResults);

      } catch (e) {
        debugPrint('Error processing batch ${i ~/ batchSize + 1}: $e');

        // Add fallback results for failed batch
        for (int j = i; j < end; j++) {
          allResults.add(_createFallbackResult(fishDetections[j], e));
        }
      }
    }

    totalStopwatch.stop();
    _performanceMetrics['batch_detection'] = totalStopwatch.elapsed;
    debugPrint('Batch detection completed in: ${totalStopwatch.elapsedMilliseconds}ms');

    return allResults;
  }

  Future<List<EnhancedDetectionResult>> _processBatch(
    List<File> imageFiles,
    List<DetectionResult> fishDetections,
    bool useAdvancedAnalysis,
    Duration timeout,
  ) async {
    if (_enableRealtimeMode && !useAdvancedAnalysis) {
      // Parallel processing for real-time mode
      List<Future<EnhancedDetectionResult>> futures = [];
      for (int i = 0; i < imageFiles.length; i++) {
        futures.add(_analysisService.analyzeRealTime(
          imageFiles[i],
          fishDetections[i],
          maxProcessingTime: const Duration(milliseconds: 500),
        ));
      }

      return await Future.wait(futures);
    } else {
      // Sequential processing for advanced analysis
      return await _analysisService.analyzeImages(
        imageFiles,
        fishDetections,
        useCache: _enableCaching,
        timeout: timeout,
      );
    }
  }

  // Real-time streaming detection
  Stream<EnhancedDetectionResult> detectStream(
    Stream<File> imageStream,
    Stream<DetectionResult> detectionStream,
  ) async* {
    await for (var detection in detectionStream) {
      // Find corresponding image
      File? image;
      try {
        image = await imageStream.first;
      } catch (e) {
        debugPrint('Error getting image from stream: $e');
        continue;
      }

      if (image != null) {
        EnhancedDetectionResult result = await detectWithMediaAnalysis(
          image,
          detection,
          useAdvancedAnalysis: !_enableRealtimeMode, // Use basic analysis for streaming
        );

        yield result;
      }
    }
  }

  // Basic analysis (confidence + simple visual)
  Future<EnhancedDetectionResult> _performBasicAnalysis(
    File imageFile,
    DetectionResult fishDetection,
  ) async {
    try {
      // Simple confidence analysis only
      ConfidenceAnalysis confidence = _performSimpleConfidenceAnalysis(fishDetection);

      // Basic visual analysis (reduced)
      VisualFeatures visualFeatures = await _performBasicVisualAnalysis(imageFile);

      // No consistency or metadata analysis for basic mode

      ComprehensiveAnalysis analysis = ComprehensiveAnalysis(
        originalDetection: fishDetection,
        confidence: confidence,
        visualFeatures: visualFeatures,
        consistency: _createFallbackConsistencyAnalysis(),
        metadata: _createFallbackMetadataAnalysis(),
      );

      // Simple fusion (confidence-based only)
      MediaType mediaType = _classifyMediaTypeFromConfidence(fishDetection.confidence);
      double mediaConfidence = _calculateSimpleMediaConfidence(mediaType, fishDetection.confidence);

      return EnhancedDetectionResult(
        fishDetection: fishDetection,
        mediaType: mediaType,
        mediaConfidence: mediaConfidence,
        analysis: analysis,
        timestamp: DateTime.now(),
        additionalFeatures: {
          'basic_mode': true,
          'processing_time_ms': 0,
        },
      );

    } catch (e) {
      debugPrint('Error in basic analysis: $e');
      return _createFallbackResult(fishDetection, e);
    }
  }

  ConfidenceAnalysis _performSimpleConfidenceAnalysis(DetectionResult fishDetection) {
    return ConfidenceAnalysis(
      signature: MediaSignature(
        confidenceLevel: _categorizeConfidence(fishDetection.confidence),
        boundingBoxQuality: 0.7, // Default value
        detectionStability: 0.7, // Default value
        confidenceScore: fishDetection.confidence,
      ),
      confidenceDescription: 'Basic confidence analysis',
      confidenceFeatures: {
        'basic_mode': 1.0,
        'confidence_score': fishDetection.confidence,
      },
    );
  }

  Future<VisualFeatures> _performBasicVisualAnalysis(File imageFile) async {
    try {
      // Use simplified visual analysis
      // Use public method instead of private field access
      ClassicalCVService cvService = ClassicalCVService();
      return await cvService.analyzeImage(imageFile);
    } catch (e) {
      debugPrint('Error in basic visual analysis: $e');
      return _createFallbackVisualFeatures();
    }
  }

  ConfidenceLevel _categorizeConfidence(double confidence) {
    if (confidence >= 0.85) return ConfidenceLevel.veryHigh;
    if (confidence >= 0.70) return ConfidenceLevel.high;
    if (confidence >= 0.50) return ConfidenceLevel.medium;
    if (confidence >= 0.30) return ConfidenceLevel.low;
    return ConfidenceLevel.veryLow;
  }

  MediaType _classifyMediaTypeFromConfidence(double confidence) {
    if (confidence >= 0.85) return MediaType.photograph;
    if (confidence >= 0.70) return MediaType.digitalArt;
    if (confidence >= 0.50) return MediaType.painting;
    if (confidence >= 0.30) return MediaType.cartoon;
    return MediaType.unknown;
  }

  double _calculateSimpleMediaConfidence(MediaType mediaType, double fishConfidence) {
    // Simple confidence calculation based on fish detection confidence
    return fishConfidence * 0.8; // Reduce confidence for basic mode
  }

  // Advanced analysis methods
  Future<AdvancedAnalysisReport> performAdvancedAnalysis(
    File imageFile,
    DetectionResult fishDetection,
  ) async {
    return await _analysisService.performAdvancedAnalysis(imageFile, fishDetection);
  }

  // Performance monitoring
  Map<String, Duration> getPerformanceMetrics() {
    return Map.from(_performanceMetrics);
  }

  void clearPerformanceMetrics() {
    _performanceMetrics.clear();
  }

  Map<String, dynamic> getSystemStatus() {
    return {
      'session_history_count': _sessionHistory.length,
      'performance_metrics': _performanceMetrics,
      'settings': {
        'enable_advanced_analysis': _enableAdvancedAnalysis,
        'enable_caching': _enableCaching,
        'analysis_timeout_ms': _analysisTimeout.inMilliseconds,
        'realtime_mode': _enableRealtimeMode,
      },
      'cache_status': _analysisService.getPerformanceStats(),
    };
  }

  // Session management
  List<EnhancedDetectionResult> getSessionHistory() {
    return List.from(_sessionHistory);
  }

  void clearSessionHistory() {
    _sessionHistory.clear();
  }

  List<EnhancedDetectionResult> getRecentResults({int limit = 10}) {
    int count = limit.clamp(0, _sessionHistory.length);
    return _sessionHistory.reversed.take(count).toList();
  }

  Map<String, dynamic> getSessionStatistics() {
    if (_sessionHistory.isEmpty) {
      return {
        'total_detections': 0,
        'average_confidence': 0.0,
        'media_type_distribution': {},
        'quality_distribution': {},
        'session_duration': 0,
      };
    }

    int totalDetections = _sessionHistory.length;
    double avgConfidence = _sessionHistory
        .map((r) => r.fishDetection.confidence)
        .reduce((a, b) => a + b) / totalDetections;

    Map<String, int> mediaTypeDistribution = {};
    Map<String, int> qualityDistribution = {};

    for (var result in _sessionHistory) {
      String mediaType = result.mediaType.toString();
      mediaTypeDistribution[mediaType] = (mediaTypeDistribution[mediaType] ?? 0) + 1;

      Map<String, dynamic>? qualityMetrics = result.additionalFeatures['quality_metrics'];
      if (qualityMetrics != null) {
        String qualityLevel = qualityMetrics['quality_level'] ?? 'unknown';
        qualityDistribution[qualityLevel] = (qualityDistribution[qualityLevel] ?? 0) + 1;
      }
    }

    DateTime sessionStart = _sessionHistory.first.timestamp;
    DateTime sessionEnd = _sessionHistory.last.timestamp;
    Duration sessionDuration = sessionEnd.difference(sessionStart);

    return {
      'total_detections': totalDetections,
      'average_confidence': avgConfidence,
      'media_type_distribution': mediaTypeDistribution,
      'quality_distribution': qualityDistribution,
      'session_duration_ms': sessionDuration.inMilliseconds,
      'session_start': sessionStart.toIso8601String(),
      'session_end': sessionEnd.toIso8601String(),
    };
  }

  // Quality control
  List<EnhancedDetectionResult> getHighConfidenceResults({double threshold = 0.8}) {
    return _sessionHistory.where((result) => result.mediaConfidence >= threshold).toList();
  }

  List<EnhancedDetectionResult> getResultsByMediaType(MediaType mediaType) {
    return _sessionHistory.where((result) => result.mediaType == mediaType).toList();
  }

  List<EnhancedDetectionResult> getRecentResultsByTime(Duration maxAge) {
    DateTime cutoff = DateTime.now().subtract(maxAge);
    return _sessionHistory.where((result) => result.timestamp.isAfter(cutoff)).toList();
  }

  // Export functionality
  Map<String, dynamic> exportResults() {
    return {
      'export_timestamp': DateTime.now().toIso8601String(),
      'total_results': _sessionHistory.length,
      'results': _sessionHistory.map((r) => r.toJson()).toList(),
      'session_statistics': getSessionStatistics(),
      'system_status': getSystemStatus(),
    };
  }

  Future<void> exportToFile(String filePath) async {
    try {
      Map<String, dynamic> exportData = exportResults();
      // Note: In a real implementation, you would save this to a file
      // using dart:convert and dart:io
      debugPrint('Export results to file: $filePath');
      debugPrint('Total results: ${exportData['total_results']}');
    } catch (e) {
      debugPrint('Error exporting results: $e');
      rethrow;
    }
  }

  // Cache management
  void clearCache() {
    _analysisService.clearCache();
    debugPrint('Analysis cache cleared');
  }

  Map<String, dynamic> getCacheStatus() {
    return _analysisService.getPerformanceStats();
  }

  // Settings management
  void updateSettings({
    bool? enableAdvancedAnalysis,
    bool? enableCaching,
    Duration? analysisTimeout,
    bool? enableRealtimeMode,
  }) {
    if (enableAdvancedAnalysis != null) {
      _enableAdvancedAnalysis = enableAdvancedAnalysis;
      debugPrint('Advanced analysis enabled: $_enableAdvancedAnalysis');
    }

    if (enableCaching != null) {
      _enableCaching = enableCaching;
      debugPrint('Caching enabled: $_enableCaching');
    }

    if (analysisTimeout != null) {
      _analysisTimeout = analysisTimeout;
      debugPrint('Analysis timeout updated: $_analysisTimeout');
    }

    if (enableRealtimeMode != null) {
      _enableRealtimeMode = enableRealtimeMode;
      debugPrint('Realtime mode enabled: $_enableRealtimeMode');
    }
  }

  // Utility methods
  void _addToSessionHistory(EnhancedDetectionResult result) {
    _sessionHistory.add(result);

    // Maintain max history size
    if (_sessionHistory.length > maxSessionHistory) {
      _sessionHistory.removeAt(0);
    }

    debugPrint('Added result to session history. Total: ${_sessionHistory.length}');
  }

  EnhancedDetectionResult _createFallbackResult(DetectionResult fishDetection, dynamic error) {
    return EnhancedDetectionResult(
      fishDetection: fishDetection,
      mediaType: MediaType.unknown,
      mediaConfidence: 0.0,
      analysis: ComprehensiveAnalysis(
        originalDetection: fishDetection,
        confidence: _createFallbackConfidenceAnalysis(fishDetection),
        visualFeatures: _createFallbackVisualFeatures(),
        consistency: _createFallbackConsistencyAnalysis(),
        metadata: _createFallbackMetadataAnalysis(),
      ),
      timestamp: DateTime.now(),
      additionalFeatures: {
        'error': error.toString(),
        'fallback_mode': true,
        'service_name': 'EnhancedDetectionService',
      },
    );
  }

  ConfidenceAnalysis _createFallbackConfidenceAnalysis(DetectionResult fishDetection) {
    return ConfidenceAnalysis(
      signature: MediaSignature(
        confidenceLevel: ConfidenceLevel.medium,
        boundingBoxQuality: 0.5,
        detectionStability: 0.5,
        confidenceScore: fishDetection.confidence,
      ),
      confidenceDescription: 'Fallback confidence analysis - service error',
      confidenceFeatures: {'fallback': 1.0},
    );
  }

  VisualFeatures _createFallbackVisualFeatures() {
    return VisualFeatures(
      edgeFeatures: EdgeFeatures(
        edgeDensity: 0.0,
        edgeDistribution: 0.0,
        edgeConsistency: 0.0,
        edgeSharpness: 0.0,
        edgeMetrics: {'fallback': 1.0},
      ),
      colorFeatures: ColorFeatures(
        colorVariance: 0.0,
        saturationProfile: 'unknown',
        lightingPattern: 'unknown',
        colorfulness: 0.0,
        colorMetrics: {'fallback': 1.0},
      ),
      textureFeatures: TextureFeatures(
        lbpPattern: 0.0,
        glcmFeatures: {},
        noiseProfile: 0.0,
        compressionArtifacts: 0.0,
        textureComplexity: 0.0,
        textureMetrics: {'fallback': 1.0},
      ),
    );
  }

  ConsistencyAnalysis _createFallbackConsistencyAnalysis() {
    return ConsistencyAnalysis(
      report: ConsistencyReport(
        confidenceVariance: 0.0,
        boundingBoxVariance: 0.0,
        positionStability: 0.5,
        detectionFrequency: 0.5,
        hasEnoughData: false,
        consistencyMetrics: {'fallback': 1.0},
      ),
      detectedPattern: MediaPattern.unknown,
      stabilityDescription: 'Fallback consistency analysis - service error',
    );
  }

  MetadataAnalysis _createFallbackMetadataAnalysis() {
    return MetadataAnalysis(
      metadata: MediaMetadata(
        isPhotograph: false,
        isDigitalCreation: false,
        compressionType: 'unknown',
        sourceIndicators: [],
        exifData: {},
        fileCharacteristics: {'fallback': 1.0},
      ),
      sourceType: 'unknown',
      metadataConfidence: 0.0,
    );
  }

  // Dispose method
  void dispose() {
    clearCache();
    clearPerformanceMetrics();
    _sessionHistory.clear();
    debugPrint('EnhancedDetectionService disposed');
  }
}

// Supporting class for advanced reports
class AdvancedDetectionReport {
  final EnhancedDetectionResult basicResult;
  final Object consistencyAnalysis; // Using Object to avoid circular imports
  final Object metadataAnalysis;     // Using Object to avoid circular imports
  final QualityAssessment qualityAssessment;
  final List<String> recommendations;
  final Duration processingTime;
  final DateTime analysisTimestamp;

  AdvancedDetectionReport({
    required this.basicResult,
    required this.consistencyAnalysis,
    required this.metadataAnalysis,
    required this.qualityAssessment,
    required this.recommendations,
    required this.processingTime,
    required this.analysisTimestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'basic_result': basicResult.toJson(),
      'quality_assessment': {
        'overall_quality': qualityAssessment.overallQuality,
        'quality_factors': qualityAssessment.qualityFactors,
        'quality_level': qualityAssessment.qualityLevel,
      },
      'recommendations': recommendations,
      'processing_time_ms': processingTime.inMilliseconds,
      'analysis_timestamp': analysisTimestamp.toIso8601String(),
    };
  }
}

class QualityAssessment {
  final double overallQuality;
  final List<String> qualityFactors;
  final String qualityLevel;
  final List<String> improvements;

  QualityAssessment({
    required this.overallQuality,
    required this.qualityFactors,
    required this.qualityLevel,
    required this.improvements,
  });
}
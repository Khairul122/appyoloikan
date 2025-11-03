import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/enhanced_detection_result.dart';
import '../models/detection_result.dart';
import 'confidence_analysis_service.dart';
import 'classical_cv_service.dart';
import 'consistency_analysis_service.dart';
import 'metadata_analysis_service.dart';
import 'media_fusion_engine.dart';

class ComprehensiveAnalysisService {
  final ConfidenceAnalysisService _confidenceService = ConfidenceAnalysisService();
  final ClassicalCVService _cvService = ClassicalCVService();
  final ConsistencyAnalysisService _consistencyService = ConsistencyAnalysisService();
  final MetadataAnalysisService _metadataService = MetadataAnalysisService();
  final MediaFusionEngine _fusionEngine = MediaFusionEngine();

  // Cache for performance optimization
  final Map<String, VisualFeatures> _visualCache = {};
  final Map<String, MetadataAnalysis> _metadataCache = {};

  // Performance monitoring
  final Map<String, Duration> _processingTimes = {};

  Future<EnhancedDetectionResult> analyzeImage(
    File imageFile,
    DetectionResult fishDetection, {
    bool useCache = true,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    Stopwatch stopwatch = Stopwatch()..start();

    try {
      // Step 1: Confidence Analysis
      ConfidenceAnalysis confidence = await _performConfidenceAnalysis(fishDetection);

      // Step 2: Visual Feature Analysis (with caching)
      VisualFeatures visualFeatures = await _performVisualAnalysis(imageFile, useCache);

      // Step 3: Consistency Analysis
      ConsistencyAnalysis consistency = await _performConsistencyAnalysis(fishDetection);

      // Step 4: Metadata Analysis (with caching)
      MetadataAnalysis metadata = await _performMetadataAnalysis(imageFile, useCache);

      // Step 5: Create comprehensive analysis
      ComprehensiveAnalysis analysis = ComprehensiveAnalysis(
        originalDetection: fishDetection,
        confidence: confidence,
        visualFeatures: visualFeatures,
        consistency: consistency,
        metadata: metadata,
      );

      // Step 6: Media classification using fusion engine
      MediaType mediaType = _fusionEngine.classifyMedia(analysis);
      double mediaConfidence = _fusionEngine.calculateMediaConfidence(mediaType, analysis);

      // Step 7: Create enhanced result
      EnhancedDetectionResult enhancedResult = EnhancedDetectionResult(
        fishDetection: fishDetection,
        mediaType: mediaType,
        mediaConfidence: mediaConfidence,
        analysis: analysis,
        timestamp: DateTime.now(),
        additionalFeatures: _extractAdditionalFeatures(analysis),
      );

      // Record processing time
      _processingTimes['total_analysis'] = stopwatch.elapsed;

      return enhancedResult;

    } catch (e) {
      debugPrint('Error in comprehensive analysis: $e');
      stopwatch.stop();
      _processingTimes['error'] = stopwatch.elapsed;

      // Return fallback result
      return _createFallbackResult(fishDetection, e);
    } finally {
      stopwatch.stop();
    }
  }

  Future<ConfidenceAnalysis> _performConfidenceAnalysis(DetectionResult fishDetection) async {
    Stopwatch stopwatch = Stopwatch()..start();

    try {
      // Get recent history for advanced analysis
      List<DetectionResult> recentHistory = _consistencyService.frameHistory;

      ConfidenceAnalysis result = _confidenceService.analyzeConfidenceDetailed(
        fishDetection,
        previousResult: recentHistory.isNotEmpty ? recentHistory.last : null,
        history: recentHistory,
      );

      _processingTimes['confidence_analysis'] = stopwatch.elapsed;
      return result;
    } catch (e) {
      debugPrint('Error in confidence analysis: $e');
      _processingTimes['confidence_analysis_error'] = stopwatch.elapsed;
      return _createFallbackConfidenceAnalysis(fishDetection);
    } finally {
      stopwatch.stop();
    }
  }

  Future<VisualFeatures> _performVisualAnalysis(File imageFile, bool useCache) async {
    Stopwatch stopwatch = Stopwatch()..start();

    try {
      DateTime lastModified = await imageFile.lastModified();
      String cacheKey = '${imageFile.path}_${lastModified.millisecondsSinceEpoch}';

      // Check cache first
      if (useCache && _visualCache.containsKey(cacheKey)) {
        _processingTimes['visual_analysis_cached'] = stopwatch.elapsed;
        return _visualCache[cacheKey]!;
      }

      // Perform analysis
      VisualFeatures result = await _cvService.analyzeImage(imageFile);

      // Cache result
      if (useCache) {
        _visualCache[cacheKey] = result;

        // Limit cache size
        if (_visualCache.length > 50) {
          _visualCache.remove(_visualCache.keys.first);
        }
      }

      _processingTimes['visual_analysis'] = stopwatch.elapsed;
      return result;
    } catch (e) {
      debugPrint('Error in visual analysis: $e');
      _processingTimes['visual_analysis_error'] = stopwatch.elapsed;
      return _createFallbackVisualFeatures();
    } finally {
      stopwatch.stop();
    }
  }

  Future<ConsistencyAnalysis> _performConsistencyAnalysis(DetectionResult fishDetection) async {
    Stopwatch stopwatch = Stopwatch()..start();

    try {
      ConsistencyAnalysis result = _consistencyService.analyzeConsistency(fishDetection);

      _processingTimes['consistency_analysis'] = stopwatch.elapsed;
      return result;
    } catch (e) {
      debugPrint('Error in consistency analysis: $e');
      _processingTimes['consistency_analysis_error'] = stopwatch.elapsed;
      return _createFallbackConsistencyAnalysis();
    } finally {
      stopwatch.stop();
    }
  }

  Future<MetadataAnalysis> _performMetadataAnalysis(File imageFile, bool useCache) async {
    Stopwatch stopwatch = Stopwatch()..start();

    try {
      DateTime lastModified = await imageFile.lastModified();
      String cacheKey = '${imageFile.path}_${lastModified.millisecondsSinceEpoch}';

      // Check cache first
      if (useCache && _metadataCache.containsKey(cacheKey)) {
        _processingTimes['metadata_analysis_cached'] = stopwatch.elapsed;
        return _metadataCache[cacheKey]!;
      }

      // Perform analysis
      MetadataAnalysis result = await _metadataService.analyzeMetadataDetailed(imageFile);

      // Cache result
      if (useCache) {
        _metadataCache[cacheKey] = result;

        // Limit cache size
        if (_metadataCache.length > 50) {
          _metadataCache.remove(_metadataCache.keys.first);
        }
      }

      _processingTimes['metadata_analysis'] = stopwatch.elapsed;
      return result;
    } catch (e) {
      debugPrint('Error in metadata analysis: $e');
      _processingTimes['metadata_analysis_error'] = stopwatch.elapsed;
      return _createFallbackMetadataAnalysis();
    } finally {
      stopwatch.stop();
    }
  }

  Map<String, dynamic> _extractAdditionalFeatures(ComprehensiveAnalysis analysis) {
    return {
      'quality_metrics': _calculateQualityMetrics(analysis),
      'authenticity_indicators': _calculateAuthenticityIndicators(analysis),
      'technical_details': _extractTechnicalDetails(analysis),
      'confidence_breakdown': _createConfidenceBreakdown(analysis),
    };
  }

  Map<String, dynamic> _calculateQualityMetrics(ComprehensiveAnalysis analysis) {
    double overallQuality = 0.0;
    List<String> qualityFactors = [];

    // Confidence quality
    double confidenceQuality = analysis.confidence.signature.confidenceScore;
    overallQuality += confidenceQuality * 0.3;
    if (confidenceQuality > 0.8) {
      qualityFactors.add('high_confidence');
    }

    // Visual quality
    double visualQuality = _calculateVisualQuality(analysis.visualFeatures);
    overallQuality += visualQuality * 0.4;
    if (visualQuality > 0.7) {
      qualityFactors.add('good_visual_quality');
    }

    // Consistency quality
    double consistencyQuality = analysis.consistency.report.positionStability;
    overallQuality += consistencyQuality * 0.3;
    if (consistencyQuality > 0.8) {
      qualityFactors.add('high_consistency');
    }

    return {
      'overall_quality': overallQuality.clamp(0.0, 1.0),
      'quality_factors': qualityFactors,
      'quality_level': _categorizeQualityLevel(overallQuality),
    };
  }

  double _calculateVisualQuality(VisualFeatures features) {
    double edgeScore = features.edgeFeatures.edgeSharpness;
    double colorScore = features.colorFeatures.colorfulness;
    double textureScore = 1.0 - features.textureFeatures.noiseProfile;

    return (edgeScore * 0.4 + colorScore * 0.3 + textureScore * 0.3).clamp(0.0, 1.0);
  }

  String _categorizeQualityLevel(double qualityScore) {
    if (qualityScore >= 0.8) return 'excellent';
    if (qualityScore >= 0.6) return 'good';
    if (qualityScore >= 0.4) return 'fair';
    return 'poor';
  }

  Map<String, dynamic> _calculateAuthenticityIndicators(ComprehensiveAnalysis analysis) {
    double authenticityScore = 0.5; // Default to neutral
    List<String> indicators = [];

    // Photographic indicators
    if (analysis.metadata.metadata.isPhotograph) {
      authenticityScore += 0.3;
      indicators.add('photographic_origin');
    }

    // Digital creation indicators
    if (analysis.metadata.metadata.isDigitalCreation) {
      authenticityScore -= 0.2;
      indicators.add('digital_modification');
    }

    // Consistency indicators
    if (analysis.consistency.report.positionStability > 0.9) {
      authenticityScore += 0.1;
      indicators.add('high_consistency');
    }

    // Visual indicators
    if (analysis.visualFeatures.textureFeatures.compressionArtifacts < 0.2) {
      authenticityScore += 0.1;
      indicators.add('minimal_compression');
    }

    return {
      'authenticity_score': authenticityScore.clamp(0.0, 1.0),
      'indicators': indicators,
      'authenticity_level': _categorizeAuthenticityLevel(authenticityScore),
    };
  }

  String _categorizeAuthenticityLevel(double score) {
    if (score >= 0.8) return 'very_authentic';
    if (score >= 0.6) return 'likely_authentic';
    if (score >= 0.4) return 'possibly_altered';
    return 'likely_synthetic';
  }

  Map<String, dynamic> _extractTechnicalDetails(ComprehensiveAnalysis analysis) {
    return {
      'edge_analysis': {
        'density': analysis.visualFeatures.edgeFeatures.edgeDensity,
        'sharpness': analysis.visualFeatures.edgeFeatures.edgeSharpness,
        'consistency': analysis.visualFeatures.edgeFeatures.edgeConsistency,
      },
      'color_analysis': {
        'variance': analysis.visualFeatures.colorFeatures.colorVariance,
        'saturation': analysis.visualFeatures.colorFeatures.saturationProfile,
        'lighting': analysis.visualFeatures.colorFeatures.lightingPattern,
      },
      'texture_analysis': {
        'complexity': analysis.visualFeatures.textureFeatures.textureComplexity,
        'noise_level': analysis.visualFeatures.textureFeatures.noiseProfile,
        'compression_artifacts': analysis.visualFeatures.textureFeatures.compressionArtifacts,
      },
      'metadata_analysis': {
        'source_indicators': analysis.metadata.metadata.sourceIndicators,
        'compression_type': analysis.metadata.metadata.compressionType,
        'metadata_confidence': analysis.metadata.metadataConfidence,
      },
    };
  }

  Map<String, dynamic> _createConfidenceBreakdown(ComprehensiveAnalysis analysis) {
    return {
      'confidence_level': analysis.confidence.signature.confidenceLevel.toString(),
      'confidence_score': analysis.confidence.signature.confidenceScore,
      'position_stability': analysis.consistency.report.positionStability,
      'detection_frequency': analysis.consistency.report.detectionFrequency,
      'metadata_confidence': analysis.metadata.metadataConfidence,
      'overall_media_confidence': _fusionEngine.calculateMediaConfidence(
        _fusionEngine.classifyMedia(analysis),
        analysis
      ),
    };
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
      confidenceDescription: 'Analysis failed - using default values',
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
      stabilityDescription: 'Analysis failed - using default values',
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

  // Batch analysis for multiple images
  Future<List<EnhancedDetectionResult>> analyzeImages(
    List<File> imageFiles,
    List<DetectionResult> fishDetections, {
    bool useCache = true,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (imageFiles.length != fishDetections.length) {
      throw ArgumentError('Image files and detections must have the same length');
    }

    List<EnhancedDetectionResult> results = [];

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        EnhancedDetectionResult result = await analyzeImage(
          imageFiles[i],
          fishDetections[i],
          useCache: useCache,
          timeout: timeout,
        );
        results.add(result);
      } catch (e) {
        debugPrint('Error analyzing image ${i + 1}: $e');
        // Add fallback result
        results.add(_createFallbackResult(fishDetections[i], e));
      }
    }

    return results;
  }

  // Real-time analysis optimization
  Future<EnhancedDetectionResult> analyzeRealTime(
    File imageFile,
    DetectionResult fishDetection, {
    Duration maxProcessingTime = const Duration(milliseconds: 500),
  }) async {
    // Use faster, simplified analysis for real-time
    Stopwatch stopwatch = Stopwatch()..start();

    try {
      // Quick confidence analysis only
      ConfidenceAnalysis confidence = _confidenceService.analyzeConfidenceDetailed(fishDetection);

      // Simplified visual analysis (reduced resolution)
      VisualFeatures visualFeatures = await _performQuickVisualAnalysis(imageFile);

      // Basic consistency analysis
      ConsistencyAnalysis consistency = _consistencyService.analyzeConsistency(fishDetection);

      // Skip metadata analysis for real-time (too slow)

      // Quick fusion
      ComprehensiveAnalysis analysis = ComprehensiveAnalysis(
        originalDetection: fishDetection,
        confidence: confidence,
        visualFeatures: visualFeatures,
        consistency: consistency,
        metadata: _createFallbackMetadataAnalysis(),
      );

      MediaType mediaType = _fusionEngine.classifyMedia(analysis);
      double mediaConfidence = _fusionEngine.calculateMediaConfidence(mediaType, analysis);

      _processingTimes['realtime_analysis'] = stopwatch.elapsed;

      return EnhancedDetectionResult(
        fishDetection: fishDetection,
        mediaType: mediaType,
        mediaConfidence: mediaConfidence,
        analysis: analysis,
        timestamp: DateTime.now(),
        additionalFeatures: {
          'realtime_mode': true,
          'processing_time_ms': stopwatch.elapsedMilliseconds,
        },
      );

    } catch (e) {
      debugPrint('Error in real-time analysis: $e');
      return _createFallbackResult(fishDetection, e);
    } finally {
      stopwatch.stop();
    }
  }

  Future<VisualFeatures> _performQuickVisualAnalysis(File imageFile) async {
    try {
      // Load image at lower resolution for faster processing
      Uint8List imageBytes = await imageFile.readAsBytes();

      // Perform quick analysis directly on bytes (service will handle resizing internally)
      return await _cvService.analyzeImageFromBytes(imageBytes);
    } catch (e) {
      debugPrint('Error in quick visual analysis: $e');
      return _createFallbackVisualFeatures();
    }
  }

  // Performance monitoring
  Map<String, Duration> getProcessingTimes() {
    return Map.from(_processingTimes);
  }

  void clearCache() {
    _visualCache.clear();
    _metadataCache.clear();
    _processingTimes.clear();
  }

  Map<String, dynamic> getPerformanceStats() {
    return {
      'cache_sizes': {
        'visual_cache': _visualCache.length,
        'metadata_cache': _metadataCache.length,
      },
      'processing_times': _processingTimes,
      'memory_usage': _visualCache.length + _metadataCache.length,
    };
  }

  // Advanced analysis methods
  Future<AdvancedAnalysisReport> performAdvancedAnalysis(
    File imageFile,
    DetectionResult fishDetection,
  ) async {
    Stopwatch stopwatch = Stopwatch()..start();

    try {
      // Comprehensive analysis
      EnhancedDetectionResult basicResult = await analyzeImage(imageFile, fishDetection);

      // Additional advanced analyses
      AdvancedConsistencyAnalysis consistencyAnalysis =
          _consistencyService.performAdvancedAnalysis(fishDetection);

      AdvancedMetadataAnalysis metadataAnalysis =
          await _metadataService.performAdvancedAnalysis(imageFile);

      // Quality assessment
      QualityAssessment qualityAssessment = _assessOverallQuality(basicResult);

      // Generate recommendations
      List<String> recommendations = _generateRecommendations(basicResult, consistencyAnalysis, metadataAnalysis);

      AdvancedAnalysisReport report = AdvancedAnalysisReport(
        basicResult: basicResult,
        consistencyAnalysis: consistencyAnalysis,
        metadataAnalysis: metadataAnalysis,
        qualityAssessment: qualityAssessment,
        recommendations: recommendations,
        processingTime: stopwatch.elapsed,
        analysisTimestamp: DateTime.now(),
      );

      _processingTimes['advanced_analysis'] = stopwatch.elapsed;
      return report;

    } catch (e) {
      debugPrint('Error in advanced analysis: $e');
      rethrow;
    } finally {
      stopwatch.stop();
    }
  }

  QualityAssessment _assessOverallQuality(EnhancedDetectionResult result) {
    double overallQuality = 0.0;
    List<String> qualityFactors = [];

    // Fish detection quality
    if (result.fishDetection.confidence > 0.8) {
      overallQuality += 0.3;
      qualityFactors.add('high_detection_confidence');
    }

    // Media classification confidence
    if (result.mediaConfidence > 0.7) {
      overallQuality += 0.2;
      qualityFactors.add('reliable_media_classification');
    }

    // Visual quality
    double visualQuality = _calculateVisualQuality(result.analysis.visualFeatures);
    overallQuality += visualQuality * 0.3;
    if (visualQuality > 0.7) {
      qualityFactors.add('good_visual_quality');
    }

    // Consistency quality
    if (result.analysis.consistency.report.positionStability > 0.8) {
      overallQuality += 0.2;
      qualityFactors.add('high_consistency');
    }

    return QualityAssessment(
      overallQuality: overallQuality.clamp(0.0, 1.0),
      qualityFactors: qualityFactors,
      qualityLevel: _categorizeQualityLevel(overallQuality),
      improvements: _suggestImprovements(result),
    );
  }

  List<String> _suggestImprovements(EnhancedDetectionResult result) {
    List<String> improvements = [];

    if (result.fishDetection.confidence < 0.7) {
      improvements.add('Improve lighting conditions');
    }

    if (result.analysis.visualFeatures.edgeFeatures.edgeSharpness < 0.5) {
      improvements.add('Ensure image is in focus');
    }

    if (result.analysis.consistency.report.positionStability < 0.6) {
      improvements.add('Hold device steady during capture');
    }

    if (result.analysis.visualFeatures.textureFeatures.noiseProfile > 0.7) {
      improvements.add('Use better lighting to reduce noise');
    }

    return improvements;
  }

  List<String> _generateRecommendations(
    EnhancedDetectionResult basicResult,
    AdvancedConsistencyAnalysis consistencyAnalysis,
    AdvancedMetadataAnalysis metadataAnalysis,
  ) {
    List<String> recommendations = [];

    // Based on media type
    switch (basicResult.mediaType) {
      case MediaType.photograph:
        recommendations.add('This appears to be a photograph - results are highly reliable');
        break;
      case MediaType.painting:
        recommendations.add('This appears to be artwork - results may vary based on artistic style');
        break;
      case MediaType.digitalArt:
        recommendations.add('This appears to be digital art - results depend on rendering quality');
        break;
      case MediaType.threeDimensional:
        recommendations.add('This appears to be a 3D object - results may vary with viewing angle');
        break;
      case MediaType.cartoon:
        recommendations.add('This appears to be cartoon/illustration - results may be less accurate');
        break;
      case MediaType.unknown:
        recommendations.add('Media type could not be determined - results may be less reliable');
        break;
    }

    // Based on consistency
    if (consistencyAnalysis.basicReport.positionStability < 0.7) {
      recommendations.add('Movement detected - try keeping camera steady');
    }

    // Based on metadata
    if (metadataAnalysis.sourceCredibility.level == CredibilityLevel.low) {
      recommendations.add('Low source credibility - verify image authenticity');
    }

    // Based on quality
    if (basicResult.mediaConfidence < 0.5) {
      recommendations.add('Low confidence - try capturing a clearer image');
    }

    return recommendations;
  }
}

// Supporting classes for advanced analysis
class AdvancedAnalysisReport {
  final EnhancedDetectionResult basicResult;
  final AdvancedConsistencyAnalysis consistencyAnalysis;
  final AdvancedMetadataAnalysis metadataAnalysis;
  final QualityAssessment qualityAssessment;
  final List<String> recommendations;
  final Duration processingTime;
  final DateTime analysisTimestamp;

  AdvancedAnalysisReport({
    required this.basicResult,
    required this.consistencyAnalysis,
    required this.metadataAnalysis,
    required this.qualityAssessment,
    required this.recommendations,
    required this.processingTime,
    required this.analysisTimestamp,
  });
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
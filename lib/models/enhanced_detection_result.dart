import 'dart:ui';
import 'detection_result.dart';

enum MediaType {
  photograph,
  painting,
  digitalArt,
  threeDimensional,
  cartoon,
  unknown,
}

enum ConfidenceLevel {
  veryHigh,
  high,
  medium,
  low,
  veryLow,
}

enum MediaPattern {
  photograph,
  artwork,
  handheld_object,
  static_object,
  moving_object,
  unknown,
}

// Confidence Analysis Models
class MediaSignature {
  final ConfidenceLevel confidenceLevel;
  final double boundingBoxQuality;
  final double detectionStability;
  final double confidenceScore;

  MediaSignature({
    required this.confidenceLevel,
    required this.boundingBoxQuality,
    required this.detectionStability,
    required this.confidenceScore,
  });
}

class ConfidenceAnalysis {
  final MediaSignature signature;
  final String confidenceDescription;
  final Map<String, double> confidenceFeatures;

  ConfidenceAnalysis({
    required this.signature,
    required this.confidenceDescription,
    required this.confidenceFeatures,
  });
}

// Visual Feature Models
class EdgeFeatures {
  final double edgeDensity;
  final double edgeDistribution;
  final double edgeConsistency;
  final double edgeSharpness;
  final Map<String, double> edgeMetrics;

  EdgeFeatures({
    required this.edgeDensity,
    required this.edgeDistribution,
    required this.edgeConsistency,
    required this.edgeSharpness,
    required this.edgeMetrics,
  });
}

class ColorFeatures {
  final double colorVariance;
  final String saturationProfile;
  final String lightingPattern;
  final double colorfulness;
  final Map<String, double> colorMetrics;

  ColorFeatures({
    required this.colorVariance,
    required this.saturationProfile,
    required this.lightingPattern,
    required this.colorfulness,
    required this.colorMetrics,
  });
}

class TextureFeatures {
  final double lbpPattern;
  final Map<String, double> glcmFeatures;
  final double noiseProfile;
  final double compressionArtifacts;
  final double textureComplexity;
  final Map<String, double> textureMetrics;

  TextureFeatures({
    required this.lbpPattern,
    required this.glcmFeatures,
    required this.noiseProfile,
    required this.compressionArtifacts,
    required this.textureComplexity,
    required this.textureMetrics,
  });
}

class VisualFeatures {
  final EdgeFeatures edgeFeatures;
  final ColorFeatures colorFeatures;
  final TextureFeatures textureFeatures;

  VisualFeatures({
    required this.edgeFeatures,
    required this.colorFeatures,
    required this.textureFeatures,
  });
}

// Consistency Analysis Models
class ConsistencyReport {
  final double confidenceVariance;
  final double boundingBoxVariance;
  final double positionStability;
  final double detectionFrequency;
  final bool hasEnoughData;
  final Map<String, double> consistencyMetrics;

  ConsistencyReport({
    required this.confidenceVariance,
    required this.boundingBoxVariance,
    required this.positionStability,
    required this.detectionFrequency,
    required this.hasEnoughData,
    required this.consistencyMetrics,
  });

  factory ConsistencyReport.insufficientData() {
    return ConsistencyReport(
      confidenceVariance: 0.0,
      boundingBoxVariance: 0.0,
      positionStability: 0.0,
      detectionFrequency: 0.0,
      hasEnoughData: false,
      consistencyMetrics: {},
    );
  }
}

class ConsistencyAnalysis {
  final ConsistencyReport report;
  final MediaPattern detectedPattern;
  final String stabilityDescription;

  ConsistencyAnalysis({
    required this.report,
    required this.detectedPattern,
    required this.stabilityDescription,
  });
}

// Metadata Analysis Models
class MediaMetadata {
  final bool isPhotograph;
  final bool isDigitalCreation;
  final String compressionType;
  final List<String> sourceIndicators;
  final Map<String, String> exifData;
  final Map<String, dynamic> fileCharacteristics;

  MediaMetadata({
    required this.isPhotograph,
    required this.isDigitalCreation,
    required this.compressionType,
    required this.sourceIndicators,
    required this.exifData,
    required this.fileCharacteristics,
  });
}

class MetadataAnalysis {
  final MediaMetadata metadata;
  final String sourceType;
  final double metadataConfidence;

  MetadataAnalysis({
    required this.metadata,
    required this.sourceType,
    required this.metadataConfidence,
  });
}

// Comprehensive Analysis Result
class ComprehensiveAnalysis {
  final DetectionResult originalDetection;
  final ConfidenceAnalysis confidence;
  final VisualFeatures visualFeatures;
  final ConsistencyAnalysis consistency;
  final MetadataAnalysis metadata;

  ComprehensiveAnalysis({
    required this.originalDetection,
    required this.confidence,
    required this.visualFeatures,
    required this.consistency,
    required this.metadata,
  });
}

// Enhanced Detection Result with Media Classification
class EnhancedDetectionResult {
  final DetectionResult fishDetection;
  final MediaType mediaType;
  final double mediaConfidence;
  final ComprehensiveAnalysis analysis;
  final DateTime timestamp;
  final Map<String, dynamic> additionalFeatures;

  EnhancedDetectionResult({
    required this.fishDetection,
    required this.mediaType,
    required this.mediaConfidence,
    required this.analysis,
    required this.timestamp,
    required this.additionalFeatures,
  });

  // Helper methods
  String get mediaTypeDescription {
    switch (mediaType) {
      case MediaType.photograph:
        return 'Foto Asli';
      case MediaType.painting:
        return 'Lukisan/Karya Seni';
      case MediaType.digitalArt:
        return 'Seni Digital';
      case MediaType.threeDimensional:
        return 'Objek 3D';
      case MediaType.cartoon:
        return 'Kartun/Illustrasi';
      case MediaType.unknown:
        return 'Tidak Diketahui';
    }
  }

  String get confidenceLevel {
    if (mediaConfidence >= 0.9) return 'Sangat Tinggi';
    if (mediaConfidence >= 0.7) return 'Tinggi';
    if (mediaConfidence >= 0.5) return 'Sedang';
    if (mediaConfidence >= 0.3) return 'Rendah';
    return 'Sangat Rendah';
  }

  bool get isHighConfidence => mediaConfidence >= 0.7;
  bool get isReliable => mediaConfidence >= 0.5;

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'fishDetection': fishDetection.toJson(),
      'mediaType': mediaType.toString(),
      'mediaConfidence': mediaConfidence,
      'analysis': {
        'confidence': analysis.confidence.signature.confidenceScore,
        'stability': analysis.consistency.report.positionStability,
        'hasPhotographyMetadata': analysis.metadata.metadata.isPhotograph,
      },
      'timestamp': timestamp.toIso8601String(),
      'additionalFeatures': additionalFeatures,
    };
  }

  factory EnhancedDetectionResult.fromJson(Map<String, dynamic> json) {
    return EnhancedDetectionResult(
      fishDetection: DetectionResult.fromJson(json['fishDetection']),
      mediaType: _parseMediaType(json['mediaType']),
      mediaConfidence: json['mediaConfidence'].toDouble(),
      analysis: _parseAnalysis(json['analysis']),
      timestamp: DateTime.parse(json['timestamp']),
      additionalFeatures: json['additionalFeatures'] ?? {},
    );
  }

  static MediaType _parseMediaType(String typeString) {
    switch (typeString) {
      case 'MediaType.photograph':
        return MediaType.photograph;
      case 'MediaType.painting':
        return MediaType.painting;
      case 'MediaType.digitalArt':
        return MediaType.digitalArt;
      case 'MediaType.threeDimensional':
        return MediaType.threeDimensional;
      case 'MediaType.cartoon':
        return MediaType.cartoon;
      default:
        return MediaType.unknown;
    }
  }

  static ComprehensiveAnalysis _parseAnalysis(Map<String, dynamic> analysisJson) {
    // Parse analysis data - simplified version
    return ComprehensiveAnalysis(
      originalDetection: DetectionResult(
        boundingBox: Rect.zero,
        className: 'unknown',
        confidence: 0.0,
        classIndex: 0,
      ),
      confidence: ConfidenceAnalysis(
        signature: MediaSignature(
          confidenceLevel: ConfidenceLevel.medium,
          boundingBoxQuality: analysisJson['confidence'] ?? 0.0,
          detectionStability: analysisJson['stability'] ?? 0.0,
          confidenceScore: analysisJson['confidence'] ?? 0.0,
        ),
        confidenceDescription: 'Parsed from JSON',
        confidenceFeatures: {},
      ),
      visualFeatures: VisualFeatures(
        edgeFeatures: EdgeFeatures(
          edgeDensity: 0.0,
          edgeDistribution: 0.0,
          edgeConsistency: 0.0,
          edgeSharpness: 0.0,
          edgeMetrics: {},
        ),
        colorFeatures: ColorFeatures(
          colorVariance: 0.0,
          saturationProfile: 'Unknown',
          lightingPattern: 'Unknown',
          colorfulness: 0.0,
          colorMetrics: {},
        ),
        textureFeatures: TextureFeatures(
          lbpPattern: 0.0,
          glcmFeatures: {},
          noiseProfile: 0.0,
          compressionArtifacts: 0.0,
          textureComplexity: 0.0,
          textureMetrics: {},
        ),
      ),
      consistency: ConsistencyAnalysis(
        report: ConsistencyReport(
          confidenceVariance: 0.0,
          boundingBoxVariance: 0.0,
          positionStability: analysisJson['stability'] ?? 0.0,
          detectionFrequency: 0.0,
          hasEnoughData: true,
          consistencyMetrics: {},
        ),
        detectedPattern: MediaPattern.unknown,
        stabilityDescription: 'Parsed from JSON',
      ),
      metadata: MetadataAnalysis(
        metadata: MediaMetadata(
          isPhotograph: analysisJson['hasPhotographyMetadata'] ?? false,
          isDigitalCreation: false,
          compressionType: 'Unknown',
          sourceIndicators: [],
          exifData: {},
          fileCharacteristics: {},
        ),
        sourceType: 'Unknown',
        metadataConfidence: 0.0,
      ),
    );
  }
}

// Quality Assessment Models
class QualityMetrics {
  final double overallQuality;
  final double sharpness;
  final double lightingQuality;
  final double noiseLevel;
  final double colorAccuracy;
  final String qualityDescription;

  QualityMetrics({
    required this.overallQuality,
    required this.sharpness,
    required this.lightingQuality,
    required this.noiseLevel,
    required this.colorAccuracy,
    required this.qualityDescription,
  });
}

class QualityAssessment {
  final QualityMetrics metrics;
  final List<String> qualityFactors;
  final List<String> improvementSuggestions;

  QualityAssessment({
    required this.metrics,
    required this.qualityFactors,
    required this.improvementSuggestions,
  });
}
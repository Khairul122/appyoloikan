import 'dart:math';
import 'package:flutter/material.dart';
import '../models/enhanced_detection_result.dart';
import '../models/detection_result.dart';


// Add detection_time field to EnhancedDetectionResult
extension EnhancedDetectionResultExtension on EnhancedDetectionResult {
  DateTime get detectionTime => timestamp; // Use timestamp as detection time
}

class ConfidenceAnalysisService {
  static const double veryHighThreshold = 0.85;
  static const double highThreshold = 0.70;
  static const double mediumThreshold = 0.50;
  static const double lowThreshold = 0.30;

  static const Map<String, double> defaultThresholds = {
    'very_high': 0.85,
    'high': 0.70,
    'medium': 0.50,
    'low': 0.30,
  };

  MediaSignature analyzeConfidence(DetectionResult result, {DetectionResult? previousResult}) {
    double confidence = result.confidence;
    Rect bbox = result.boundingBox;

    ConfidenceLevel confidenceLevel = _categorizeConfidence(confidence);
    double boundingBoxQuality = _analyzeBoundingBoxQuality(bbox, result);
    double detectionStability = _checkStability(result, previousResult);

    return MediaSignature(
      confidenceLevel: confidenceLevel,
      boundingBoxQuality: boundingBoxQuality,
      detectionStability: detectionStability,
      confidenceScore: confidence,
    );
  }

  ConfidenceAnalysis analyzeConfidenceDetailed(DetectionResult result, {
    DetectionResult? previousResult,
    List<DetectionResult>? history,
  }) {
    MediaSignature signature = analyzeConfidence(result, previousResult: previousResult);

    String confidenceDescription = _generateConfidenceDescription(signature);
    Map<String, double> confidenceFeatures = _extractConfidenceFeatures(result, history);

    return ConfidenceAnalysis(
      signature: signature,
      confidenceDescription: confidenceDescription,
      confidenceFeatures: confidenceFeatures,
    );
  }

  ConfidenceLevel _categorizeConfidence(double conf) {
    if (conf >= veryHighThreshold) {
      return ConfidenceLevel.veryHigh;    // Likely photograph
    } else if (conf >= highThreshold) {
      return ConfidenceLevel.high;         // Could be 3D or digital
    } else if (conf >= mediumThreshold) {
      return ConfidenceLevel.medium;       // Likely artwork
    } else if (conf >= lowThreshold) {
      return ConfidenceLevel.low;          // Likely cartoon/illustration
    } else {
      return ConfidenceLevel.veryLow;      // Very low quality or noise
    }
  }

  double _analyzeBoundingBoxQuality(Rect bbox, DetectionResult result) {
    // Aspect ratio analysis
    double aspectRatio = bbox.width / bbox.height;
    double idealAspectRatio = 1.0; // Square-ish is ideal for fish

    // Quality factors
    double aspectRatioScore = _calculateAspectRatioQuality(aspectRatio, idealAspectRatio);
    double sizeScore = _calculateSizeQuality(bbox);
    double positionScore = _calculatePositionQuality(bbox);
    double confidenceScore = result.confidence;

    // Weighted combination
    double quality = (aspectRatioScore * 0.3 +
                     sizeScore * 0.3 +
                     positionScore * 0.2 +
                     confidenceScore * 0.2);

    return quality.clamp(0.0, 1.0);
  }

  double _calculateAspectRatioQuality(double currentRatio, double idealRatio) {
    double ratio = min(currentRatio, idealRatio) / max(currentRatio, idealRatio);
    return ratio.clamp(0.0, 1.0);
  }

  double _calculateSizeQuality(Rect bbox) {
    // Assume full image is 640x640
    double imageSize = 640.0 * 640.0;
    double bboxSize = bbox.width * bbox.height;
    double sizeRatio = bboxSize / imageSize;

    // Optimal size is between 10% and 50% of image
    if (sizeRatio < 0.05) return 0.3; // Too small
    if (sizeRatio > 0.7) return 0.7;  // Too large

    return 1.0; // Good size
  }

  double _calculatePositionQuality(Rect bbox) {
    // Center is (320, 320) for 640x640 image
    double centerX = 320.0;
    double centerY = 320.0;
    double bboxCenterX = bbox.left + bbox.width / 2;
    double bboxCenterY = bbox.top + bbox.height / 2;

    // Distance from center
    double distance = sqrt(pow(bboxCenterX - centerX, 2) + pow(bboxCenterY - centerY, 2));
    double maxDistance = sqrt(pow(centerX, 2) + pow(centerY, 2));

    // Center objects have higher quality
    double positionScore = 1.0 - (distance / maxDistance);
    return positionScore.clamp(0.0, 1.0);
  }

  double _checkStability(DetectionResult result, DetectionResult? previousResult) {
    if (previousResult == null) return 0.5; // No previous data

    double confidenceStability = _calculateConfidenceStability(result.confidence, previousResult.confidence);
    double positionStability = _calculatePositionStability(result.boundingBox, previousResult.boundingBox);
    double sizeStability = _calculateSizeStability(result.boundingBox, previousResult.boundingBox);

    return (confidenceStability * 0.4 + positionStability * 0.4 + sizeStability * 0.2).clamp(0.0, 1.0);
  }

  double _calculateConfidenceStability(double current, double previous) {
    double difference = (current - previous).abs();
    return (1.0 - difference).clamp(0.0, 1.0);
  }

  double _calculatePositionStability(Rect current, Rect previous) {
    double currentCenterX = current.left + current.width / 2;
    double currentCenterY = current.top + current.height / 2;
    double previousCenterX = previous.left + previous.width / 2;
    double previousCenterY = previous.top + previous.height / 2;

    double distance = sqrt(pow(currentCenterX - previousCenterX, 2) + pow(currentCenterY - previousCenterY, 2));
    double maxDistance = sqrt(pow(640, 2) + pow(640, 2)); // Maximum possible distance

    return (1.0 - (distance / maxDistance)).clamp(0.0, 1.0);
  }

  double _calculateSizeStability(Rect current, Rect previous) {
    double currentSize = current.width * current.height;
    double previousSize = previous.width * previous.height;

    double sizeRatio = min(currentSize, previousSize) / max(currentSize, previousSize);
    return sizeRatio.clamp(0.0, 1.0);
  }

  String _generateConfidenceDescription(MediaSignature signature) {
    switch (signature.confidenceLevel) {
      case ConfidenceLevel.veryHigh:
        return 'Sangat tinggi - Kemungkinan besar foto asli dengan kualitas excellent';
      case ConfidenceLevel.high:
        return 'Tinggi - Kemungkinan foto asli atau objek 3D berkualitas baik';
      case ConfidenceLevel.medium:
        return 'Sedang - Kemungkinan karya seni atau lukisan';
      case ConfidenceLevel.low:
        return 'Rendah - Kemungkinan kartun atau ilustrasi';
      case ConfidenceLevel.veryLow:
        return 'Sangat rendah - Kualitas rendah atau noise tinggi';
    }
  }

  Map<String, double> _extractConfidenceFeatures(DetectionResult result, List<DetectionResult>? history) {
    Map<String, double> features = {
      'raw_confidence': result.confidence,
      'bounding_box_quality': 0.0,
      'stability_score': 0.0,
      'consistency_score': 0.0,
      'detection_frequency': 0.0,
    };

    // Calculate bounding box quality
    features['bounding_box_quality'] = _analyzeBoundingBoxQuality(result.boundingBox, result);

    if (history != null && history.isNotEmpty) {
      // Calculate stability and consistency
      features['stability_score'] = _calculateStabilityScore(result, history);
      features['consistency_score'] = _calculateConsistencyScore(history);
      features['detection_frequency'] = _calculateDetectionFrequency(history);
    }

    return features;
  }

  double _calculateStabilityScore(DetectionResult current, List<DetectionResult> history) {
    if (history.isEmpty) return 0.5;

    double totalStability = 0.0;
    int count = 0;

    for (int i = history.length - 1; i >= max(0, history.length - 5); i--) {
      DetectionResult previous = history[i];
      totalStability += _checkStability(current, previous);
      count++;
    }

    return count > 0 ? totalStability / count : 0.5;
  }

  double _calculateConsistencyScore(List<DetectionResult> history) {
    if (history.length < 2) return 0.5;

    double totalVariance = 0.0;
    int count = 0;

    for (int i = 1; i < history.length; i++) {
      double variance = (history[i].confidence - history[i-1].confidence).abs();
      totalVariance += variance;
      count++;
    }

    double averageVariance = count > 0 ? totalVariance / count : 0.0;
    return (1.0 - averageVariance).clamp(0.0, 1.0);
  }

  double _calculateDetectionFrequency(List<DetectionResult> history) {
    if (history.isEmpty) return 0.0;

    int successfulDetections = history.where((detection) => detection.confidence > 0.3).length;
    return successfulDetections / history.length;
  }

  // Advanced confidence analysis with multiple detections
  AdvancedConfidenceResult analyzeAdvancedConfidence(
    DetectionResult currentResult,
    List<DetectionResult> recentHistory, {
    Duration timeWindow = const Duration(seconds: 5),
  }) {
    // Filter history within time window
    List<DetectionResult> relevantHistory = _filterRelevantHistory(recentHistory, timeWindow);

    // Basic confidence analysis
    MediaSignature signature = analyzeConfidence(currentResult, previousResult: relevantHistory.isNotEmpty ? relevantHistory.last : null);

    // Statistical analysis
    ConfidenceStatistics statistics = _calculateConfidenceStatistics(relevantHistory);

    // Trend analysis
    ConfidenceTrend trend = _analyzeConfidenceTrend(relevantHistory);

    // Quality assessment
    QualityAssessment quality = _assessDetectionQuality(currentResult, relevantHistory);

    return AdvancedConfidenceResult(
      currentSignature: signature,
      statistics: statistics,
      trend: trend,
      quality: quality,
      analysisTimestamp: DateTime.now(),
      reliabilityScore: _calculateReliabilityScore(currentResult, relevantHistory),
    );
  }

  List<DetectionResult> _filterRelevantHistory(List<DetectionResult> history, Duration timeWindow) {
    DateTime cutoff = DateTime.now().subtract(timeWindow);
    return history.where((detection) => detection.detectionTime?.isAfter(cutoff) ?? false).toList();
  }

  ConfidenceStatistics _calculateConfidenceStatistics(List<DetectionResult> history) {
    if (history.isEmpty) {
      return ConfidenceStatistics(
        mean: 0.0,
        median: 0.0,
        standardDeviation: 0.0,
        min: 0.0,
        max: 0.0,
        count: 0,
      );
    }

    List<double> confidences = history.map((d) => d.confidence).toList();
    confidences.sort();

    double mean = confidences.reduce((a, b) => a + b) / confidences.length;
    double median = confidences.length % 2 == 0
        ? (confidences[confidences.length ~/ 2 - 1] + confidences[confidences.length ~/ 2]) / 2
        : confidences[confidences.length ~/ 2];

    double variance = confidences.map((c) => pow(c - mean, 2)).reduce((a, b) => a + b) / confidences.length;
    double standardDeviation = sqrt(variance);

    return ConfidenceStatistics(
      mean: mean,
      median: median,
      standardDeviation: standardDeviation,
      min: confidences.first,
      max: confidences.last,
      count: confidences.length,
    );
  }

  ConfidenceTrend _analyzeConfidenceTrend(List<DetectionResult> history) {
    if (history.length < 3) {
      return ConfidenceTrend.stable;
    }

    // Simple linear regression to detect trend
    int n = history.length;
    double sumX = 0.0, sumY = 0.0, sumXY = 0.0, sumX2 = 0.0;

    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += history[i].confidence;
      sumXY += i * history[i].confidence;
      sumX2 += i * i;
    }

    double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);

    if (slope > 0.1) {
      return ConfidenceTrend.improving;
    } else if (slope < -0.1) {
      return ConfidenceTrend.degrading;
    } else {
      return ConfidenceTrend.stable;
    }
  }

  QualityAssessment _assessDetectionQuality(DetectionResult current, List<DetectionResult> history) {
    double qualityScore = _analyzeBoundingBoxQuality(current.boundingBox, current);
    double consistencyScore = history.isNotEmpty ? _calculateConsistencyScore(history) : 0.5;
    double stabilityScore = history.isNotEmpty ? _calculateStabilityScore(current, history) : 0.5;

    String qualityLevel;
    if (qualityScore > 0.8 && consistencyScore > 0.8) {
      qualityLevel = 'excellent';
    } else if (qualityScore > 0.6 && consistencyScore > 0.6) {
      qualityLevel = 'good';
    } else if (qualityScore > 0.4 && consistencyScore > 0.4) {
      qualityLevel = 'fair';
    } else {
      qualityLevel = 'poor';
    }

    return QualityAssessment(
      overallQuality: (qualityScore + consistencyScore + stabilityScore) / 3,
      boundingBoxQuality: qualityScore,
      consistencyScore: consistencyScore,
      stabilityScore: stabilityScore,
      qualityLevel: qualityLevel,
    );
  }

  double _calculateReliabilityScore(DetectionResult current, List<DetectionResult> history) {
    if (history.isEmpty) return current.confidence * 0.7;

    double confidenceWeight = 0.4;
    double stabilityWeight = 0.3;
    double consistencyWeight = 0.3;

    double stabilityScore = _calculateStabilityScore(current, history);
    double consistencyScore = _calculateConsistencyScore(history);

    return (current.confidence * confidenceWeight +
            stabilityScore * stabilityWeight +
            consistencyScore * consistencyWeight).clamp(0.0, 1.0);
  }
}

// Additional supporting classes
class AdvancedConfidenceResult {
  final MediaSignature currentSignature;
  final ConfidenceStatistics statistics;
  final ConfidenceTrend trend;
  final QualityAssessment quality;
  final DateTime analysisTimestamp;
  final double reliabilityScore;

  AdvancedConfidenceResult({
    required this.currentSignature,
    required this.statistics,
    required this.trend,
    required this.quality,
    required this.analysisTimestamp,
    required this.reliabilityScore,
  });
}

class ConfidenceStatistics {
  final double mean;
  final double median;
  final double standardDeviation;
  final double min;
  final double max;
  final int count;

  ConfidenceStatistics({
    required this.mean,
    required this.median,
    required this.standardDeviation,
    required this.min,
    required this.max,
    required this.count,
  });
}

enum ConfidenceTrend {
  improving,
  stable,
  degrading,
}

class QualityAssessment {
  final double overallQuality;
  final double boundingBoxQuality;
  final double consistencyScore;
  final double stabilityScore;
  final String qualityLevel;

  QualityAssessment({
    required this.overallQuality,
    required this.boundingBoxQuality,
    required this.consistencyScore,
    required this.stabilityScore,
    required this.qualityLevel,
  });
}
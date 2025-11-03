import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/enhanced_detection_result.dart';
import '../models/detection_result.dart';

class ConsistencyAnalysisService {
  static const int maxHistoryLength = 10;
  static const int minHistoryLength = 3;

  List<DetectionResult> frameHistory = [];
  Map<String, List<DetectionResult>> classHistory = {}; // Track history per class

  ConsistencyAnalysis analyzeConsistency(DetectionResult newResult) {
    // Add to general history
    frameHistory.add(newResult);
    if (frameHistory.length > maxHistoryLength) {
      frameHistory.removeAt(0);
    }

    // Add to class-specific history
    String className = newResult.className;
    if (!classHistory.containsKey(className)) {
      classHistory[className] = [];
    }
    classHistory[className]!.add(newResult);
    if (classHistory[className]!.length > maxHistoryLength) {
      classHistory[className]!.removeAt(0);
    }

    // Check if we have enough data
    if (frameHistory.length < minHistoryLength) {
      return ConsistencyAnalysis(
        report: ConsistencyReport.insufficientData(),
        detectedPattern: MediaPattern.unknown,
        stabilityDescription: 'Collecting data for analysis...',
      );
    }

    // Calculate consistency metrics
    ConsistencyReport report = _calculateConsistencyReport(newResult);

    // Classify media pattern
    MediaPattern pattern = _classifyMediaPattern(report);

    // Generate description
    String description = _generateStabilityDescription(report, pattern);

    return ConsistencyAnalysis(
      report: report,
      detectedPattern: pattern,
      stabilityDescription: description,
    );
  }

  ConsistencyReport _calculateConsistencyReport(DetectionResult currentResult) {
    List<DetectionResult> recentHistory = _getRecentHistory(currentResult.className);

    if (recentHistory.length < minHistoryLength) {
      return ConsistencyReport.insufficientData();
    }

    // Calculate confidence variance
    double confidenceVariance = _calculateConfidenceVariance(recentHistory);

    // Calculate bounding box variance
    double boundingBoxVariance = _calculateBoundingBoxVariance(recentHistory);

    // Calculate position stability
    double positionStability = _calculatePositionStability(recentHistory);

    // Calculate detection frequency
    double detectionFrequency = _calculateDetectionFrequency(recentHistory);

    // Calculate additional metrics
    Map<String, double> consistencyMetrics = _calculateAdditionalMetrics(recentHistory);

    return ConsistencyReport(
      confidenceVariance: confidenceVariance,
      boundingBoxVariance: boundingBoxVariance,
      positionStability: positionStability,
      detectionFrequency: detectionFrequency,
      hasEnoughData: true,
      consistencyMetrics: consistencyMetrics,
    );
  }

  List<DetectionResult> _getRecentHistory(String className) {
    return classHistory[className] ?? [];
  }

  double _calculateConfidenceVariance(List<DetectionResult> history) {
    if (history.length < 2) return 0.0;

    double mean = history.map((r) => r.confidence).reduce((a, b) => a + b) / history.length;
    double variance = history.map((r) => pow(r.confidence - mean, 2)).reduce((a, b) => a + b) / history.length;

    return variance;
  }

  double _calculateBoundingBoxVariance(List<DetectionResult> history) {
    if (history.length < 2) return 0.0;

    double varianceSum = 0.0;
    int count = 0;

    for (int i = 1; i < history.length; i++) {
      Rect current = history[i].boundingBox;
      Rect previous = history[i - 1].boundingBox;

      // Calculate size variance
      double currentSize = current.width * current.height;
      double previousSize = previous.width * previous.height;
      double sizeDiff = (currentSize - previousSize).abs();
      double avgSize = (currentSize + previousSize) / 2;
      double sizeVariance = avgSize > 0 ? sizeDiff / avgSize : 0.0;

      // Calculate position variance
      double currentCenterX = current.left + current.width / 2;
      double currentCenterY = current.top + current.height / 2;
      double previousCenterX = previous.left + previous.width / 2;
      double previousCenterY = previous.top + previous.height / 2;
      double distance = sqrt(pow(currentCenterX - previousCenterX, 2) + pow(currentCenterY - previousCenterY, 2));
      double maxDistance = sqrt(pow(640, 2) + pow(640, 2)); // Max possible distance
      double positionVariance = distance / maxDistance;

      varianceSum += (sizeVariance + positionVariance) / 2;
      count++;
    }

    return count > 0 ? varianceSum / count : 0.0;
  }

  double _calculatePositionStability(List<DetectionResult> history) {
    if (history.length < 2) return 0.0;

    List<double> centerXs = [];
    List<double> centerYs = [];

    for (DetectionResult result in history) {
      Rect bbox = result.boundingBox;
      centerXs.add(bbox.left + bbox.width / 2);
      centerYs.add(bbox.top + bbox.height / 2);
    }

    // Calculate standard deviation for X and Y positions
    double meanX = centerXs.reduce((a, b) => a + b) / centerXs.length;
    double meanY = centerYs.reduce((a, b) => a + b) / centerYs.length;

    double varianceX = centerXs.map((x) => pow(x - meanX, 2)).reduce((a, b) => a + b) / centerXs.length;
    double varianceY = centerYs.map((y) => pow(y - meanY, 2)).reduce((a, b) => a + b) / centerYs.length;

    double stdDevX = sqrt(varianceX);
    double stdDevY = sqrt(varianceY);

    // Calculate stability (inverse of standard deviation)
    double maxStdDev = sqrt(pow(640/2, 2) + pow(640/2, 2));
    double combinedStdDev = sqrt(stdDevX * stdDevX + stdDevY * stdDevY);
    double stability = 1.0 - (combinedStdDev / maxStdDev);

    return stability.clamp(0.0, 1.0);
  }

  double _calculateDetectionFrequency(List<DetectionResult> history) {
    if (history.isEmpty) return 0.0;

    int successfulDetections = history.where((detection) => detection.confidence > 0.3).length;
    return successfulDetections / history.length;
  }

  Map<String, double> _calculateAdditionalMetrics(List<DetectionResult> history) {
    Map<String, double> metrics = {};

    // Confidence trend
    metrics['confidence_trend'] = _calculateConfidenceTrend(history);

    // Size consistency
    metrics['size_consistency'] = _calculateSizeConsistency(history);

    // Aspect ratio stability
    metrics['aspect_ratio_stability'] = _calculateAspectRatioStability(history);

    // Movement pattern
    metrics['movement_pattern'] = _calculateMovementPattern(history);

    return metrics;
  }

  double _calculateConfidenceTrend(List<DetectionResult> history) {
    if (history.length < 3) return 0.0;

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
    return slope.clamp(-1.0, 1.0);
  }

  double _calculateSizeConsistency(List<DetectionResult> history) {
    if (history.length < 2) return 0.0;

    List<double> sizes = history.map((r) => r.boundingBox.width * r.boundingBox.height).toList();
    double mean = sizes.reduce((a, b) => a + b) / sizes.length;
    double variance = sizes.map((s) => pow(s - mean, 2)).reduce((a, b) => a + b) / sizes.length;
    double stdDev = sqrt(variance);

    return mean > 0 ? 1.0 - (stdDev / mean) : 0.0;
  }

  double _calculateAspectRatioStability(List<DetectionResult> history) {
    if (history.length < 2) return 0.0;

    List<double> aspectRatios = history.map((r) => r.boundingBox.width / r.boundingBox.height).toList();
    double mean = aspectRatios.reduce((a, b) => a + b) / aspectRatios.length;
    double variance = aspectRatios.map((ar) => pow(ar - mean, 2)).reduce((a, b) => a + b) / aspectRatios.length;
    double stdDev = sqrt(variance);

    return mean > 0 ? 1.0 - (stdDev / mean) : 0.0;
  }

  double _calculateMovementPattern(List<DetectionResult> history) {
    if (history.length < 3) return 0.0;

    List<double> distances = [];
    for (int i = 1; i < history.length; i++) {
      Rect current = history[i].boundingBox;
      Rect previous = history[i - 1].boundingBox;

      double currentCenterX = current.left + current.width / 2;
      double currentCenterY = current.top + current.height / 2;
      double previousCenterX = previous.left + previous.width / 2;
      double previousCenterY = previous.top + previous.height / 2;

      double distance = sqrt(pow(currentCenterX - previousCenterX, 2) + pow(currentCenterY - previousCenterY, 2));
      distances.add(distance);
    }

    if (distances.isEmpty) return 0.0;

    double meanDistance = distances.reduce((a, b) => a + b) / distances.length;
    double variance = distances.map((d) => pow(d - meanDistance, 2)).reduce((a, b) => a + b) / distances.length;

    // Lower variance indicates more consistent movement pattern
    return 1.0 - (variance / (meanDistance * meanDistance + 1e-6));
  }

  MediaPattern _classifyMediaPattern(ConsistencyReport report) {
    // Classify media pattern based on consistency metrics
    if (report.confidenceVariance < 0.1 && report.positionStability > 0.9 && report.detectionFrequency > 0.95) {
      return MediaPattern.photograph;        // Very stable
    } else if (report.confidenceVariance < 0.2 && report.positionStability > 0.85 && report.detectionFrequency > 0.85) {
      return MediaPattern.artwork;           // Moderately stable
    } else if (report.confidenceVariance > 0.3 || report.positionStability < 0.7) {
      return MediaPattern.handheld_object;   // Unstable
    } else {
      return MediaPattern.unknown;
    }
  }

  String _generateStabilityDescription(ConsistencyReport report, MediaPattern pattern) {
    switch (pattern) {
      case MediaPattern.photograph:
        return 'Sangat stabil - Konsisten tinggi, kemungkinan foto statis';
      case MediaPattern.artwork:
        return 'Stabil - Deteksi konsisten, kemungkinan karya seni';
      case MediaPattern.handheld_object:
        return 'Tidak stabil - Variasi tinggi, kemungkinan objek yang digerakkan';
      case MediaPattern.static_object:
        return 'Sangat stabil - Objek statis dengan deteksi konsisten';
      case MediaPattern.moving_object:
        return 'Bergerak - Objek dalam gerakan dengan variasi wajar';
      case MediaPattern.unknown:
        return 'Perlu lebih banyak data untuk analisis';
    }
  }

  // Advanced consistency analysis
  AdvancedConsistencyAnalysis performAdvancedAnalysis(DetectionResult currentResult) {
    List<DetectionResult> recentHistory = _getRecentHistory(currentResult.className);

    if (recentHistory.length < minHistoryLength) {
      return AdvancedConsistencyAnalysis(
        basicReport: ConsistencyReport.insufficientData(),
        temporalPattern: TemporalPattern.unknown,
        movementCharacteristics: MovementCharacteristics(),
        qualityMetrics: ConsistencyQualityMetrics(),
        confidence: 0.0,
        analysisTimestamp: DateTime.now(),
      );
    }

    // Basic consistency report
    ConsistencyReport basicReport = _calculateConsistencyReport(currentResult);

    // Temporal pattern analysis
    TemporalPattern temporalPattern = _analyzeTemporalPattern(recentHistory);

    // Movement characteristics
    MovementCharacteristics movementCharacteristics = _analyzeMovementCharacteristics(recentHistory);

    // Quality metrics
    ConsistencyQualityMetrics qualityMetrics = _calculateQualityMetrics(recentHistory);

    // Overall confidence
    double confidence = _calculateOverallConfidence(basicReport, temporalPattern, movementCharacteristics);

    return AdvancedConsistencyAnalysis(
      basicReport: basicReport,
      temporalPattern: temporalPattern,
      movementCharacteristics: movementCharacteristics,
      qualityMetrics: qualityMetrics,
      confidence: confidence,
      analysisTimestamp: DateTime.now(),
    );
  }

  TemporalPattern _analyzeTemporalPattern(List<DetectionResult> history) {
    if (history.length < 5) return TemporalPattern.unknown;

    // Analyze confidence pattern over time
    List<double> confidences = history.map((h) => h.confidence).toList();

    // Check for patterns
    bool isOscillating = _detectOscillation(confidences);
    bool isImproving = _detectImprovement(confidences);
    bool isDegrading = _detectDegradation(confidences);
    bool isStable = _detectStability(confidences);

    if (isOscillating) {
      return TemporalPattern.oscillating;
    } else if (isImproving) {
      return TemporalPattern.improving;
    } else if (isDegrading) {
      return TemporalPattern.degrading;
    } else if (isStable) {
      return TemporalPattern.stable;
    } else {
      return TemporalPattern.unknown;
    }
  }

  bool _detectOscillation(List<double> values) {
    if (values.length < 6) return false;

    int signChanges = 0;
    for (int i = 1; i < values.length; i++) {
      double diff = values[i] - values[i - 1];
      if (i > 1) {
        double prevDiff = values[i - 1] - values[i - 2];
        if ((diff > 0 && prevDiff < 0) || (diff < 0 && prevDiff > 0)) {
          signChanges++;
        }
      }
    }

    return signChanges >= values.length ~/ 3;
  }

  bool _detectImprovement(List<double> values) {
    if (values.length < 3) return false;

    int improvements = 0;
    for (int i = 1; i < values.length; i++) {
      if (values[i] > values[i - 1]) {
        improvements++;
      }
    }

    return improvements > values.length * 0.6;
  }

  bool _detectDegradation(List<double> values) {
    if (values.length < 3) return false;

    int degradations = 0;
    for (int i = 1; i < values.length; i++) {
      if (values[i] < values[i - 1]) {
        degradations++;
      }
    }

    return degradations > values.length * 0.6;
  }

  bool _detectStability(List<double> values) {
    if (values.length < 3) return false;

    double mean = values.reduce((a, b) => a + b) / values.length;
    double variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    double stdDev = sqrt(variance);

    return stdDev < 0.1; // Low variance indicates stability
  }

  MovementCharacteristics _analyzeMovementCharacteristics(List<DetectionResult> history) {
    if (history.length < 2) {
      return MovementCharacteristics();
    }

    List<Offset> positions = [];
    List<double> sizes = [];

    for (DetectionResult result in history) {
      Rect bbox = result.boundingBox;
      positions.add(Offset(bbox.left + bbox.width / 2, bbox.top + bbox.height / 2));
      sizes.add(bbox.width * bbox.height);
    }

    // Calculate movement metrics
    double totalDistance = 0.0;
    double maxSpeed = 0.0;
    List<double> speeds = [];

    for (int i = 1; i < positions.length; i++) {
      double distance = (positions[i] - positions[i - 1]).distance;
      totalDistance += distance;
      speeds.add(distance);
      maxSpeed = max(maxSpeed, distance);
    }

    double avgSpeed = speeds.isNotEmpty ? speeds.reduce((a, b) => a + b) / speeds.length : 0.0;

    // Calculate size changes
    double totalSizeChange = 0.0;
    for (int i = 1; i < sizes.length; i++) {
      totalSizeChange += (sizes[i] - sizes[i - 1]).abs();
    }

    // Determine movement type
    MovementType movementType = _classifyMovementType(positions, speeds, sizes);

    return MovementCharacteristics(
      averageSpeed: avgSpeed,
      maxSpeed: maxSpeed,
      totalDistance: totalDistance,
      movementType: movementType,
      directionVariability: _calculateDirectionVariability(positions),
      sizeStability: _calculateSizeStability(sizes),
    );
  }

  MovementType _classifyMovementType(List<Offset> positions, List<double> speeds, List<double> sizes) {
    if (speeds.every((s) => s < 5.0)) {
      return MovementType.static;
    } else if (speeds.every((s) => s > 20.0)) {
      return MovementType.fast;
    } else if (_isCircularMovement(positions)) {
      return MovementType.circular;
    } else if (_isLinearMovement(positions)) {
      return MovementType.linear;
    } else {
      return MovementType.irregular;
    }
  }

  bool _isCircularMovement(List<Offset> positions) {
    if (positions.length < 4) return false;

    // Calculate center of movement
    Offset center = positions.reduce((a, b) => a + b) / positions.length.toDouble();

    // Check if positions form a circle around center
    List<double> distances = positions.map((p) => (p - center).distance).toList();
    double meanDistance = distances.reduce((a, b) => a + b) / distances.length;
    double variance = distances.map((d) => pow(d - meanDistance, 2)).reduce((a, b) => a + b) / distances.length;

    return variance < (meanDistance * 0.2); // Low variance indicates circular movement
  }

  bool _isLinearMovement(List<Offset> positions) {
    if (positions.length < 3) return false;

    // Calculate linearity using correlation
    double correlation = _calculateLinearCorrelation(positions);
    return correlation > 0.8;
  }

  double _calculateLinearCorrelation(List<Offset> positions) {
    if (positions.length < 2) return 0.0;

    List<double> x = positions.map((p) => p.dx).toList();
    List<double> y = positions.map((p) => p.dy).toList();

    double meanX = x.reduce((a, b) => a + b) / x.length;
    double meanY = y.reduce((a, b) => a + b) / y.length;

    double numerator = 0.0;
    double sumXX = 0.0;
    double sumYY = 0.0;

    for (int i = 0; i < positions.length; i++) {
      numerator += (x[i] - meanX) * (y[i] - meanY);
      sumXX += pow(x[i] - meanX, 2);
      sumYY += pow(y[i] - meanY, 2);
    }

    double denominator = sqrt(sumXX * sumYY);
    return denominator > 0 ? numerator / denominator : 0.0;
  }

  double _calculateDirectionVariability(List<Offset> positions) {
    if (positions.length < 3) return 0.0;

    List<double> angles = [];
    for (int i = 1; i < positions.length; i++) {
      Offset direction = positions[i] - positions[i - 1];
      double angle = atan2(direction.dy, direction.dx);
      angles.add(angle);
    }

    // Calculate angle variance
    double meanAngle = angles.reduce((a, b) => a + b) / angles.length;
    double variance = angles.map((a) => pow(a - meanAngle, 2)).reduce((a, b) => a + b) / angles.length;

    return variance;
  }

  double _calculateSizeStability(List<double> sizes) {
    if (sizes.length < 2) return 0.0;

    double mean = sizes.reduce((a, b) => a + b) / sizes.length;
    double variance = sizes.map((s) => pow(s - mean, 2)).reduce((a, b) => a + b) / sizes.length;
    double stdDev = sqrt(variance);

    return mean > 0 ? 1.0 - (stdDev / mean) : 0.0;
  }

  ConsistencyQualityMetrics _calculateQualityMetrics(List<DetectionResult> history) {
    // Calculate various quality metrics
    double confidenceQuality = _calculateConfidenceQuality(history);
    double consistencyScore = _calculateOverallConsistencyScore(history);
    double reliabilityScore = _calculateReliabilityScore(history);

    return ConsistencyQualityMetrics(
      confidenceQuality: confidenceQuality,
      consistencyScore: consistencyScore,
      reliabilityScore: reliabilityScore,
      dataQuality: _assessDataQuality(history),
    );
  }

  double _calculateConfidenceQuality(List<DetectionResult> history) {
    List<double> confidences = history.map((h) => h.confidence).toList();
    double mean = confidences.reduce((a, b) => a + b) / confidences.length;
    double variance = confidences.map((c) => pow(c - mean, 2)).reduce((a, b) => a + b) / confidences.length;

    // High mean and low variance indicate good quality
    return mean * (1.0 - variance.clamp(0.0, 1.0));
  }

  double _calculateOverallConsistencyScore(List<DetectionResult> history) {
    ConsistencyReport report = _calculateConsistencyReport(history.last);

    // Combine multiple consistency metrics
    double score = (report.positionStability * 0.4 +
                   (1.0 - report.confidenceVariance) * 0.3 +
                   report.detectionFrequency * 0.3);

    return score.clamp(0.0, 1.0);
  }

  double _calculateReliabilityScore(List<DetectionResult> history) {
    // Consider consistency, confidence, and stability
    double consistencyScore = _calculateOverallConsistencyScore(history);
    double confidenceQuality = _calculateConfidenceQuality(history);

    return (consistencyScore * 0.6 + confidenceQuality * 0.4).clamp(0.0, 1.0);
  }

  DataQuality _assessDataQuality(List<DetectionResult> history) {
    if (history.length < 3) return DataQuality.insufficient;

    double consistencyScore = _calculateOverallConsistencyScore(history);
    double confidenceQuality = _calculateConfidenceQuality(history);

    if (consistencyScore > 0.8 && confidenceQuality > 0.8) {
      return DataQuality.excellent;
    } else if (consistencyScore > 0.6 && confidenceQuality > 0.6) {
      return DataQuality.good;
    } else if (consistencyScore > 0.4 && confidenceQuality > 0.4) {
      return DataQuality.fair;
    } else {
      return DataQuality.poor;
    }
  }

  double _calculateOverallConfidence(ConsistencyReport report, TemporalPattern pattern, MovementCharacteristics movement) {
    double baseConfidence = report.positionStability * 0.4 + report.detectionFrequency * 0.4 + (1.0 - report.confidenceVariance) * 0.2;

    // Adjust based on temporal pattern
    switch (pattern) {
      case TemporalPattern.stable:
      case TemporalPattern.improving:
        baseConfidence *= 1.1;
        break;
      case TemporalPattern.degrading:
      case TemporalPattern.oscillating:
        baseConfidence *= 0.9;
        break;
      case TemporalPattern.unknown:
        break;
    }

    // Adjust based on movement characteristics
    if (movement.movementType == MovementType.static) {
      baseConfidence *= 1.05; // Static objects are more reliable
    } else if (movement.movementType == MovementType.irregular) {
      baseConfidence *= 0.95; // Irregular movement is less reliable
    }

    return baseConfidence.clamp(0.0, 1.0);
  }

  // Utility methods
  void clearHistory() {
    frameHistory.clear();
    classHistory.clear();
  }

  void clearHistoryForClass(String className) {
    classHistory.remove(className);
  }

  Map<String, dynamic> getStatistics() {
    Map<String, dynamic> stats = {
      'total_detections': frameHistory.length,
      'classes_tracked': classHistory.length,
      'class_statistics': {},
    };

    classHistory.forEach((className, history) {
      stats['class_statistics'][className] = {
        'detection_count': history.length,
        'avg_confidence': history.map((h) => h.confidence).reduce((a, b) => a + b) / history.length,
        'last_detection': history.last.detectionTime?.toIso8601String(),
      };
    });

    return stats;
  }
}

// Supporting classes for advanced analysis
class AdvancedConsistencyAnalysis {
  final ConsistencyReport basicReport;
  final TemporalPattern temporalPattern;
  final MovementCharacteristics movementCharacteristics;
  final ConsistencyQualityMetrics qualityMetrics;
  final double confidence;
  final DateTime analysisTimestamp;

  AdvancedConsistencyAnalysis({
    required this.basicReport,
    required this.temporalPattern,
    required this.movementCharacteristics,
    required this.qualityMetrics,
    required this.confidence,
    required this.analysisTimestamp,
  });
}

enum TemporalPattern {
  stable,
  improving,
  degrading,
  oscillating,
  unknown,
}

class MovementCharacteristics {
  final double averageSpeed;
  final double maxSpeed;
  final double totalDistance;
  final MovementType movementType;
  final double directionVariability;
  final double sizeStability;

  MovementCharacteristics({
    this.averageSpeed = 0.0,
    this.maxSpeed = 0.0,
    this.totalDistance = 0.0,
    this.movementType = MovementType.static,
    this.directionVariability = 0.0,
    this.sizeStability = 0.0,
  });
}

enum MovementType {
  static,
  slow,
  fast,
  linear,
  circular,
  irregular,
}

class ConsistencyQualityMetrics {
  final double confidenceQuality;
  final double consistencyScore;
  final double reliabilityScore;
  final DataQuality dataQuality;

  ConsistencyQualityMetrics({
    this.confidenceQuality = 0.0,
    this.consistencyScore = 0.0,
    this.reliabilityScore = 0.0,
    this.dataQuality = DataQuality.insufficient,
  });
}

enum DataQuality {
  excellent,
  good,
  fair,
  poor,
  insufficient,
}
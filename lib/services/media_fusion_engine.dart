import '../models/enhanced_detection_result.dart';

class MediaFusionEngine {
  static const double confidenceWeight = 0.3;
  static const double visualFeatureWeight = 0.4;
  static const double consistencyWeight = 0.2;
  static const double metadataWeight = 0.1;

  static const Map<String, double> defaultThresholds = {
    'photograph_threshold': 0.7,
    'painting_threshold': 0.6,
    'digital_art_threshold': 0.6,
    'three_d_threshold': 0.5,
    'cartoon_threshold': 0.6,
    'minimum_confidence': 0.3,
  };

  MediaType classifyMedia(ComprehensiveAnalysis analysis) {
    Map<MediaType, double> scores = {
      MediaType.photograph: 0.0,
      MediaType.painting: 0.0,
      MediaType.digitalArt: 0.0,
      MediaType.threeDimensional: 0.0,
      MediaType.cartoon: 0.0,
    };

    // Apply scoring from different analysis components
    _applyConfidenceScoring(scores, analysis.confidence);
    _applyVisualFeatureScoring(scores, analysis.visualFeatures);
    _applyConsistencyScoring(scores, analysis.consistency);
    _applyMetadataScoring(scores, analysis.metadata);

    // Apply threshold filtering
    _applyThresholdFiltering(scores);

    // Determine best match
    return _determineBestMatch(scores);
  }

  void _applyConfidenceScoring(Map<MediaType, double> scores, ConfidenceAnalysis conf) {
    switch (conf.signature.confidenceLevel) {
      case ConfidenceLevel.veryHigh:
        scores[MediaType.photograph] = scores[MediaType.photograph]! + confidenceWeight;
        break;
      case ConfidenceLevel.high:
        scores[MediaType.photograph] = scores[MediaType.photograph]! + (confidenceWeight * 0.8);
        scores[MediaType.digitalArt] = scores[MediaType.digitalArt]! + (confidenceWeight * 0.2);
        break;
      case ConfidenceLevel.medium:
        scores[MediaType.painting] = scores[MediaType.painting]! + (confidenceWeight * 0.7);
        scores[MediaType.threeDimensional] = scores[MediaType.threeDimensional]! + (confidenceWeight * 0.3);
        break;
      case ConfidenceLevel.low:
        scores[MediaType.cartoon] = scores[MediaType.cartoon]! + (confidenceWeight * 0.8);
        scores[MediaType.painting] = scores[MediaType.painting]! + (confidenceWeight * 0.2);
        break;
      case ConfidenceLevel.veryLow:
        scores[MediaType.cartoon] = scores[MediaType.cartoon]! + confidenceWeight;
        break;
    }

    // Additional scoring based on confidence features
    if (conf.confidenceFeatures['stability_score'] != null) {
      double stability = conf.confidenceFeatures['stability_score']!;
      if (stability > 0.8) {
        scores[MediaType.photograph] = scores[MediaType.photograph]! + 0.1;
      } else if (stability < 0.5) {
        scores[MediaType.cartoon] = scores[MediaType.cartoon]! + 0.1;
      }
    }
  }

  void _applyVisualFeatureScoring(Map<MediaType, double> scores, VisualFeatures vf) {
    // Edge-based scoring
    if (vf.edgeFeatures.edgeDensity > 0.25 && vf.colorFeatures.colorVariance > 0.7) {
      scores[MediaType.painting] = scores[MediaType.painting]! + (visualFeatureWeight * 0.4);
    }

    // Edge sharpness for digital art
    if (vf.edgeFeatures.edgeSharpness > 0.8) {
      scores[MediaType.digitalArt] = scores[MediaType.digitalArt]! + (visualFeatureWeight * 0.3);
    }

    // Compression artifact scoring
    if (vf.textureFeatures.compressionArtifacts > 0.5) {
      scores[MediaType.digitalArt] = scores[MediaType.digitalArt]! + (visualFeatureWeight * 0.3);
    }

    // Texture complexity scoring
    if (vf.textureFeatures.textureComplexity < 0.2) {
      scores[MediaType.digitalArt] = scores[MediaType.digitalArt]! + (visualFeatureWeight * 0.2);
    } else if (vf.textureFeatures.textureComplexity > 0.8) {
      scores[MediaType.painting] = scores[MediaType.painting]! + (visualFeatureWeight * 0.2);
    }

    // Color variance analysis
    if (vf.colorFeatures.colorVariance > 0.8) {
      scores[MediaType.painting] = scores[MediaType.painting]! + (visualFeatureWeight * 0.2);
    } else if (vf.colorFeatures.colorVariance < 0.3) {
      scores[MediaType.digitalArt] = scores[MediaType.digitalArt]! + (visualFeatureWeight * 0.2);
    }

    // Saturation profile analysis
    switch (vf.colorFeatures.saturationProfile) {
      case 'high':
        scores[MediaType.painting] = scores[MediaType.painting]! + (visualFeatureWeight * 0.1);
        break;
      case 'natural':
        scores[MediaType.photograph] = scores[MediaType.photograph]! + (visualFeatureWeight * 0.1);
        break;
      case 'perfect':
        scores[MediaType.digitalArt] = scores[MediaType.digitalArt]! + (visualFeatureWeight * 0.1);
        break;
    }

    // Lighting pattern analysis
    if (vf.colorFeatures.lightingPattern == 'natural') {
      scores[MediaType.photograph] = scores[MediaType.photograph]! + (visualFeatureWeight * 0.1);
    } else if (vf.colorFeatures.lightingPattern == 'controlled') {
      scores[MediaType.painting] = scores[MediaType.painting]! + (visualFeatureWeight * 0.1);
    }
  }

  void _applyConsistencyScoring(Map<MediaType, double> scores, ConsistencyAnalysis consistency) {
    switch (consistency.detectedPattern) {
      case MediaPattern.photograph:
        scores[MediaType.photograph] = scores[MediaType.photograph]! + consistencyWeight;
        break;
      case MediaPattern.artwork:
        scores[MediaType.painting] = scores[MediaType.painting]! + (consistencyWeight * 0.7);
        scores[MediaType.digitalArt] = scores[MediaType.digitalArt]! + (consistencyWeight * 0.3);
        break;
      case MediaPattern.handheld_object:
        scores[MediaType.threeDimensional] = scores[MediaType.threeDimensional]! + consistencyWeight;
        break;
      case MediaPattern.static_object:
        scores[MediaType.photograph] = scores[MediaType.photograph]! + (consistencyWeight * 0.8);
        scores[MediaType.painting] = scores[MediaType.painting]! + (consistencyWeight * 0.2);
        break;
      case MediaPattern.moving_object:
        scores[MediaType.threeDimensional] = scores[MediaType.threeDimensional]! + (consistencyWeight * 0.9);
        scores[MediaType.cartoon] = scores[MediaType.cartoon]! + (consistencyWeight * 0.1);
        break;
      case MediaPattern.unknown:
        // No scoring for unknown patterns
        break;
    }

    // Additional scoring based on position stability
    double stability = consistency.report.positionStability;
    if (stability > 0.9) {
      scores[MediaType.photograph] = scores[MediaType.photograph]! + 0.1;
    } else if (stability < 0.6) {
      scores[MediaType.threeDimensional] = scores[MediaType.threeDimensional]! + 0.1;
    }

    // Detection frequency scoring
    double frequency = consistency.report.detectionFrequency;
    if (frequency > 0.9) {
      scores[MediaType.photograph] = scores[MediaType.photograph]! + 0.05;
    }
  }

  void _applyMetadataScoring(Map<MediaType, double> scores, MetadataAnalysis metadata) {
    if (metadata.metadata.isPhotograph) {
      scores[MediaType.photograph] = scores[MediaType.photograph]! + metadataWeight;
    }

    if (metadata.metadata.isDigitalCreation) {
      scores[MediaType.digitalArt] = scores[MediaType.digitalArt]! + (metadataWeight * 0.8);
      scores[MediaType.cartoon] = scores[MediaType.cartoon]! + (metadataWeight * 0.2);
    }

    // Compression type analysis
    switch (metadata.metadata.compressionType) {
      case 'JPEG':
        scores[MediaType.photograph] = scores[MediaType.photograph]! + (metadataWeight * 0.3);
        break;
      case 'PNG':
        scores[MediaType.digitalArt] = scores[MediaType.digitalArt]! + (metadataWeight * 0.3);
        break;
      case 'WebP':
        scores[MediaType.digitalArt] = scores[MediaType.digitalArt]! + (metadataWeight * 0.2);
        break;
    }

    // Source indicators
    if (metadata.metadata.sourceIndicators.contains('camera')) {
      scores[MediaType.photograph] = scores[MediaType.photograph]! + (metadataWeight * 0.2);
    } else if (metadata.metadata.sourceIndicators.contains('digital_art_software')) {
      scores[MediaType.digitalArt] = scores[MediaType.digitalArt]! + (metadataWeight * 0.2);
    }
  }

  void _applyThresholdFiltering(Map<MediaType, double> scores) {
    scores.forEach((mediaType, score) {
      double threshold = _getThresholdForMediaType(mediaType);
      if (score < threshold) {
        scores[mediaType] = 0.0;
      }
    });

    // Check if any score passes minimum confidence
    bool hasValidScore = scores.values.any((score) => score >= defaultThresholds['minimum_confidence']!);
    if (!hasValidScore) {
      // If no score passes threshold, assign to unknown
      scores[MediaType.unknown] = defaultThresholds['minimum_confidence']!;
    }
  }

  double _getThresholdForMediaType(MediaType mediaType) {
    switch (mediaType) {
      case MediaType.photograph:
        return defaultThresholds['photograph_threshold']!;
      case MediaType.painting:
        return defaultThresholds['painting_threshold']!;
      case MediaType.digitalArt:
        return defaultThresholds['digital_art_threshold']!;
      case MediaType.threeDimensional:
        return defaultThresholds['three_d_threshold']!;
      case MediaType.cartoon:
        return defaultThresholds['cartoon_threshold']!;
      case MediaType.unknown:
        return defaultThresholds['minimum_confidence']!;
    }
  }

  MediaType _determineBestMatch(Map<MediaType, double> scores) {
    if (scores.isEmpty) return MediaType.unknown;

    // Find the media type with highest score
    MediaType bestType = MediaType.unknown;
    double bestScore = 0.0;

    scores.forEach((mediaType, score) {
      if (score > bestScore) {
        bestScore = score;
        bestType = mediaType;
      }
    });

    return bestType;
  }

  double calculateMediaConfidence(MediaType mediaType, ComprehensiveAnalysis analysis) {
    Map<MediaType, double> scores = {
      MediaType.photograph: 0.0,
      MediaType.painting: 0.0,
      MediaType.digitalArt: 0.0,
      MediaType.threeDimensional: 0.0,
      MediaType.cartoon: 0.0,
    };

    _applyConfidenceScoring(scores, analysis.confidence);
    _applyVisualFeatureScoring(scores, analysis.visualFeatures);
    _applyConsistencyScoring(scores, analysis.consistency);
    _applyMetadataScoring(scores, analysis.metadata);

    double finalScore = scores[mediaType] ?? 0.0;

    // Normalize score to 0-1 range
    return (finalScore / 1.0).clamp(0.0, 1.0);
  }

  // Advanced fusion with conflict resolution
  FusionResult performAdvancedFusion(ComprehensiveAnalysis analysis) {
    Map<MediaType, double> scores = {
      MediaType.photograph: 0.0,
      MediaType.painting: 0.0,
      MediaType.digitalArt: 0.0,
      MediaType.threeDimensional: 0.0,
      MediaType.cartoon: 0.0,
    };

    // Apply all scoring methods
    _applyConfidenceScoring(scores, analysis.confidence);
    _applyVisualFeatureScoring(scores, analysis.visualFeatures);
    _applyConsistencyScoring(scores, analysis.consistency);
    _applyMetadataScoring(scores, analysis.metadata);

    // Analyze conflicts and resolve them
    ConflictResolution conflictResolution = _analyzeAndResolveConflicts(scores, analysis);

    // Determine final result
    MediaType finalMediaType = _determineBestMatch(scores);
    double finalConfidence = calculateMediaConfidence(finalMediaType, analysis);

    return FusionResult(
      mediaType: finalMediaType,
      confidence: finalConfidence,
      scores: scores,
      conflictResolution: conflictResolution,
      analysisBreakdown: _createAnalysisBreakdown(analysis),
    );
  }

  ConflictResolution _analyzeAndResolveConflicts(Map<MediaType, double> scores, ComprehensiveAnalysis analysis) {
    List<String> conflicts = [];
    ConflictResolutionStrategy strategy = ConflictResolutionStrategy.none;

    // Check for conflicting high scores
    List<MapEntry<MediaType, double>> highScores = scores.entries
        .where((entry) => entry.value > 0.6)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (highScores.length > 1) {
      // Multiple high scores indicate conflict
      conflicts.addAll(highScores.map((entry) => entry.value.toString()));

      // Determine resolution strategy based on analysis components
      if (analysis.metadata.metadata.isPhotograph) {
        strategy = ConflictResolutionStrategy.metadataPriority;
      } else if (analysis.consistency.report.positionStability > 0.8) {
        strategy = ConflictResolutionStrategy.consistencyPriority;
      } else {
        strategy = ConflictResolutionStrategy.visualPriority;
      }
    }

    return ConflictResolution(
      hasConflicts: conflicts.isNotEmpty,
      conflictingMediaTypes: conflicts,
      resolutionStrategy: strategy,
      confidence: _calculateConflictResolutionConfidence(scores, analysis),
    );
  }

  double _calculateConflictResolutionConfidence(Map<MediaType, double> scores, ComprehensiveAnalysis analysis) {
    List<double> sortedScores = scores.values.toList();
    sortedScores.sort((a, b) => b.compareTo(a));

    if (sortedScores.length < 2) return sortedScores.isNotEmpty ? sortedScores.first : 0.0;

    double maxScore = sortedScores[0];
    double secondMaxScore = sortedScores[1];

    double scoreGap = maxScore - secondMaxScore;
    double confidence = scoreGap > 0.3 ? maxScore : (maxScore * 0.8);

    return confidence.clamp(0.0, 1.0);
  }

  Map<String, dynamic> _createAnalysisBreakdown(ComprehensiveAnalysis analysis) {
    return {
      'confidence_score': analysis.confidence.signature.confidenceScore,
      'confidence_level': analysis.confidence.signature.confidenceLevel.toString(),
      'edge_density': analysis.visualFeatures.edgeFeatures.edgeDensity,
      'color_variance': analysis.visualFeatures.colorFeatures.colorVariance,
      'texture_complexity': analysis.visualFeatures.textureFeatures.textureComplexity,
      'position_stability': analysis.consistency.report.positionStability,
      'is_photograph': analysis.metadata.metadata.isPhotograph,
      'is_digital_creation': analysis.metadata.metadata.isDigitalCreation,
    };
  }
}

class FusionResult {
  final MediaType mediaType;
  final double confidence;
  final Map<MediaType, double> scores;
  final ConflictResolution conflictResolution;
  final Map<String, dynamic> analysisBreakdown;

  FusionResult({
    required this.mediaType,
    required this.confidence,
    required this.scores,
    required this.conflictResolution,
    required this.analysisBreakdown,
  });
}

class ConflictResolution {
  final bool hasConflicts;
  final List<String> conflictingMediaTypes;
  final ConflictResolutionStrategy resolutionStrategy;
  final double confidence;

  ConflictResolution({
    required this.hasConflicts,
    required this.conflictingMediaTypes,
    required this.resolutionStrategy,
    required this.confidence,
  });
}

enum ConflictResolutionStrategy {
  none,
  metadataPriority,
  consistencyPriority,
  visualPriority,
  weightedAverage,
}
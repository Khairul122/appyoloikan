import '../utils/constants.dart';

class PredictionResult {
  final String label;
  final double confidence;
  final int index;
  final DateTime timestamp;

  PredictionResult({
    required this.label,
    required this.confidence,
    required this.index,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory PredictionResult.fromMap(Map<String, dynamic> map) {
    return PredictionResult(
      label: map['label'] ?? '',
      confidence: map['confidence']?.toDouble() ?? 0.0,
      index: map['index'] ?? 0,
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'confidence': confidence,
      'index': index,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  String get confidencePercentage => '${(confidence * 100).toStringAsFixed(1)}%';
  
  bool get isHighConfidence => confidence > 0.7;
  bool get isMediumConfidence => confidence > AppConstants.confidenceThreshold && confidence <= 0.7;
  bool get isLowConfidence => confidence <= AppConstants.confidenceThreshold;
  
  String get confidenceLevel {
    if (isHighConfidence) return 'Tinggi';
    if (isMediumConfidence) return 'Sedang';
    return 'Rendah';
  }

  String get displayName {
    return label
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
  
  @override
  String toString() {
    return 'PredictionResult(label: $displayName, confidence: $confidencePercentage)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PredictionResult &&
        other.label == label &&
        other.confidence == confidence &&
        other.index == index;
  }
  
  @override
  int get hashCode {
    return label.hashCode ^ confidence.hashCode ^ index.hashCode;
  }
}
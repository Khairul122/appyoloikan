class DetectionResult {
  final String label;
  final double confidence;
  final int classIndex;
  final double x;
  final double y;
  final double width;
  final double height;

  DetectionResult({
    required this.label,
    required this.confidence,
    required this.classIndex,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  String get confidencePercentage => '${(confidence * 100).toStringAsFixed(1)}%';
  
  bool get isHighConfidence => confidence > 0.7;
  bool get isMediumConfidence => confidence > 0.4 && confidence <= 0.7;
  bool get isLowConfidence => confidence <= 0.4;

  String get displayName {
    return label
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
  
  @override
  String toString() {
    return 'DetectionResult(label: $displayName, confidence: $confidencePercentage)';
  }
}
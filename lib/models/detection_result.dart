import '../utils/constants.dart';

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

  String get displayName {
    return label
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
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

  double get centerX => x + width / 2;
  double get centerY => y + height / 2;
  double get area => width * height;
  
  bool isValidBounds(double maxWidth, double maxHeight) {
    return x >= 0 && y >= 0 && 
           x + width <= maxWidth && 
           y + height <= maxHeight &&
           width > AppConstants.minBoundingBoxSize && 
           height > AppConstants.minBoundingBoxSize;
  }
  
  @override
  String toString() {
    return 'DetectionResult(label: $displayName, confidence: $confidencePercentage, bounds: [${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)}, ${width.toStringAsFixed(1)}, ${height.toStringAsFixed(1)}])';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DetectionResult &&
        other.label == label &&
        other.classIndex == classIndex &&
        (other.confidence - confidence).abs() < 0.001;
  }

  @override
  int get hashCode {
    return Object.hash(label, classIndex, confidence);
  }
}
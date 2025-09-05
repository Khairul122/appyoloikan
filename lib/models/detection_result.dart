class DetectionResult {
  final String label;
  final double confidence;
  final int classIndex;
  final double x;
  final double y;
  final double width;
  final double height;
  
  late final String _displayName;
  late final String _confidencePercentage;

  DetectionResult({
    required this.label,
    required this.confidence,
    required this.classIndex,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  }) {
    _displayName = label
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
    
    _confidencePercentage = '${(confidence * 100).toStringAsFixed(1)}%';
  }

  String get displayName => _displayName;
  String get confidencePercentage => _confidencePercentage;
  
  bool get isHighConfidence => confidence > 0.7;
  bool get isMediumConfidence => confidence > 0.4 && confidence <= 0.7;
  bool get isLowConfidence => confidence <= 0.4;

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
           width > 0 && height > 0;
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
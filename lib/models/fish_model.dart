class FishModel {
  final String name;
  final double confidence;
  final int classIndex;

  FishModel({
    required this.name,
    required this.confidence,
    required this.classIndex,
  });

  String get confidencePercentage => '${(confidence * 100).toStringAsFixed(1)}%';
  
  String get confidenceLevel {
    if (confidence >= 0.7) return 'Tinggi';
    if (confidence >= 0.4) return 'Sedang';
    return 'Rendah';
  }

  String get displayName {
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
  
  @override
  String toString() {
    return 'FishModel(name: $displayName, confidence: $confidencePercentage)';
  }
}
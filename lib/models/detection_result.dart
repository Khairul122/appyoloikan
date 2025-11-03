import 'dart:ui';

class DetectionResult {
  final Rect boundingBox;
  final String className;
  final double confidence;
  final int classIndex;
  final DateTime? detectionTime;

  DetectionResult({
    required this.boundingBox,
    required this.className,
    required this.confidence,
    required this.classIndex,
    this.detectionTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'boundingBox': {
        'left': boundingBox.left,
        'top': boundingBox.top,
        'width': boundingBox.width,
        'height': boundingBox.height,
      },
      'className': className,
      'confidence': confidence,
      'classIndex': classIndex,
      'detectionTime': detectionTime?.toIso8601String(),
    };
  }

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    final bbox = json['boundingBox'];
    return DetectionResult(
      boundingBox: Rect.fromLTWH(
        bbox['left'].toDouble(),
        bbox['top'].toDouble(),
        bbox['width'].toDouble(),
        bbox['height'].toDouble(),
      ),
      className: json['className'],
      confidence: json['confidence'].toDouble(),
      classIndex: json['classIndex'],
      detectionTime: json['detectionTime'] != null
          ? DateTime.parse(json['detectionTime'])
          : null,
    );
  }
}

// Extension for backward compatibility
extension DetectionResultExtension on DetectionResult {
  DateTime get detectionTime => this.detectionTime ?? DateTime.now();
}
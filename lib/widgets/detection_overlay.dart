import 'package:flutter/material.dart';
import '../models/detection_result.dart';
import '../models/fish_model.dart';
import '../utils/app_colors.dart';

class LetterboxInfo {
  final double scale;
  final double offsetX;
  final double offsetY;
  
  LetterboxInfo({
    required this.scale,
    required this.offsetX,
    required this.offsetY,
  });
}

class DetectionOverlay extends StatelessWidget {
  final List<DetectionResult> detections;
  final Size imageSize;
  final Size screenSize;

  const DetectionOverlay({
    super.key,
    required this.detections,
    required this.imageSize,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DetectionPainter(
        detections: detections,
        imageSize: imageSize,
        screenSize: screenSize,
      ),
      size: screenSize,
    );
  }
}

class DetectionPainter extends CustomPainter {
  final List<DetectionResult> detections;
  final Size imageSize;
  final Size screenSize;

  DetectionPainter({
    required this.detections,
    required this.imageSize,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    print('DetectionPainter: painting ${detections.length} detections');
    print('DetectionPainter: canvas size: $size, screen size: $screenSize, image size: $imageSize');
    
    for (int i = 0; i < detections.length; i++) {
      final detection = detections[i];
      print('Detection $i: ${detection.className}, bbox: ${detection.boundingBox}, confidence: ${detection.confidence}');
      _drawBoundingBox(canvas, detection);
      _drawLabel(canvas, detection);
    }
  }

  void _drawBoundingBox(Canvas canvas, DetectionResult detection) {
    final letterboxInfo = _calculateLetterboxScaling();
    
    final left = (detection.boundingBox.left * imageSize.width * letterboxInfo.scale) + letterboxInfo.offsetX;
    final top = (detection.boundingBox.top * imageSize.height * letterboxInfo.scale) + letterboxInfo.offsetY;
    final right = (detection.boundingBox.right * imageSize.width * letterboxInfo.scale) + letterboxInfo.offsetX;
    final bottom = (detection.boundingBox.bottom * imageSize.height * letterboxInfo.scale) + letterboxInfo.offsetY;

    final rect = Rect.fromLTRB(left, top, right, bottom);
    print('Letterbox scaling: scale=${letterboxInfo.scale}, offset=(${letterboxInfo.offsetX},${letterboxInfo.offsetY})');
    print('Drawing bbox: original=${detection.boundingBox}, scaled=$rect');
    print('Image size: $imageSize, Screen size: $screenSize');
    
    final paint = Paint()
      ..color = _getConfidenceColor(detection.confidence)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8.0)),
      paint,
    );
  }

  void _drawLabel(Canvas canvas, DetectionResult detection) {
    final letterboxInfo = _calculateLetterboxScaling();
    
    final fish = FishModel.fromClassName(detection.className);
    final confidence = (detection.confidence * 100).toStringAsFixed(1);
    final labelText = '${detection.className} ${confidence}%';

    final textSpan = TextSpan(
      text: labelText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(
            offset: Offset(1.0, 1.0),
            blurRadius: 2.0,
            color: Colors.black87,
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();

    final left = (detection.boundingBox.left * imageSize.width * letterboxInfo.scale) + letterboxInfo.offsetX;
    final top = (detection.boundingBox.top * imageSize.height * letterboxInfo.scale) + letterboxInfo.offsetY;

    // Standard YOLO label positioning - above bounding box
    final labelY = top - textPainter.height - 4;
    final adjustedLabelY = labelY < 0 ? top + 4 : labelY; // If label goes above screen, put it below bbox top
    
    final labelRect = Rect.fromLTWH(
      left,
      adjustedLabelY - 2,
      textPainter.width + 8,
      textPainter.height + 4,
    );

    final labelPaint = Paint()
      ..color = _getConfidenceColor(detection.confidence).withOpacity(0.9);

    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(3.0)),
      labelPaint,
    );

    textPainter.paint(
      canvas,
      Offset(left + 4, adjustedLabelY),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return AppColors.confidenceHigh;
    } else if (confidence >= 0.7) {
      return AppColors.confidenceMedium;
    } else {
      return AppColors.confidenceLow;
    }
  }

  LetterboxInfo _calculateLetterboxScaling() {
    // Calculate letterbox scaling to maintain aspect ratio
    final imageAspectRatio = imageSize.width / imageSize.height;
    final screenAspectRatio = screenSize.width / screenSize.height;
    
    double scale;
    double offsetX = 0.0;
    double offsetY = 0.0;
    
    if (imageAspectRatio > screenAspectRatio) {
      // Image is wider than screen - fit by width (letterbox top/bottom)
      scale = screenSize.width / imageSize.width;
      final scaledHeight = imageSize.height * scale;
      offsetY = (screenSize.height - scaledHeight) / 2.0;
    } else {
      // Image is taller than screen - fit by height (letterbox left/right)
      scale = screenSize.height / imageSize.height;
      final scaledWidth = imageSize.width * scale;
      offsetX = (screenSize.width - scaledWidth) / 2.0;
    }
    
    return LetterboxInfo(
      scale: scale,
      offsetX: offsetX,
      offsetY: offsetY,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DetectionInfoCard extends StatelessWidget {
  final DetectionResult? detection;

  const DetectionInfoCard({
    super.key,
    this.detection,
  });

  @override
  Widget build(BuildContext context) {
    if (detection == null) {
      return const SizedBox.shrink();
    }

    final fish = FishModel.fromClassName(detection!.className);
    final confidence = (detection!.confidence * 100).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getConfidenceColor(detection!.confidence),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fish.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$confidence%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _getConfidenceColor(detection!.confidence),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            fish.scientificName,
            style: const TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fish.description,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return AppColors.confidenceHigh;
    } else if (confidence >= 0.7) {
      return AppColors.confidenceMedium;
    } else {
      return AppColors.confidenceLow;
    }
  }
}
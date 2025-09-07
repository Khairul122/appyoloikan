import 'package:flutter/material.dart';
import '../models/detection_result.dart';
import '../models/fish_model.dart';
import '../utils/app_colors.dart';

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
    for (final detection in detections) {
      _drawBoundingBox(canvas, detection);
      _drawLabel(canvas, detection);
    }
  }

  void _drawBoundingBox(Canvas canvas, DetectionResult detection) {
    final scaleX = screenSize.width / imageSize.width;
    final scaleY = screenSize.height / imageSize.height;

    final left = detection.boundingBox.left * scaleX;
    final top = detection.boundingBox.top * scaleY;
    final right = detection.boundingBox.right * scaleX;
    final bottom = detection.boundingBox.bottom * scaleY;

    final rect = Rect.fromLTRB(left, top, right, bottom);
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
    final scaleX = screenSize.width / imageSize.width;
    final scaleY = screenSize.height / imageSize.height;

    final fish = FishModel.fromClassName(detection.className);
    final confidence = (detection.confidence * 100).toStringAsFixed(1);
    final labelText = '${fish.name}\n$confidence%';

    final textSpan = TextSpan(
      text: labelText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();

    final left = detection.boundingBox.left * scaleX;
    final top = detection.boundingBox.top * scaleY;

    final labelRect = Rect.fromLTWH(
      left,
      top - textPainter.height - 8,
      textPainter.width + 16,
      textPainter.height + 8,
    );

    final labelPaint = Paint()
      ..color = _getConfidenceColor(detection.confidence).withOpacity(0.8);

    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(6.0)),
      labelPaint,
    );

    textPainter.paint(
      canvas,
      Offset(left + 8, top - textPainter.height - 4),
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
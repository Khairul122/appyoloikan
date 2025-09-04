import 'package:flutter/material.dart';
import '../models/detection_result.dart';
import '../utils/app_colors.dart';

class DetectionOverlay extends StatelessWidget {
  final List<DetectionResult> detections;
  final Size previewSize;
  final double previewScale;

  const DetectionOverlay({
    Key? key,
    required this.detections,
    required this.previewSize,
    required this.previewScale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: previewSize,
      painter: DetectionPainter(
        detections: detections,
        previewScale: previewScale,
      ),
    );
  }
}

class DetectionPainter extends CustomPainter {
  final List<DetectionResult> detections;
  final double previewScale;

  DetectionPainter({
    required this.detections,
    required this.previewScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < detections.length; i++) {
      final detection = detections[i];
      _drawDetection(canvas, detection, i);
    }
  }

  void _drawDetection(Canvas canvas, DetectionResult detection, int index) {
    final confidenceColor = AppColors.getConfidenceColor(detection.confidence);
    
    final rect = Rect.fromLTWH(
      detection.x * previewScale,
      detection.y * previewScale,
      detection.width * previewScale,
      detection.height * previewScale,
    );

    final boundingBoxPaint = Paint()
      ..color = confidenceColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final backgroundPaint = Paint()
      ..color = confidenceColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, backgroundPaint);
    canvas.drawRect(rect, boundingBoxPaint);

    _drawCorners(canvas, rect, confidenceColor);
    _drawLabel(canvas, detection, rect, confidenceColor);
  }

  void _drawCorners(Canvas canvas, Rect rect, Color color) {
    final cornerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final cornerLength = 20.0;

    final corners = [
      [rect.topLeft, rect.topLeft + Offset(cornerLength, 0), rect.topLeft + Offset(0, cornerLength)],
      [rect.topRight, rect.topRight + Offset(-cornerLength, 0), rect.topRight + Offset(0, cornerLength)],
      [rect.bottomLeft, rect.bottomLeft + Offset(cornerLength, 0), rect.bottomLeft + Offset(0, -cornerLength)],
      [rect.bottomRight, rect.bottomRight + Offset(-cornerLength, 0), rect.bottomRight + Offset(0, -cornerLength)],
    ];

    for (final corner in corners) {
      canvas.drawLine(corner[0], corner[1], cornerPaint);
      canvas.drawLine(corner[0], corner[2], cornerPaint);
    }
  }

  void _drawLabel(Canvas canvas, DetectionResult detection, Rect rect, Color color) {
    final textSpan = TextSpan(
      children: [
        TextSpan(
          text: detection.displayName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: '\n${detection.confidencePercentage}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final labelRect = Rect.fromLTWH(
      rect.left,
      rect.top - textPainter.height - 8,
      textPainter.width + 12,
      textPainter.height + 8,
    );

    final labelPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final labelBorderPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, Radius.circular(4)),
      labelPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, Radius.circular(4)),
      labelBorderPaint,
    );

    textPainter.paint(
      canvas,
      Offset(labelRect.left + 6, labelRect.top + 4),
    );

    _drawConfidenceBar(canvas, detection, labelRect, color);
  }

  void _drawConfidenceBar(Canvas canvas, DetectionResult detection, Rect labelRect, Color color) {
    final barRect = Rect.fromLTWH(
      labelRect.left + 6,
      labelRect.bottom + 2,
      labelRect.width - 12,
      3,
    );

    final backgroundBarPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final confidenceBarPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, Radius.circular(1.5)),
      backgroundBarPaint,
    );

    final confidenceWidth = barRect.width * detection.confidence;
    final confidenceRect = Rect.fromLTWH(
      barRect.left,
      barRect.top,
      confidenceWidth,
      barRect.height,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(confidenceRect, Radius.circular(1.5)),
      confidenceBarPaint,
    );
  }

  @override
  bool shouldRepaint(covariant DetectionPainter oldDelegate) {
    return detections != oldDelegate.detections ||
           previewScale != oldDelegate.previewScale;
  }
}
import 'package:flutter/material.dart';
import '../models/detection_result.dart';
import '../utils/constants.dart';

class DetectionOverlay extends StatelessWidget {
  final DetectionResult? detection;
  final Size previewSize;

  const DetectionOverlay({
    Key? key,
    required this.detection,
    required this.previewSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (detection == null) return SizedBox.shrink();

    return CustomPaint(
      size: previewSize,
      painter: DetectionPainter(detection: detection!),
    );
  }
}

class DetectionPainter extends CustomPainter {
  final DetectionResult detection;

  DetectionPainter({required this.detection});

  @override
  void paint(Canvas canvas, Size size) {
    try {
      final rect = _calculateBoundingRect(size);
      final color = _getConfidenceColor(detection.confidence);

      _drawBackground(canvas, rect, color);
      _drawBorder(canvas, rect, color);
      _drawCorners(canvas, rect, color);
      _drawLabel(canvas, detection, rect, color);
      
    } catch (e) {
      // Error handled silently in production
    }
  }

  Rect _calculateBoundingRect(Size size) {
    final x = detection.x.clamp(0.0, size.width - AppConstants.minBoundingBoxSize);
    final y = detection.y.clamp(0.0, size.height - AppConstants.minBoundingBoxSize);
    final width = detection.width.clamp(AppConstants.minBoundingBoxSize.toDouble(), size.width - x);
    final height = detection.height.clamp(AppConstants.minBoundingBoxSize.toDouble(), size.height - y);
    
    return Rect.fromLTWH(x, y, width, height);
  }

  void _drawBackground(Canvas canvas, Rect rect, Color color) {
    final fillPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);
  }

  void _drawBorder(Canvas canvas, Rect rect, Color color) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawRect(rect, strokePaint);
  }

  void _drawCorners(Canvas canvas, Rect rect, Color color) {
    final cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;
    
    final corners = [
      [rect.topLeft, [Offset(cornerLength, 0), Offset(0, cornerLength)]],
      [rect.topRight, [Offset(-cornerLength, 0), Offset(0, cornerLength)]],
      [rect.bottomLeft, [Offset(cornerLength, 0), Offset(0, -cornerLength)]],
      [rect.bottomRight, [Offset(-cornerLength, 0), Offset(0, -cornerLength)]],
    ];

    for (final corner in corners) {
      final point = corner[0] as Offset;
      final offsets = corner[1] as List<Offset>;
      for (final offset in offsets) {
        canvas.drawLine(point, point + offset, cornerPaint);
      }
    }
  }

  void _drawLabel(Canvas canvas, DetectionResult detection, Rect rect, Color color) {
    final textSpan = TextSpan(
      children: [
        TextSpan(
          text: detection.displayName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        TextSpan(
          text: '\n${detection.confidencePercentage}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.2,
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
      (rect.top - textPainter.height - 16).clamp(0, rect.top),
      textPainter.width + 24,
      textPainter.height + 16,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, Radius.circular(8)),
      Paint()..color = color,
    );

    textPainter.paint(canvas, Offset(labelRect.left + 12, labelRect.top + 8));

    _drawConfidenceBar(canvas, detection, labelRect, color);
  }

  void _drawConfidenceBar(Canvas canvas, DetectionResult detection, Rect labelRect, Color color) {
    final barHeight = 6.0;
    final barRect = Rect.fromLTWH(
      labelRect.left + 12,
      labelRect.bottom + 6,
      labelRect.width - 24,
      barHeight,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, Radius.circular(barHeight / 2)),
      Paint()..color = Colors.white.withOpacity(0.3),
    );

    final confidenceWidth = barRect.width * detection.confidence;
    final confidenceRect = Rect.fromLTWH(
      barRect.left,
      barRect.top,
      confidenceWidth,
      barRect.height,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(confidenceRect, Radius.circular(barHeight / 2)),
      Paint()..color = Colors.white,
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.7) return Colors.lightGreen;
    if (confidence >= AppConstants.confidenceThreshold) return Colors.orange;
    return Colors.red;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
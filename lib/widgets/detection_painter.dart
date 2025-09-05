import 'package:flutter/material.dart';
import '../models/detection_result.dart';

class DetectionPainter extends CustomPainter {
  final List<DetectionResult> detections;
  final Size imageSize;
  final Size canvasSize;

  DetectionPainter({
    required this.detections,
    required this.imageSize,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty) return;

    final scaleX = canvasSize.width / imageSize.width;
    final scaleY = canvasSize.height / imageSize.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final offsetX = (canvasSize.width - imageSize.width * scale) / 2;
    final offsetY = (canvasSize.height - imageSize.height * scale) / 2;

    for (final detection in detections) {
      _drawBoundingBox(canvas, detection, scale, offsetX, offsetY);
    }
  }

  void _drawBoundingBox(Canvas canvas, DetectionResult detection, double scale, double offsetX, double offsetY) {
    final left = detection.x * scale + offsetX;
    final top = detection.y * scale + offsetY;
    final width = detection.width * scale;
    final height = detection.height * scale;

    final rect = Rect.fromLTWH(left, top, width, height);
    
    final color = _getConfidenceColor(detection.confidence);
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRect(rect, paint);

    _drawCorners(canvas, rect, color);
    _drawLabel(canvas, detection, rect, color);
  }

  void _drawCorners(Canvas canvas, Rect rect, Color color) {
    final cornerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final cornerLength = 20.0;

    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + Offset(0, cornerLength),
      cornerPaint,
    );

    canvas.drawLine(
      rect.topRight,
      rect.topRight + Offset(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      rect.topRight,
      rect.topRight + Offset(0, cornerLength),
      cornerPaint,
    );

    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + Offset(0, -cornerLength),
      cornerPaint,
    );

    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight + Offset(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight + Offset(0, -cornerLength),
      cornerPaint,
    );
  }

  void _drawLabel(Canvas canvas, DetectionResult detection, Rect rect, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: detection.displayName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: '\n${detection.confidencePercentage}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final labelRect = Rect.fromLTWH(
      rect.left,
      rect.top - textPainter.height - 12,
      textPainter.width + 16,
      textPainter.height + 12,
    );

    final labelPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, Radius.circular(6)),
      labelPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, Radius.circular(6)),
      borderPaint,
    );

    textPainter.paint(
      canvas,
      Offset(labelRect.left + 8, labelRect.top + 6),
    );

    _drawConfidenceBar(canvas, detection, labelRect, color);
  }

  void _drawConfidenceBar(Canvas canvas, DetectionResult detection, Rect labelRect, Color color) {
    final barHeight = 4.0;
    final barRect = Rect.fromLTWH(
      labelRect.left + 8,
      labelRect.bottom + 4,
      labelRect.width - 16,
      barHeight,
    );

    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final confidencePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, Radius.circular(barHeight / 2)),
      backgroundPaint,
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
      confidencePaint,
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.7) return Colors.green;
    if (confidence >= 0.5) return Colors.orange;
    return Colors.red;
  }

  @override
  bool shouldRepaint(DetectionPainter oldDelegate) {
    return detections != oldDelegate.detections ||
           imageSize != oldDelegate.imageSize ||
           canvasSize != oldDelegate.canvasSize;
  }
}
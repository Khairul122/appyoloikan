import 'package:flutter/material.dart';
import '../models/enhanced_detection_result.dart';

// Extension methods for screen sizing
extension ScreenExtension on int {
  double get w => this.toDouble();
  double get h => this.toDouble();
  double get sp => this.toDouble();
  double get r => this.toDouble();
}

class EnhancedDetectionWidget extends StatefulWidget {
  final EnhancedDetectionResult result;
  final VoidCallback? onTap;
  final bool showDetails;

  const EnhancedDetectionWidget({
    super.key,
    required this.result,
    this.onTap,
    this.showDetails = true,
  });

  @override
  State<EnhancedDetectionWidget> createState() => _EnhancedDetectionWidgetState();
}

class _EnhancedDetectionWidgetState extends State<EnhancedDetectionWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildMediaInfo(),
              if (widget.showDetails) ...[
                const SizedBox(height: 12),
                _buildDetectionInfo(),
                const SizedBox(height: 12),
                _buildExpandableDetails(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _getMediaTypeColor(),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.result.fishDetection.className,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _getMediaTypeDisplayName(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getConfidenceColor(),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${(widget.result.mediaConfidence * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaInfo() {
    return Row(
      children: [
        _buildInfoChip(
          'Media Type',
          _getMediaTypeDisplayName(),
          _getMediaTypeColor(),
        ),
        const SizedBox(width: 8),
        _buildInfoChip(
          'Confidence',
          '${(widget.result.fishDetection.confidence * 100).toStringAsFixed(1)}%',
          _getConfidenceColor(),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionInfo() {
    final boundingBox = widget.result.fishDetection.boundingBox;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detection Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Position: (${boundingBox.left.toStringAsFixed(0)}, ${boundingBox.top.toStringAsFixed(0)})'),
              Text('Size: ${boundingBox.width.toStringAsFixed(0)} × ${boundingBox.height.toStringAsFixed(0)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableDetails() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Row(
            children: [
              Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Advanced Analysis',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 12),
          _buildAdvancedDetails(),
        ],
      ],
    );
  }

  Widget _buildAdvancedDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Visual Quality', _getQualityLevel()),
          _buildDetailRow('Edge Analysis', '${(widget.result.analysis.visualFeatures.edgeFeatures.edgeSharpness * 100).toStringAsFixed(1)}%'),
          _buildDetailRow('Color Variance', '${(widget.result.analysis.visualFeatures.colorFeatures.colorVariance * 100).toStringAsFixed(1)}%'),
          _buildDetailRow('Texture Complexity', '${(widget.result.analysis.visualFeatures.textureFeatures.textureComplexity * 100).toStringAsFixed(1)}%'),
          if (widget.result.analysis.consistency.report.hasEnoughData) ...[
            _buildDetailRow('Position Stability', '${(widget.result.analysis.consistency.report.positionStability * 100).toStringAsFixed(1)}%'),
            _buildDetailRow('Detection Frequency', '${(widget.result.analysis.consistency.report.detectionFrequency * 100).toStringAsFixed(1)}%'),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getMediaTypeColor() {
    switch (widget.result.mediaType) {
      case MediaType.photograph:
        return Colors.blue;
      case MediaType.painting:
        return Colors.purple;
      case MediaType.digitalArt:
        return Colors.green;
      case MediaType.threeDimensional:
        return Colors.orange;
      case MediaType.cartoon:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getMediaTypeDisplayName() {
    switch (widget.result.mediaType) {
      case MediaType.photograph:
        return 'Photograph';
      case MediaType.painting:
        return 'Painting/Artwork';
      case MediaType.digitalArt:
        return 'Digital Art';
      case MediaType.threeDimensional:
        return '3D Object';
      case MediaType.cartoon:
        return 'Cartoon/Illustration';
      default:
        return 'Unknown';
    }
  }

  Color _getConfidenceColor() {
    if (widget.result.mediaConfidence >= 0.8) {
      return Colors.green;
    } else if (widget.result.mediaConfidence >= 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getQualityLevel() {
    final additionalFeatures = widget.result.additionalFeatures;
    if (additionalFeatures.containsKey('quality_metrics')) {
      final qualityMetrics = additionalFeatures['quality_metrics'] as Map<String, dynamic>?;
      if (qualityMetrics != null) {
        final qualityLevel = qualityMetrics['quality_level'] as String?;
        if (qualityLevel != null) {
          switch (qualityLevel) {
            case 'excellent':
              return 'Excellent';
            case 'good':
              return 'Good';
            case 'fair':
              return 'Fair';
            case 'poor':
              return 'Poor';
          }
        }
      }
    }
    return 'Unknown';
  }
}
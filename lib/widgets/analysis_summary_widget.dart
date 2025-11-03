import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/enhanced_detection_result.dart';

class AnalysisSummaryWidget extends StatefulWidget {
  final List<EnhancedDetectionResult> analysisResults;
  final VoidCallback? onExport;
  final bool showCharts;

  const AnalysisSummaryWidget({
    super.key,
    required this.analysisResults,
    this.onExport,
    this.showCharts = true,
  });

  @override
  State<AnalysisSummaryWidget> createState() => _AnalysisSummaryWidgetState();
}

class _AnalysisSummaryWidgetState extends State<AnalysisSummaryWidget> {
  late Map<String, dynamic> statistics;

  @override
  void initState() {
    super.initState();
    statistics = _calculateStatistics();
  }

  Map<String, dynamic> _calculateStatistics() {
    if (widget.analysisResults.isEmpty) {
      return {
        'totalDetections': 0,
        'averageConfidence': 0.0,
        'uniqueSpecies': <String>[],
        'reliableDetections': 0,
        'speciesDistribution': <String, int>{},
        'mediaTypeDistribution': <String, int>{},
      };
    }

    int totalDetections = widget.analysisResults.length;
    double averageConfidence = widget.analysisResults
        .map((r) => r.fishDetection.confidence)
        .reduce((a, b) => a + b) / totalDetections;

    Set<String> uniqueSpecies = widget.analysisResults
        .map((r) => r.fishDetection.className)
        .toSet();

    int reliableDetections = widget.analysisResults
        .where((r) => r.fishDetection.confidence > 0.7)
        .length;

    Map<String, int> speciesDistribution = {};
    for (var result in widget.analysisResults) {
      String species = result.fishDetection.className;
      speciesDistribution[species] = (speciesDistribution[species] ?? 0) + 1;
    }

    Map<String, int> mediaTypeDistribution = {};
    for (var result in widget.analysisResults) {
      String mediaType = result.mediaType.toString().split('.').last;
      mediaTypeDistribution[mediaType] = (mediaTypeDistribution[mediaType] ?? 0) + 1;
    }

    return {
      'totalDetections': totalDetections,
      'averageConfidence': averageConfidence,
      'uniqueSpecies': uniqueSpecies,
      'reliableDetections': reliableDetections,
      'speciesDistribution': speciesDistribution,
      'mediaTypeDistribution': mediaTypeDistribution,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.white,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Analysis Summary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.onExport != null)
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: widget.onExport,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatisticsGrid(),
            if (widget.showCharts) ...[
              const SizedBox(height: 24),
              _buildMediaTypeChart(),
              const SizedBox(height: 24),
              _buildSpeciesChart(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Total Detections', '${statistics['totalDetections']}', Icons.analytics)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Avg Confidence', '${(statistics['averageConfidence'] * 100).toStringAsFixed(1)}%', Icons.trending_up)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Unique Species', '${statistics['uniqueSpecies'].length}', Icons.category)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Reliable Detections', '${statistics['reliableDetections']}', Icons.verified)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTypeChart() {
    final distribution = statistics['mediaTypeDistribution'] as Map<String, int>;
    if (distribution.isEmpty) {
      return const Center(child: Text('No media type data available'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Media Type Distribution',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: distribution.entries.map((entry) {
                final color = _getMediaTypeColor(entry.key);
                return PieChartSectionData(
                  value: entry.value.toDouble(),
                  title: '${entry.key}\n${entry.value}',
                  titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
                  color: color,
                  radius: 80,
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeciesChart() {
    final distribution = statistics['speciesDistribution'] as Map<String, int>;
    if (distribution.isEmpty) {
      return const Center(child: Text('No species data available'));
    }

    final sortedEntries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Species Distribution',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: sortedEntries.first.value.toDouble() * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.blueGrey,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final species = sortedEntries[group.x.toInt()].key;
                    final count = rod.toY.toInt();
                    return BarTooltipItem(
                      '$species\n$count',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= sortedEntries.length) return const SizedBox();
                      final species = sortedEntries[value.toInt()].key;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          species.length > 8 ? '${species.substring(0, 8)}...' : species,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: sortedEntries.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.value.toDouble(),
                      color: _getSpeciesColor(entry.value.key),
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Color _getMediaTypeColor(String mediaType) {
    switch (mediaType.toLowerCase()) {
      case 'photograph':
        return Colors.blue;
      case 'painting':
        return Colors.purple;
      case 'digitalart':
        return Colors.green;
      case 'threedimensional':
        return Colors.orange;
      case 'cartoon':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getSpeciesColor(String species) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
    ];
    return colors[species.hashCode % colors.length];
  }
}
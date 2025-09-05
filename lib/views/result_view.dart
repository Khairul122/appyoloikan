import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/fish_controller.dart';
import '../utils/constants.dart';

class ResultView extends StatelessWidget {
  final FishController fishController = Get.find<FishController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Obx(() => _buildBody()),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('Hasil Prediksi'),
      backgroundColor: Colors.blue[600],
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () => fishController.clearCurrentPrediction(),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: _retryPrediction,
        ),
        _buildPopupMenu(),
      ],
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<String>(
      onSelected: _handleMenuSelection,
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, color: Colors.blue),
              SizedBox(width: 8),
              Text('Bagikan'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('Hapus'),
            ],
          ),
        ),
      ],
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'delete':
        _confirmDeleteImage(Get.context!);
        break;
      case 'share':
        _shareResult();
        break;
    }
  }

  Widget _buildBody() {
    final currentImage = fishController.currentImage.value;
    if (currentImage == null) {
      return Center(
        child: Text('Tidak ada gambar yang dipilih'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(currentImage, constraints),
              _buildPredictionSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSection(File imageFile, BoxConstraints constraints) {
    final imageHeight = constraints.maxHeight * 0.4;
    
    return Container(
      width: double.infinity,
      height: imageHeight.clamp(200.0, 400.0),
      color: Colors.grey[100],
      child: Stack(
        children: [
          Center(
            child: Image.file(
              imageFile,
              fit: BoxFit.contain,
              width: double.infinity,
              height: imageHeight,
            ),
          ),
          if (fishController.isPredicting.value) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Menganalisis gambar...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionSection() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hasil Prediksi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          Obx(() => _buildPredictionContent()),
        ],
      ),
    );
  }

  Widget _buildPredictionContent() {
    if (fishController.isPredicting.value) {
      return _buildLoadingResults();
    }

    if (fishController.errorMessage.value.isNotEmpty) {
      return _buildErrorResults();
    }

    if (fishController.predictionResults.isEmpty) {
      return _buildNoResults();
    }

    return _buildPredictionResults();
  }

  Widget _buildLoadingResults() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Sedang menganalisis...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorResults() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
          SizedBox(height: 12),
          Text(
            'Gagal Menganalisis',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            fishController.errorMessage.value,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red[600]),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _retryPrediction,
            child: Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.orange[400]),
          SizedBox(height: 12),
          Text(
            'Tidak Ada Hasil',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tidak dapat mengidentifikasi jenis ikan dari gambar ini',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.orange[600]),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _retryPrediction,
            child: Text('Coba Gambar Lain'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionResults() {
    return Column(
      children: fishController.predictionResults.asMap().entries.map((entry) {
        final index = entry.key;
        final result = entry.value;
        return _buildResultCard(result, index == 0);
      }).toList(),
    );
  }

  Widget _buildResultCard(dynamic result, bool isTopResult) {
    final confidence = result.confidence as double;
    final confidenceColor = _getConfidenceColor(confidence);
    final confidenceBackgroundColor = _getConfidenceBackgroundColor(confidence);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTopResult ? confidenceBackgroundColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTopResult ? confidenceColor : Colors.grey[300]!,
          width: isTopResult ? 2 : 1,
        ),
        boxShadow: isTopResult ? [
          BoxShadow(
            color: confidenceColor.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultHeader(result, isTopResult, confidenceColor),
          SizedBox(height: 8),
          _buildResultInfo(result),
          if (isTopResult) ...[
            SizedBox(height: 12),
            _buildProgressBar(confidence, confidenceColor),
          ],
        ],
      ),
    );
  }

  Widget _buildResultHeader(dynamic result, bool isTopResult, Color confidenceColor) {
    final displayName = (result.label as String)
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
    
    final confidencePercentage = '${((result.confidence as double) * 100).toStringAsFixed(1)}%';

    return Row(
      children: [
        if (isTopResult) ...[
          Icon(Icons.star, color: confidenceColor, size: 20),
          SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            displayName,
            style: TextStyle(
              fontSize: isTopResult ? 20 : 16,
              fontWeight: isTopResult ? FontWeight.bold : FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: confidenceColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            confidencePercentage,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultInfo(dynamic result) {
    final confidence = result.confidence as double;
    final confidenceLevel = _getConfidenceLevel(confidence);

    return Row(
      children: [
        Icon(Icons.analytics_outlined, size: 16, color: Colors.grey[600]),
        SizedBox(width: 4),
        Text(
          'Tingkat Keyakinan: $confidenceLevel',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double confidence, Color confidenceColor) {
    return Container(
      width: double.infinity,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: confidence,
        child: Container(
          decoration: BoxDecoration(
            color: confidenceColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => fishController.clearCurrentPrediction(),
              child: Text('Analisis Baru'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _retryPrediction,
              child: Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getConfidenceBackgroundColor(double confidence) {
    if (confidence >= 0.8) return Colors.green[50]!;
    if (confidence >= 0.6) return Colors.orange[50]!;
    return Colors.red[50]!;
  }

  String _getConfidenceLevel(double confidence) {
    if (confidence >= 0.7) return 'Tinggi';
    if (confidence >= AppConstants.confidenceThreshold) return 'Sedang';
    return 'Rendah';
  }

  void _retryPrediction() {
    final currentImage = fishController.currentImage.value;
    if (currentImage != null) {
      fishController.predictImage(currentImage);
    }
  }

  void _shareResult() {
    final topResult = fishController.predictionResults.isNotEmpty 
        ? fishController.predictionResults.first 
        : null;
    
    if (topResult != null) {
      final displayName = (topResult.label as String)
          .replaceAll('_', ' ')
          .split(' ')
          .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
          .join(' ');
      final confidencePercentage = '${((topResult.confidence as double) * 100).toStringAsFixed(1)}%';
      
      Get.snackbar(
        'Berbagi Hasil',
        '$displayName dengan keyakinan $confidencePercentage',
        duration: Duration(seconds: 2),
      );
    }
  }

  void _confirmDeleteImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Gambar'),
        content: Text('Apakah Anda yakin ingin menghapus gambar dan hasil prediksi ini?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              final currentImage = fishController.currentImage.value;
              if (currentImage != null) {
                fishController.deleteImage(currentImage);
              }
            },
            child: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
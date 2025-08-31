import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/fish_controller.dart';
import '../models/prediction_result.dart';
import '../utils/app_colors.dart';

class ResultView extends StatelessWidget {
  final FishController fishController = Get.find<FishController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  _confirmDeleteImage(context);
                  break;
                case 'share':
                  _shareResult();
                  break;
              }
            },
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
          ),
        ],
      ),
      body: Obx(() => _buildBody()),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildBody() {
    final currentImage = fishController.currentImage.value;
    if (currentImage == null) {
      return Center(
        child: Text('Tidak ada gambar yang dipilih'),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageSection(currentImage),
          _buildPredictionSection(),
        ],
      ),
    );
  }

  Widget _buildImageSection(File imageFile) {
    return Container(
      width: double.infinity,
      height: 300,
      color: Colors.grey[100],
      child: Stack(
        children: [
          Center(
            child: Image.file(
              imageFile,
              fit: BoxFit.contain,
              width: double.infinity,
              height: 300,
            ),
          ),
          if (fishController.isPredicting.value)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Menganalisis gambar...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
          Obx(() {
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
          }),
        ],
      ),
    );
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
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
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
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red[400],
          ),
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
            style: TextStyle(
              color: Colors.red[600],
            ),
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
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.orange[400],
          ),
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
            style: TextStyle(
              color: Colors.orange[600],
            ),
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
      children: fishController.predictionResults.map((result) {
        return _buildResultCard(result);
      }).toList(),
    );
  }

  Widget _buildResultCard(PredictionResult result) {
    final isTopResult = fishController.predictionResults.first == result;
    final confidenceColor = AppColors.getConfidenceColor(result.confidence);
    final confidenceBackgroundColor = AppColors.getConfidenceBackgroundColor(result.confidence);

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
          Row(
            children: [
              if (isTopResult)
                Icon(
                  Icons.star,
                  color: confidenceColor,
                  size: 20,
                ),
              if (isTopResult) SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.displayName,
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
                  result.confidencePercentage,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 16,
                color: Colors.grey[600],
              ),
              SizedBox(width: 4),
              Text(
                'Tingkat Keyakinan: ${result.confidenceLevel}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          if (isTopResult) ...[
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: result.confidence,
                child: Container(
                  decoration: BoxDecoration(
                    color: confidenceColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
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
      Get.snackbar(
        'Berbagi Hasil',
        '${topResult.displayName} dengan keyakinan ${topResult.confidencePercentage}',
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
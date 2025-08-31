import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../controllers/fish_controller.dart';
import '../views/camera_view.dart';
import '../views/result_view.dart';
import '../utils/app_colors.dart';

class HomeView extends StatelessWidget {
  final FishController fishController = Get.find<FishController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fish Classification'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () => _showRecentImages(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear_all':
                  _showClearAllDialog(context);
                  break;
                case 'about':
                  _showAboutDialog(context);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear All Images'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('About'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() => _buildBody()),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildBody() {
    if (fishController.isModelLoading.value) {
      return _buildLoadingView();
    }

    if (!fishController.isModelLoaded.value) {
      return _buildErrorView();
    }

    if (fishController.currentImage.value != null) {
      return ResultView();
    }

    return _buildWelcomeView();
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
          SizedBox(height: 16),
          Text(
            'Loading ML Model...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            SizedBox(height: 16),
            Text(
              'Failed to Load Model',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              fishController.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => fishController.loadModel(),
              child: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 40),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.camera_alt,
              size: 60,
              color: Colors.blue[600],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Fish Classification App',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Identifikasi jenis ikan dengan AI menggunakan YOLOv11',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 40),
          _buildFeatureCard(
            icon: Icons.camera_alt,
            title: 'Ambil Foto',
            description: 'Gunakan kamera untuk mengambil foto ikan secara langsung',
            color: Colors.green,
          ),
          SizedBox(height: 16),
          _buildFeatureCard(
            icon: Icons.photo_library,
            title: 'Upload Gambar',
            description: 'Pilih gambar ikan dari galeri untuk dianalisis',
            color: Colors.orange,
          ),
          SizedBox(height: 16),
          _buildFeatureCard(
            icon: Icons.analytics,
            title: 'Hasil Akurat',
            description: 'Mendapatkan prediksi jenis ikan dengan tingkat akurasi tinggi',
            color: Colors.purple,
          ),
          SizedBox(height: 40),
          _buildRecentImagesPreview(),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: color,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentImagesPreview() {
    return Obx(() {
      if (fishController.recentImages.isEmpty) {
        return SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gambar Terkini',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              TextButton(
                onPressed: () => _showRecentImages(Get.context!),
                child: Text('Lihat Semua'),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: fishController.recentImages.length.clamp(0, 5),
              itemBuilder: (context, index) {
                final image = fishController.recentImages[index];
                return GestureDetector(
                  onTap: () => fishController.selectImage(image),
                  child: Container(
                    width: 100,
                    margin: EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        image,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildFloatingActionButton() {
    return Obx(() {
      if (!fishController.isModelLoaded.value) {
        return SizedBox.shrink();
      }

      return SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        activeForegroundColor: Colors.white,
        activeBackgroundColor: Colors.blue[800],
        visible: true,
        closeManually: false,
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        tooltip: 'Pilih Sumber Gambar',
        heroTag: "speed-dial-hero-tag",
        elevation: 8.0,
        shape: CircleBorder(),
        children: [
          SpeedDialChild(
            child: Icon(Icons.camera_alt, color: Colors.white),
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            label: 'Kamera',
            labelStyle: TextStyle(fontSize: 14.0, color: Colors.black87),
            onTap: () => _handleCameraCapture(),
          ),
          SpeedDialChild(
            child: Icon(Icons.photo_library, color: Colors.white),
            backgroundColor: Colors.orange[600],
            foregroundColor: Colors.white,
            label: 'Galeri',
            labelStyle: TextStyle(fontSize: 14.0, color: Colors.black87),
            onTap: () => fishController.pickImageFromGallery(),
          ),
          SpeedDialChild(
            child: Icon(Icons.camera, color: Colors.white),
            backgroundColor: Colors.purple[600],
            foregroundColor: Colors.white,
            label: 'Kamera Langsung',
            labelStyle: TextStyle(fontSize: 14.0, color: Colors.black87),
            onTap: () => _navigateToCamera(),
          ),
        ],
      );
    });
  }

  void _handleCameraCapture() {
    fishController.pickImageFromCamera();
  }

  void _navigateToCamera() {
    Get.to(() => CameraView());
  }

  void _showRecentImages(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Gambar Terkini',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: Obx(() {
                    if (fishController.recentImages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Belum ada gambar',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      controller: scrollController,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: fishController.recentImages.length,
                      itemBuilder: (context, index) {
                        final image = fishController.recentImages[index];
                        return GestureDetector(
                          onTap: () {
                            Get.back();
                            fishController.selectImage(image);
                          },
                          onLongPress: () => _showImageOptions(context, image),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                image,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showImageOptions(BuildContext context, File image) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.visibility, color: Colors.blue),
              title: Text('Lihat & Analisis'),
              onTap: () {
                Get.back();
                Get.back();
                fishController.selectImage(image);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Hapus'),
              onTap: () {
                Get.back();
                _confirmDeleteImage(context, image);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteImage(BuildContext context, File image) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Gambar'),
        content: Text('Apakah Anda yakin ingin menghapus gambar ini?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              fishController.deleteImage(image);
            },
            child: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Semua Gambar'),
        content: Text('Apakah Anda yakin ingin menghapus semua gambar?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              fishController.clearAllImages();
            },
            child: Text('Hapus Semua', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tentang Aplikasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fish Classification App'),
            SizedBox(height: 8),
            Text('Versi: 1.0.0'),
            SizedBox(height: 8),
            Text('Menggunakan YOLOv11 untuk klasifikasi jenis ikan'),
            SizedBox(height: 8),
            Text('Dikembangkan dengan Flutter'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../controllers/fish_controller.dart';
import '../routes/app_routes.dart';
import '../views/camera_view.dart';
import '../views/result_view.dart';
import '../utils/constants.dart';

class HomeView extends StatelessWidget {
  final FishController fishController = Get.find<FishController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Obx(() => _buildBody()),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(AppConstants.appName),
      backgroundColor: Colors.blue[600],
      foregroundColor: Colors.white,
      elevation: 2,
      actions: [
        IconButton(
          icon: Icon(Icons.history),
          onPressed: () => _showRecentImages(context),
        ),
        _buildPopupMenu(),
      ],
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<String>(
      onSelected: _handleMenuSelection,
      itemBuilder: (BuildContext context) => [
        _buildMenuItem('live_detection', Icons.video_camera_front, 'Live Detection', Colors.green),
        _buildMenuItem('clear_all', Icons.delete_sweep, 'Clear All Images', Colors.red),
        _buildMenuItem('about', Icons.info_outline, 'About', Colors.blue),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    String value, 
    IconData icon, 
    String text, 
    Color color
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'live_detection':
        _navigateToLiveDetection();
        break;
      case 'clear_all':
        _showClearAllDialog(Get.context!);
        break;
      case 'about':
        _showAboutDialog(Get.context!);
        break;
    }
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
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
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
              style: TextStyle(color: Colors.grey[600]),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAppHeader(),
              SizedBox(height: 40),
              _buildFeatureGrid(),
              SizedBox(height: 40),
              _buildRecentImagesPreview(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppHeader() {
    return Column(
      children: [
        SizedBox(height: 40),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.camera_alt, size: 60, color: Colors.blue[600]),
        ),
        SizedBox(height: 24),
        Text(
          AppConstants.appName,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 12),
        Text(
          AppConstants.appDescription,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      _FeatureData(Icons.camera_alt, 'Ambil Foto', 'Gunakan kamera untuk mengambil foto ikan secara langsung', Colors.green),
      _FeatureData(Icons.photo_library, 'Upload Gambar', 'Pilih gambar ikan dari galeri untuk dianalisis', Colors.orange),
      _FeatureData(Icons.video_camera_front, 'Live Detection', 'Deteksi ikan secara real-time dengan bounding box', Colors.purple),
      _FeatureData(Icons.analytics, 'Hasil Akurat', 'Mendapatkan prediksi jenis ikan dengan tingkat akurasi tinggi', Colors.blue),
    ];

    return Column(
      children: features.map((feature) => _buildFeatureCard(
        icon: feature.icon,
        title: feature.title,
        description: feature.description,
        color: feature.color,
      )).toList(),
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
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              child: Icon(icon, size: 24, color: color),
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
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                return _buildImagePreview(image);
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildImagePreview(File image) {
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
          child: Image.file(image, fit: BoxFit.cover),
        ),
      ),
    );
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
        children: _buildSpeedDialChildren(),
      );
    });
  }

  List<SpeedDialChild> _buildSpeedDialChildren() {
    return [
      _buildSpeedDialChild(Icons.camera_alt, Colors.green[600]!, 'Kamera', fishController.pickImageFromCamera),
      _buildSpeedDialChild(Icons.photo_library, Colors.orange[600]!, 'Galeri', fishController.pickImageFromGallery),
      _buildSpeedDialChild(Icons.camera, Colors.purple[600]!, 'Kamera Langsung', _navigateToCamera),
      _buildSpeedDialChild(Icons.video_camera_front, Colors.red[600]!, 'Live Detection', _navigateToLiveDetection),
    ];
  }

  SpeedDialChild _buildSpeedDialChild(
    IconData icon, 
    Color backgroundColor, 
    String label, 
    VoidCallback onTap
  ) {
    return SpeedDialChild(
      child: Icon(icon, color: Colors.white),
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      label: label,
      labelStyle: TextStyle(fontSize: 14.0, color: Colors.black87),
      onTap: onTap,
    );
  }

  void _navigateToCamera() => Get.to(() => CameraView());
  void _navigateToLiveDetection() => Get.toNamed(AppRoutes.liveDetection);

  void _showRecentImages(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildRecentImagesSheet(),
    );
  }

  Widget _buildRecentImagesSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSheetHandle(),
              SizedBox(height: 16),
              Text(
                'Gambar Terkini',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Expanded(child: _buildImageGrid(scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildImageGrid(ScrollController scrollController) {
    return Obx(() {
      if (fishController.recentImages.isEmpty) {
        return _buildEmptyImageState();
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
          return _buildGridImageItem(image);
        },
      );
    });
  }

  Widget _buildEmptyImageState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Belum ada gambar',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildGridImageItem(File image) {
    return GestureDetector(
      onTap: () {
        Get.back();
        fishController.selectImage(image);
      },
      onLongPress: () => _showImageOptions(Get.context!, image),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(image, fit: BoxFit.cover),
        ),
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
            Text(AppConstants.appName),
            SizedBox(height: 8),
            Text('Versi: ${AppConstants.appVersion}'),
            SizedBox(height: 8),
            Text(AppConstants.appDescription),
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

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _FeatureData(this.icon, this.title, this.description, this.color);
}
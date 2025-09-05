import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../controllers/fish_controller.dart';
import '../views/camera_view.dart';
import '../views/result_view.dart';
import '../views/live_detection_view.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';

class HomeView extends StatelessWidget {
  final FishController fishController = Get.find<FishController>();

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLandscape = screenSize.width > screenSize.height;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, isTablet),
      body: Obx(() => _buildBody(context, isTablet, isLandscape)),
      floatingActionButton: _buildFloatingActionButton(isTablet),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isTablet) {
    return AppBar(
      title: Text(
        AppConstants.appName,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: isTablet ? 22 : 20,
          letterSpacing: 0.5,
        ),
      ),
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textOnPrimary,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.history_rounded,
                size: isTablet ? 22 : 20,
              ),
            ),
            onPressed: () => _showRecentImages(context),
          ),
        ),
        Container(
          margin: EdgeInsets.only(right: 16),
          child: PopupMenuButton<String>(
            icon: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.more_vert_rounded,
                size: isTablet ? 22 : 20,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            offset: Offset(0, 60),
            elevation: 8,
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
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.delete_sweep_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Hapus Semua',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.info,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Tentang Aplikasi',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, bool isTablet, bool isLandscape) {
    if (fishController.isModelLoading.value) {
      return _buildLoadingView(context, isTablet);
    }

    if (!fishController.isModelLoaded.value) {
      return _buildErrorView(context, isTablet);
    }

    if (fishController.currentImage.value != null) {
      return ResultView();
    }

    return _buildWelcomeView(context, isTablet, isLandscape);
  }

  Widget _buildLoadingView(BuildContext context, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.background,
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(isTablet ? 48 : 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isTablet ? 100 : 80,
                height: isTablet ? 100 : 80,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    backgroundColor: AppColors.grey200,
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 40 : 32),
              Text(
                'Memuat Model AI...',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Mohon tunggu sebentar',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.error.withOpacity(0.05),
            AppColors.background,
          ],
        ),
      ),
      child: Center(
        child: Container(
          margin: EdgeInsets.all(isTablet ? 48 : 24),
          padding: EdgeInsets.all(isTablet ? 40 : 32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isTablet ? 100 : 80,
                height: isTablet ? 100 : 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.error.withOpacity(0.1),
                      AppColors.error.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: isTablet ? 48 : 40,
                  color: AppColors.error,
                ),
              ),
              SizedBox(height: isTablet ? 32 : 24),
              Text(
                'Gagal Memuat Model',
                style: TextStyle(
                  fontSize: isTablet ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 12),
              Text(
                fishController.errorMessage.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              SizedBox(height: isTablet ? 40 : 32),
              Container(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => fishController.loadModel(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: EdgeInsets.symmetric(
                      vertical: isTablet ? 20 : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Coba Lagi',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeView(BuildContext context, bool isTablet, bool isLandscape) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.02),
            AppColors.background,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          isTablet ? 32 : 16,
          kToolbarHeight + MediaQuery.of(context).padding.top + 16,
          isTablet ? 32 : 16,
          isTablet ? 40 : 100,
        ),
        child: isLandscape && isTablet
            ? _buildLandscapeLayout(context, isTablet)
            : _buildPortraitLayout(context, isTablet),
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildHeroSection(isTablet),
        SizedBox(height: isTablet ? 48 : 32),
        _buildQuickActions(isTablet),
        SizedBox(height: isTablet ? 48 : 32),
        _buildFeatureGrid(isTablet),
        SizedBox(height: isTablet ? 48 : 32),
        _buildRecentImagesPreview(isTablet),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, bool isTablet) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildHeroSection(isTablet),
              SizedBox(height: 32),
              _buildQuickActions(isTablet),
            ],
          ),
        ),
        SizedBox(width: 32),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildFeatureGrid(isTablet),
              SizedBox(height: 32),
              _buildRecentImagesPreview(isTablet),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 48 : 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.white,
            AppColors.grey100,
          ],
        ),
        borderRadius: BorderRadius.circular(isTablet ? 32 : 24),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
        border: Border.all(
          color: AppColors.borderLight.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: isTablet ? 140 : 120,
            height: isTablet ? 140 : 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.secondary.withOpacity(0.15)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.psychology_rounded,
              size: isTablet ? 70 : 60,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: isTablet ? 32 : 24),
          Text(
            AppConstants.appName,
            style: TextStyle(
              fontSize: isTablet ? 32 : 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 12),
          Text(
            AppConstants.appDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              color: AppColors.textSecondary,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mulai Analisis',
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.camera_alt_rounded,
                  label: 'Kamera',
                  color: AppColors.accent,
                  onTap: () => fishController.pickImageFromCamera(),
                  isTablet: isTablet,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeri',
                  color: AppColors.warning,
                  onTap: () => fishController.pickImageFromGallery(),
                  isTablet: isTablet,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.videocam_rounded,
                  label: 'Live',
                  color: AppColors.secondary,
                  onTap: () => _navigateToLiveDetection(),
                  isTablet: isTablet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 20 : 16,
          horizontal: isTablet ? 16 : 12,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: isTablet ? 32 : 28,
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(bool isTablet) {
    final features = [
      {
        'icon': Icons.camera_alt_rounded,
        'title': 'Ambil Foto',
        'description': 'Gunakan kamera untuk mengambil foto ikan secara langsung',
        'color': AppColors.accent,
      },
      {
        'icon': Icons.photo_library_rounded,
        'title': 'Upload Gambar',
        'description': 'Pilih gambar ikan dari galeri untuk dianalisis',
        'color': AppColors.warning,
      },
      {
        'icon': Icons.analytics_rounded,
        'title': 'Hasil Akurat',
        'description': 'Mendapatkan prediksi jenis ikan dengan tingkat akurasi tinggi',
        'color': AppColors.secondary,
      },
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fitur Utama',
            style: TextStyle(
              fontSize: isTablet ? 22 : 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isTablet ? 24 : 20),
          if (isTablet)
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: features.length,
              itemBuilder: (context, index) => _buildFeatureCard(
                features[index],
                isTablet,
              ),
            )
          else
            Column(
              children: features
                  .map((feature) => Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: _buildFeatureCard(feature, isTablet),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (feature['color'] as Color).withOpacity(0.05),
            AppColors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (feature['color'] as Color).withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: isTablet
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (feature['color'] as Color).withOpacity(0.15),
                        (feature['color'] as Color).withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (feature['color'] as Color).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    size: 32,
                    color: feature['color'] as Color,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  feature['title'] as String,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  feature['description'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (feature['color'] as Color).withOpacity(0.15),
                        (feature['color'] as Color).withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (feature['color'] as Color).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    size: 28,
                    color: feature['color'] as Color,
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        feature['description'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRecentImagesPreview(bool isTablet) {
    return Obx(() {
      if (fishController.recentImages.isEmpty) {
        return SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gambar Terkini',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showRecentImages(Get.context!),
                  label: Text(
                    'Lihat Semua',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Container(
              height: isTablet ? 130 : 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: fishController.recentImages.length.clamp(0, 5),
                itemBuilder: (context, index) {
                  final image = fishController.recentImages[index];
                  return GestureDetector(
                    onTap: () => fishController.selectImage(image),
                    child: Container(
                      width: isTablet ? 130 : 110,
                      margin: EdgeInsets.only(right: isTablet ? 16 : 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.borderLight.withOpacity(0.5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowLight,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
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
        ),
      );
    });
  }

  Widget _buildFloatingActionButton(bool isTablet) {
    return Obx(() {
      if (!fishController.isModelLoaded.value) {
        return SizedBox.shrink();
      }

      return SpeedDial(
        icon: Icons.add_rounded,
        activeIcon: Icons.close_rounded,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        activeForegroundColor: AppColors.textOnPrimary,
        activeBackgroundColor: AppColors.primaryDark,
        visible: true,
        closeManually: false,
        curve: Curves.easeInOutCubicEmphasized,
        overlayColor: AppColors.black,
        overlayOpacity: 0.7,
        tooltip: 'Pilih Sumber Gambar',
        heroTag: "speed-dial-hero-tag",
        elevation: 12.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        spaceBetweenChildren: isTablet ? 20 : 16,
        buttonSize: Size(isTablet ? 68 : 60, isTablet ? 68 : 60),
        childrenButtonSize: Size(isTablet ? 60 : 52, isTablet ? 60 : 52),
        children: [
          SpeedDialChild(
            child: Icon(Icons.camera_alt_rounded, color: AppColors.textOnPrimary),
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.textOnPrimary,
            label: 'Kamera',
            labelStyle: TextStyle(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            labelBackgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            onTap: () => fishController.pickImageFromCamera(),
          ),
          SpeedDialChild(
            child: Icon(Icons.photo_library_rounded, color: AppColors.textOnPrimary),
            backgroundColor: AppColors.warning,
            foregroundColor: AppColors.textOnPrimary,
            label: 'Galeri',
            labelStyle: TextStyle(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            labelBackgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            onTap: () => fishController.pickImageFromGallery(),
          ),
          SpeedDialChild(
            child: Icon(Icons.videocam_rounded, color: AppColors.textOnPrimary),
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.textOnPrimary,
            label: 'Kamera Langsung',
            labelStyle: TextStyle(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            labelBackgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            onTap: () => _navigateToLiveDetection(),
          ),
        ],
      );
    });
  }

  void _navigateToLiveDetection() {
    Get.to(() => LiveDetectionView(), transition: Transition.cupertino);
  }

  void _showRecentImages(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowMedium,
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 28 : 20),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.grey300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(height: isTablet ? 24 : 16),
                      Text(
                        'Gambar Terkini',
                        style: TextStyle(
                          fontSize: isTablet ? 24 : 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    if (fishController.recentImages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: isTablet ? 100 : 80,
                              height: isTablet ? 100 : 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.grey200,
                                    AppColors.grey100,
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.photo_library_outlined,
                                size: isTablet ? 48 : 40,
                                color: AppColors.grey500,
                              ),
                            ),
                            SizedBox(height: isTablet ? 32 : 24),
                            Text(
                              'Belum ada gambar',
                              style: TextStyle(
                                fontSize: isTablet ? 20 : 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Ambil foto atau pilih dari galeri',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: isTablet ? 28 : 20),
                      child: GridView.builder(
                        controller: scrollController,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isTablet ? 3 : 2,
                          crossAxisSpacing: isTablet ? 20 : 16,
                          mainAxisSpacing: isTablet ? 20 : 16,
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
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.borderLight.withOpacity(0.5),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadowLight,
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(
                                  image,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
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
    final isTablet = MediaQuery.of(context).size.width > 600;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(32),
          ),
        ),
        padding: EdgeInsets.all(isTablet ? 28 : 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: isTablet ? 24 : 16),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.visibility_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              title: Text(
                'Lihat & Analisis',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onTap: () {
                Get.back();
                Get.back();
                fishController.selectImage(image);
              },
            ),
            SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.delete_rounded,
                  color: AppColors.error,
                  size: 24,
                ),
              ),
              title: Text(
                'Hapus',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onTap: () {
                Get.back();
                _confirmDeleteImage(context, image);
              },
            ),
            SizedBox(height: isTablet ? 24 : 16),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteImage(BuildContext context, File image) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.delete_rounded,
                color: AppColors.error,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Text(
              'Hapus Gambar',
              style: TextStyle(
                fontSize: isTablet ? 22 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus gambar ini? Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Batal',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Get.back();
              fishController.deleteImage(image);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Text(
              'Hapus',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.delete_sweep_rounded,
                color: AppColors.error,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Hapus Semua Gambar',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus semua gambar? Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Batal',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Get.back();
              fishController.clearAllImages();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Text(
              'Hapus Semua',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Tentang Aplikasi',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAboutItem('Nama Aplikasi', AppConstants.appName, isTablet),
            SizedBox(height: 16),
            _buildAboutItem('Versi', AppConstants.appVersion, isTablet),
            SizedBox(height: 16),
            _buildAboutItem('Deskripsi', AppConstants.appDescription, isTablet),
            SizedBox(height: 16),
            _buildAboutItem('Teknologi', 'Flutter & YOLOv11', isTablet),
          ],
        ),
        actions: [
          Container(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Get.back(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: EdgeInsets.symmetric(
                  vertical: isTablet ? 16 : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: Text(
                'OK',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutItem(String label, String value, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 14 : 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
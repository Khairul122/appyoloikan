import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/splash_controller.dart';
import '../utils/constants.dart';

class SplashScreen extends StatelessWidget {
  final SplashController controller = Get.put(SplashController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildGradientBackground(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildLogoSection(constraints),
                    ),
                    Expanded(
                      flex: 2,
                      child: _buildLoadingSection(constraints),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildGradientBackground() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.blue[800]!,
          Colors.blue[600]!,
          Colors.blue[400]!,
        ],
      ),
    );
  }

  Widget _buildLogoSection(BoxConstraints constraints) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAnimatedLogo(constraints),
          SizedBox(height: 24),
          _buildAppTitleSection(),
        ],
      ),
    );
  }

  Widget _buildAnimatedLogo(BoxConstraints constraints) {
    final logoSize = constraints.maxWidth * 0.3;
    
    return AnimatedBuilder(
      animation: controller.animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: controller.scaleAnimation.value,
          child: FadeTransition(
            opacity: controller.fadeAnimation,
            child: Container(
              width: logoSize.clamp(100.0, 200.0),
              height: logoSize.clamp(100.0, 200.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt,
                size: logoSize.clamp(50.0, 100.0),
                color: Colors.blue[600],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppTitleSection() {
    return SlideTransition(
      position: controller.slideAnimation,
      child: FadeTransition(
        opacity: controller.fadeAnimation,
        child: Column(
          children: [
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              AppConstants.appDescription,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w300,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSection(BoxConstraints constraints) {
    return SlideTransition(
      position: controller.slideAnimation,
      child: FadeTransition(
        opacity: controller.fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildProgressBar(),
            SizedBox(height: 24),
            _buildLoadingText(),
            SizedBox(height: 16),
            _buildProgressPercentage(),
            SizedBox(height: 40),
            _buildLoadingIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Obx(() => Container(
      width: double.infinity,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: controller.loadingProgress.value,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.white.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildLoadingText() {
    return Obx(() => AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: Text(
        controller.loadingText.value,
        key: ValueKey(controller.loadingText.value),
        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    ));
  }

  Widget _buildProgressPercentage() {
    return Obx(() => Text(
      '${(controller.loadingProgress.value * 100).toInt()}%',
      style: TextStyle(
        fontSize: 14,
        color: Colors.white.withOpacity(0.8),
        fontWeight: FontWeight.w600,
      ),
    ));
  }

  Widget _buildLoadingIndicator() {
    return Obx(() {
      if (!controller.isLoading.value) return SizedBox.shrink();

      return Container(
        width: 120,
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return AnimatedContainer(
              duration: Duration(milliseconds: 400),
              margin: EdgeInsets.symmetric(horizontal: 4),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      );
    });
  }
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../controllers/splash_controller.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';

class SplashScreen extends StatelessWidget {
  final SplashController controller = Get.put(SplashController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.splashGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppConstants.largePadding),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildLogoSection(),
                ),
                Expanded(
                  flex: 2,
                  child: _buildLoadingSection(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Logo with Lottie
          AnimatedBuilder(
            animation: controller.animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: controller.scaleAnimation.value,
                child: FadeTransition(
                  opacity: controller.fadeAnimation,
                  child: Container(
                    width: 150,
                    height: 150,
                    child: Lottie.asset(
                      'lib/assets/animations/loading.json',
                      controller: controller.animationController,
                      repeat: true,
                      reverse: false,
                      animate: true,
                    ),
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 24),

          // App Title with slide animation
          SlideTransition(
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
                      color: AppColors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    AppConstants.appDescription,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.white.withAlpha(230),
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSection() {
    return SlideTransition(
      position: controller.slideAnimation,
      child: FadeTransition(
        opacity: controller.fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Progress Bar
            Obx(() => Container(
                  width: double.infinity,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.white.withAlpha(77),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: controller.loadingProgress.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.white,
                            AppColors.white.withAlpha(200),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.white.withAlpha(128),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                )),

            SizedBox(height: 24),

            // Loading Text
            Obx(() => AnimatedSwitcher(
                  duration: AppConstants.animationDuration,
                  child: Text(
                    controller.loadingText.value,
                    key: ValueKey(controller.loadingText.value),
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.white,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )),

            SizedBox(height: 16),

            // Progress Percentage
            Obx(() => Text(
                  '${(controller.loadingProgress.value * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.white.withAlpha(204),
                    fontWeight: FontWeight.w600,
                  ),
                )),

            SizedBox(height: 40),

            // Loading Dots Animation
            _buildLoadingDots(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingDots() {
    return Obx(() {
      if (!controller.isLoading.value) return SizedBox.shrink();

      return Container(
        width: 120,
        height: 40,
        child: Lottie.asset(
          'lib/assets/animations/loading_dots.json',
          repeat: true,
          animate: true,
        ),
      );
    });
  }
}

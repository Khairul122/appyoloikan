import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../routes/app_routes.dart';
import '../services/ml_service.dart';

class SplashController extends GetxController with GetSingleTickerProviderStateMixin {
  var isLoading = true.obs;
  var loadingProgress = 0.0.obs;
  var loadingText = 'Memuat aplikasi...'.obs;
  var isFirstRun = true.obs;
  
  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<double> scaleAnimation;
  late Animation<Offset> slideAnimation;
  
  @override
  void onInit() {
    super.onInit();
    _initAnimations();
    _startSplashSequence();
  }
  
  void _initAnimations() {
    animationController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    
    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Interval(0.0, 0.5, curve: Curves.easeInOut),
    ));
    
    scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Interval(0.2, 0.7, curve: Curves.elasticOut),
    ));
    
    slideAnimation = Tween<Offset>(
      begin: Offset(0.0, 1.0),
      end: Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Interval(0.4, 1.0, curve: Curves.easeOutBack),
    ));
  }
  
  void _startSplashSequence() async {
    try {
      animationController.forward();
      await _initializeApp();
    } catch (e) {
      print('Error during splash sequence: $e');
      _navigateToHome();
    }
  }
  
  Future<void> _initializeApp() async {
    try {
      loadingText.value = 'Memeriksa aplikasi...';
      loadingProgress.value = 0.1;
      await _checkFirstRun();
      await Future.delayed(Duration(milliseconds: 300));
      
      loadingText.value = 'Menginisialisasi...';
      loadingProgress.value = 0.3;
      await _initializePreferences();
      await Future.delayed(Duration(milliseconds: 400));
      
      loadingText.value = 'Memuat model AI...';
      loadingProgress.value = 0.5;
      await _loadMLModel();
      await Future.delayed(Duration(milliseconds: 500));
      
      loadingText.value = 'Menyiapkan layanan...';
      loadingProgress.value = 0.8;
      await _initializeServices();
      await Future.delayed(Duration(milliseconds: 400));
      
      loadingText.value = 'Menyelesaikan...';
      loadingProgress.value = 1.0;
      await Future.delayed(Duration(milliseconds: 500));
      
      _navigateToHome();
      
    } catch (e) {
      print('Initialization error: $e');
      loadingText.value = 'Terjadi kesalahan...';
      await Future.delayed(Duration(milliseconds: 1000));
      _navigateToHome();
    }
  }
  
  Future<void> _checkFirstRun() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isFirstRun.value = prefs.getBool(AppConstants.keyFirstRun) ?? true;
      
      if (isFirstRun.value) {
        await prefs.setBool(AppConstants.keyFirstRun, false);
      }
    } catch (e) {
      print('Error checking first run: $e');
      isFirstRun.value = true;
    }
  }
  
  Future<void> _initializePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (!prefs.containsKey(AppConstants.keyModelLoaded)) {
        await prefs.setBool(AppConstants.keyModelLoaded, false);
      }
      
    } catch (e) {
      print('Error initializing preferences: $e');
    }
  }
  
  Future<void> _loadMLModel() async {
    try {
      final mlService = MLService.instance;
      final success = await mlService.loadModel();
      
      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(AppConstants.keyModelLoaded, true);
        await prefs.setString(
          AppConstants.keyLastModelUpdate, 
          DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      print('Error loading ML model: $e');
    }
  }
  
  Future<void> _initializeServices() async {
    try {
      await Future.delayed(Duration(milliseconds: 200));
    } catch (e) {
      print('Error initializing services: $e');
    }
  }
  
  void _navigateToHome() {
    isLoading.value = false;
    
    Future.delayed(Duration(milliseconds: 500), () {
      Get.offAllNamed(AppRoutes.home);
    });
  }
  
  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}
import 'package:get/get.dart';
import '../views/splash_screen.dart';
import '../views/home_view.dart';
import '../views/live_detection_view.dart';
import '../views/upload_detection_view.dart';

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String liveDetection = '/live-detection';
  static const String uploadDetection = '/upload-detection';

  static List<GetPage> routes = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: home,
      page: () => const HomeView(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: liveDetection,
      page: () => const LiveDetectionView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: uploadDetection,
      page: () => const UploadDetectionView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
}
import 'package:get/get.dart';
import '../views/splash_screen.dart';
import '../views/home_view.dart';
import '../views/camera_view.dart';
import '../views/result_view.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/home';
  static const String camera = '/camera';
  static const String result = '/result';
  
  static final routes = [
    GetPage(
      name: splash,
      page: () => SplashScreen(),
      transition: Transition.fade,
      transitionDuration: Duration(milliseconds: 300),
    ),
    GetPage(
      name: home,
      page: () => HomeView(),
      transition: Transition.fadeIn,
      transitionDuration: Duration(milliseconds: 300),
    ),
    GetPage(
      name: camera,
      page: () => CameraView(),
      transition: Transition.rightToLeft,
      transitionDuration: Duration(milliseconds: 300),
    ),
    GetPage(
      name: result,
      page: () => ResultView(),
      transition: Transition.rightToLeft,
      transitionDuration: Duration(milliseconds: 300),
    ),
  ];
}
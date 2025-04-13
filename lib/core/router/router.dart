import 'package:musiva/features/auth/presentation/pages/splash_page.dart';
import 'package:musiva/features/home/presentation/pages/home_page.dart';
import 'package:musiva/features/profile/presentation/pages/profile_page.dart';

final routes = {
  '/': (context) => const SplashPage(),
  '/home': (context) => const HomePage(),
  '/profile': (context) => const ProfilePage(),
};

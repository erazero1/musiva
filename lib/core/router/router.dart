import 'package:musiva/features/auth/presentation/pages/splash_page.dart';
import 'package:musiva/features/home/presentation/pages/home_page.dart';
import 'package:musiva/features/profile/presentation/pages/profile_page.dart';
import 'package:musiva/features/settings/presentation/pages/settings_page.dart';
import 'package:musiva/features/song_upload/presentation/pages/upload_page.dart';

final routes = {
  '/': (context) => const SplashPage(),
  '/home': (context) => const HomePage(),
  '/profile': (context) => const ProfilePage(),
  '/song_upload': (context) => UploadSongPage(),
  '/settings': (context) => const SettingsPage(),
};

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:musiva/core/di/service_locator.dart';
import 'package:musiva/core/error/global_error_handler.dart';
import 'package:musiva/core/utils/logger.dart';
import 'package:musiva/musiva_app.dart';

void main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize global error handler
    GlobalErrorHandler.init();
    
    log.i('Main: Initializing Firebase');
    try {
      await Firebase.initializeApp();
      log.i('Main: Firebase initialized successfully');
    } catch (e, stackTrace) {
      log.e('Main: Failed to initialize Firebase', e, stackTrace);
      // Continue app initialization even if Firebase fails
    }

    log.i('Main: Setting up dependencies');
    await setupDependencies();
    
    log.i('Main: Initializing settings feature');
    await initSettingsFeature();
    
    log.i('Main: Setting preferred orientations');
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp, 
      DeviceOrientation.landscapeLeft, 
      DeviceOrientation.landscapeRight,
    ]);
    
    log.i('Main: Starting app');
    runApp(MusivaApp());
  }, (error, stackTrace) {
    log.e('Main: Uncaught error in main zone', error, stackTrace);
    // Here you could report to a crash reporting service
  });
}

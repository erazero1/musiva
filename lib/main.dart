import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:musiva/core/di/service_locator.dart';
import 'package:musiva/musiva_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  setupDependencies();
  runApp(MusivaApp());
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:musiva/musiva_app.dart';
import 'features/auth/injection_container.dart' as auth_di;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await auth_di.initAuthDependencies();
  runApp(MusivaApp());
}
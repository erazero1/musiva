import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musiva/core/router/router.dart';
import 'package:musiva/core/theme/dark_theme.dart';
import 'package:musiva/core/theme/theme.dart';
import 'package:musiva/features/auth/presentation/bloc/auth_bloc.dart';

import 'features/auth/injection_container.dart';

class MusivaApp extends StatelessWidget {
  const MusivaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set system overlay style for status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return BlocProvider<AuthBloc>(
      create: (_) => sl<AuthBloc>(),
      child: MaterialApp(
        title: 'Musiva',
        debugShowCheckedModeBanner: false,
        theme: themeData,
        darkTheme: darkThemeData,
        themeMode: ThemeMode.system,
        routes: routes,
      ),
    );
  }
}

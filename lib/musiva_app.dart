import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:musiva/core/router/router.dart';
import 'package:musiva/core/theme/theme_modes/dark_theme.dart';
import 'package:musiva/core/theme/theme_modes/theme.dart';
import 'package:musiva/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//  AppLocalizations.of(context)!.
import 'core/di/service_locator.dart';
import 'core/theme/bloc/theme_bloc.dart';

class MusivaApp extends StatefulWidget {
  const MusivaApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    final _MusivaAppState? state = context.findAncestorStateOfType<_MusivaAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<MusivaApp> createState() => _MusivaAppState();
}

class _MusivaAppState extends State<MusivaApp> {
  Locale? _locale;

  void setLocale(Locale newLocale) {
    setState(() {
      _locale = newLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Set system overlay style for status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>(),
        ),
        BlocProvider<ThemeBloc>(
          create: (_) => ThemeBloc(),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: _locale ?? Locale(Intl.getCurrentLocale()),
            title: AppLocalizations.of(context)?.app_name ?? "Musiva",
            debugShowCheckedModeBanner: false,
            theme: themeData,
            darkTheme: darkThemeData,
            themeMode: themeState.themeMode,
            routes: routes,
          );
        },
      ),
    );
  }
}

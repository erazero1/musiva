import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:musiva/core/router/router.dart';
import 'package:musiva/core/theme/theme_modes/dark_theme.dart';
import 'package:musiva/core/theme/theme_modes/theme.dart';
import 'package:musiva/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musiva/features/settings/presentation/bloc/user_preferences_bloc.dart';
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

class _MusivaAppState extends State<MusivaApp> with WidgetsBindingObserver {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize and load user preferences when app starts
    final preferencesBloc = sl<UserPreferencesBloc>();
    preferencesBloc.add(LoadUserPreferences());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // This helps update the UI when system theme changes (if using system theme)
    setState(() {});
    super.didChangePlatformBrightness();
  }

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
        BlocProvider<UserPreferencesBloc>(
          create: (_) => sl<UserPreferencesBloc>(),
          lazy: false, // Create immediately to load preferences
        ),
        BlocProvider<ThemeBloc>(
          create: (_) => sl<ThemeBloc>(),
          lazy: false, // Create immediately for theme initialization
        ),
      ],
      child: BlocConsumer<UserPreferencesBloc, UserPreferencesState>(
        listener: (context, preferencesState) {
          if (preferencesState is UserPreferencesLoaded) {
            // Update locale from preferences
            final languageCode = preferencesState.preferences.languageCode;
            if (languageCode.isNotEmpty && (_locale == null || _locale!.languageCode != languageCode)) {
              setLocale(Locale(languageCode));
            }
          }
        },
        builder: (context, _) {
          return BlocBuilder<ThemeBloc, ThemeState>(
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
          );
        },
      ),
    );
  }
}
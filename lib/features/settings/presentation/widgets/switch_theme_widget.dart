import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musiva/core/theme/bloc/theme_bloc.dart';

class SwitchThemeWidget extends StatelessWidget {
  const SwitchThemeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        // Check if dark mode is enabled - correctly handle system theme too
        bool isDarkMode;

        if (state.themeMode == ThemeMode.system) {
          // If system theme, check the brightness of the current context
          isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
        } else {
          // Otherwise use the explicit theme mode
          isDarkMode = state.themeMode == ThemeMode.dark;
        }

        return ListTile(
          leading: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
          title: Text(AppLocalizations.of(context)!.switch_theme_label),
          subtitle: Text(
              isDarkMode
                  ? AppLocalizations.of(context)?.dark_theme_label ?? "Dark"
                  : AppLocalizations.of(context)?.light_theme_label ?? "Light"
          ),
          trailing: Switch(
            value: isDarkMode,
            onChanged: (bool value) {
              // Dispatch correct theme mode
              final newThemeMode = value ? ThemeMode.dark : ThemeMode.light;
              context.read<ThemeBloc>().add(SetThemeModeEvent(themeMode: newThemeMode));
            },
          ),
        );
      },
    );
  }
}
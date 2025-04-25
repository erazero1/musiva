import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../core/theme/bloc/theme_bloc.dart';

class SwitchThemeWidget extends StatelessWidget {
  const SwitchThemeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Check the current theme state
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: const Icon(Icons.brightness_6),
      title: Text(AppLocalizations.of(context)!.switch_theme_label),
      trailing: Switch(
        value: isDarkMode,
        onChanged: (bool value) {
          BlocProvider.of<ThemeBloc>(context).add(ToggleThemeEvent());
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musiva/features/settings/presentation/bloc/user_preferences_bloc.dart';
import 'package:musiva/features/settings/presentation/widgets/switch_theme_widget.dart';
import 'package:musiva/musiva_app.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Load user preferences when settings page is opened
    context.read<UserPreferencesBloc>().add(LoadUserPreferences());

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings_label),
      ),
      body: const SettingsPageContent(),
    );
  }
}

class SettingsPageContent extends StatefulWidget {
  const SettingsPageContent({super.key});

  @override
  State<SettingsPageContent> createState() => _SettingsPageContentState();
}

class _SettingsPageContentState extends State<SettingsPageContent> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<UserPreferencesBloc, UserPreferencesState>(
      builder: (context, state) {
        // Show loading indicator while preferences are loading
        if (state is UserPreferencesLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Extract the language code from state or use default
        String languageCode = 'en';
        if (state is UserPreferencesLoaded) {
          languageCode = state.preferences.languageCode;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              localizations.settings_label,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            /// Theme Toggle
            const Card(
              child: SwitchThemeWidget(),
            ),

            const SizedBox(height: 16),

            /// Language Selector
            Card(
              child: ListTile(
                leading: const Icon(Icons.language),
                title: Text(localizations.language_label),
                subtitle: Text(
                  languageCode == "kk"
                      ? "Қазақша"
                      : languageCode == "ru"
                      ? "Русский"
                      : "English",
                ),
                onTap: () => _showLanguageDialog(context, languageCode),
              ),
            ),

            // Display error message if there is one
            if (state is UserPreferencesError)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  state.message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context, String currentLanguageCode) {
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(localizations.choose_language_label),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption("kk", "Қазақша", currentLanguageCode),
              _buildLanguageOption("ru", "Русский", currentLanguageCode),
              _buildLanguageOption("en", "English", currentLanguageCode),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String code, String label, String currentLanguageCode) {
    return RadioListTile<String>(
      value: code,
      groupValue: currentLanguageCode,
      title: Text(label),
      onChanged: (value) {
        if (value != null) {
          Navigator.pop(context);
          _changeLanguage(value);
        }
      },
    );
  }

  void _changeLanguage(String languageCode) {
    // Update language in UserPreferencesBloc
    context.read<UserPreferencesBloc>().add(
      ChangeLanguage(languageCode: languageCode),
    );

    // Set language in the app
    MusivaApp.setLocale(context, Locale(languageCode));
  }
}
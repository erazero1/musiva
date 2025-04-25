import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musiva/features/settings/presentation/widgets/switch_theme_widget.dart';
import 'package:musiva/musiva_app.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
  Locale _selectedLocale = Locale("en");

  void _changeLanguage(Locale locale) {
    setState(() {
      _selectedLocale = locale;
      MusivaApp.setLocale(context, locale);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          localizations.settings_label,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),

        /// Theme Toggle
        Card(
          child: SwitchThemeWidget()
        ),

        const SizedBox(height: 16),

        /// Language Selector
        Card(
          child: ListTile(
            leading: Icon(Icons.language),
            title: Text(localizations.language_label),
            subtitle: Text(
              _selectedLocale.languageCode == "kk"
                  ? "Қазақша"
                  : _selectedLocale.languageCode == "ru"
                  ? "Русский"
                  : "English",
            ),
            onTap: () => _showLanguageDialog(context),
          ),
        ),
      ],
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(localizations.choose_language_label),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption("kk", "Қазақша"),
              _buildLanguageOption("ru", "Русский"),
              _buildLanguageOption("en", "English"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String code, String label) {
    return RadioListTile<String>(
      value: code,
      groupValue: _selectedLocale.languageCode,
      title: Text(label),
      onChanged: (value) {
        if (value != null) {
          Navigator.pop(context);
          _changeLanguage(Locale(value));
        }
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AuthForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController? displayNameController;
  final bool isRegister;
  final GlobalKey<FormState> formKey;

  const AuthForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    this.displayNameController,
    this.isRegister = false,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          if (isRegister && displayNameController != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextFormField(
                controller: displayNameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.display_name_label,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (isRegister && (value == null || value.isEmpty)) {
                    return AppLocalizations.of(context)!.enter_your_name_label;
                  }
                  return null;
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.email_label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.email),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.enter_your_email_label;
                }
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value)) {
                  return AppLocalizations.of(context)!.enter_valid_email;
                }
                return null;
              },
            ),
          ),
          TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.password_label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.lock),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!.enter_your_password;
              }
              if (isRegister && value.length < 8) {
                return AppLocalizations.of(context)!.enter_valid_password;
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
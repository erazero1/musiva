import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musiva/features/auth/presentation/bloc/auth_bloc.dart';


class MusivaAppBar extends StatelessWidget {
  final String title;

  const MusivaAppBar({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isGuest = authState is GuestAuthenticated; // <- adjust if needed

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row (Logo, Title, Icons)
          Row(
            children: [
              // App logo
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Title with animation
              DefaultTextStyle(
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    title,
                    key: ValueKey<String>(title),
                  ),
                ),
              ),

              const Spacer(),


              // Settings icon
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ],
          ),

          // Guest mode warning
          if (isGuest) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context)!.guest_mode_warning,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../auth/domain/entities/user.dart';
import '../bloc/profile_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.instance<ProfileBloc>()..add(LoadProfileEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: Text( AppLocalizations.of(context)!.profile_label),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (state is ProfileLoaded) {
              return _buildProfileContent(context, state.user);
            } else if (state is ProfileError) {
              return Center(
                child: Text(
                  '${ AppLocalizations.of(context)!.error_label}: ${state.message}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            return Center(
              child: Text( AppLocalizations.of(context)!.loading_profile_label),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, User user) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const SizedBox(height: 20),
          _buildProfileAvatar(user),
          const SizedBox(height: 24),
          Text(
            user.displayName ?? 'Music Lover',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.email,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 40),
          _buildProfileItem(
            context,
            icon: Icons.person,
            title:  AppLocalizations.of(context)!.edit_profile_label,
            onTap: () {
              // TODO: Navigate to edit profile screen
            },
          ),
          _buildProfileItem(
            context,
            icon: Icons.settings,
            title:  AppLocalizations.of(context)!.settings_label,
            onTap: () {
              // TODO: Navigate to settings screen
            },
          ),
          _buildProfileItem(
            context,
            icon: Icons.help_outline,
            title:  AppLocalizations.of(context)!.help_support_label,
            onTap: () {
              // TODO: Navigate to help screen
            },
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              context.read<ProfileBloc>().logout();
              Navigator.of(context).pushReplacementNamed('/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Text(
              AppLocalizations.of(context)!.logout_label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(User user) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: user.photoUrl != null
          ? ClipRRect(
        borderRadius: BorderRadius.circular(60),
        child: Image.network(
          user.photoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.person,
              size: 60,
              color: Colors.grey,
            );
          },
        ),
      )
          : const Icon(
        Icons.person,
        size: 60,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildProfileItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
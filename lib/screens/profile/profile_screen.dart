import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: currentUserAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Could not load profile: $error'),
        ),
        data: (user) {
          if (user == null) {
            // Shouldn't normally happen (Splash already gates on auth
            // state) but guarding against it avoids a null-pointer crash
            // if, e.g., the Firestore doc is ever deleted mid-session.
            return const Center(child: Text('No profile found.'));
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      backgroundImage: user.photoUrl != null
                          ? CachedNetworkImageProvider(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null
                          ? Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 36,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: user.isOnline ? AppColors.online : AppColors.offline,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  user.email,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  user.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: user.isOnline ? AppColors.online : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit profile'),
                trailing: const Icon(Icons.chevron_right),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.divider),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.logout, color: AppColors.error),
                title: Text('Logout', style: TextStyle(color: AppColors.error)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.divider),
                ),
                onTap: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

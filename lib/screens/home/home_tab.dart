import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/call_model.dart';
import '../../providers/user_provider.dart';
import '../../widgets/user_tile.dart';
import '../contacts/contacts_screen.dart';

/// Content of the "Home" bottom-nav tab: a greeting with the user's own
/// profile photo, a search shortcut into Contacts, and a preview of online
/// contacts. This satisfies the PDF's Home Screen spec (profile, search,
/// contacts, bottom nav) without duplicating the full Contacts list logic.
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final allUsersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: currentUserAsync.when(
          data: (user) => Text('Hi, ${user?.name.split(' ').first ?? 'there'} 👋'),
          loading: () => const Text('Talkway'),
          error: (_, __) => const Text('Talkway'),
        ),
        actions: [
          currentUserAsync.when(
            data: (user) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                backgroundImage: user?.photoUrl != null
                    ? CachedNetworkImageProvider(user!.photoUrl!)
                    : null,
                child: user?.photoUrl == null
                    ? Text(
                        (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 12, color: AppColors.primary),
                      )
                    : null,
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search shortcut — tapping jumps straight into Contacts, which
          // owns the real search box. Avoids duplicating search state here.
          Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ContactsScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Search people...',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Online now',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          allUsersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Could not load contacts.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            data: (users) {
              final online = users.where((u) => u.isOnline).toList();
              if (online.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No one is online right now.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              return Column(
                children: online
                    .map((user) => UserTile(
                          user: user,
                          onAudioCall: () => startCallWith(context, ref, user, CallType.audio),
                          onVideoCall: () => startCallWith(context, ref, user, CallType.video),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
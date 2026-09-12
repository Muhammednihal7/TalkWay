import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/call_model.dart';
import '../../models/user_model.dart';
import '../../providers/call_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/user_tile.dart';
import '../call/call_screen.dart';

/// Creates a real Firestore call record for the given contact and
/// navigates into CallScreen as the caller. Shared by both ContactsScreen
/// and HomeTab so there's exactly one place this logic lives.
Future<void> startCallWith(
  BuildContext context,
  WidgetRef ref,
  UserModel contact,
  CallType type,
) async {
  final currentUserAsync = ref.read(currentUserProvider);
  final currentUser = currentUserAsync.value;
  if (currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not load your profile. Try again.')),
    );
    return;
  }

  final callService = ref.read(callServiceProvider);
  try {
    final call = await callService.startCall(
      callerId: currentUser.uid,
      callerName: currentUser.name,
      callerPhotoUrl: currentUser.photoUrl,
      calleeId: contact.uid,
      calleeName: contact.name,
      calleePhotoUrl: contact.photoUrl,
      type: type,
    );

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CallScreen(call: call, isCaller: true),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not start the call: $e')),
    );
  }
}

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    final filteredContacts = ref.watch(filteredContactsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (value) =>
                  ref.read(contactsSearchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: 'Search people...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
              ),
            ),
          ),
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load contacts. Check your connection and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),
              data: (_) {
                if (filteredContacts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            'No contacts found',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: filteredContacts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = filteredContacts[index];
                    return UserTile(
                      user: user,
                      onAudioCall: () => startCallWith(context, ref, user, CallType.audio),
                      onVideoCall: () => startCallWith(context, ref, user, CallType.video),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
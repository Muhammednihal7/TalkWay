import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/user_model.dart';
import 'call_button.dart';

/// One row in the Contacts list: avatar, name, online/offline status,
/// audio call button, video call button. Matches the layout shown in the
/// assignment PDF's Contacts Screen example.
class UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onAudioCall;
  final VoidCallback onVideoCall;
  final VoidCallback? onTap;

  const UserTile({
    super.key,
    required this.user,
    required this.onAudioCall,
    required this.onVideoCall,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            backgroundImage:
                user.photoUrl != null ? CachedNetworkImageProvider(user.photoUrl!) : null,
            child: user.photoUrl == null
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          // Small status dot anchored to the bottom-right of the avatar —
          // the green/grey indicator required by the spec.
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: user.isOnline ? AppColors.online : AppColors.offline,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        user.isOnline ? 'Online' : 'Offline',
        style: TextStyle(
          color: user.isOnline ? AppColors.online : AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CallButton.audio(onPressed: onAudioCall),
          const SizedBox(width: 8),
          CallButton.video(onPressed: onVideoCall),
        ],
      ),
    );
  }
}

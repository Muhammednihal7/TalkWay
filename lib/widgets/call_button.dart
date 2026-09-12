import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Small circular icon button used for the audio/video call actions on a
/// contact row. Reused wherever a "call this person" action appears.
class CallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const CallButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  factory CallButton.audio({required VoidCallback onPressed}) {
    return CallButton(icon: Icons.call, onPressed: onPressed, color: AppColors.online);
  }

  factory CallButton.video({required VoidCallback onPressed}) {
    return CallButton(icon: Icons.videocam, onPressed: onPressed, color: AppColors.primary);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    return Material(
      color: effectiveColor.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: effectiveColor, size: 20),
        ),
      ),
    );
  }
}

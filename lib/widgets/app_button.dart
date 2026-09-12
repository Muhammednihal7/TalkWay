import 'package:flutter/material.dart';

/// A single reusable primary button used everywhere in the app instead of
/// writing ElevatedButton(...) with a loading spinner by hand each time.
/// Handles its own "loading" visual state so screens don't juggle that logic.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.outlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // Disable the button while a request is in flight so the user can't
    // double-tap and fire two login requests at once.
    final effectiveOnPressed = isLoading ? null : onPressed;

    final child = isLoading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    if (outlined) {
      return OutlinedButton(onPressed: effectiveOnPressed, child: child);
    }
    return ElevatedButton(onPressed: effectiveOnPressed, child: child);
  }
}

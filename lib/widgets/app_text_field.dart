import 'package:flutter/material.dart';

/// A reusable text field used across Login/Register/Edit Profile.
/// Wraps TextFormField so every input in the app looks and behaves
/// consistently (label, obscure-text toggle for passwords, validation).
class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  // Passwords start hidden; the user can tap the eye icon to reveal them.
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscure,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

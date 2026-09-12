import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/validators.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

/// Lets the user update their display name and (optionally) a profile
/// photo URL. A real "pick from gallery + upload" flow needs Firebase
/// Storage, which is intentionally out of scope for the core assignment —
/// noted here and in the README as a known limitation rather than silently
/// skipped.
class EditProfileScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _photoUrlController;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _photoUrlController = TextEditingController(text: widget.user.photoUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final userService = ref.read(userServiceProvider);
      await userService.updateProfile(
        uid: widget.user.uid,
        name: _nameController.text,
        photoUrl: _photoUrlController.text.trim().isEmpty
            ? null
            : _photoUrlController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _errorMessage = 'Could not save changes. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'Name',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline,
                  validator: Validators.name,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Photo URL (optional)',
                  hint: 'https://...',
                  controller: _photoUrlController,
                  prefixIcon: Icons.image_outlined,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                AppButton(
                  label: 'Save changes',
                  isLoading: _isSaving,
                  onPressed: _handleSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

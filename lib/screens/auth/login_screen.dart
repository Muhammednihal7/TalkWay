import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // A Form + GlobalKey is how Flutter validates multiple fields together —
  // calling _formKey.currentState!.validate() runs every field's validator
  // at once and returns false if any of them fail.
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    // Controllers hold native resources — always dispose them or you leak
    // memory every time this screen is rebuilt.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).login(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false, // clears the back stack so back-button can't return to Login
      );
    }
    // On failure we don't navigate — the error is shown below via authState.
  }

  @override
  Widget build(BuildContext context) {
    // Watching this rebuilds the screen whenever login/loading/error state
    // changes — that's what drives the button's spinner and the error text.
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Icon(Icons.call, size: 56, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Welcome back',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Log in to ${AppConstants.appName}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

                AppTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  controller: _passwordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline,
                  validator: Validators.password,
                ),

                // Error state — only shown when the last attempt failed.
                if (authState.hasError) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Theme.of(context).colorScheme.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.error.toString(),
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                AppButton(
                  label: 'Login',
                  isLoading: authState.isLoading,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: authState.isLoading
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            ),
                    child: const Text("Don't have an account? Create one"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

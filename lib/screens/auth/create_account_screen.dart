import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../core/app_environment.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    auth.clearError();
    final success = await auth.signUp(
      _emailController.text.trim(),
      _passwordController.text,
      displayName: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : null,
    );
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Account created successfully! Please sign in.')),
        );
        context.pop();
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    await auth.signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            margin: const EdgeInsets.all(AppTheme.spacing24),
            padding: const EdgeInsets.all(AppTheme.spacing32),
            decoration: BoxDecoration(
              color: AppTheme.bgSecondary,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(color: AppTheme.borderPrimary),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(LucideIcons.shield,
                          color: Colors.white, size: 36),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing24),
                  const Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  const Text(
                    'Join CyberSentinel as a security analyst.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing32),
                  if (auth.error != null)
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacing12),
                      margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border:
                            Border.all(color: AppTheme.error.withOpacity(0.5)),
                      ),
                      child: Text(
                        auth.error!,
                        style: const TextStyle(
                            color: AppTheme.error, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name (Optional)',
                      prefixIcon: const Icon(LucideIcons.user, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide:
                            const BorderSide(color: AppTheme.borderPrimary),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide:
                            const BorderSide(color: AppTheme.borderPrimary),
                      ),
                    ),
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(LucideIcons.mail, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide:
                            const BorderSide(color: AppTheme.borderPrimary),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide:
                            const BorderSide(color: AppTheme.borderPrimary),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Email is required' : null,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(LucideIcons.lock, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide:
                            const BorderSide(color: AppTheme.borderPrimary),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide:
                            const BorderSide(color: AppTheme.borderPrimary),
                      ),
                    ),
                    obscureText: true,
                    validator: (v) => (v == null || v.isEmpty || v.length < 6)
                        ? 'Password must be at least 6 characters'
                        : null,
                  ),
                  const SizedBox(height: AppTheme.spacing24),
                  ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleEmailSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spacing16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Create Account',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  if (AppEnvironment.enableGoogleAuth) ...[
                    const SizedBox(height: AppTheme.spacing24),
                    Row(
                      children: [
                        const Expanded(
                            child: Divider(color: AppTheme.borderPrimary)),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacing16),
                          child: Text('OR',
                              style: TextStyle(
                                  color: AppTheme.textTertiary, fontSize: 12)),
                        ),
                        const Expanded(
                            child: Divider(color: AppTheme.borderPrimary)),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing24),
                    OutlinedButton.icon(
                      onPressed: auth.isLoading ? null : _handleGoogleSignIn,
                      icon: const Icon(LucideIcons.chrome,
                          size: 18), // fallback for Google icon
                      label: const Text('Continue with Google'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacing16),
                        side: const BorderSide(color: AppTheme.borderPrimary),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTheme.spacing16),
                  TextButton(
                    onPressed: () {
                      context.read<AuthProvider>().clearError();
                      context.pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                    ),
                    child: const Text('Already have an account? Sign In'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

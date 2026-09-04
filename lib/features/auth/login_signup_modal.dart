import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/sanctuary_buttons.dart';
import '../../core/widgets/sanctuary_chips_badges.dart';
import '../../core/providers/mock_auth_provider.dart';

class LoginSignupModal extends ConsumerStatefulWidget {
  final String? gatedActionTitle;

  const LoginSignupModal({
    super.key,
    this.gatedActionTitle,
  });

  static Future<void> show(BuildContext context, {String? gatedActionTitle}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => LoginSignupModal(gatedActionTitle: gatedActionTitle),
    );
  }

  @override
  ConsumerState<LoginSignupModal> createState() => _LoginSignupModalState();
}

class _LoginSignupModalState extends ConsumerState<LoginSignupModal> {
  bool isSignUp = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all required credentials';
        _successMessage = null;
      });
      return;
    }

    if (isSignUp && password != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final notifier = ref.read(authNotifierProvider.notifier);
    bool success = false;

    if (isSignUp) {
      success = await notifier.signup(
        name: _nameController.text.trim(),
        email: email,
        password: password,
      );
    } else {
      success = await notifier.login(
        email: email,
        password: password,
      );
    }

    if (!mounted) return;

    final currentAuthState = ref.read(authNotifierProvider);

    if (success || currentAuthState.isAuthenticated) {
      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).pop();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = currentAuthState.errorMessage ?? 'Authentication failed. Please check your credentials.';
      });
    }
  }

  void _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Please enter a valid email address above first to reset your password.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final success = await ref.read(authNotifierProvider.notifier).sendPasswordReset(email: email);

    if (!mounted) return;

    if (success) {
      setState(() {
        _isLoading = false;
        _successMessage = 'Password reset email sent to $email. Please check your inbox!';
      });
    } else {
      final error = ref.read(authNotifierProvider).errorMessage;
      setState(() {
        _isLoading = false;
        _errorMessage = error ?? 'Failed to send password reset email.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Stack(
            children: [
              // Ambient Emerald Radial Light Glow
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryContainer.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Logo & Pulse badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.emeraldStrokeAlpha25,
                            ),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: AppTheme.primaryContainer,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'GraceGrid',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppTheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 8),
                        const LiveBadge(label: 'SANCTUARY'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Headline
                    Text(
                      isSignUp ? 'Join the Fellowship' : 'Welcome Back',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontSize: 26,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Sub-copy
                    Text(
                      widget.gatedActionTitle != null
                          ? 'Sign in to ${widget.gatedActionTitle!.toLowerCase()}, pray with others, and join live worship.'
                          : 'Sign in to post testimonies, pray with others, and join live fellowship rooms. (Scripture reading remains free & un-gated!)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Segmented Toggle (Log In / Sign Up)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLow,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: AppTheme.emeraldStrokeAlpha15),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => isSignUp = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !isSignUp ? AppTheme.primaryContainer : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Center(
                                  child: Text(
                                    'Log In',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: !isSignUp ? AppTheme.onPrimary : AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => isSignUp = true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSignUp ? AppTheme.primaryContainer : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Center(
                                  child: Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isSignUp ? AppTheme.onPrimary : AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Fields
                    if (isSignUp) ...[
                      _buildTextField(
                        controller: _nameController,
                        hintText: 'Display Name',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _buildTextField(
                      controller: _emailController,
                      hintText: 'Email or Phone Number',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                    ),
                    if (isSignUp) ...[
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        hintText: 'Confirm Password',
                        icon: Icons.lock_outline,
                        obscureText: true,
                      ),
                    ] else ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _handleForgotPassword,
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],

                    if (_successMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.emeraldStrokeAlpha40),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: AppTheme.primary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Primary Action Button
                    PrimarySanctuaryButton(
                      text: isSignUp ? 'Create Account' : 'Continue',
                      fullWidth: true,
                      isLoading: _isLoading,
                      onPressed: _handleSubmit,
                    ),

                    const SizedBox(height: 20),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppTheme.outlineVariant.withValues(alpha: 0.5))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or continue with',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AppTheme.outlineVariant.withValues(alpha: 0.5))),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Social Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GhostButton(
                            text: 'Google',
                            icon: Icons.g_mobiledata,
                            onPressed: () {
                              _emailController.text = 'believer@gmail.com';
                              _passwordController.text = 'password123';
                              _handleSubmit();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GhostButton(
                            text: 'Apple',
                            icon: Icons.apple,
                            onPressed: () {
                              _emailController.text = 'believer@apple.com';
                              _passwordController.text = 'password123';
                              _handleSubmit();
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Guest Footer Link
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Continue browsing as Guest',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurfaceVariant,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.emeraldStrokeAlpha25),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppTheme.onSurface, fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: AppTheme.onSurfaceVariant, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

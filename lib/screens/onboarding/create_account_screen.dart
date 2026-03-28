import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/content_strings.dart';
import '../../routes/route_names.dart';
import '../../theme/presnt_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/presnt/presnt_buttons.dart';
import '../../widgets/presnt/presnt_onboarding_progress.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      debugPrint('[CREATE_ACCOUNT] Starting createAccount for $email');
      await ref.read(authProvider.notifier).createAccount(name, email, password);
      debugPrint('[CREATE_ACCOUNT] createAccount completed successfully');
      final user = ref.read(authProvider);
      debugPrint('[CREATE_ACCOUNT] User state after create: uid=${user?.uid}, email=${user?.email}');
      if (mounted) {
        debugPrint('[CREATE_ACCOUNT] Navigating to faceUpload');
        context.goNamed(RouteNames.faceUpload);
      }
    } catch (e) {
      debugPrint('[CREATE_ACCOUNT] ERROR caught in screen: [${e.runtimeType}] $e');
      if (mounted) {
        final message = e.toString().replaceFirst('Exception: ', '').trim();
        setState(() {
          _error = message.isEmpty ? 'Account creation failed. Please try again.' : message;
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error!),
            backgroundColor: PresntTokens.tertiaryContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).loginWithGoogle();
      if (mounted) {
        context.goNamed(RouteNames.faceUpload);
      }
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '').trim();
      setState(() {
        _error = message.isEmpty ? 'Google sign-in failed. Please try again.' : message;
        _loading = false;
      });
    }
  }

  Future<void> _continueWithFacebook() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).loginWithFacebook();
      if (mounted) {
        context.goNamed(RouteNames.faceUpload);
      }
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '').trim();
      setState(() {
        _error = message.isEmpty ? 'Facebook sign-in failed. Please try again.' : message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PresntTokens.surface,
      body: Stack(
        children: [
          Positioned(
            top: -60,
            left: -40,
            child: _blob(PresntTokens.primary.withValues(alpha: 0.06)),
          ),
          Positioned(
            bottom: -50,
            right: -30,
            child: _blob(PresntTokens.secondary.withValues(alpha: 0.06)),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.goNamed(RouteNames.welcome);
                          }
                        },
                        icon: const Icon(Icons.arrow_back_rounded, color: PresntTokens.primary),
                      ),
                      Expanded(
                        child: Text(
                          'Create Account',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: PresntTokens.onSurface,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          'STEP 1 OF 6',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            letterSpacing: 2,
                            color: PresntTokens.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const PresntOnboardingProgress(step: 1, rightLabel: 'Account'),
                        const SizedBox(height: 32),
                        Text.rich(
                          TextSpan(
                            style: GoogleFonts.manrope(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                              letterSpacing: -1.2,
                              color: PresntTokens.onSurface,
                            ),
                            children: const [
                              TextSpan(text: 'Start your\n'),
                              TextSpan(
                                text: 'presence.',
                                style: TextStyle(color: PresntTokens.primary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Enter your details to begin crafting your high-fidelity AI persona.',
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            height: 1.5,
                            color: PresntTokens.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 36),
                        _LabeledField(
                          label: 'FULL NAME',
                          controller: _nameController,
                          hint: 'Alexander Voss',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 20),
                        _LabeledField(
                          label: 'EMAIL ADDRESS',
                          controller: _emailController,
                          hint: kSignInEmailHint,
                          icon: Icons.alternate_email_rounded,
                          keyboard: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        _LabeledField(
                          label: 'PASSWORD',
                          controller: _passwordController,
                          hint: '••••••••••••',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscure,
                          suffix: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: PresntTokens.surfaceBright,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: GoogleFonts.manrope(color: PresntTokens.tertiaryContainer, fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: 28),
                        if (_loading)
                          const Center(child: CircularProgressIndicator(color: PresntTokens.primary))
                        else
                          Column(
                            children: [
                              PresntGradientCta(
                                label: 'Continue',
                                trailing: const Icon(Icons.east_rounded, color: PresntTokens.onPrimaryFixed),
                                onPressed: _continue,
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _continueWithGoogle,
                                icon: const Icon(Icons.g_mobiledata_rounded),
                                label: const Text('Continue with Google'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                  foregroundColor: PresntTokens.onSurface,
                                  side: BorderSide(color: PresntTokens.outlineVariant.withValues(alpha: 0.3)),
                                ),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: _continueWithFacebook,
                                icon: const Icon(Icons.facebook_rounded),
                                label: const Text('Continue with Facebook'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                  foregroundColor: PresntTokens.onSurface,
                                  side: BorderSide(color: PresntTokens.outlineVariant.withValues(alpha: 0.3)),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => context.goNamed(RouteNames.signIn),
                          child: Text.rich(
                            TextSpan(
                              style: GoogleFonts.inter(fontSize: 13, color: PresntTokens.outline),
                              children: const [
                                TextSpan(text: 'Already have an account? '),
                                TextSpan(
                                  text: 'Sign in',
                                  style: TextStyle(
                                    color: PresntTokens.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text.rich(
                          TextSpan(
                            style: GoogleFonts.inter(fontSize: 11, color: PresntTokens.outline, height: 1.4),
                            children: const [
                              TextSpan(text: 'By continuing, you agree to our '),
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                  color: PresntTokens.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(Color c) {
    return IgnorePointer(
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboard;
  final bool obscure;
  final Widget? suffix;

  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboard,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
              color: PresntTokens.outline,
            ),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          obscureText: obscure,
          style: GoogleFonts.manrope(color: PresntTokens.onSurface, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: PresntTokens.surfaceBright.withValues(alpha: 0.7)),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            suffixIcon: suffix ??
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(icon, color: PresntTokens.surfaceBright.withValues(alpha: 0.6)),
                ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: PresntTokens.ctaPurple, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ],
    );
  }
}

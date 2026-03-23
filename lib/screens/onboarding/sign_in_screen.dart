import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/presnt_tokens.dart';
import '../../widgets/presnt/presnt_buttons.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authProvider.notifier).login(email, password);
      if (!mounted) return;
      context.goNamed(RouteNames.home);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '').trim();
      setState(() {
        _error = message.isEmpty ? 'Sign in failed. Please try again.' : message;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_error!),
          behavior: SnackBarBehavior.floating,
          backgroundColor: PresntTokens.tertiaryContainer,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PresntTokens.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sign in',
                    style: GoogleFonts.manrope(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: PresntTokens.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Continue your Presnt journey.',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: PresntTokens.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _field(
                    controller: _emailController,
                    hint: 'you@example.com',
                    icon: Icons.alternate_email_rounded,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: _passwordController,
                    hint: '••••••••',
                    icon: _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    obscure: _obscure,
                    onSuffixTap: () => setState(() => _obscure = !_obscure),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: GoogleFonts.manrope(fontSize: 13, color: PresntTokens.tertiaryContainer),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (_loading)
                    const Center(child: CircularProgressIndicator(color: PresntTokens.primary))
                  else
                    PresntGradientCta(
                      label: 'Sign In',
                      trailing: const Icon(Icons.login_rounded, color: PresntTokens.onPrimaryFixed),
                      onPressed: _signIn,
                    ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => context.goNamed(RouteNames.createAccount),
                    child: const Text('Need an account? Create one'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    VoidCallback? onSuffixTap,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.manrope(color: PresntTokens.onSurface, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: PresntTokens.surfaceBright.withValues(alpha: 0.7)),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        suffixIcon: IconButton(
          onPressed: onSuffixTap,
          icon: Icon(icon, color: PresntTokens.surfaceBright.withValues(alpha: 0.7)),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

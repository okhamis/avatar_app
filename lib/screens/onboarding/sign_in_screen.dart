import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/content_strings.dart';
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
  final _linkPasswordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _linkPasswordController.dispose();
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

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).loginWithGoogle();
      if (!mounted) return;
      context.goNamed(RouteNames.home);
    } on AuthLinkRequiredException catch (e) {
      if (!mounted) return;
      await _showLinkAccountDialog(e);
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '').trim();
      setState(() {
        _error = message.isEmpty ? 'Google sign-in failed. Please try again.' : message;
        _loading = false;
      });
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).loginWithFacebook();
      if (!mounted) return;
      context.goNamed(RouteNames.home);
    } on AuthLinkRequiredException catch (e) {
      if (!mounted) return;
      await _showLinkAccountDialog(e);
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '').trim();
      setState(() {
        _error = message.isEmpty ? 'Facebook sign-in failed. Please try again.' : message;
        _loading = false;
      });
    }
  }

  Future<void> _showLinkAccountDialog(AuthLinkRequiredException link) async {
    _linkPasswordController.clear();
    String dialogError = '';
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Link your account'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'An account already exists for ${link.email}. Sign in once with your password to link ${_providerLabel(link.pendingProviderId)}.',
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Existing sign-in methods: ${link.signInMethods.join(', ')}',
                    style: GoogleFonts.manrope(fontSize: 12, color: PresntTokens.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _linkPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Account password',
                    ),
                  ),
                  if (dialogError.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(dialogError, style: const TextStyle(color: Colors.redAccent)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref.read(authProvider.notifier).resolvePendingLinkWithEmailPassword(
                            email: link.email,
                            password: _linkPasswordController.text,
                          );
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                      if (!mounted) return;
                      context.goNamed(RouteNames.home);
                    } catch (e) {
                      setDialogState(() {
                        dialogError = e.toString().replaceFirst('Exception: ', '').trim();
                      });
                    }
                  },
                  child: const Text('Sign in & link'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _providerLabel(String providerId) {
    if (providerId == GoogleAuthProvider.PROVIDER_ID) return 'Google';
    if (providerId == FacebookAuthProvider.PROVIDER_ID) return 'Facebook';
    return providerId;
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
                    hint: kSignInEmailHint,
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
                    Column(
                      children: [
                        PresntGradientCta(
                          label: 'Sign In',
                          trailing: const Icon(Icons.login_rounded, color: PresntTokens.onPrimaryFixed),
                          onPressed: _signIn,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _signInWithGoogle,
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
                          onPressed: _signInWithFacebook,
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
                  const SizedBox(height: 10),
                  Text(
                    'Use the same login method each time to keep your family profile linked.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(fontSize: 12, color: PresntTokens.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
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

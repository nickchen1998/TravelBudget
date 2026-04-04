import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../constants/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // App icon placeholder
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.orange,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.flight, size: 52, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                l.appName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.signInDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.inkLight,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              if (auth.isLoading)
                const CircularProgressIndicator()
              else ...[
                if (Platform.isIOS)
                  MediaQuery.withNoTextScaling(
                    child: SignInWithAppleButton(
                      onPressed: () => _handleAppleSignIn(context),
                      height: 50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                if (Platform.isIOS) const SizedBox(height: 12),
                _GoogleSignInButton(
                  onPressed: () => _handleGoogleSignIn(context),
                ),
              ],
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAppleSignIn(BuildContext context) async {
    final l = AppLocalizations.of(context);
    try {
      await context.read<AuthProvider>().signInWithApple();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.signInFailed)),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    final l = AppLocalizations.of(context);
    try {
      await context.read<AuthProvider>().signInWithGoogle();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.signInFailed)),
        );
      }
    }
  }
}

// ── Google Sign-In Button ─────────────────────────────────────────────────

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GoogleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFDDDDDD)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://developers.google.com/identity/images/g-logo.png',
              height: 20,
              width: 20,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.g_mobiledata,
                size: 24,
                color: Color(0xFF4285F4),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context).signInWithGoogle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

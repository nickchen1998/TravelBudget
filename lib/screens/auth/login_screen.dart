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
              else
                MediaQuery.withNoTextScaling(
                  child: SignInWithAppleButton(
                    onPressed: () => _handleSignIn(context),
                    height: 50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignIn(BuildContext context) async {
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
}

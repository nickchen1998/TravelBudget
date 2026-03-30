import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';

class JoinTripScreen extends StatefulWidget {
  const JoinTripScreen({super.key});

  @override
  State<JoinTripScreen> createState() => _JoinTripScreenState();
}

class _JoinTripScreenState extends State<JoinTripScreen> {
  final _supabase = Supabase.instance.client;
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinTrip() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() { _isLoading = true; _error = null; });

    final l = AppLocalizations.of(context);
    final tripProvider = context.read<TripProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final result = await _supabase.rpc(
        'accept_invitation',
        params: {'token': code},
      );

      final tripUuid = result as String?;
      if (tripUuid == null) throw Exception('No trip returned');

      await tripProvider.loadTrips();
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text(l.joinSuccess),
          behavior: SnackBarBehavior.floating,
        ));
        navigator.pop();
      }
    } catch (e) {
      if (mounted) setState(() => _error = l.joinFailed);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signIn() async {
    final auth = context.read<AuthProvider>();
    final l = AppLocalizations.of(context);
    setState(() { _isLoading = true; _error = null; });
    try {
      await auth.signInWithApple();
    } catch (e) {
      if (mounted) setState(() => _error = '${l.signInFailed}: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: Text(l.joinWithCode)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Icon + title
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppTheme.orangeSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.vpn_key_outlined,
                        size: 44, color: AppTheme.orange),
                  ),
                  const SizedBox(height: 16),
                  Text(l.joinWithCode,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink)),
                  const SizedBox(height: 8),
                  Text(
                    l.joinWithCodeDesc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14, color: AppTheme.inkFaint),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            if (!auth.isLoggedIn) ...[
              // Must log in first
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warmWhite,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppTheme.parchment),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.loginRequired,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.ink)),
                    const SizedBox(height: 4),
                    Text(l.loginRequiredDesc,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.inkFaint)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading || auth.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                MediaQuery.withNoTextScaling(
                  child: SignInWithAppleButton(
                    onPressed: _signIn,
                    height: 50,
                    borderRadius:
                        const BorderRadius.all(Radius.circular(14)),
                  ),
                ),
            ] else ...[
              // Code input
              Text(l.enterInviteCode,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.inkLight)),
              const SizedBox(height: 10),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                  letterSpacing: 6,
                ),
                maxLength: 6,
                onSubmitted: (_) => _joinTrip(),
                decoration: InputDecoration(
                  hintText: 'XXXXXX',
                  hintStyle: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.parchment,
                    letterSpacing: 6,
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: AppTheme.warmWhite,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.parchment),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.parchment),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppTheme.orange, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isLoading ? null : _joinTrip,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(l.joinTrip,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(_error!,
                    style: const TextStyle(color: AppTheme.stampRed),
                    textAlign: TextAlign.center),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

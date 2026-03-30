import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';

class JoinTripScreen extends StatefulWidget {
  final String token;

  const JoinTripScreen({super.key, required this.token});

  @override
  State<JoinTripScreen> createState() => _JoinTripScreenState();
}

class _JoinTripScreenState extends State<JoinTripScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tryAutoJoin();
  }

  Future<void> _tryAutoJoin() async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      await _joinTrip();
    }
  }

  Future<void> _joinTrip() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final l = AppLocalizations.of(context);
    final tripProvider = context.read<TripProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final result = await _supabase.rpc(
        'accept_invitation',
        params: {'token': widget.token},
      );

      final tripUuid = result as String?;
      if (tripUuid == null) throw Exception('No trip returned');

      await tripProvider.loadTrips();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l.joinSuccess),
            behavior: SnackBarBehavior.floating,
          ),
        );
        navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = '${l.joinFailed}: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInAndJoin() async {
    final auth = context.read<AuthProvider>();
    final l = AppLocalizations.of(context);
    try {
      await auth.signInWithApple();
      if (mounted) await _joinTrip();
    } catch (e) {
      if (mounted) {
        setState(() => _error = '${l.signInFailed}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: Text(l.joinTrip),
        backgroundColor: AppTheme.cream,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.orangeSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.group_add,
                    size: 48, color: AppTheme.orange),
              ),
              const SizedBox(height: 24),
              Text(
                l.joinTrip,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink),
              ),
              const SizedBox(height: 8),
              Text(
                l.joinTripDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, color: AppTheme.inkFaint),
              ),
              const SizedBox(height: 32),
              if (_isLoading || auth.isLoading)
                const CircularProgressIndicator()
              else if (auth.isLoggedIn)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _joinTrip,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(l.joinTrip,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _signInAndJoin,
                    icon: const Icon(Icons.apple, size: 22),
                    label: Text(l.signInWithApple),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!,
                    style: const TextStyle(color: AppTheme.stampRed),
                    textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

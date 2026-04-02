import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/trip.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';

String _generateCode() {
  // Exclude easily-confused chars: 0/O, 1/I
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rng = Random.secure();
  return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
}

Future<String> _getOrCreateInviteCode(String tripUuid) async {
  final supabase = Supabase.instance.client;

  final existing = await supabase
      .from('trip_invitations')
      .select('invite_token')
      .eq('trip_id', tripUuid)
      .eq('role', 'editor')
      .gt('expires_at', DateTime.now().toIso8601String())
      .maybeSingle();

  if (existing != null) {
    return existing['invite_token'] as String;
  }

  final code = _generateCode();
  await supabase.from('trip_invitations').insert({
    'trip_id': tripUuid,
    'invited_by': supabase.auth.currentUser!.id,
    'invite_token': code,
    'role': 'editor',
    'max_uses': 20,
    'expires_at':
        DateTime.now().add(const Duration(days: 7)).toIso8601String(),
  });
  return code;
}

Future<void> showInviteCodeSheet(BuildContext context, Trip trip) async {
  final auth = context.read<AuthProvider>();
  final tripProvider = context.read<TripProvider>();
  final l = AppLocalizations.of(context);

  // --- Login gate ---
  if (!auth.isLoggedIn) {
    final shouldLogin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.shareTrip,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(l.signInToShare),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text(l.cancel, style: const TextStyle(color: AppTheme.inkLight)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.signInWithApple),
          ),
        ],
      ),
    );
    if (shouldLogin != true || !context.mounted) return;
    try {
      await auth.signInWithApple();
    } catch (_) {
      return;
    }
    if (!context.mounted) return;
  }

  // --- Sync gate ---
  Trip currentTrip = trip;
  if (trip.uuid == null) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(
      content: Text(l.syncing),
      behavior: SnackBarBehavior.floating,
    ));
    await auth.syncNow();
    await tripProvider.loadTrips();
    if (!context.mounted) return;
    messenger.hideCurrentSnackBar();

    final updated = tripProvider.trips.where((t) => t.id == trip.id).toList();
    if (updated.isEmpty || updated.first.uuid == null) {
      messenger.showSnackBar(SnackBar(
        content: Text(l.syncFailed),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    currentTrip = updated.first;
  }

  if (!context.mounted) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _InviteCodeSheet(tripUuid: currentTrip.uuid!),
  );
}

class _InviteCodeSheet extends StatefulWidget {
  final String tripUuid;
  const _InviteCodeSheet({required this.tripUuid});

  @override
  State<_InviteCodeSheet> createState() => _InviteCodeSheetState();
}

class _InviteCodeSheetState extends State<_InviteCodeSheet> {
  String? _code;
  bool _loading = true;
  String? _error;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final code = await _getOrCreateInviteCode(widget.tripUuid);
      if (mounted) setState(() { _code = code; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _regenerate() async {
    setState(() { _loading = true; _code = null; _error = null; _copied = false; });
    try {
      // Expire existing invitations for this trip first, then create a new one
      await Supabase.instance.client
          .from('trip_invitations')
          .delete()
          .eq('trip_id', widget.tripUuid)
          .eq('role', 'editor');
      final code = await _getOrCreateInviteCode(widget.tripUuid);
      if (mounted) setState(() { _code = code; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.parchment,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: AppTheme.orangeSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.vpn_key_outlined,
                    size: 32, color: AppTheme.orange),
              ),
              const SizedBox(height: 16),

              Text(l.inviteCode,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink)),
              const SizedBox(height: 6),
              Text(l.inviteCodeDesc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.inkFaint)),
              const SizedBox(height: 24),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(),
                )
              else if (_error != null)
                Text(_error!,
                    style: const TextStyle(color: AppTheme.stampRed),
                    textAlign: TextAlign.center)
              else ...[
                // Code display — no text scaling to prevent Dynamic Type wrapping
                MediaQuery.withNoTextScaling(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.cream,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.parchment),
                    ),
                    child: Text(
                      _code!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.orange,
                        letterSpacing: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(l.inviteCodeExpiry,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.inkFaint)),
                const SizedBox(height: 20),

                // Copy button — shows "已複製" after tapping
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: _copied
                      ? FilledButton.icon(
                          onPressed: null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.moss,
                            disabledBackgroundColor: AppTheme.moss,
                            disabledForegroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(l.codeCopied),
                        )
                      : FilledButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _code!));
                            setState(() => _copied = true);
                          },
                          icon: const Icon(Icons.copy, size: 18),
                          label: Text(l.copyCode),
                        ),
                ),
                const SizedBox(height: 10),

                // Regenerate
                TextButton(
                  onPressed: _regenerate,
                  child: Text(l.regenerateCode,
                      style: const TextStyle(
                          color: AppTheme.inkFaint, fontSize: 13)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

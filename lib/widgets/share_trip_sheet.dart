import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/trip.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';

String _generateToken() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final rng = Random.secure();
  return List.generate(24, (_) => chars[rng.nextInt(chars.length)]).join();
}

Future<String> _getOrCreateEditorLink(String tripUuid) async {
  final supabase = Supabase.instance.client;
  try {
    final existing = await supabase
        .from('trip_invitations')
        .select('invite_token')
        .eq('trip_id', tripUuid)
        .eq('role', 'editor')
        .gt('expires_at', DateTime.now().toIso8601String())
        .maybeSingle();

    String token;
    if (existing != null) {
      token = existing['invite_token'] as String;
    } else {
      token = _generateToken();
      await supabase.from('trip_invitations').insert({
        'trip_id': tripUuid,
        'invited_by': supabase.auth.currentUser!.id,
        'invite_token': token,
        'role': 'editor',
        'max_uses': 50,
        'expires_at':
            DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      });
    }

    return 'https://nickchen1998.github.io/TravelBudget/join?token=$token';
  } catch (_) {
    return '';
  }
}

/// Handles login + sync gating, then directly invokes the iOS share sheet.
Future<void> showShareTripSheet(BuildContext context, Trip trip) async {
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

    final updated =
        tripProvider.trips.where((t) => t.id == trip.id).toList();
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

  // --- Generate link + share ---
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(SnackBar(
    content: Text(l.preparingLink),
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 10),
  ));

  final link = await _getOrCreateEditorLink(currentTrip.uuid!);

  if (!context.mounted) return;
  messenger.hideCurrentSnackBar();

  if (link.isEmpty) {
    messenger.showSnackBar(SnackBar(
      content: Text(l.syncFailed),
      behavior: SnackBarBehavior.floating,
    ));
    return;
  }

  await Share.share(link);
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/trip.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';

class ShareTripSheet extends StatefulWidget {
  final Trip trip;

  const ShareTripSheet({super.key, required this.trip});

  @override
  State<ShareTripSheet> createState() => _ShareTripSheetState();
}

class _ShareTripSheetState extends State<ShareTripSheet> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  String? _copiedRole; // 複製成功後短暫顯示 check icon
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _generateToken() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random.secure();
    return List.generate(24, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<void> _loadData() async {
    if (widget.trip.uuid == null) return;
    try {
      final members = await _supabase
          .from('trip_members')
          .select('role, user_id, profiles(display_name, email)')
          .eq('trip_id', widget.trip.uuid!);
      if (mounted) setState(() => _members = List<Map<String, dynamic>>.from(members));
    } catch (_) {}
  }

  Future<String> _getOrCreateLink(String role) async {
    final tripUuid = widget.trip.uuid;
    if (tripUuid == null) return '';

    try {
      // Check existing valid invitation
      final existing = await _supabase
          .from('trip_invitations')
          .select('invite_token')
          .eq('trip_id', tripUuid)
          .eq('role', role)
          .gt('expires_at', DateTime.now().toIso8601String())
          .maybeSingle();

      String token;
      if (existing != null) {
        token = existing['invite_token'] as String;
      } else {
        token = _generateToken();
        await _supabase.from('trip_invitations').insert({
          'trip_id': tripUuid,
          'invited_by': _supabase.auth.currentUser!.id,
          'invite_token': token,
          'role': role,
          'max_uses': 50,
          'expires_at': DateTime.now()
              .add(const Duration(days: 7))
              .toIso8601String(),
        });
      }

      return 'https://nickchen1998.github.io/TravelBudget/join?token=$token';
    } catch (e) {
      return '';
    }
  }

  Future<void> _shareLink(BuildContext context, String role) async {
    setState(() => _isLoading = true);
    try {
      final link = await _getOrCreateLink(role);
      if (link.isEmpty) return;

      await Share.share(link);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _copyLink(String role) async {
    setState(() => _isLoading = true);
    try {
      final link = await _getOrCreateLink(role);
      if (link.isEmpty) return;
      await Clipboard.setData(ClipboardData(text: link));
      if (mounted) {
        setState(() => _copiedRole = role);
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => _copiedRole = null);
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.parchment,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(l.shareInviteTitle,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink)),
              const SizedBox(height: 4),
              Text(l.shareInviteDesc,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.inkFaint)),
              const SizedBox(height: 20),

              // Editor link
              _buildLinkTile(
                context,
                icon: Icons.edit_outlined,
                roleLabel: l.shareAsEditor,
                roleColor: AppTheme.orange,
                role: 'editor',
                onShare: () => _shareLink(context, 'editor'),
                onCopy: () => _copyLink('editor'),
              ),
              const SizedBox(height: 12),

              // Viewer link
              _buildLinkTile(
                context,
                icon: Icons.visibility_outlined,
                roleLabel: l.shareAsViewer,
                roleColor: AppTheme.moss,
                role: 'viewer',
                onShare: () => _shareLink(context, 'viewer'),
                onCopy: () => _copyLink('viewer'),
              ),

              // Members list
              if (_members.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(l.members,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink)),
                const SizedBox(height: 8),
                ..._members.map((m) {
                  final profile =
                      m['profiles'] as Map<String, dynamic>? ?? {};
                  final rawEmail = profile['email'] as String?;
                  final name = profile['display_name'] as String? ??
                      rawEmail?.split('@').first ??
                      '—';
                  final role = m['role'] as String;
                  final roleLabel = role == 'owner'
                      ? l.roleOwner
                      : role == 'editor'
                          ? l.roleEditor
                          : l.roleViewer;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.orangeSoft,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                                color: AppTheme.orange,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(name,
                              style:
                                  const TextStyle(color: AppTheme.ink)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: role == 'owner'
                                ? AppTheme.orangeSoft
                                : AppTheme.parchment,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(roleLabel,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: role == 'owner'
                                      ? AppTheme.orange
                                      : AppTheme.inkFaint)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkTile(
    BuildContext context, {
    required IconData icon,
    required String roleLabel,
    required Color roleColor,
    required String role,
    required VoidCallback onShare,
    required VoidCallback onCopy,
  }) {
    final isCopied = _copiedRole == role;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.parchment.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: roleColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(roleLabel,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppTheme.ink)),
          ),
          if (_isLoading)
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
          if (!_isLoading) ...[
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: IconButton(
                key: ValueKey(isCopied),
                icon: Icon(
                  isCopied ? Icons.check_circle : Icons.copy,
                  size: 20,
                ),
                color: isCopied ? AppTheme.moss : AppTheme.inkFaint,
                onPressed: isCopied ? null : onCopy,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.ios_share, size: 20),
              color: AppTheme.orange,
              onPressed: onShare,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shows the share sheet, handling login gate.
Future<void> showShareTripSheet(BuildContext context, Trip trip) async {
  final auth = context.read<AuthProvider>();
  final tripProvider = context.read<TripProvider>();
  final l = AppLocalizations.of(context);

  if (!auth.isLoggedIn) {
    // Show login prompt
    final shouldLogin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.shareTrip,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(l.signInToShare),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel,
                style: const TextStyle(color: AppTheme.inkLight)),
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

  // Ensure trip is synced before sharing
  Trip currentTrip = trip;
  if (trip.uuid == null) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l.syncing),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await auth.syncNow();
    await tripProvider.loadTrips();
    if (!context.mounted) return;
    messenger.hideCurrentSnackBar();

    final updated = tripProvider.trips.where((t) => t.id == trip.id).toList();
    if (updated.isEmpty || updated.first.uuid == null) {
      // Sync failed to assign uuid — show error and bail
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
    builder: (_) => ShareTripSheet(trip: currentTrip),
  );
}

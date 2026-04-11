import 'dart:async';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/ad_provider.dart';
import '../../models/trip.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/trip_provider.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/iap_prompt_dialog.dart';
import '../../widgets/trip_card.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/invite_code_widget.dart';
import '../join_trip_screen.dart';
import '../trip/trip_form_screen.dart';
import '../trip/trip_detail_screen.dart';
import '../overview/overview_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  bool _attRequested = false;
  bool _iapPromptChecked = false;

  // Auth state listener for auto-refresh on login
  AuthProvider? _authListenTarget;
  bool _wasLoggedIn = false;

  int get _tripLimit => context.read<AdProvider>().cloudTripLimit;

  bool _nearTripLimit(TripProvider provider) {
    final limit = _tripLimit;
    // 小限制（≤5）只在真正到上限時警告，避免從第 2 筆就叨念；
    // 大限制用 80% 閾值提前提醒。
    final threshold = limit <= 5 ? limit : (limit * 0.8).round();
    return provider.cloudTripCount >= threshold;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_attRequested) {
      _attRequested = true;
      Future.delayed(const Duration(seconds: 1), () async {
        if (!mounted) return;
        final status =
            await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
      });
    }

    final auth = context.read<AuthProvider>();
    if (_authListenTarget != auth) {
      _authListenTarget?.removeListener(_onAuthChanged);
      _authListenTarget = auth;
      _wasLoggedIn = auth.isLoggedIn;
      auth.addListener(_onAuthChanged);
    }
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final isLoggedIn = _authListenTarget?.isLoggedIn ?? false;
    if (isLoggedIn && !_wasLoggedIn) {
      context.read<TripProvider>().loadTrips();
    }
    _wasLoggedIn = isLoggedIn;
  }

  @override
  void dispose() {
    _authListenTarget?.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final titles = [l.appName, l.statsOverview, l.settings];

    final showAds = context.watch<AdProvider>().showAds;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: Text(titles[_currentTab])),
      body: Column(
        children: [
          _OfflineBanner(),
          Expanded(
            child: IndexedStack(
              index: _currentTab,
              children: [
                _buildTripsTab(),
                const OverviewScreen(),
                const SettingsScreen(),
              ],
            ),
          ),
          if (showAds) const BannerAdWidget(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (i) => setState(() => _currentTab = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.luggage_outlined),
            selectedIcon: const Icon(Icons.luggage),
            label: l.tabTrips,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: l.tabStats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l.tabSettings,
          ),
        ],
      ),
      floatingActionButton: _currentTab == 0
          ? FloatingActionButton(
              onPressed: () => _showAddOptions(context),
              child: const Icon(Icons.add, size: 28),
            )
          : null,
    );
  }

  Widget _buildTripsTab() {
    final l = AppLocalizations.of(context);
    return Consumer<TripProvider>(
      builder: (context, tripProvider, _) {
        // IAP prompt check (once per app session)
        if (!_iapPromptChecked && tripProvider.trips.isNotEmpty) {
          _iapPromptChecked = true;
          final adProvider = context.read<AdProvider>();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            IapPromptDialog.showIfNeeded(
              context,
              cloudTripCount: tripProvider.cloudTripCount,
              cloudTripLimit: _tripLimit,
              adsRemoved: adProvider.adsRemoved,
            );
          });
        }

        if (tripProvider.trips.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => tripProvider.loadTrips(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: AppTheme.orangeSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.flight_takeoff,
                          size: 36,
                          color: AppTheme.orange,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l.noTripsTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l.noTripsSubtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => tripProvider.loadTrips(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: tripProvider.trips.length + (_nearTripLimit(tripProvider) ? 1 : 0),
            itemBuilder: (context, index) {
              // 雲端旅行接近上限警告橫幅
              if (_nearTripLimit(tripProvider) && index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.cloudTripLimitWarning(tripProvider.cloudTripCount, _tripLimit),
                            style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final tripIndex = _nearTripLimit(tripProvider) ? index - 1 : index;
              final trip = tripProvider.trips[tripIndex];
              final spent = trip.id != null
                  ? tripProvider.getSpentForTrip(trip.id!)
                  : 0.0;
              return TripCard(
                trip: trip,
                spent: spent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TripDetailScreen(trip: trip),
                    ),
                  ).then((_) => tripProvider.loadTrips());
                },
                onDelete:
                    (trip.id != null || trip.uuid != null) &&
                        (trip.memberRole == null || trip.memberRole == 'owner')
                    ? () => _confirmDelete(context, tripProvider, trip)
                    : null,
                onLeave: trip.memberRole == 'editor' && trip.uuid != null
                    ? () => _confirmLeave(context, tripProvider, trip)
                    : null,
                onUploadToCloud: trip.uuid == null
                    ? () => _handleUploadToCloud(context, tripProvider, trip)
                    : null,
                onDownloadToLocal: trip.uuid != null &&
                        (trip.memberRole == null || trip.memberRole == 'owner')
                    ? () => _handleDownloadToLocal(context, tripProvider, trip)
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  void _showAddOptions(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tripProvider = context.read<TripProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.warmWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                _addOptionTile(
                  icon: Icons.luggage_outlined,
                  color: AppTheme.orange,
                  title: l.newTrip,
                  subtitle: l.newTripDesc,
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TripFormScreen()),
                    );
                    if (result == true && mounted) tripProvider.loadTrips();
                  },
                ),
                const SizedBox(height: 10),
                _addOptionTile(
                  icon: Icons.vpn_key_outlined,
                  color: AppTheme.moss,
                  title: l.joinWithCode,
                  subtitle: l.joinWithCodeDesc,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const JoinTripScreen()),
                    );
                  },
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _addOptionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.cream,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.parchment, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleUploadToCloud(
    BuildContext context,
    TripProvider provider,
    Trip trip,
  ) async {
    final l = AppLocalizations.of(context);
    final auth = context.read<AuthProvider>();

    // If not logged in, inform user and guide to login
    if (!auth.isLoggedIn) {
      final provider = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            l.uploadToCloud,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text('${l.signInDesc}\n\n${l.uploadToCloudDesc}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                l.cancel,
                style: const TextStyle(color: AppTheme.inkLight),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'google'),
              child: Text(l.signInWithGoogle),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'apple'),
              child: Text(l.signInWithApple),
            ),
          ],
        ),
      );
      if (provider == null || !context.mounted) return;

      try {
        if (provider == 'google') {
          await context.read<AuthProvider>().signInWithGoogle();
        } else {
          await context.read<AuthProvider>().signInWithApple();
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.signInFailed)));
        }
        return;
      }
      if (!context.mounted) return;
    } else {
      // Already logged in: confirm upload
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            l.uploadToCloud,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(l.uploadToCloudDesc),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                l.cancel,
                style: const TextStyle(color: AppTheme.inkLight),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.uploadToCloud),
            ),
          ],
        ),
      );
      if (confirm != true || !context.mounted) return;
    }

    // Perform upload
    final error = await provider.uploadLocalTripToCloud(trip);
    if (!context.mounted) return;

    if (error == 'trip_limit_exceeded') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.tripLimitTitle,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          content: Text(l.tripLimitDesc(_tripLimit)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.confirm),
            ),
          ],
        ),
      );
    } else if (error == 'network_required') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.networkRequiredError)));
    } else if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.saveFailed)));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.uploadSuccess)));
      // After upload, show invite code so user can share immediately
      final uploaded = provider.trips.firstWhere(
        (t) => t.id == trip.id,
        orElse: () => trip,
      );
      if (uploaded.uuid != null && context.mounted) {
        await showInviteCodeSheet(context, uploaded);
      }
    }
  }

  Future<void> _handleDownloadToLocal(
    BuildContext context,
    TripProvider provider,
    Trip trip,
  ) async {
    final l = AppLocalizations.of(context);

    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l.downloadToLocal,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(l.downloadToLocalDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l.cancel,
              style: const TextStyle(color: AppTheme.inkLight),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.downloadToLocal),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final error = await provider.downloadCloudTripToLocal(trip);
    if (!context.mounted) return;

    if (error == 'has_members') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.downloadToLocalHasMembers)),
      );
    } else if (error == 'network_required') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.networkRequiredError)),
      );
    } else if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.saveFailed)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.downloadToLocalSuccess)),
      );
    }
  }

  void _confirmDelete(BuildContext context, TripProvider provider, Trip trip) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l.deleteTrip,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(l.deleteTripConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l.cancel,
              style: const TextStyle(color: AppTheme.inkLight),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              String? error;
              if (trip.id != null) {
                error = await provider.deleteTrip(trip.id!);
              } else if (trip.uuid != null) {
                error = await provider.deleteTripByUuid(trip.uuid!);
              }
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context).networkRequiredError,
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.stampRed),
            child: Text(l.delete),
          ),
        ],
      ),
    );
  }

  void _confirmLeave(BuildContext context, TripProvider provider, Trip trip) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l.leaveTrip,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(l.leaveTripConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l.cancel,
              style: const TextStyle(color: AppTheme.inkLight),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final error = await provider.leaveTrip(trip.uuid!);
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context).networkRequiredError,
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.stampRed),
            child: Text(l.leave),
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityProvider>().isOnline;
    if (isOnline) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      color: Colors.orange.shade700,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l.offlineBanner,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/ad_provider.dart';
import '../../models/trip.dart';
import '../../providers/trip_provider.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/trip_card.dart';
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
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_attRequested) {
      _attRequested = true;
      // Delay ATT request so the app UI is visible first
      Future.delayed(const Duration(seconds: 1), () async {
        if (!mounted) return;
        final status = await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final titles = [l.appName, l.statsOverview, l.settings];

    final showAds = context.watch<AdProvider>().showAds;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: Text(titles[_currentTab]),
      ),
      body: Column(
        children: [
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
        if (tripProvider.trips.isEmpty) {
          return Center(
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
                  child: const Icon(Icons.flight_takeoff,
                      size: 36, color: AppTheme.orange),
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
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: tripProvider.trips.length,
          itemBuilder: (context, index) {
            final trip = tripProvider.trips[index];
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
              onDelete: (trip.id != null || trip.uuid != null) &&
                      (trip.memberRole == null || trip.memberRole == 'owner')
                  ? () => _confirmDelete(context, tripProvider, trip)
                  : null,
            );
          },
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
                    width: 40, height: 4,
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
                      MaterialPageRoute(
                          builder: (_) => const JoinTripScreen()),
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
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppTheme.ink)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.inkFaint)),
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

  void _confirmDelete(
      BuildContext context, TripProvider provider, Trip trip) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteTrip,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(l.deleteTripConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel,
                style: const TextStyle(color: AppTheme.inkLight)),
          ),
          TextButton(
            onPressed: () {
              if (trip.id != null) {
                provider.deleteTrip(trip.id!);
              } else if (trip.uuid != null) {
                provider.deleteTripByUuid(trip.uuid!);
              }
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.stampRed),
            child: Text(l.delete),
          ),
        ],
      ),
    );
  }
}

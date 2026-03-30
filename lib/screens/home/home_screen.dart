import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/ad_provider.dart';
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
  StreamSubscription<Uri>? _linkSub;

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    final appLinks = AppLinks();
    // Handle links when app is already running
    _linkSub = appLinks.uriLinkStream.listen(_handleDeepLink);
    // Handle initial link (app opened from cold start via link)
    appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    final bool isCustomScheme =
        uri.scheme == 'travelbudget' && uri.host == 'join';
    final bool isUniversalLink = uri.host == 'nickchen1998.github.io' &&
        uri.path == '/TravelBudget/join';

    if (isCustomScheme || isUniversalLink) {
      final token = uri.queryParameters['token'];
      if (token != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => JoinTripScreen(token: token),
          ),
        );
      }
    }
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
              onPressed: () async {
                final tripProvider = context.read<TripProvider>();
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TripFormScreen()),
                );
                if (result == true && mounted) {
                  tripProvider.loadTrips();
                }
              },
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
            final spent = tripProvider.getSpentForTrip(trip.id!);
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
              onDelete: () =>
                  _confirmDelete(context, tripProvider, trip.id!),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context, TripProvider provider, int tripId) {
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
              provider.deleteTrip(tripId);
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

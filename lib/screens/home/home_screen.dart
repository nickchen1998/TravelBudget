import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/trip_provider.dart';
import '../../widgets/trip_card.dart';
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

  static const _titles = ['旅算 TravelBudget', '統計總覽', '設定'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentTab]),
      ),
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildTripsTab(),
          const OverviewScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (i) => setState(() => _currentTab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.luggage_outlined),
            selectedIcon: Icon(Icons.luggage),
            label: '旅行',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: '統計',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
      floatingActionButton: _currentTab == 0
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TripFormScreen()),
                );
                if (result == true && mounted) {
                  context.read<TripProvider>().loadTrips();
                }
              },
              child: const Icon(Icons.add, size: 28),
            )
          : null,
    );
  }

  Widget _buildTripsTab() {
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
                const Text(
                  '還沒有旅行計畫',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '點擊下方按鈕，開始記錄你的旅程',
                  style: TextStyle(
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除旅行',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('確定要刪除此旅行嗎？所有相關的消費紀錄都會一併刪除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消',
                style: TextStyle(color: AppTheme.inkLight)),
          ),
          TextButton(
            onPressed: () {
              provider.deleteTrip(tripId);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.stampRed),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }
}

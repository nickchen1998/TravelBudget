import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'constants/app_theme.dart';
import 'db/database_helper.dart';
import 'providers/trip_provider.dart';
import 'providers/expense_provider.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  await initializeDateFormatting('zh_TW', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TripProvider()..loadTrips()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
      ],
      child: const TravelBudgetApp(),
    ),
  );
}

class TravelBudgetApp extends StatelessWidget {
  const TravelBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '旅算 TravelBudget',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeScreen(),
    );
  }
}

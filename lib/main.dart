import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'constants/app_theme.dart';
import 'db/database_helper.dart';
import 'l10n/app_localizations.dart';
import 'providers/ad_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/trip_provider.dart';
import 'providers/expense_provider.dart';
import 'services/ad_service.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  await AdService.initialize();
  await initializeDateFormatting('zh_TW', null);
  await initializeDateFormatting('ja', null);
  await initializeDateFormatting('ko', null);
  await initializeDateFormatting('zh_CN', null);
  await initializeDateFormatting('en', null);

  final localeProvider = LocaleProvider();
  await localeProvider.loadSavedLocale();

  final adProvider = AdProvider();
  await adProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: adProvider),
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
    final locale = context.watch<LocaleProvider>().locale;

    return MaterialApp(
      title: '熊好算 TravelBudget',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
    );
  }
}

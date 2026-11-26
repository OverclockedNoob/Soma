import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/premium_ui.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/stats_screen.dart';
import 'services/exercise_service.dart';
import 'services/storage_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  await WorkoutStorage.init();
  await CustomWorkoutStorage.init();
  await SettingsStorage.init();
  await ProgramStorage.init();

  // Loads all 500 exercises from the bundled local JSON asset.
  await ExerciseService.init();

  runApp(const WorkoutApp());
}

class WorkoutApp extends StatelessWidget {
  const WorkoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Soma',
      theme: ThemeData(
        fontFamily: 'Outfit',
        colorScheme: ColorScheme.fromSeed(
          seedColor: PUI.primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: PUI.bg,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: PUI.text(size: 20, weight: FontWeight.w800),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: PUI.surface,
          contentTextStyle: PUI.text(color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

/// Hosts the bottom tab bar and keeps each top-level tab mounted inside an
/// [IndexedStack] so scroll positions are preserved when switching tabs.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    ExerciseLibraryScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  void _onTabSelected(int index) {
    if (SettingsStorage.getSoundEffects()) {
      unawaited(SystemSound.play(SystemSoundType.click));
    }
    unawaited(HapticFeedback.lightImpact());
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PUI.bg,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: PremiumBottomBar(
        index: _selectedIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}

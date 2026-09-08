import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'services/storage_services.dart';
import 'services/exercisedb_service.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';
import 'core/premium_ui.dart';

void main() async {
  // Needed before touching any plugins (Hive, haptics, etc.) since we're async here
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Order matters a little here — settings and workouts don't depend on each other,
  // but I'm keeping them sequential for now since Hive boxes can be finicky
  // if opened concurrently. Can revisit with Future.wait if startup feels slow.
  await WorkoutStorage.init();
  await CustomWorkoutStorage.init();
  await SettingsStorage.init();
  await ProgramStorage.init();

  // Loads all ~500 exercises from the bundled JSON — no network call, so this
  // should be near-instant even on first launch.
  await ExerciseDbService.init();

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: PUI.primary,
          brightness: Brightness.dark, // app is dark-mode only for now
        ),
        scaffoldBackgroundColor: PUI.bg,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent, // let screen backgrounds show through
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

/// Handles the bottom tab bar and swapping between the four main sections
/// of the app. Using an IndexedStack instead of a plain if/switch so each
/// tab keeps its scroll position and state when you jump around.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // Built once in initState so we're not recreating screen widgets on every rebuild
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      HomeScreen(),
      ExerciseLibraryScreen(),
      StatisticsScreen(),
      SettingsScreen(),
    ];
  }

  void _onTabSelected(int index) {
    HapticFeedback.lightImpact(); // small tactile confirmation on tap
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
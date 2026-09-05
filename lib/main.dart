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
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await WorkoutStorage.init();
  await CustomWorkoutStorage.init();
  await SettingsStorage.init();
  await ProgramStorage.init();
  
  // 🚀 Loads the 500 exercises from your local JSON file instantly!
  await ExerciseDbService.init();

  runApp(const WorkoutApp());
}

class WorkoutApp extends StatelessWidget {
  const WorkoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Workout Tracker',
      theme: ThemeData(
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
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
    HapticFeedback.lightImpact();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PUI.bg,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: PremiumBottomBar(
        index: _selectedIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}
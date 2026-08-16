import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'services/storage_services.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await WorkoutStorage.init();
  await CustomWorkoutStorage.init();
  await SettingsStorage.init();
  await ProgramStorage.init(); // <--- ADD THIS LINE
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
          seedColor: const Color(0xFF6C5CE7),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        useMaterial3: true,
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
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF6C5CE7).withOpacity(0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: NavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedIndex: _selectedIndex,
        indicatorColor: const Color(0xFF6C5CE7).withOpacity(0.3),
        onDestinationSelected: _onTabSelected,
        animationDuration: const Duration(milliseconds: 300),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.grey.shade600),
            selectedIcon: const Icon(Icons.home, color: Color(0xFF6C5CE7)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.fitness_center_outlined,
              color: Colors.grey.shade600,
            ),
            selectedIcon: const Icon(
              Icons.fitness_center,
              color: Color(0xFF6C5CE7),
            ),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, color: Colors.grey.shade600),
            selectedIcon: const Icon(Icons.bar_chart, color: Color(0xFF6C5CE7)),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: Colors.grey.shade600),
            selectedIcon: const Icon(Icons.settings, color: Color(0xFF6C5CE7)),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}


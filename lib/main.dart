import 'dart:async';

import 'package:flutter/foundation.dart';
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

void main() {
  // Needed before touching any plugins (Hive, haptics, system chrome, etc.)
  WidgetsFlutterBinding.ensureInitialized();

  // App is dark-mode only, so keep status bar icons light even on screens
  // that don't have an AppBar to set this for us.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // Android
      statusBarBrightness: Brightness.dark, // iOS (dark bar = light icons)
    ),
  );

  // Storage init happens inside WorkoutApp so we can show a loading screen
  // while it runs and an error screen (with retry) if it fails, instead of
  // hanging on a blank screen.
  runApp(const WorkoutApp());
}

/// Opens all storage and loads bundled data.
///
/// Order matters a little here — settings and workouts don't depend on each
/// other, but they're kept sequential since Hive boxes can be finicky if
/// opened concurrently. Can revisit with Future.wait if startup feels slow.
///
/// Safe to call again for a retry: Hive.initFlutter and Hive.openBox both
/// tolerate repeat calls (openBox returns the already-open box).
Future<void> _initServices() async {
  try {
    // Skip path_provider lookup if a test harness already initialized Hive and
    // opened boxes in a temporary directory.
    if (!Hive.isBoxOpen('workouts')) {
      await Hive.initFlutter();
    }
    await WorkoutStorage.init();
    await CustomWorkoutStorage.init();
    await SettingsStorage.init();
    await ProgramStorage.init();
    // Loads all 500 exercises from the bundled JSON — no network call, so
    // this is fast, though it parses on the main isolate.
    await ExerciseService.init();
  } catch (e, st) {
    debugPrint('Startup failed: $e\n$st');
    rethrow;
  }
}

ThemeData _buildTheme() {
  return ThemeData(
    fontFamily: 'Outfit',
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: PUI.primary,
      brightness: Brightness.dark, // app is dark-mode only for now
    ),
    scaffoldBackgroundColor: PUI.bg,
    appBarTheme: AppBarTheme(
      backgroundColor:
          Colors.transparent, // let screen backgrounds show through
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
  );
}

class WorkoutApp extends StatefulWidget {
  final Future<void> Function()? initOverride;

  const WorkoutApp({super.key, this.initOverride});

  @override
  State<WorkoutApp> createState() => _WorkoutAppState();
}

class _WorkoutAppState extends State<WorkoutApp> {
  late Future<Object?> _initFuture;

  Future<Object?> _runInit() async {
    try {
      await (widget.initOverride ?? _initServices)();
      return null;
    } catch (e, st) {
      debugPrint('Startup failed: $e\n$st');
      return e;
    }
  }

  @override
  void initState() {
    super.initState();
    _initFuture = _runInit();
  }

  void _retry() {
    setState(() {
      _initFuture = _runInit();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Soma',
      theme: _buildTheme(),
      home: FutureBuilder<Object?>(
        future: _initFuture,
        builder: (BuildContext context, AsyncSnapshot<Object?> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _StartupLoadingScreen();
          }
          final startupError = snapshot.data ?? snapshot.error;
          if (startupError != null) {
            return _StartupErrorScreen(
              error: startupError,
              onRetry: _retry,
            );
          }
          return const MainNavigationScreen();
        },
      ),
    );
  }
}

class _StartupLoadingScreen extends StatelessWidget {
  const _StartupLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: PUI.bg,
      body: Center(
        child: CircularProgressIndicator(color: PUI.primary),
      ),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _StartupErrorScreen({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PUI.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white70,
                  size: 56,
                ),
                const SizedBox(height: 16),
                Text(
                  "Couldn't start Soma",
                  style: PUI.text(size: 20, weight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Something went wrong while loading your data. '
                  'Your workouts have not been deleted. Try again, and if '
                  'it keeps happening, restart the app.',
                  style: PUI.text(
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                // Raw error text is only useful to us, not to end users.
                if (kDebugMode) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    '$error',
                    style: PUI.text(
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
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
  // Const instances, so there's nothing to rebuild or cache in initState.
  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    ExerciseLibraryScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  int _selectedIndex = 0;

  // Tabs are only built the first time they're opened, so startup doesn't
  // pay for screens the user may never visit. Once built, they stay alive
  // inside the IndexedStack and keep their state.
  late final List<bool> _visited =
      List<bool>.generate(_pages.length, (int i) => i == 0);

  void _onTabSelected(int index) {
    if (index == _selectedIndex) return; // already here, nothing to do
    if (SettingsStorage.getSoundEffects()) {
      unawaited(SystemSound.play(SystemSoundType.click));
    }
    unawaited(HapticFeedback.lightImpact()); // small tactile confirmation on tap
    setState(() {
      _selectedIndex = index;
      _visited[index] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // On Android, back from any other tab returns to Home first. Only back
    // from Home actually leaves the app.
    return PopScope<void>(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (bool didPop, void _) {
        if (!didPop) _onTabSelected(0);
      },
      child: Scaffold(
        backgroundColor: PUI.bg,
        body: IndexedStack(
          index: _selectedIndex,
          children: <Widget>[
            for (var i = 0; i < _pages.length; i++)
              if (_visited[i])
                // Pause tickers/animations in tabs that aren't showing.
                TickerMode(
                  enabled: i == _selectedIndex,
                  child: _pages[i],
                )
              else
                const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: PremiumBottomBar(
          index: _selectedIndex,
          onTap: _onTabSelected,
        ),
      ),
    );
  }
}

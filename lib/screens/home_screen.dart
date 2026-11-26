import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/event_bus.dart';
import '../core/premium_ui.dart';
import '../models/workout_models.dart';
import '../services/storage_services.dart';
import '../services/streak_service.dart';
import '../widgets/vibe_check_sheet.dart';
import 'calendar_screen.dart';
import 'my_workouts_screen.dart';
import 'stats_screen.dart';
import 'workout_builder_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int totalWorkouts = 0;
  int currentStreak = 0;
  int totalCalories = 0;
  int recoveryCoins = 0;
  List<double> weeklyData = List<double>.filled(7, 0.0);
  int weeklyWorkoutCount = 0;
  String _userName = 'Champion';
  bool _showReminders = true;
  bool _completedToday = false;

  String? _todaysWorkoutName;
  List<Map<String, dynamic>>? _todaysExercises;
  bool _isTodayRestDay = false;

  bool _isLoaded = false;
  Timer? _introTimer;

  @override
  void initState() {
    super.initState();
    _loadData();

    WorkoutEventBus.instance.revision.addListener(_onWorkoutDataChanged);

    _introTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isLoaded = true);
    });
  }

  void _onWorkoutDataChanged() {
    if (mounted) {
      _loadData();
    }
  }

  @override
  void dispose() {
    _introTimer?.cancel();
    WorkoutEventBus.instance.revision.removeListener(_onWorkoutDataChanged);
    super.dispose();
  }

  void _loadData() {
    final sessions = WorkoutStorage.getAllWorkoutSessions();
    final thisWeekSessions = WorkoutStorage.getWorkoutSessionsThisWeek();
    final userName = SettingsStorage.getUserName();
    final showReminders = SettingsStorage.getNotifications();
    final activeProgram = ProgramStorage.getActiveProgramModel();
    final today = DateTime.now();
    final todayKey = formatDateKey(today);

    String? todaysName;
    List<Map<String, dynamic>>? todaysExercises;
    bool isRest = false;

    if (activeProgram != null && activeProgram.isDateInRange(today)) {
      if (activeProgram.isScheduledRestDay(today)) {
        isRest = true;
      } else {
        final workoutId = activeProgram.workoutIdForDate(today);
        final routine = CustomWorkoutStorage.getRoutineById(workoutId);
        if (routine != null) {
          todaysName = routine.name;
          todaysExercises = routine.exercises
              .map((RoutineExercise e) => e.toMap())
              .toList();
        }
      }
    }

    final progress = List<double>.filled(7, 0.0);
    for (final session in thisWeekSessions) {
      final day = session.dayUtc;
      if (day != null) {
        final idx = day.weekday - 1;
        if (idx >= 0 && idx < 7) progress[idx] = 1.0;
      }
    }

    setState(() {
      _userName = userName;
      _showReminders = showReminders;
      _todaysWorkoutName = todaysName;
      _todaysExercises = todaysExercises;
      _isTodayRestDay = isRest;
      _completedToday = sessions.any((WorkoutSession s) => s.date == todayKey);
      totalWorkouts = sessions.length;
      totalCalories = sessions.fold<int>(
        0,
        (int sum, WorkoutSession s) => sum + s.calories,
      );
      currentStreak = StreakService.calculateCurrentStreak();
      weeklyData = progress;
      weeklyWorkoutCount = progress.where((double d) => d > 0).length;
      recoveryCoins = SettingsStorage.getRecoveryCoins();
    });
  }

  void _showVibeCheck(List<Map<String, dynamic>>? exercises, String name) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => VibeCheckSheet(
          originalExercises: exercises ?? const <Map<String, dynamic>>[],
          workoutName: name,
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 0 && hour < 5) return 'Working Late';
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  String _formatCalories(int calories) => calories >= 1000
      ? '${(calories / 1000).toStringAsFixed(1)}k'
      : '$calories';

  Widget _buildAnimatedSection({required Widget child}) {
    return AnimatedOpacity(
      opacity: _isLoaded ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _isLoaded ? Offset.zero : const Offset(0, 0.12),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showStreakReminder =
        _showReminders && !_completedToday && !_isTodayRestDay && currentStreak > 0;

    return Scaffold(
      backgroundColor: PUI.bg,
      body: Stack(
        children: <Widget>[
          const AuroraBackground(),
          SafeArea(
            child: RefreshIndicator(
              color: PUI.primary,
              backgroundColor: PUI.bg,
              onRefresh: () async => _loadData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildAnimatedSection(child: _buildHeader()),
                    if (showStreakReminder) ...<Widget>[
                      const SizedBox(height: 16),
                      _buildAnimatedSection(child: _buildReminderBanner()),
                    ],
                    const SizedBox(height: 20),
                    _buildAnimatedSection(child: _buildMissionCard()),
                    const SizedBox(height: 16),
                    _buildAnimatedSection(child: _buildStatsRow()),
                    const SizedBox(height: 16),
                    _buildAnimatedSection(child: _buildWeeklyChart()),
                    const SizedBox(height: 24),
                    _buildAnimatedSection(child: _buildQuickActions()),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final progress = weeklyWorkoutCount / 7;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _getGreeting().toUpperCase(),
                  style: PUI.text(
                    size: 11,
                    weight: FontWeight.w600,
                    letterSpacing: 2.2,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 6),
                GradientText(_userName, size: 32),
              ],
            ),
          ),
          SizedBox(
            width: 54,
            height: 54,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                CustomPaint(
                  size: const Size(54, 54),
                  painter: _RingPainter(progress),
                ),
                Text(
                  '$weeklyWorkoutCount/7',
                  style: PUI.text(size: 11, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Glass(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.notifications_active_outlined,
              color: PUI.amber,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Keep your $currentStreak-day streak alive — train or freeze today!',
                style: PUI.text(
                  size: 12,
                  weight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionCard() {
    final rest = _isTodayRestDay;
    final missionTitle = rest
        ? 'Recovery Day 🧘'
        : (_todaysWorkoutName ?? 'Quick Workout');
    final subtitle = rest
        ? 'You earned it. Recover and grow.'
        : (_completedToday
            ? 'Completed today — tap for a bonus session'
            : 'Tap to begin your session');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Pressable(
        onTap: () {
          if (rest) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Rest day! Enjoy your recovery. 🧘'),
              ),
            );
          } else {
            _showVibeCheck(
              _todaysExercises,
              _todaysWorkoutName ?? 'Quick Workout',
            );
          }
        },
        child: Glass(
          radius: 28,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "TODAY'S MISSION",
                        style: PUI.text(
                          size: 11,
                          weight: FontWeight.w700,
                          letterSpacing: 2.2,
                          color: PUI.mint.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        missionTitle,
                        style: PUI.text(size: 22, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: PUI.text(
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: rest
                        ? null
                        : const LinearGradient(
                            colors: <Color>[PUI.primary, PUI.primaryDeep],
                          ),
                    color: rest ? Colors.white.withValues(alpha: 0.08) : null,
                    shape: BoxShape.circle,
                    boxShadow: rest
                        ? const <BoxShadow>[]
                        : <BoxShadow>[
                            BoxShadow(
                              color: PUI.primary.withValues(alpha: 0.5),
                              blurRadius: 16,
                            ),
                          ],
                  ),
                  child: Icon(
                    rest
                        ? Icons.self_improvement
                        : (_completedToday
                            ? Icons.check_rounded
                            : Icons.play_arrow),
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: <Widget>[
          _buildStatTile(
            'WORKOUTS',
            '$totalWorkouts',
            Icons.fitness_center,
            PUI.primary,
          ),
          const SizedBox(width: 10),
          _buildStatTile(
            'STREAK',
            '$currentStreak',
            Icons.local_fire_department,
            PUI.flame,
            valueGradient: const <Color>[PUI.flame, PUI.amber],
          ),
          const SizedBox(width: 10),
          _buildStatTile(
            'KCAL',
            _formatCalories(totalCalories),
            Icons.bolt,
            PUI.amber,
          ),
          const SizedBox(width: 10),
          _buildStatTile(
            'COINS',
            '$recoveryCoins',
            Icons.shield,
            PUI.mint,
            onTap: _showRecoveryBankPopup,
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    IconData icon,
    Color accent, {
    List<Color>? valueGradient,
    VoidCallback? onTap,
  }) {
    final content = Glass(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              icon,
              color: accent,
              size: 18,
              shadows: <Shadow>[
                Shadow(
                  color: accent.withValues(alpha: 0.8),
                  blurRadius: 10,
                ),
              ],
            ),
            const SizedBox(height: 10),
            valueGradient != null
                ? GradientText(value, size: 20, colors: valueGradient)
                : Text(
                    value,
                    style: PUI.text(size: 20, weight: FontWeight.w800),
                  ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: PUI.text(
                  size: 9,
                  weight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return Expanded(
      child: onTap == null ? content : Pressable(onTap: onTap, child: content),
    );
  }

  Widget _buildWeeklyChart() {
    const days = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayIndex = DateTime.now().weekday - 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Glass(
        radius: 24,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'THIS WEEK',
                    style: PUI.text(
                      size: 12,
                      weight: FontWeight.w700,
                      letterSpacing: 1.8,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  Pressable(
                    onTap: () => unawaited(
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const StatisticsScreen(),
                        ),
                      ),
                    ),
                    child: Text(
                      'SEE ALL',
                      style: PUI.text(
                        size: 11,
                        weight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: PUI.mint,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 110,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List<Widget>.generate(7, (int i) {
                    final active = weeklyData[i] > 0;
                    final isToday = i == todayIndex;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          height: active ? (isToday ? 105 : 75) : 12,
                          decoration: BoxDecoration(
                            gradient: active
                                ? const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: <Color>[
                                      PUI.primary,
                                      PUI.primaryDeep,
                                    ],
                                  )
                                : null,
                            color: active
                                ? null
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: (active && isToday)
                                ? <BoxShadow>[
                                    BoxShadow(
                                      color: PUI.primary.withValues(
                                        alpha: 0.55,
                                      ),
                                      blurRadius: 16,
                                    ),
                                  ]
                                : const <BoxShadow>[],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: List<Widget>.generate(7, (int i) {
                  final isToday = i == todayIndex;
                  return Expanded(
                    child: Center(
                      child: Text(
                        days[i],
                        style: PUI.text(
                          size: 10,
                          weight: isToday ? FontWeight.w800 : FontWeight.w500,
                          color: isToday
                              ? PUI.mint
                              : Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'QUICK ACTIONS',
            style: PUI.text(
              size: 12,
              weight: FontWeight.w700,
              letterSpacing: 1.8,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 14),
          Pressable(
            onTap: () {
              unawaited(
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const MyWorkoutsScreen(),
                  ),
                ),
              );
            },
            child: Glass(
              radius: 22,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            PUI.primary.withValues(alpha: 0.35),
                            PUI.primary.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.folder_outlined,
                        color: PUI.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'My Workouts',
                            style: PUI.text(size: 16, weight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'View, edit, or start your custom routines',
                            style: PUI.text(
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _buildActionCard(
                'Start Workout',
                Icons.play_circle_fill,
                PUI.primary,
                () => _showVibeCheck(null, 'Quick Workout'),
              ),
              const SizedBox(width: 12),
              _buildActionCard(
                'Custom Plan',
                Icons.edit_note,
                PUI.pink,
                () {
                  unawaited(
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const WorkoutBuilderScreen(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _buildActionCard(
                'Weekly Split',
                Icons.calendar_month,
                PUI.mint,
                () => unawaited(
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const CalendarScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildActionCard(
                'My Progress',
                Icons.trending_up,
                PUI.amber,
                () => unawaited(
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const StatisticsScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return Expanded(
      child: Pressable(
        onTap: onTap,
        child: Glass(
          radius: 22,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            color.withValues(alpha: 0.35),
                            color.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 11,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: PUI.text(size: 14, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRecoveryBankPopup() {
    final todayStr = formatDateKey(DateTime.now());
    final isAlreadyFrozen = SettingsStorage.isDateFrozen(todayStr);

    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: PUI.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        builder: (BuildContext sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: PUI.mint.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield,
                  color: PUI.mint,
                  size: 40,
                  shadows: <Shadow>[
                    Shadow(
                      color: PUI.mint.withValues(alpha: 0.8),
                      blurRadius: 14,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Recovery Bank',
                style: PUI.text(size: 22, weight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'You have $recoveryCoins Recovery Coins',
                style: PUI.text(
                  size: 15,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              if (isAlreadyFrozen)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PUI.mint.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: PUI.mint.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.check_circle, color: PUI.mint),
                      const SizedBox(width: 8),
                      Text(
                        "Today's streak is frozen! ❄️",
                        style: PUI.text(
                          color: PUI.mint,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: recoveryCoins > 0
                        ? () => _spendCoinAndFreeze(sheetContext, todayStr)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: recoveryCoins > 0
                          ? PUI.primary
                          : Colors.grey.shade800,
                      disabledBackgroundColor: Colors.grey.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      recoveryCoins > 0
                          ? 'Freeze Streak (1 Coin)'
                          : 'Not enough coins',
                      style: PUI.text(size: 16, weight: FontWeight.w700),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
      ),
    );
  }

  Future<void> _spendCoinAndFreeze(
    BuildContext sheetContext,
    String dateStr,
  ) async {
    final navigator = Navigator.of(sheetContext);
    final messenger = ScaffoldMessenger.of(context);

    final success = await SettingsStorage.spendCoinAndFreezeDate(dateStr);
    if (!success) return;
    if (!mounted) return;

    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: <Widget>[
            const Icon(Icons.ac_unit, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Streak frozen for today! ❄️',
              style: PUI.text(weight: FontWeight.w700),
            ),
          ],
        ),
        backgroundColor: PUI.primary,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * pi, false, bgPaint);
    if (progress <= 0) return;
    final fillPaint = Paint()
      ..shader = const SweepGradient(
        colors: <Color>[PUI.primary, PUI.mint],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress.clamp(0.0, 1.0),
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

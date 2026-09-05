import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workout_tracker/services/storage_services.dart';
import 'active_workout_screen.dart';
import 'workout_builder_screen.dart';
import 'stats_screen.dart';
import 'library_screen.dart';
import 'split_builder_screen.dart';
import 'calendar_screen.dart';
import '../core/premium_ui.dart';
import '../widgets/vibe_check_sheet.dart';

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
  List<double> weeklyData = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
  int weeklyWorkoutCount = 0;
  String _userName = 'Mitesh';

  Map<String, dynamic>? _activeProgram;
  String? _todaysWorkoutName;
  List<Map<String, dynamic>>? _todaysExercises;
  bool _isTodayRestDay = false;

  static const List<String> _fullDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isLoaded = true);
    });
  }

  void _loadData() {
    final workouts = WorkoutStorage.getAllWorkouts();
    _userName = SettingsStorage.getUserName();
    final programs = ProgramStorage.getAllPrograms();

    _activeProgram = null;
    _todaysWorkoutName = null;
    _todaysExercises = null;
    _isTodayRestDay = false;

    if (programs.isNotEmpty) {
      _activeProgram = programs.last;
      final rawSchedule = _activeProgram!['schedule'];

      if (rawSchedule != null) {
        final schedule = Map<String, dynamic>.from(rawSchedule as Map);
        final today = DateTime.now();
        final dayName = _fullDays[today.weekday - 1];
        final workoutId = schedule[dayName];

        if (workoutId == null) {
          _isTodayRestDay = true;
        } else {
          _isTodayRestDay = false;
          final savedWorkouts = CustomWorkoutStorage.getAllCustomWorkouts();
          final workout = savedWorkouts.firstWhere(
            (w) => w['id'] == workoutId,
            orElse: () => {},
          );
          _todaysWorkoutName = workout['name'] as String?;

          if (workout['exercises'] != null) {
            _todaysExercises =
                (workout['exercises'] as List)
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList();
          }
        }
      }
    }

    setState(() {
      totalWorkouts = workouts.length;
      totalCalories = workouts.fold(
        0,
        (sum, w) => sum + ((w['calories'] as int?) ?? 0),
      );
      currentStreak = _calculateStreak(workouts);
      weeklyData = _getWeeklyData(workouts);
      weeklyWorkoutCount = weeklyData.where((d) => d > 0).length;
      recoveryCoins = SettingsStorage.getRecoveryCoins();
    });
  }

  void _showVibeCheck(List<Map<String, dynamic>>? exercises, String name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VibeCheckSheet(
        originalExercises: exercises ?? [],
        workoutName: name,
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 0 && hour < 5) return "Working Late";
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    if (hour < 21) return "Good Evening";
    return "Good Night";
  }

  // 🛡️ UPGRADED STREAK LOGIC: Respects Frozen Dates and Rest Days!
  int _calculateStreak(List<Map<String, dynamic>> workouts) {
    if (workouts.isEmpty) return 0;
    
    // Build set of workout dates
    final workoutDates = <DateTime>{};
    for (var w in workouts) {
      try {
        final d = DateTime.parse(w['date'] as String);
        workoutDates.add(DateTime(d.year, d.month, d.day));
      } catch (_) {}
    }
    
    // Build set of frozen dates
    final frozenDates = <DateTime>{};
    for (final dateStr in SettingsStorage.getFrozenDates()) {
      try {
        final d = DateTime.parse(dateStr);
        frozenDates.add(DateTime(d.year, d.month, d.day));
      } catch (_) {}
    }
    
    // Build set of rest days from program schedule (look back 30 days)
    final restDays = <DateTime>{};
    if (_activeProgram != null && _activeProgram!['schedule'] != null) {
      final schedule = Map<String, dynamic>.from(_activeProgram!['schedule'] as Map);
      final today = DateTime.now();
      for (int i = 0; i < 30; i++) {
        final d = today.subtract(Duration(days: i));
        final dayName = _fullDays[d.weekday - 1];
        if (schedule[dayName] == null) {
          restDays.add(DateTime(d.year, d.month, d.day));
        }
      }
    }
    
    // Start streak calculation
    final today = DateTime.now();
    DateTime check = DateTime(today.year, today.month, today.day);
    int streak = 0;
    
    // Grace period: if today hasn't been worked yet and isn't frozen/rest, go back one day
    if (!workoutDates.contains(check) && !frozenDates.contains(check) && !restDays.contains(check)) {
      check = check.subtract(const Duration(days: 1));
    }
    
    // Walk backwards, counting worked days, skipping frozen and rest days
    while (workoutDates.contains(check) || frozenDates.contains(check) || restDays.contains(check)) {
      if (workoutDates.contains(check)) {
        streak++;
      }
      check = check.subtract(const Duration(days: 1));
    }
    
    return streak;
  }

  List<double> _getWeeklyData(List<Map<String, dynamic>> workouts) {
    final weeklyProgress = List<double>.filled(7, 0.0);
    if (workouts.isEmpty) return weeklyProgress;
    final today = DateTime.now();
    final startOfWeek = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - 1),
    );
    for (var workout in workouts) {
      try {
        final workoutDate = DateTime.parse(workout['date'] as String);
        if (workoutDate.isAfter(
              startOfWeek.subtract(const Duration(days: 1)),
            ) &&
            workoutDate.isBefore(startOfWeek.add(const Duration(days: 7)))) {
          final dayIndex = workoutDate.weekday - 1;
          if (dayIndex >= 0 && dayIndex < 7) weeklyProgress[dayIndex] = 1.0;
        }
      } catch (_) {}
    }
    return weeklyProgress;
  }

  String _formatCalories(int calories) =>
      calories >= 1000 ? "${(calories / 1000).toStringAsFixed(1)}k" : "$calories";

  Widget _buildAnimatedSection({required Widget child}) {
    return AnimatedOpacity(
      opacity: _isLoaded ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _isLoaded ? Offset.zero : const Offset(0, 0.2),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PUI.bg,
      body: Stack(
        children: [
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
                  children: [
                    _buildAnimatedSection(child: _buildHeader()),
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
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting().toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.2,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 6),
              GradientText(_userName, size: 32),
            ],
          ),
          SizedBox(
            width: 54,
            height: 54,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(54, 54),
                  painter: _RingPainter(progress),
                ),
                Text(
                  "$weeklyWorkoutCount/7",
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard() {
    final rest = _isTodayRestDay;
    return Pressable(
      onTap: () {
        if (rest) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Rest day! Enjoy your recovery. 🧘")),
          );
        } else {
          _showVibeCheck(_todaysExercises, _todaysWorkoutName ?? "Workout");
        }
      },
      child: Glass(
        radius: 28,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TODAY'S MISSION",
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.2,
                        color: PUI.mint.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      rest ? "Recovery Day 🧘" : (_todaysWorkoutName ?? "Quick Workout"),
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rest ? "You earned it. Recover and grow." : "Tap to begin your session",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
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
                      : const LinearGradient(colors: [PUI.primary, PUI.primaryDeep]),
                  color: rest ? Colors.white.withOpacity(0.08) : null,
                  shape: BoxShape.circle,
                  boxShadow: rest
                      ? []
                      : [BoxShadow(color: PUI.primary.withOpacity(0.5), blurRadius: 16)],
                ),
                child: Icon(
                  rest ? Icons.self_improvement : Icons.play_arrow,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          _buildStatTile("WORKOUTS", "$totalWorkouts", Icons.fitness_center, PUI.primary),
          const SizedBox(width: 10),
          _buildStatTile("STREAK", "$currentStreak", Icons.local_fire_department, PUI.flame,
              valueGradient: [PUI.flame, PUI.amber]),
          const SizedBox(width: 10),
          _buildStatTile("KCAL", _formatCalories(totalCalories), Icons.bolt, PUI.amber),
          const SizedBox(width: 10),
          _buildStatTile("COINS", "$recoveryCoins", Icons.shield, PUI.mint,
              onTap: _showRecoveryBankPopup),
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
          children: [
            Icon(
              icon,
              color: accent,
              size: 18,
              shadows: [Shadow(color: accent.withOpacity(0.8), blurRadius: 10)],
            ),
            const SizedBox(height: 10),
            valueGradient != null
                ? GradientText(value, size: 20, colors: valueGradient)
                : Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: Colors.white.withOpacity(0.4),
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
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayIndex = DateTime.now().weekday - 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Glass(
        radius: 24,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "THIS WEEK",
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  Pressable(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StatisticsScreen()),
                    ),
                    child: Text(
                      "SEE ALL",
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
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
                  children: List.generate(7, (i) {
                    final active = weeklyData[i] > 0;
                    final isToday = i == todayIndex;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          height: active ? (isToday ? 105 : 75) : 12,
                          decoration: BoxDecoration(
                            gradient: active
                                ? const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [PUI.primary, PUI.primaryDeep],
                                  )
                                : null,
                            color: active ? null : Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: (active && isToday)
                                ? [BoxShadow(color: PUI.primary.withOpacity(0.55), blurRadius: 16)]
                                : [],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(7, (i) {
                  final isToday = i == todayIndex;
                  return Expanded(
                    child: Center(
                      child: Text(
                        days[i],
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                          color: isToday ? PUI.mint : Colors.white.withOpacity(0.35),
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
        children: [
          Text(
            "QUICK ACTIONS",
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildActionCard("Start Workout", Icons.play_circle_fill, PUI.primary,
                  () => _showVibeCheck(null, "Quick Workout")),
              const SizedBox(width: 12),
              _buildActionCard("Custom Plan", Icons.edit_note, PUI.pink, () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WorkoutBuilderScreen()),
                );
                _loadData();
              }),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildActionCard("Weekly Split", Icons.calendar_month, PUI.mint,
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => CalendarScreen()))),
              const SizedBox(width: 12),
              _buildActionCard("My Progress", Icons.trending_up, PUI.amber,
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StatisticsScreen()))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback? onTap) {
    return Expanded(
      child: Pressable(
        onTap: onTap,
        child: Glass(
          radius: 22,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.35), color.withOpacity(0.1)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 11, color: Colors.white.withOpacity(0.25)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRecoveryBankPopup() {
    final todayStr =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
    final isAlreadyFrozen = SettingsStorage.isDateFrozen(todayStr);

    showModalBottomSheet(
      context: context,
      backgroundColor: PUI.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 24),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(color: PUI.mint.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(Icons.shield, color: PUI.mint, size: 40,
                    shadows: [Shadow(color: PUI.mint.withOpacity(0.8), blurRadius: 14)]),
              ),
              const SizedBox(height: 16),
              Text("Recovery Bank",
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 8),
              Text("You have $recoveryCoins Recovery Coins",
                  style: GoogleFonts.outfit(fontSize: 15, color: Colors.white.withOpacity(0.6))),
              const SizedBox(height: 24),
              if (isAlreadyFrozen)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PUI.mint.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: PUI.mint.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: PUI.mint),
                      const SizedBox(width: 8),
                      Text("Today's streak is frozen! ❄️",
                          style: GoogleFonts.outfit(color: PUI.mint, fontWeight: FontWeight.w700)),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: recoveryCoins > 0 ? () => _spendCoinAndFreeze(todayStr) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: recoveryCoins > 0 ? PUI.primary : Colors.grey.shade800,
                      disabledBackgroundColor: Colors.grey.shade800,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      recoveryCoins > 0 ? "Freeze Streak (1 Coin)" : "Not enough coins",
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _spendCoinAndFreeze(String dateStr) async {
    final success = await SettingsStorage.spendRecoveryCoin();
    if (!success) return;
    await SettingsStorage.freezeDate(dateStr);
    if (!mounted) return;
    Navigator.pop(context);
    setState(() => recoveryCoins = SettingsStorage.getRecoveryCoins());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.ac_unit, color: Colors.white),
          SizedBox(width: 8),
          Text("Streak frozen for today! ❄️"),
        ]),
        backgroundColor: PUI.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * pi, false, bgPaint);

    if (progress <= 0) return;

    final fillPaint = Paint()
      ..shader = SweepGradient(
        colors: [PUI.primary, PUI.mint],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress.clamp(0.0, 1.0), false, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
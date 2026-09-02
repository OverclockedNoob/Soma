import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workout_tracker/services/storage_services.dart';
import 'active_workout_screen.dart';
import 'workout_builder_screen.dart';
import 'stats_screen.dart';
import 'library_screen.dart';
import 'split_builder_screen.dart';
import 'calendar_screen.dart';
import '../widgets/vibe_check_sheet.dart';

// ── SUPER PREMIUM PALETTE ─────────────────────────────────────
const Color _kBg = Color(0xFF05060A);
const Color _kPrimary = Color(0xFF8B7CFF);
const Color _kPrimaryDeep = Color(0xFF5A3CC4);
const Color _kMint = Color(0xFF3DDCB8);
const Color _kAmber = Color(0xFFFFC24A);
const Color _kFlame = Color(0xFFFF6B4A);
const Color _kPink = Color(0xFFFF6B9D);

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

  int _calculateStreak(List<Map<String, dynamic>> workouts) {
    if (workouts.isEmpty) return 0;
    final workoutDates = <DateTime>{};
    for (var w in workouts) {
      try {
        final d = DateTime.parse(w['date'] as String);
        workoutDates.add(DateTime(d.year, d.month, d.day));
      } catch (_) {}
    }
    final sorted = workoutDates.toList()..sort((a, b) => b.compareTo(a));
    final today = DateTime.now();
    DateTime check = DateTime(today.year, today.month, today.day);
    int streak = 0;
    for (final day in sorted) {
      if (day == check) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else if (day.isBefore(check)) {
        break;
      }
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

  // ════════════════════════════════════════════════════════════
  //  SUPER PREMIUM UI
  // ════════════════════════════════════════════════════════════

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

  Widget _glass({required Widget child, double radius = 24}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.02),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _gradientText(
    String text, {
    double size = 32,
    FontWeight weight = FontWeight.w800,
    List<Color>? colors,
  }) {
    return ShaderMask(
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors ?? [Colors.white, Colors.white.withOpacity(0.55)],
      ).createShader(rect),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: size,
          fontWeight: weight,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildAurora() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -260,
              left: -180,
              child: Container(
                width: 650,
                height: 650,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    radius: 1.0,
                    colors: [
                      _kPrimary.withOpacity(0.14),
                      _kPrimary.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -160,
              right: -220,
              child: Container(
                width: 600,
                height: 600,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    radius: 1.0,
                    colors: [
                      _kMint.withOpacity(0.08),
                      _kMint.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          _buildAurora(),
          SafeArea(
            child: RefreshIndicator(
              color: _kPrimary,
              backgroundColor: _kBg,
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
              _gradientText(_userName, size: 32),
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
    return _Pressable(
      onTap: () {
        if (rest) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Rest day! Enjoy your recovery. 🧘")),
          );
        } else {
          _showVibeCheck(_todaysExercises, _todaysWorkoutName ?? "Workout");
        }
      },
      child: _glass(
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
                        color: _kMint.withOpacity(0.9),
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
                      : const LinearGradient(colors: [_kPrimary, _kPrimaryDeep]),
                  color: rest ? Colors.white.withOpacity(0.08) : null,
                  shape: BoxShape.circle,
                  boxShadow: rest
                      ? []
                      : [BoxShadow(color: _kPrimary.withOpacity(0.5), blurRadius: 16)],
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
          _buildStatTile("WORKOUTS", "$totalWorkouts", Icons.fitness_center, _kPrimary),
          const SizedBox(width: 10),
          _buildStatTile("STREAK", "$currentStreak", Icons.local_fire_department, _kFlame,
              valueGradient: [_kFlame, _kAmber]),
          const SizedBox(width: 10),
          _buildStatTile("KCAL", _formatCalories(totalCalories), Icons.bolt, _kAmber),
          const SizedBox(width: 10),
          _buildStatTile("COINS", "$recoveryCoins", Icons.shield, _kMint,
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
    final content = _glass(
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
                ? _gradientText(value, size: 20, colors: valueGradient)
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
      child: onTap == null ? content : _Pressable(onTap: onTap, child: content),
    );
  }

  Widget _buildWeeklyChart() {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayIndex = DateTime.now().weekday - 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: _glass(
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
                  _Pressable(
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
                        color: _kMint,
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
                                    colors: [_kPrimary, _kPrimaryDeep],
                                  )
                                : null,
                            color: active ? null : Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: (active && isToday)
                                ? [BoxShadow(color: _kPrimary.withOpacity(0.55), blurRadius: 16)]
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
                          color: isToday ? _kMint : Colors.white.withOpacity(0.35),
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
              _buildActionCard("Start Workout", Icons.play_circle_fill, _kPrimary,
                  () => _showVibeCheck(null, "Quick Workout")),
              const SizedBox(width: 12),
              _buildActionCard("Custom Plan", Icons.edit_note, _kPink, () async {
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
              _buildActionCard("Weekly Split", Icons.calendar_month, _kMint,
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => CalendarScreen()))),
              const SizedBox(width: 12),
              _buildActionCard("My Progress", Icons.trending_up, _kAmber,
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StatisticsScreen()))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback? onTap) {
    return Expanded(
      child: _Pressable(
        onTap: onTap,
        child: _glass(
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
      backgroundColor: const Color(0xFF0D1016),
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
                decoration: BoxDecoration(color: _kMint.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(Icons.shield, color: _kMint, size: 40,
                    shadows: [Shadow(color: _kMint.withOpacity(0.8), blurRadius: 14)]),
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
                    color: _kMint.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kMint.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: _kMint),
                      const SizedBox(width: 8),
                      Text("Today's streak is frozen! ❄️",
                          style: GoogleFonts.outfit(color: _kMint, fontWeight: FontWeight.w700)),
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
                      backgroundColor: recoveryCoins > 0 ? _kPrimary : Colors.grey.shade800,
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

  void _spendCoinAndFreeze(String dateStr) async {
    final success = await SettingsStorage.spendRecoveryCoin();
    if (success) {
      await SettingsStorage.freezeDate(dateStr);
      Navigator.pop(context);
      setState(() => recoveryCoins = SettingsStorage.getRecoveryCoins());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.ac_unit, color: Colors.white),
            SizedBox(width: 8),
            Text("Streak frozen for today! ❄️"),
          ]),
          backgroundColor: _kPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}

// ════════════════════════════════════════════════════════════
//  SUPPORT WIDGETS
// ════════════════════════════════════════════════════════════

class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _Pressable({required this.child, this.onTap});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: widget.child,
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
        colors: [_kPrimary, _kMint],
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
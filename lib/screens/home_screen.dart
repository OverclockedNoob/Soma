import 'package:flutter/material.dart';
import 'package:workout_tracker/services/storage_services.dart';
import 'active_workout_screen.dart';
import 'workout_builder_screen.dart';
import 'stats_screen.dart';
import 'library_screen.dart';
import 'split_builder_screen.dart';
import 'calendar_screen.dart';
import '../widgets/vibe_check_sheet.dart'; // <--- NEW IMPORT

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
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
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

  // 🧠 NEW: VIBE CHECK HELPER METHOD
  void _showVibeCheck(List<Map<String, dynamic>>? exercises, String name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => VibeCheckSheet(
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
      calories >= 1000
          ? "${(calories / 1000).toStringAsFixed(1)}k"
          : "$calories";

  void _showRecoveryBankPopup() {
    final todayStr =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
    final isAlreadyFrozen = SettingsStorage.isDateFrozen(todayStr);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E3F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: const Color(0xFF6C5CE7).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield,
                  color: Color(0xFF6C5CE7),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Recovery Bank",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You have $recoveryCoins Recovery Coins",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),

              if (isAlreadyFrozen)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        "Today's streak is frozen! ❄️",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
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
                    onPressed:
                        recoveryCoins > 0
                            ? () => _spendCoinAndFreeze(todayStr)
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          recoveryCoins > 0
                              ? const Color(0xFF6C5CE7)
                              : Colors.grey.shade700,
                      disabledBackgroundColor: Colors.grey.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      recoveryCoins > 0
                          ? "Freeze Streak (1 Coin)"
                          : "Not enough coins",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                "Missing a workout? Spend a coin to protect your streak!",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
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

      setState(() {
        recoveryCoins = SettingsStorage.getRecoveryCoins();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.ac_unit, color: Colors.white),
              SizedBox(width: 8),
              Text("Streak frozen for today! ❄️"),
            ],
          ),
          backgroundColor: const Color(0xFF6C5CE7),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          color: const Color(0xFF6C5CE7),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF6C5CE7),
                        const Color(0xFF6C5CE7).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getGreeting(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$_userName 💪",
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickStat(
                                "$totalWorkouts",
                                "Workouts",
                                Icons.fitness_center,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildQuickStat(
                                "$currentStreak",
                                "Streak",
                                Icons.local_fire_department,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _showRecoveryBankPopup,
                              child: Expanded(
                                child: _buildQuickStat(
                                  "$recoveryCoins",
                                  "Recovery",
                                  Icons.shield,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildQuickStat(
                                _formatCalories(totalCalories),
                                "Calories",
                                Icons.bolt,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Weekly Activity",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          TextButton(
                            onPressed:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const StatisticsScreen(),
                                  ),
                                ),
                            child: const Text(
                              "View All",
                              style: TextStyle(color: Color(0xFF6C5CE7)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildWeeklyChart(),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Quick Actions",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionCard(
                              "Start\nWorkout",
                              Icons.play_circle_filled,
                              const Color(0xFF6C5CE7),
                              // 🧠 UPDATED: Opens Vibe Check instead of direct workout
                              onTap: () {
                                _showVibeCheck(null, "Quick Workout");
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionCard(
                              "Custom\nPlan",
                              Icons.edit_note,
                              const Color(0xFFFF6B9D),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const WorkoutBuilderScreen(),
                                  ),
                                );
                                _loadData();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionCard(
                              "Weekly\nSplit",
                              Icons.calendar_month,
                              const Color(0xFF00D9FF),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CalendarScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionCard(
                              "My\nProgress",
                              Icons.trending_up,
                              const Color(0xFFFFB800),
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const StatisticsScreen(),
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: _buildDynamicStartButton(),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicStartButton() {
    if (_isTodayRestDay) {
      return Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Rest day! Enjoy your recovery. You earned it. 🧘",
                ),
                backgroundColor: Color(0xFF6C5CE7),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.self_improvement, size: 28, color: Colors.white70),
              SizedBox(width: 12),
              Text(
                "Rest Day 🧘",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_todaysWorkoutName != null) {
      return Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C5CE7), Color(0xFF9B59B6)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C5CE7).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          // 🧠 UPDATED: Opens Vibe Check with today's scheduled exercises
          onPressed: () {
            _showVibeCheck(_todaysExercises, _todaysWorkoutName ?? "Workout");
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_arrow, size: 28, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                "Start $_todaysWorkoutName",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C5CE7), Color(0xFF9B59B6)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C5CE7).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          // 🧠 UPDATED: Opens Vibe Check for a generic quick workout
          onPressed: () {
            _showVibeCheck(null, "Quick Workout");
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow, size: 28, color: Colors.white),
              SizedBox(width: 12),
              Text(
                "Start Today's Workout",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildQuickStat(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF6C5CE7).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "This Week",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$weeklyWorkoutCount Workouts",
                  style: const TextStyle(
                    color: Color(0xFF6C5CE7),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(weeklyData.length, (index) {
                final isActive = weeklyData[index] > 0;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 32,
                      height: isActive ? 80 : 8,
                      decoration: BoxDecoration(
                        gradient:
                            isActive
                                ? const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF6C5CE7),
                                    Color(0xFF9B59B6),
                                  ],
                                )
                                : null,
                        color: isActive ? null : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      days[index],
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isActive
                                ? const Color(0xFF6C5CE7)
                                : Colors.white.withOpacity(0.5),
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

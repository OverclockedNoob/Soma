import 'package:flutter/material.dart';
import 'package:workout_tracker/services/storage_services.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<Map<String, dynamic>> workouts = [];
  int recoveryCoins = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final loadedWorkouts = WorkoutStorage.getAllWorkouts();
    final coins = SettingsStorage.getRecoveryCoins();
    if (mounted) {
      setState(() {
        workouts = loadedWorkouts;
        recoveryCoins = coins;
        _isLoading = false;
      });
    }
  }

  // ── Stats Calculations ───────────────────────────────────────────

  int getTotalWorkouts() => workouts.length;

  // 🛡️ UPDATED STREAK: Respects Frozen Dates!
  int getCurrentStreak() {
    if (workouts.isEmpty) return 0;

    final workoutDateSet = <DateTime>{};
    for (var workout in workouts) {
      try {
        final d = DateTime.parse(workout['date'] as String);
        workoutDateSet.add(DateTime(d.year, d.month, d.day));
      } catch (_) {
        continue;
      }
    }

    final sortedDates = workoutDateSet.toList()..sort((a, b) => b.compareTo(a));
    if (sortedDates.isEmpty) return 0;

    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final yesterday = todayNormalized.subtract(const Duration(days: 1));

    DateTime checkDay;
    if (sortedDates.first == todayNormalized) {
      checkDay = todayNormalized;
    } else if (sortedDates.first == yesterday) {
      checkDay = yesterday;
    } else {
      // Check if today or yesterday is frozen!
      String todayStr =
          "${todayNormalized.year}-${todayNormalized.month.toString().padLeft(2, '0')}-${todayNormalized.day.toString().padLeft(2, '0')}";
      String yesterdayStr =
          "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

      if (SettingsStorage.isDateFrozen(todayStr))
        checkDay = todayNormalized;
      else if (SettingsStorage.isDateFrozen(yesterdayStr))
        checkDay = yesterday;
      else
        return 0; // Streak is broken
    }

    int streak = 0;
    for (final day in sortedDates) {
      if (day == checkDay) {
        streak++;
        checkDay = checkDay.subtract(const Duration(days: 1));
      } else if (day.isBefore(checkDay)) {
        // Check if the gap is covered by frozen dates
        bool gapFrozen = true;
        DateTime tempCheck = checkDay;
        while (tempCheck.isAfter(day)) {
          String dateStr =
              "${tempCheck.year}-${tempCheck.month.toString().padLeft(2, '0')}-${tempCheck.day.toString().padLeft(2, '0')}";
          if (!SettingsStorage.isDateFrozen(dateStr)) {
            gapFrozen = false;
            break;
          }
          tempCheck = tempCheck.subtract(const Duration(days: 1));
        }
        if (gapFrozen) {
          streak += checkDay.difference(day).inDays;
          checkDay = day;
        } else {
          break;
        }
      }
    }
    return streak;
  }

  double getTotalHours() {
    final totalMinutes = workouts.fold<int>(
      0,
      (sum, w) => sum + ((w['durationMinutes'] as int?) ?? 0),
    );
    return totalMinutes / 60.0;
  }

  int getTotalCalories() {
    return workouts.fold<int>(
      0,
      (sum, w) => sum + ((w['calories'] as int?) ?? 0),
    );
  }

  List<double> getWeeklyProgress() {
    final weeklyProgress = List<double>.filled(7, 0.0);
    final thisWeekWorkouts = WorkoutStorage.getWorkoutsThisWeek();
    final dayCounts = List<int>.filled(7, 0);

    for (var workout in thisWeekWorkouts) {
      try {
        final date = DateTime.parse(workout['date'] as String);
        final dayIndex = date.weekday - 1;
        if (dayIndex >= 0 && dayIndex < 7) dayCounts[dayIndex]++;
      } catch (_) {
        continue;
      }
    }

    final maxCount =
        dayCounts.isEmpty ? 0 : dayCounts.reduce((a, b) => a > b ? a : b);
    if (maxCount == 0) return weeklyProgress;

    for (int i = 0; i < 7; i++) {
      weeklyProgress[i] = dayCounts[i] / maxCount;
    }
    return weeklyProgress;
  }

  @override
  Widget build(BuildContext context) {
    final totalWorkouts = getTotalWorkouts();
    final currentStreak = getCurrentStreak();
    final totalHours = getTotalHours();
    final totalCalories = getTotalCalories();
    final weeklyProgress = getWeeklyProgress();
    final weeklyCount = weeklyProgress.where((d) => d > 0).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          color: const Color(0xFF6C5CE7),
          child:
              _isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
                  )
                  : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header ────────────────────────────────
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Statistics",
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          "Track your progress",
                                          style: TextStyle(
                                            fontSize: 16,
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
                                        Icons.bar_chart,
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
                                        totalWorkouts.toString(),
                                        "Workouts",
                                        Icons.fitness_center,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildQuickStat(
                                        currentStreak.toString(),
                                        "Streak",
                                        Icons.local_fire_department,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildQuickStat(
                                        recoveryCoins.toString(),
                                        "Coins",
                                        Icons.shield,
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
                              // ── Stat Cards ──────────────────────
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      totalWorkouts.toString(),
                                      "Total Workouts",
                                      Icons.fitness_center,
                                      const Color(0xFF6C5CE7),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      totalCalories.toString(),
                                      "Calories Burned",
                                      Icons.local_fire_department,
                                      const Color(0xFFFF6B9D),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      "${totalHours.toStringAsFixed(1)}h",
                                      "Total Hours",
                                      Icons.timer,
                                      const Color(0xFF00D9FF),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      "$weeklyCount",
                                      "This Week",
                                      Icons.calendar_today,
                                      const Color(0xFFFFB800),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              // ── Weekly Chart ─────────────────────
                              const Text(
                                "This Week",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E3F),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF6C5CE7,
                                    ).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Activity",
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.7,
                                            ),
                                            fontSize: 14,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF6C5CE7,
                                            ).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            "$weeklyCount Workouts",
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: List.generate(
                                          weeklyProgress.length,
                                          (index) => _buildProgressBar(
                                            [
                                              'M',
                                              'T',
                                              'W',
                                              'T',
                                              'F',
                                              'S',
                                              'S',
                                            ][index],
                                            weeklyProgress[index],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // ── Empty State ──────────────────────
                              if (workouts.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1E3F),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF6C5CE7,
                                      ).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.fitness_center,
                                        size: 60,
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        "No workouts yet",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Complete a workout to see your stats!",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.4),
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }

  // ── Helper Widgets ───────────────────────────────────────────────

  Widget _buildQuickStat(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
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

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String day, double progress) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 32,
                height: 80 * progress,
                decoration: BoxDecoration(
                  gradient:
                      progress > 0
                          ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF6C5CE7), Color(0xFF9B59B6)],
                          )
                          : null,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            color:
                progress > 0
                    ? const Color(0xFF6C5CE7)
                    : Colors.white.withOpacity(0.4),
            fontSize: 12,
            fontWeight: progress > 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

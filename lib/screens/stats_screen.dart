import 'package:flutter/material.dart';
import 'package:workout_tracker/services/storage_services.dart';
import '../core/premium_ui.dart';

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

    return PremiumScaffold(
      aurora: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: PUI.primary))
          : RefreshIndicator(
              color: PUI.primary,
              backgroundColor: PUI.bg,
              onRefresh: () async => _loadData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "YOUR PROGRESS",
                                style: PUI.text(
                                  size: 11,
                                  weight: FontWeight.w600,
                                  letterSpacing: 2.2,
                                  color: Colors.white.withOpacity(0.4),
                                ),
                              ),
                              const SizedBox(height: 6),
                              GradientText("Statistics", size: 32),
                            ],
                          ),
                          Glass(
                            radius: 16,
                            padding: const EdgeInsets.all(12),
                            child: Icon(Icons.bar_chart_rounded, color: PUI.primary, size: 24),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Stat Cards (2x3 Grid) ─────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildStatCard("$totalWorkouts", "Workouts", Icons.fitness_center, PUI.primary)),
                              const SizedBox(width: 10),
                              Expanded(child: _buildStatCard("$currentStreak", "Streak", Icons.local_fire_department, PUI.flame)),
                              const SizedBox(width: 10),
                              Expanded(child: _buildStatCard("${totalHours.toStringAsFixed(1)}h", "Hours", Icons.timer, PUI.mint)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _buildStatCard("$totalCalories", "Calories", Icons.bolt, PUI.amber)),
                              const SizedBox(width: 10),
                              Expanded(child: _buildStatCard("$weeklyCount", "This Week", Icons.calendar_today, PUI.pink)),
                              const SizedBox(width: 10),
                              Expanded(child: _buildStatCard("$recoveryCoins", "Coins", Icons.shield, PUI.mint)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Weekly Chart ──────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: SectionTitle("This Week"),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Glass(
                        radius: 24,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Activity",
                                  style: PUI.text(size: 14, color: Colors.white.withOpacity(0.6)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: PUI.mint.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "$weeklyCount Workouts",
                                    style: PUI.text(size: 12, weight: FontWeight.w700, color: PUI.mint),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 120,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(
                                  weeklyProgress.length,
                                  (index) => _buildProgressBar(
                                    index,
                                    ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
                                    weeklyProgress[index],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Empty State ───────────────────────────
                    if (workouts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Glass(
                          radius: 24,
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: PUI.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.fitness_center,
                                  size: 48,
                                  color: PUI.primary.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "No workouts yet",
                                style: PUI.text(size: 20, weight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Complete a workout to see your stats!",
                                style: PUI.text(size: 14, color: Colors.white.withOpacity(0.5)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Helper Widgets ───────────────────────────────────────────────

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Glass(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: PUI.text(size: 20, weight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: PUI.text(size: 11, color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int index, String day, double progress) {
    final isToday = index == (DateTime.now().weekday - 1);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                width: double.infinity,
                height: progress > 0 ? (progress * 100).clamp(10, 100) : 8,
                decoration: BoxDecoration(
                  gradient: progress > 0
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [PUI.primary, PUI.primaryDeep],
                        )
                      : null,
                  color: progress > 0 ? null : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: (progress > 0 && isToday)
                      ? [BoxShadow(color: PUI.primary.withOpacity(0.5), blurRadius: 14)]
                      : [],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              day,
              style: PUI.text(
                size: 10,
                weight: isToday ? FontWeight.w800 : FontWeight.w500,
                color: isToday ? PUI.mint : Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
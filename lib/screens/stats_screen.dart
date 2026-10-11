import 'package:flutter/material.dart';
import 'package:workout_tracker/services/storage_services.dart';
import 'package:workout_tracker/services/streak_service.dart';
import '../core/event_bus.dart';
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

    // Refresh when workouts are saved/deleted or settings change elsewhere
    // in the app (e.g. HomeScreen freezing a streak with a Recovery Coin —
    // it already broadcasts that, this screen just wasn't listening before).
    // Same pattern HomeScreen uses.
    WorkoutEventBus.instance.revision.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    if (mounted) _loadData();
  }

  @override
  void dispose() {
    WorkoutEventBus.instance.revision.removeListener(_onDataChanged);
    super.dispose();
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

  int getTotalWorkouts() => workouts.length;

  // Delegates to StreakService — the single shared implementation also used
  // by HomeScreen, so the two screens can never disagree. (The old local
  // version didn't know about scheduled rest days, counted frozen days into
  // the streak number, and had a gap-bridging bug that dropped workout days
  // following a freeze.)
  int getCurrentStreak() => StreakService.currentStreak();

  double getTotalHours() {
    final totalMinutes = workouts.fold<int>(0, (sum, w) => sum + ((w['durationMinutes'] as int?) ?? 0));
    return totalMinutes / 60.0;
  }

  int getTotalCalories() => workouts.fold<int>(0, (sum, w) => sum + ((w['calories'] as int?) ?? 0));

  // heads up, this is relative to your busiest day this week, not an
  // absolute target. train once and that bar goes full height. works fine
  // visually but don't read too much into the exact percentages
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

    final maxCount = dayCounts.isEmpty ? 0 : dayCounts.reduce((a, b) => a > b ? a : b);
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("YOUR PROGRESS", style: PUI.text(size: 11, weight: FontWeight.w600, letterSpacing: 2.2, color: Colors.white.withOpacity(0.4))),
                              const SizedBox(height: 6),
                              GradientText("Statistics", size: 32),
                            ],
                          ),
                          Glass(radius: 16, padding: const EdgeInsets.all(12), child: Icon(Icons.bar_chart_rounded, color: PUI.primary, size: 24)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0), child: _buildHeroStreakCard(currentStreak)),
                    const SizedBox(height: 24),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0), child: _buildStatsGrid(totalWorkouts, totalHours, totalCalories, weeklyCount)),
                    const SizedBox(height: 32),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0), child: SectionTitle("Weekly Activity")),
                    const SizedBox(height: 16),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0), child: _buildWeeklyChart(weeklyProgress, weeklyCount)),
                    const SizedBox(height: 32),

                    // only show lifetime section once there's real data —
                    // "avg duration: 0 min" on a brand new install looks broken
                    if (workouts.isNotEmpty) ...[
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0), child: SectionTitle("Lifetime Averages")),
                      const SizedBox(height: 16),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0), child: _buildLifetimeHighlights()),
                      const SizedBox(height: 40),
                    ],
                    if (workouts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
                        child: Glass(
                          radius: 24,
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: PUI.primary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.fitness_center, size: 48, color: PUI.primary.withOpacity(0.6))),
                              const SizedBox(height: 20),
                              Text("No workouts yet", style: PUI.text(size: 20, weight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Text("Complete a workout to see your stats!", style: PUI.text(size: 14, color: Colors.white.withOpacity(0.5)), textAlign: TextAlign.center),
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

  Widget _buildHeroStreakCard(int streak) {
    return Glass(
      radius: 28,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(gradient: LinearGradient(colors: [PUI.flame.withOpacity(0.15), Colors.transparent], begin: Alignment.topRight, end: Alignment.bottomLeft)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("CURRENT STREAK", style: PUI.text(size: 11, weight: FontWeight.w700, letterSpacing: 2.0, color: PUI.flame.withOpacity(0.8))),
                  const SizedBox(height: 8),
                  GradientText("$streak Days", size: 42, weight: FontWeight.w900, colors: [PUI.flame, PUI.amber]),
                  const SizedBox(height: 4),
                  Text(streak > 0 ? "Keep the fire burning! 🔥" : "Start your streak today", style: PUI.text(size: 13, color: Colors.white.withOpacity(0.6))),
                ],
              ),
            ),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [PUI.flame, PUI.amber]), shape: BoxShape.circle, boxShadow: [BoxShadow(color: PUI.flame.withOpacity(0.4), blurRadius: 24)]),
              child: const Icon(Icons.local_fire_department, color: Colors.white, size: 36),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(int totalWorkouts, double totalHours, int totalCalories, int weeklyCount) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatTile("$totalWorkouts", "Workouts", Icons.fitness_center, PUI.primary)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatTile("${totalHours.toStringAsFixed(1)}h", "Total Time", Icons.timer, PUI.mint)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatTile("$totalCalories", "Calories", Icons.bolt, PUI.amber)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatTile("$weeklyCount/7", "This Week", Icons.calendar_month, PUI.pink)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatTile("$recoveryCoins", "Recovery Coins", Icons.shield, PUI.mint)),
            const SizedBox(width: 12),
            // leaving this slot empty on purpose to keep the grid 3-wide —
            // good spot for a PR/max-weight stat down the line
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildStatTile(String value, String label, IconData icon, Color accent) {
    return Glass(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 20, shadows: [Shadow(color: accent.withOpacity(0.6), blurRadius: 8)]),
            const SizedBox(height: 12),
            Text(value, style: PUI.text(size: 22, weight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label, style: PUI.text(size: 11, weight: FontWeight.w600, color: Colors.white.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(List<double> weeklyProgress, int weeklyCount) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayIndex = DateTime.now().weekday - 1;
    final completionPct = (weeklyCount / 7 * 100).toStringAsFixed(0);

    return Glass(
      radius: 28,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Activity", style: PUI.text(size: 16, weight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text("$weeklyCount workouts this week", style: PUI.text(size: 12, color: Colors.white.withOpacity(0.5))),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: PUI.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: PUI.primary.withOpacity(0.3))),
                  child: Text("$completionPct%", style: PUI.text(size: 12, weight: FontWeight.w800, color: PUI.primary)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final progress = weeklyProgress[i];
                  final isToday = i == todayIndex;
                  final isActive = progress > 0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeOutCubic,
                              width: double.infinity,
                              // clamped so a tiny value doesn't render as a
                              // basically-invisible sliver
                              height: isActive ? (progress * 120).clamp(16.0, 120.0) : 8.0,
                              decoration: BoxDecoration(
                                gradient: isActive ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: isToday ? [PUI.mint, PUI.mint.withOpacity(0.4)] : [PUI.primary, PUI.primaryDeep]) : null,
                                color: isActive ? null : Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: (isActive && isToday) ? [BoxShadow(color: PUI.mint.withOpacity(0.5), blurRadius: 16)] : (isActive ? [BoxShadow(color: PUI.primary.withOpacity(0.3), blurRadius: 8)] : []),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(days[i], style: PUI.text(size: 12, weight: isToday ? FontWeight.w800 : FontWeight.w600, color: isToday ? PUI.mint : Colors.white.withOpacity(0.4))),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLifetimeHighlights() {
    final totalMinutes = workouts.fold<int>(0, (sum, w) => sum + ((w['durationMinutes'] as int?) ?? 0));
    final avgMinutes = workouts.isNotEmpty ? (totalMinutes / workouts.length).round() : 0;
    return Glass(
      radius: 28,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Averages", style: PUI.text(size: 16, weight: FontWeight.w800)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildAvgTile("Avg. Duration", "$avgMinutes min", Icons.hourglass_bottom, PUI.primary)),
                const SizedBox(width: 16),
                Expanded(child: _buildAvgTile("Total Volume", "${(totalMinutes / 60).toStringAsFixed(1)} hrs", Icons.trending_up, PUI.mint)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAvgTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value, style: PUI.text(size: 20, weight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label, style: PUI.text(size: 11, color: Colors.white.withOpacity(0.5), weight: FontWeight.w600)),
        ],
      ),
    );
  }
}
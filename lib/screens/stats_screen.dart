import 'package:flutter/material.dart';

import '../core/event_bus.dart';
import '../core/premium_ui.dart';
import '../models/workout_models.dart';
import '../services/storage_services.dart';
import '../services/streak_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<WorkoutSession> sessions = <WorkoutSession>[];
  List<WorkoutSession> thisWeekSessions = <WorkoutSession>[];
  int currentStreak = 0;
  int recoveryCoins = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
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
    final loadedSessions = WorkoutStorage.getAllWorkoutSessions();
    final weekSessions = WorkoutStorage.getWorkoutSessionsThisWeek();
    final coins = SettingsStorage.getRecoveryCoins();
    final streak = StreakService.calculateCurrentStreak();
    if (mounted) {
      setState(() {
        sessions = loadedSessions;
        thisWeekSessions = weekSessions;
        recoveryCoins = coins;
        currentStreak = streak;
        _isLoading = false;
      });
    }
  }

  int getTotalWorkouts() => sessions.length;

  double getTotalHours() {
    final totalSeconds = sessions.fold<int>(
      0,
      (int sum, WorkoutSession s) => sum + s.durationSeconds,
    );
    return totalSeconds / 3600.0;
  }

  int getTotalCalories() => sessions.fold<int>(
        0,
        (int sum, WorkoutSession s) => sum + s.calories,
      );

  int getTotalReps() => sessions.fold<int>(
        0,
        (int sum, WorkoutSession s) => sum + s.totalReps,
      );

  List<double> getWeeklyProgress() {
    final weeklyProgress = List<double>.filled(7, 0.0);
    final dayCounts = List<int>.filled(7, 0);

    for (final session in thisWeekSessions) {
      final day = session.dayUtc;
      if (day != null) {
        final dayIndex = day.weekday - 1;
        if (dayIndex >= 0 && dayIndex < 7) dayCounts[dayIndex]++;
      }
    }

    final maxCount = dayCounts.reduce((int a, int b) => a > b ? a : b);
    if (maxCount == 0) return weeklyProgress;

    for (int i = 0; i < 7; i++) {
      weeklyProgress[i] = dayCounts[i] / maxCount;
    }
    return weeklyProgress;
  }

  @override
  Widget build(BuildContext context) {
    final totalWorkouts = getTotalWorkouts();
    final totalHours = getTotalHours();
    final totalCalories = getTotalCalories();
    final weeklyProgress = getWeeklyProgress();
    final weeklyCount = weeklyProgress.where((double d) => d > 0).length;

    return PremiumScaffold(
      title: Navigator.canPop(context) ? 'Statistics' : null,
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
                  children: <Widget>[
                    if (!Navigator.canPop(context))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'YOUR PROGRESS',
                                  style: PUI.text(
                                    size: 11,
                                    weight: FontWeight.w600,
                                    letterSpacing: 2.2,
                                    color: Colors.white.withValues(alpha: 0.4),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const GradientText('Statistics', size: 32),
                              ],
                            ),
                            const Glass(
                              radius: 16,
                              padding: EdgeInsets.all(12),
                              child: Icon(
                                Icons.bar_chart_rounded,
                                color: PUI.primary,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox(height: 8),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: _buildHeroStreakCard(currentStreak),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: _buildStatsGrid(
                        totalWorkouts,
                        totalHours,
                        totalCalories,
                        weeklyCount,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0),
                      child: SectionTitle('Weekly Activity'),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: _buildWeeklyChart(weeklyProgress, weeklyCount),
                    ),
                    const SizedBox(height: 32),
                    if (sessions.isNotEmpty) ...<Widget>[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0),
                        child: SectionTitle('Lifetime Highlights'),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: _buildLifetimeHighlights(),
                      ),
                      const SizedBox(height: 40),
                    ],
                    if (sessions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 40,
                        ),
                        child: Glass(
                          radius: 24,
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: PUI.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.fitness_center,
                                  size: 48,
                                  color: PUI.primary.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'No workouts yet',
                                style: PUI.text(
                                  size: 20,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Complete a workout to see your stats!',
                                style: PUI.text(
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
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

  Widget _buildHeroStreakCard(int streak) {
    return Glass(
      radius: 28,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              PUI.flame.withValues(alpha: 0.15),
              Colors.transparent,
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'CURRENT STREAK',
                    style: PUI.text(
                      size: 11,
                      weight: FontWeight.w700,
                      letterSpacing: 2.0,
                      color: PUI.flame.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GradientText(
                    '$streak ${streak == 1 ? 'Day' : 'Days'}',
                    size: 40,
                    weight: FontWeight.w900,
                    colors: const <Color>[PUI.flame, PUI.amber],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    streak > 0
                        ? 'Keep the fire burning! 🔥'
                        : 'Start your streak today',
                    style: PUI.text(
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[PUI.flame, PUI.amber],
                ),
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: PUI.flame.withValues(alpha: 0.4),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 36,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
    int totalWorkouts,
    double totalHours,
    int totalCalories,
    int weeklyCount,
  ) {
    final totalReps = getTotalReps();
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _buildStatTile(
                '$totalWorkouts',
                'Workouts',
                Icons.fitness_center,
                PUI.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatTile(
                '${totalHours.toStringAsFixed(1)}h',
                'Total Time',
                Icons.timer,
                PUI.mint,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatTile(
                '$totalCalories',
                'Calories',
                Icons.bolt,
                PUI.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _buildStatTile(
                '$weeklyCount/7',
                'This Week',
                Icons.calendar_month,
                PUI.pink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatTile(
                '$recoveryCoins',
                'Recovery Coins',
                Icons.shield,
                PUI.mint,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatTile(
                '$totalReps',
                'Total Reps',
                Icons.repeat_rounded,
                PUI.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatTile(
    String value,
    String label,
    IconData icon,
    Color accent,
  ) {
    return Glass(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              icon,
              color: accent,
              size: 20,
              shadows: <Shadow>[
                Shadow(
                  color: accent.withValues(alpha: 0.6),
                  blurRadius: 8,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: PUI.text(size: 22, weight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: PUI.text(
                size: 11,
                weight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(List<double> weeklyProgress, int weeklyCount) {
    const days = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayIndex = DateTime.now().weekday - 1;
    final completionPct = (weeklyCount / 7 * 100).toStringAsFixed(0);

    return Glass(
      radius: 28,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Activity',
                      style: PUI.text(size: 16, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$weeklyCount active ${weeklyCount == 1 ? 'day' : 'days'} this week',
                      style: PUI.text(
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: PUI.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: PUI.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '$completionPct%',
                    style: PUI.text(
                      size: 12,
                      weight: FontWeight.w800,
                      color: PUI.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List<Widget>.generate(7, (int i) {
                  final progress = weeklyProgress[i];
                  final isToday = i == todayIndex;
                  final isActive = progress > 0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            width: double.infinity,
                            height: isActive
                                ? (progress * 108).clamp(16.0, 108.0)
                                : 8.0,
                            decoration: BoxDecoration(
                              gradient: isActive
                                  ? LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: isToday
                                          ? <Color>[
                                              PUI.mint,
                                              PUI.mint.withValues(alpha: 0.4),
                                            ]
                                          : const <Color>[
                                              PUI.primary,
                                              PUI.primaryDeep,
                                            ],
                                    )
                                  : null,
                              color: isActive
                                  ? null
                                  : Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: (isActive && isToday)
                                  ? <BoxShadow>[
                                      BoxShadow(
                                        color: PUI.mint.withValues(alpha: 0.5),
                                        blurRadius: 16,
                                      ),
                                    ]
                                  : (isActive
                                      ? <BoxShadow>[
                                          BoxShadow(
                                            color: PUI.primary.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : const <BoxShadow>[]),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            days[i],
                            style: PUI.text(
                              size: 12,
                              weight:
                                  isToday ? FontWeight.w800 : FontWeight.w600,
                              color: isToday
                                  ? PUI.mint
                                  : Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
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
    final totalSeconds = sessions.fold<int>(
      0,
      (int sum, WorkoutSession s) => sum + s.durationSeconds,
    );
    final avgMinutes = sessions.isNotEmpty
        ? (totalSeconds / 60.0 / sessions.length).round()
        : 0;
    final avgSets = sessions.isNotEmpty
        ? (sessions.fold<int>(
                  0,
                  (int sum, WorkoutSession s) => sum + s.totalSets,
                ) /
                sessions.length)
            .toStringAsFixed(1)
        : '0';

    return Glass(
      radius: 28,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Session Averages',
              style: PUI.text(size: 16, weight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildAvgTile(
                    'Avg. Duration',
                    '$avgMinutes min',
                    Icons.hourglass_bottom,
                    PUI.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAvgTile(
                    'Avg. Sets / Session',
                    avgSets,
                    Icons.trending_up,
                    PUI.mint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvgTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value, style: PUI.text(size: 20, weight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            label,
            style: PUI.text(
              size: 11,
              color: Colors.white.withValues(alpha: 0.5),
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

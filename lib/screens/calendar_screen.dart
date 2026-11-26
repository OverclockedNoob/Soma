import 'dart:async';

import 'package:flutter/material.dart';

import '../core/event_bus.dart';
import '../core/premium_ui.dart';
import '../models/workout_models.dart';
import '../services/storage_services.dart';
import '../widgets/vibe_check_sheet.dart';
import 'split_builder_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  List<SplitProgram> _allPrograms = <SplitProgram>[];
  SplitProgram? _activeProgram;

  Set<String> _completedDateKeys = <String>{};
  Map<String, WorkoutRoutine> _routinesById = <String, WorkoutRoutine>{};

  Color _programColor = PUI.primary;

  String? _todaysWorkoutName;
  List<Map<String, dynamic>>? _todaysExercises;
  bool _isTodayRestDay = false;

  static const List<String> _weekDays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

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
    final programs = ProgramStorage.getAllProgramModels();
    final active = ProgramStorage.getActiveProgramModel();
    final sessions = WorkoutStorage.getAllWorkoutSessions();
    final routines = CustomWorkoutStorage.getAllRoutines();

    final routineMap = <String, WorkoutRoutine>{
      for (final WorkoutRoutine r in routines) r.id: r,
    };
    final completedKeys = <String>{
      for (final WorkoutSession s in sessions)
        if (s.date.isNotEmpty) s.date,
    };

    String? todaysName;
    List<Map<String, dynamic>>? todaysExercises;
    bool isRest = false;

    final today = DateTime.now();
    if (active != null && active.isDateInRange(today)) {
      if (active.isScheduledRestDay(today)) {
        isRest = true;
      } else {
        final workoutId = active.workoutIdForDate(today);
        final routine = workoutId == null ? null : routineMap[workoutId];
        if (routine != null) {
          todaysName = routine.name;
          todaysExercises = routine.exercises
              .map((RoutineExercise e) => e.toMap())
              .toList();
        }
      }
    }

    setState(() {
      _allPrograms = programs;
      _activeProgram = active;
      _completedDateKeys = completedKeys;
      _routinesById = routineMap;
      _programColor = active != null ? Color(active.colorValue) : PUI.primary;
      _todaysWorkoutName = todaysName;
      _todaysExercises = todaysExercises;
      _isTodayRestDay = isRest;
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

  void _changeMonth(int direction) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + direction,
      );
    });
  }

  Future<void> _createNewSplit() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const SplitBuilderScreen()),
    );
    if (mounted) _loadData();
  }

  void _showManageSplits() {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: PUI.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              const SizedBox(height: 16),
              Text(
                'Manage Splits',
                style: PUI.text(size: 20, weight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: _allPrograms.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No splits created yet.',
                          style: PUI.text(color: Colors.white54),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _allPrograms.length,
                        itemBuilder: (BuildContext itemContext, int index) {
                          final program = _allPrograms[index];
                          final isActive = program.id == _activeProgram?.id;
                          final programColor = Color(program.colorValue);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? programColor.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isActive
                                    ? programColor
                                    : Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: ListTile(
                              leading: Icon(
                                Icons.calendar_month,
                                color: programColor,
                              ),
                              title: Text(
                                program.name,
                                style: PUI.text(weight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                '${program.durationWeeks} Weeks • Starts ${_formatDate(program.startDate)}',
                                style: PUI.text(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  size: 12,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  if (!isActive)
                                    TextButton(
                                      onPressed: () async {
                                        final sheetNav = Navigator.of(
                                          sheetContext,
                                        );
                                        final messenger = ScaffoldMessenger.of(
                                          context,
                                        );
                                        await ProgramStorage.setActiveProgram(
                                          program.id,
                                        );
                                        if (!mounted) return;
                                        sheetNav.pop();
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Activated: ${program.name}',
                                              style: PUI.text(
                                                weight: FontWeight.w700,
                                              ),
                                            ),
                                            backgroundColor: programColor,
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Activate',
                                        style: PUI.text(
                                          color: programColor,
                                          weight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: PUI.flame,
                                    ),
                                    onPressed: () async {
                                      final sheetNav = Navigator.of(
                                        sheetContext,
                                      );
                                      await ProgramStorage.deleteProgram(
                                        program.id,
                                      );
                                      if (!mounted) return;
                                      sheetNav.pop();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
      ),
    );
  }

  String _formatDate(String isoString) {
    final day = tryParseCalendarDayUtc(isoString);
    if (day == null) return 'Unknown';
    return '${day.day}/${day.month}/${day.year}';
  }

  WorkoutRoutine? _routineForDate(DateTime date) {
    final active = _activeProgram;
    if (active == null) return null;
    final workoutId = active.workoutIdForDate(date);
    if (workoutId == null) return null;
    return _routinesById[workoutId];
  }

  bool _isWorkoutCompleted(DateTime date) =>
      _completedDateKeys.contains(formatDateKey(date));

  bool _isRestDay(DateTime date) =>
      _activeProgram?.isScheduledRestDay(date) ?? false;

  bool _isInProgramRange(DateTime date) =>
      _activeProgram?.isDateInRange(date) ?? false;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final firstWeekdayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday - 1;

    final todayFormatted =
        'Today is: ${_weekDays[today.weekday - 1]}, ${_getMonthName(today.month)} ${today.day}';

    return PremiumScaffold(
      title: 'My Schedule',
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.folder_open, color: Colors.white70, size: 22),
          onPressed: _showManageSplits,
          tooltip: 'Manage Splits',
        ),
        IconButton(
          icon: const Icon(Icons.add_circle, color: PUI.primary, size: 26),
          onPressed: _createNewSplit,
          tooltip: 'Create New Split',
        ),
        const SizedBox(width: 8),
      ],
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                todayFormatted,
                style: PUI.text(
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    color: PUI.primary,
                    size: 28,
                  ),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  '${_getMonthName(_focusedMonth.month)} ${_focusedMonth.year}',
                  style: PUI.text(size: 20, weight: FontWeight.w800),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chevron_right,
                    color: PUI.primary,
                    size: 28,
                  ),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),
          if (_activeProgram != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    _programColor.withValues(alpha: 0.2),
                    _programColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _programColor.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.calendar_month, color: _programColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Active Program',
                          style: PUI.text(color: Colors.white70, size: 12),
                        ),
                        Text(
                          _activeProgram!.name,
                          style: PUI.text(size: 16, weight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${_activeProgram!.durationWeeks} Weeks',
                    style: PUI.text(
                      color: _programColor,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: <Widget>[
                  Text(
                    'No active split found.',
                    style: PUI.text(
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 240,
                    child: PrimaryButton(
                      label: 'Create Your First Split',
                      icon: Icons.add,
                      height: 50,
                      onTap: _createNewSplit,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: _weekDays
                  .map(
                    (String day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: PUI.text(
                            color: Colors.white.withValues(alpha: 0.5),
                            size: 12,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                ),
                itemCount: daysInMonth + firstWeekdayOfMonth,
                itemBuilder: (BuildContext context, int index) {
                  if (index < firstWeekdayOfMonth) return const SizedBox();

                  final dayOfMonth = index - firstWeekdayOfMonth + 1;
                  final currentDate = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month,
                    dayOfMonth,
                  );

                  final isToday = currentDate.year == today.year &&
                      currentDate.month == today.month &&
                      currentDate.day == today.day;
                  final isCompleted = _isWorkoutCompleted(currentDate);
                  final isRest = _isRestDay(currentDate);
                  final assignedRoutine = _routineForDate(currentDate);
                  final isInProgram = _isInProgramRange(currentDate);

                  Color bgColor = PUI.surface;
                  Color borderColor = Colors.white.withValues(alpha: 0.06);
                  double borderWidth = 1;

                  if (isInProgram) {
                    bgColor = _programColor.withValues(alpha: 0.14);
                    borderColor = _programColor.withValues(alpha: 0.4);
                  }
                  if (isToday) {
                    bgColor = _programColor.withValues(alpha: 0.3);
                    borderColor = _programColor;
                    borderWidth = 2;
                  }

                  return GestureDetector(
                    onTap: () {
                      if (assignedRoutine != null && !isRest) {
                        _showVibeCheck(
                          assignedRoutine.exercises
                              .map((RoutineExercise e) => e.toMap())
                              .toList(),
                          assignedRoutine.name,
                        );
                      } else if (isRest) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Rest Day! Recover and grow. 🧘'),
                          ),
                        );
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: borderColor,
                          width: borderWidth,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            '$dayOfMonth',
                            style: PUI.text(
                              color: isToday
                                  ? Colors.white
                                  : isRest
                                      ? Colors.white.withValues(alpha: 0.35)
                                      : Colors.white,
                              size: 13,
                              weight: isToday
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (isCompleted)
                            const Icon(
                              Icons.check_circle,
                              color: PUI.mint,
                              size: 14,
                            )
                          else if (isRest)
                            Icon(
                              Icons.bedtime,
                              color: Colors.white.withValues(alpha: 0.25),
                              size: 13,
                            )
                          else if (assignedRoutine != null)
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: _programColor,
                                shape: BoxShape.circle,
                              ),
                            )
                          else
                            const SizedBox(height: 7),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_activeProgram != null) _buildTodaysMissionBar(),
        ],
      ),
    );
  }

  Widget _buildTodaysMissionBar() {
    final inRangeToday = _activeProgram!.isDateInRange(DateTime.now());
    final missionLabel = !inRangeToday
        ? 'Split Completed — Start a New Split!'
        : _isTodayRestDay
            ? 'Rest & Recovery Day 🧘'
            : (_todaysWorkoutName ?? 'No workout scheduled');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PUI.surface,
        border: Border(
          top: BorderSide(
            color: _programColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  "Today's Mission",
                  style: PUI.text(color: Colors.white70, size: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  missionLabel,
                  style: PUI.text(
                    color: (!inRangeToday || _isTodayRestDay)
                        ? Colors.white54
                        : _programColor,
                    size: 16,
                    weight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (inRangeToday && !_isTodayRestDay && _todaysWorkoutName != null)
            Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    _programColor,
                    _programColor.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: _programColor.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  _showVibeCheck(
                    _todaysExercises,
                    _todaysWorkoutName ?? 'Workout',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      'Start',
                      style: PUI.text(size: 16, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}

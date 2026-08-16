import 'package:flutter/material.dart';
import 'package:workout_tracker/services/storage_services.dart';
import 'split_builder_screen.dart';
import 'active_workout_screen.dart';
import '../widgets/vibe_check_sheet.dart'; // <--- NEW IMPORT

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  List<Map<String, dynamic>> _allPrograms = [];
  Map<String, dynamic>? _activeProgram;

  List<Map<String, dynamic>> _completedWorkouts = [];
  List<Map<String, dynamic>> _savedWorkouts = [];

  Color _programColor = const Color(0xFF6C5CE7);
  DateTime? _programStartDate;
  DateTime? _programEndDate;

  String? _todaysWorkoutName;
  List<Map<String, dynamic>>? _todaysExercises;
  bool _isTodayRestDay = false;

  static const List<String> _weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
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
    final programs = ProgramStorage.getAllPrograms();
    final workouts = WorkoutStorage.getAllWorkouts();
    final savedRoutines = CustomWorkoutStorage.getAllCustomWorkouts();

    _todaysWorkoutName = null;
    _todaysExercises = null;
    _isTodayRestDay = false;

    setState(() {
      _allPrograms = programs;
      _completedWorkouts = workouts;
      _savedWorkouts = savedRoutines;

      _activeProgram = _allPrograms.isNotEmpty ? _allPrograms.last : null;
      _calculateProgramDetails();
      _calculateTodaysMission();
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

  void _calculateProgramDetails() {
    if (_activeProgram == null) {
      _programStartDate = null;
      _programEndDate = null;
      _programColor = const Color(0xFF6C5CE7);
      return;
    }

    int? colorValue = _activeProgram!['colorValue'] as int?;
    _programColor =
        colorValue != null ? Color(colorValue) : const Color(0xFF6C5CE7);

    String? startDateStr = _activeProgram!['startDate'] as String?;
    int? durationWeeks = _activeProgram!['durationWeeks'] as int?;

    if (startDateStr != null && durationWeeks != null) {
      _programStartDate = DateTime.tryParse(startDateStr);
      if (_programStartDate != null) {
        _programEndDate = _programStartDate!.add(
          Duration(days: durationWeeks * 7),
        );
      }
    }
  }

  void _calculateTodaysMission() {
    if (_activeProgram == null) {
      _todaysWorkoutName = null;
      _todaysExercises = null;
      _isTodayRestDay = false;
      return;
    }

    final rawSchedule = _activeProgram!['schedule'];
    if (rawSchedule == null) return;

    final schedule = Map<String, dynamic>.from(rawSchedule as Map);
    final today = DateTime.now();
    final dayName = _fullDays[today.weekday - 1];
    final workoutId = schedule[dayName];

    if (workoutId == null) {
      _isTodayRestDay = true;
    } else {
      final workout = _savedWorkouts.firstWhere(
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

  void _changeMonth(int direction) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + direction,
      );
    });
  }

  void _createNewSplit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SplitBuilderScreen()),
    );
    _loadData();
  }

  void _showManageSplits() {
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
              const SizedBox(height: 16),
              const Text(
                "Manage Splits",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child:
                    _allPrograms.isEmpty
                        ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            "No splits created yet.",
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                        : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _allPrograms.length,
                          itemBuilder: (context, index) {
                            final program = _allPrograms[index];
                            final isActive =
                                program['id'] == _activeProgram?['id'];
                            final colorValue =
                                program['colorValue'] as int? ?? 0xFF6C5CE7;
                            final programColor = Color(colorValue);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color:
                                    isActive
                                        ? programColor.withOpacity(0.2)
                                        : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      isActive
                                          ? programColor
                                          : Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  Icons.calendar_month,
                                  color: programColor,
                                ),
                                title: Text(
                                  program['name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  "${program['durationWeeks']} Weeks • ${_formatDate(program['startDate'])}",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isActive)
                                      TextButton(
                                        onPressed: () {
                                          setState(
                                            () => _activeProgram = program,
                                          );
                                          _calculateProgramDetails();
                                          _calculateTodaysMission();
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Activated: ${program['name']}",
                                              ),
                                              backgroundColor: programColor,
                                            ),
                                          );
                                        },
                                        child: Text(
                                          "Activate",
                                          style: TextStyle(
                                            color: programColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Color(0xFFE91E63),
                                      ),
                                      onPressed: () async {
                                        await ProgramStorage.deleteProgram(
                                          program['id'],
                                        );
                                        Navigator.pop(context);
                                        _loadData();
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
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return "Unknown";
    try {
      final date = DateTime.parse(isoString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return "Unknown";
    }
  }

  List<Map<String, dynamic>>? _getExercisesForDate(DateTime date) {
    if (_activeProgram == null) return null;
    final rawSchedule = _activeProgram!['schedule'];
    if (rawSchedule == null) return null;
    final schedule = Map<String, dynamic>.from(rawSchedule as Map);

    final dayName = _fullDays[date.weekday - 1];
    final workoutId = schedule[dayName];
    if (workoutId == null) return null;

    final workout = _savedWorkouts.firstWhere(
      (w) => w['id'] == workoutId,
      orElse: () => {},
    );
    if (workout['exercises'] != null) {
      return (workout['exercises'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return null;
  }

  String? _getAssignedWorkoutName(DateTime date) {
    if (_activeProgram == null) return null;
    final rawSchedule = _activeProgram!['schedule'];
    if (rawSchedule == null) return null;
    final schedule = Map<String, dynamic>.from(rawSchedule as Map);

    final dayName = _fullDays[date.weekday - 1];
    final workoutId = schedule[dayName];
    if (workoutId == null) return null;

    final workout = _savedWorkouts.firstWhere(
      (w) => w['id'] == workoutId,
      orElse: () => {},
    );
    return workout['name'] as String?;
  }

  bool _isWorkoutCompleted(DateTime date) {
    final dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return _completedWorkouts.any((w) => w['date'] == dateStr);
  }

  bool _isRestDay(DateTime date) {
    if (_activeProgram == null) return false;
    final rawSchedule = _activeProgram!['schedule'];
    if (rawSchedule == null) return false;
    final schedule = Map<String, dynamic>.from(rawSchedule as Map);
    final dayName = _fullDays[date.weekday - 1];
    return schedule[dayName] == null;
  }

  bool _isInProgramRange(DateTime date) {
    if (_programStartDate == null || _programEndDate == null) return false;
    return !date.isBefore(_programStartDate!) &&
        date.isBefore(_programEndDate!);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstWeekdayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday - 1;

    final todayFormatted =
        "Today is: ${_weekDays[today.weekday - 1]}, ${_getMonthName(today.month)} ${today.day}";

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Schedule",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.folder_open,
              color: Colors.white70,
              size: 24,
            ),
            onPressed: _showManageSplits,
            tooltip: "Manage Splits",
          ),
          IconButton(
            icon: const Icon(
              Icons.add_circle,
              color: Color(0xFF6C5CE7),
              size: 28,
            ),
            onPressed: _createNewSplit,
            tooltip: "Create New Split",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  todayFormatted,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      color: Color(0xFF6C5CE7),
                      size: 28,
                    ),
                    onPressed: () => _changeMonth(-1),
                  ),
                  Text(
                    "${_getMonthName(_focusedMonth.month)} ${_focusedMonth.year}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF6C5CE7),
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
                    colors: [
                      _programColor.withOpacity(0.2),
                      _programColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _programColor.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, color: _programColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Active Program",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _activeProgram!['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "${_activeProgram!['durationWeeks']} Weeks",
                      style: TextStyle(
                        color: _programColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      "No active split found.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _createNewSplit,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        "Create Your First Split",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children:
                    _weekDays
                        .map(
                          (day) => Expanded(
                            child: Center(
                              child: Text(
                                day,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
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
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                  ),
                  itemCount: daysInMonth + firstWeekdayOfMonth,
                  itemBuilder: (context, index) {
                    if (index < firstWeekdayOfMonth) return const SizedBox();

                    final dayOfMonth = index - firstWeekdayOfMonth + 1;
                    final currentDate = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month,
                      dayOfMonth,
                    );

                    final isToday =
                        currentDate.year == today.year &&
                        currentDate.month == today.month &&
                        currentDate.day == today.day;
                    final isCompleted = _isWorkoutCompleted(currentDate);
                    final isRest = _isRestDay(currentDate);
                    final assignedWorkout = _getAssignedWorkoutName(
                      currentDate,
                    );
                    final isInProgram = _isInProgramRange(currentDate);

                    Color bgColor = const Color(0xFF1E1E3F);
                    Color borderColor = Colors.white.withOpacity(0.05);
                    double borderWidth = 1;

                    if (isInProgram) {
                      bgColor = _programColor.withOpacity(0.15);
                      borderColor = _programColor.withOpacity(0.4);
                    }
                    if (isToday) {
                      bgColor = _programColor.withOpacity(0.3);
                      borderColor = _programColor;
                      borderWidth = 2;
                    }

                    return GestureDetector(
                      // 🧠 UPDATED: Opens Vibe Check when tapping a scheduled day
                      onTap: () {
                        if (assignedWorkout != null && !isRest) {
                          final exercises = _getExercisesForDate(currentDate);
                          _showVibeCheck(exercises, assignedWorkout);
                        } else if (isRest) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Rest Day! Recover and grow. 🧘"),
                              backgroundColor: Colors.grey.shade700,
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
                          children: [
                            Text(
                              "$dayOfMonth",
                              style: TextStyle(
                                color:
                                    isToday
                                        ? Colors.white
                                        : isRest
                                        ? Colors.white.withOpacity(0.3)
                                        : Colors.white,
                                fontSize: 14,
                                fontWeight:
                                    isToday
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (isCompleted)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 16,
                              )
                            else if (isRest)
                              Icon(
                                Icons.bedtime,
                                color: Colors.white.withOpacity(0.2),
                                size: 14,
                              )
                            else if (assignedWorkout != null)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _programColor,
                                  shape: BoxShape.circle,
                                ),
                              )
                            else
                              const SizedBox(height: 8),
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
      ),
    );
  }

  Widget _buildTodaysMissionBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F),
        border: Border(
          top: BorderSide(color: _programColor.withOpacity(0.3), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Today's Mission",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  _isTodayRestDay
                      ? "Rest & Recovery Day 🧘"
                      : _todaysWorkoutName ?? "No workout scheduled",
                  style: TextStyle(
                    color: _isTodayRestDay ? Colors.white54 : _programColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (!_isTodayRestDay && _todaysWorkoutName != null)
            Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_programColor, _programColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _programColor.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                // 🧠 UPDATED: Opens Vibe Check from the Mission Bar
                onPressed: () {
                  _showVibeCheck(
                    _todaysExercises,
                    _todaysWorkoutName ?? "Workout",
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow, color: Colors.white, size: 20),
                    SizedBox(width: 4),
                    Text(
                      "Start",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return months[month - 1];
  }
}

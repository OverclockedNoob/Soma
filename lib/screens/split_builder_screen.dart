import 'package:flutter/material.dart';
import 'package:workout_tracker/services/storage_services.dart';

class SplitBuilderScreen extends StatefulWidget {
  const SplitBuilderScreen({super.key});

  @override
  State<SplitBuilderScreen> createState() => _SplitBuilderScreenState();
}

class _SplitBuilderScreenState extends State<SplitBuilderScreen> {
  final TextEditingController _nameController = TextEditingController(
    text: "My 4-Week Split",
  );
  int _durationWeeks = 4;

  // 🎨 NEW: Color Picker State
  int _selectedColorValue = 0xFF6C5CE7; // Default Purple
  final List<Color> _presetColors = [
    const Color(0xFF6C5CE7), // Purple
    const Color(0xFFFF6B9D), // Pink
    const Color(0xFF00D9FF), // Cyan
    const Color(0xFFFFB800), // Orange
    const Color(0xFF4CAF50), // Green
    const Color(0xFFE91E63), // Deep Pink
  ];

  Map<String, String?> _schedule = {
    "Monday": null,
    "Tuesday": null,
    "Wednesday": null,
    "Thursday": null,
    "Friday": null,
    "Saturday": null,
    "Sunday": null,
  };

  List<Map<String, dynamic>> _savedWorkouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedWorkouts();
  }

  void _loadSavedWorkouts() {
    final workouts = CustomWorkoutStorage.getAllCustomWorkouts();
    setState(() {
      _savedWorkouts = workouts;
      _isLoading = false;
    });
  }

  void _assignWorkoutToDay(String day) {
    if (_savedWorkouts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please create a Custom Workout first!")),
      );
      return;
    }

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
              Text(
                "Assign workout for $day",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _schedule[day] = null);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.bedtime, color: Colors.white),
                  label: const Text(
                    "Rest Day",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _savedWorkouts.length,
                  itemBuilder: (context, index) {
                    final workout = _savedWorkouts[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _schedule[day] = workout['id']);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF6C5CE7,
                          ).withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: const BorderSide(color: Color(0xFF6C5CE7)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.fitness_center,
                              color: Color(0xFF6C5CE7),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                workout['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
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

  void _saveSplit() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please name your split!")));
      return;
    }

    final program = {
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "name": _nameController.text.trim(),
      "durationWeeks": _durationWeeks,
      "startDate": DateTime.now().toIso8601String(),
      "schedule": _schedule,
      "colorValue": _selectedColorValue, // 🎨 SAVE THE COLOR
    };

    ProgramStorage.saveProgram(program);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${program['name']} created successfully! 🎉"),
        backgroundColor: Color(_selectedColorValue),
      ),
    );
  }

  String? _getWorkoutNameForDay(String day) {
    final workoutId = _schedule[day];
    if (workoutId == null) return null;
    final workout = _savedWorkouts.firstWhere(
      (w) => w['id'] == workoutId,
      orElse: () => {},
    );
    return workout['name'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = Color(_selectedColorValue);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Create Split",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
              )
              : SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name Input
                            const Text(
                              "Split Name",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E3F),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selectedColor.withOpacity(0.5),
                                ),
                              ),
                              child: TextField(
                                controller: _nameController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'e.g., Month 1: PPL',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(20),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 🎨 COLOR PICKER
                            const Text(
                              "Split Theme Color",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children:
                                  _presetColors.map((color) {
                                    bool isSelected =
                                        _selectedColorValue == color.value;
                                    return GestureDetector(
                                      onTap:
                                          () => setState(
                                            () =>
                                                _selectedColorValue =
                                                    color.value,
                                          ),
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                          right: 14,
                                        ),
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color:
                                                isSelected
                                                    ? Colors.white
                                                    : Colors.transparent,
                                            width: 3,
                                          ),
                                          boxShadow:
                                              isSelected
                                                  ? [
                                                    BoxShadow(
                                                      color: color.withOpacity(
                                                        0.6,
                                                      ),
                                                      blurRadius: 10,
                                                    ),
                                                  ]
                                                  : null,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                            const SizedBox(height: 32),

                            // Duration Selector
                            const Text(
                              "Duration",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E3F),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selectedColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Weeks",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed:
                                            _durationWeeks > 1
                                                ? () => setState(
                                                  () => _durationWeeks--,
                                                )
                                                : null,
                                        icon: Icon(
                                          Icons.remove_circle_outline,
                                          color:
                                              _durationWeeks > 1
                                                  ? selectedColor
                                                  : Colors.white24,
                                        ),
                                      ),
                                      Text(
                                        "$_durationWeeks",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed:
                                            () => setState(
                                              () => _durationWeeks++,
                                            ),
                                        icon: Icon(
                                          Icons.add_circle_outline,
                                          color: selectedColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Schedule Header
                            const Text(
                              "Weekly Schedule",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Tap a day to assign a workout or rest.",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Days of the Week List
                            ..._schedule.keys.map((day) {
                              final workoutName = _getWorkoutNameForDay(day);
                              final isRest = workoutName == null;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E3F),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        isRest
                                            ? Colors.white.withOpacity(0.1)
                                            : selectedColor,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          isRest
                                              ? Colors.white.withOpacity(0.1)
                                              : selectedColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isRest
                                          ? Icons.bedtime
                                          : Icons.fitness_center,
                                      color:
                                          isRest
                                              ? Colors.white54
                                              : selectedColor,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    day,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    isRest ? "Rest Day" : workoutName,
                                    style: TextStyle(
                                      color:
                                          isRest
                                              ? Colors.white54
                                              : selectedColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                    color: Colors.white54,
                                  ),
                                  onTap: () => _assignWorkoutToDay(day),
                                ),
                              );
                            }),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    // Save Button
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              selectedColor,
                              selectedColor.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: selectedColor.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _saveSplit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Save Split Program',
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
                    ),
                  ],
                ),
              ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:workout_tracker/services/storage_services.dart';
import '../core/premium_ui.dart';

class SplitBuilderScreen extends StatefulWidget {
  const SplitBuilderScreen({super.key});

  @override
  State<SplitBuilderScreen> createState() => _SplitBuilderScreenState();
}

class _SplitBuilderScreenState extends State<SplitBuilderScreen> {
  final TextEditingController _nameController = TextEditingController(text: "My 4-Week Split");
  int _durationWeeks = 4;

  // 🎨 COLOR PICKER STATE
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
        SnackBar(content: Text("Please create a Custom Workout first!", style: PUI.text())),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: PUI.surface.withOpacity(0.95),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  GradientText("Assign for $day", size: 22, weight: FontWeight.w800),
                  const SizedBox(height: 20),
                  
                  // Rest Day Option
                  Pressable(
                    onTap: () {
                      setState(() => _schedule[day] = null);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: PUI.mint.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: PUI.mint.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bedtime, color: PUI.mint),
                          const SizedBox(width: 12),
                          Text("Rest Day", style: PUI.text(size: 16, weight: FontWeight.w700, color: PUI.mint)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(children: [Expanded(child: Divider(color: Colors.white.withOpacity(0.1))), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("OR", style: PUI.text(size: 12, color: Colors.white.withOpacity(0.4)))), Expanded(child: Divider(color: Colors.white.withOpacity(0.1)))]),
                  const SizedBox(height: 16),

                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _savedWorkouts.length,
                      itemBuilder: (context, index) {
                        final workout = _savedWorkouts[index];
                        final isSelected = _schedule[day] == workout['id'];
                        final themeColor = Color(_selectedColorValue);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Pressable(
                            onTap: () {
                              setState(() => _schedule[day] = workout['id']);
                              Navigator.pop(context);
                            },
                            child: Glass(
                              radius: 16,
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: themeColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.fitness_center, color: themeColor, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      workout['name'],
                                      style: PUI.text(size: 16, weight: FontWeight.w700),
                                    ),
                                  ),
                                  if (isSelected) Icon(Icons.check_circle, color: themeColor),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _saveSplit() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please name your split!", style: PUI.text())),
      );
      return;
    }

    final program = {
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "name": _nameController.text.trim(),
      "durationWeeks": _durationWeeks,
      "startDate": DateTime.now().toIso8601String(),
      "schedule": _schedule,
      "colorValue": _selectedColorValue,
    };

    ProgramStorage.saveProgram(program);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${program['name']} created successfully! 🎉", style: PUI.text(weight: FontWeight.w700)),
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

    return PremiumScaffold(
      title: "Create Split",
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: PUI.primary))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── NAME INPUT ────────────────────────
                        Text("Split Name", style: PUI.text(size: 14, weight: FontWeight.w700, color: Colors.white.withOpacity(0.6))),
                        const SizedBox(height: 8),
                        Glass(
                          radius: 16,
                          padding: EdgeInsets.zero,
                          child: TextField(
                            controller: _nameController,
                            style: PUI.text(size: 16, weight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: 'e.g., Month 1: PPL',
                              hintStyle: PUI.text(color: Colors.white.withOpacity(0.3)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── COLOR PICKER ──────────────────────
                        Text("Theme Color", style: PUI.text(size: 14, weight: FontWeight.w700, color: Colors.white.withOpacity(0.6))),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 44,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _presetColors.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              final color = _presetColors[index];
                              final isSelected = _selectedColorValue == color.value;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedColorValue = color.value),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: isSelected ? 44 : 36,
                                  height: isSelected ? 44 : 36,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 3),
                                    boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 12)] : [],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── DURATION ──────────────────────────
                        Text("Duration", style: PUI.text(size: 14, weight: FontWeight.w700, color: Colors.white.withOpacity(0.6))),
                        const SizedBox(height: 8),
                        Glass(
                          radius: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Weeks", style: PUI.text(size: 16, weight: FontWeight.w700)),
                              Row(
                                children: [
                                  Pressable(
                                    onTap: _durationWeeks > 1 ? () => setState(() => _durationWeeks--) : null,
                                    child: Icon(Icons.remove_circle_outline, color: _durationWeeks > 1 ? selectedColor : Colors.white24, size: 28),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: GradientText("$_durationWeeks", size: 28, colors: [Colors.white, selectedColor]),
                                  ),
                                  Pressable(
                                    onTap: () => setState(() => _durationWeeks++),
                                    child: Icon(Icons.add_circle_outline, color: selectedColor, size: 28),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── SCHEDULE ──────────────────────────
                        const SectionTitle("Weekly Schedule"),
                        const SizedBox(height: 16),
                        ..._schedule.keys.map((day) {
                          final workoutName = _getWorkoutNameForDay(day);
                          final isRest = workoutName == null;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Pressable(
                              onTap: () => _assignWorkoutToDay(day),
                              child: Glass(
                                radius: 16,
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isRest ? Colors.white.withOpacity(0.05) : selectedColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isRest ? Icons.bedtime : Icons.fitness_center,
                                        color: isRest ? Colors.white54 : selectedColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(day, style: PUI.text(size: 16, weight: FontWeight.w700)),
                                          Text(
                                            isRest ? "Rest Day" : workoutName!,
                                            style: PUI.text(size: 12, color: isRest ? Colors.white54 : selectedColor, weight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // ── SAVE BUTTON ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: PrimaryButton(
                    label: "Save Split Program",
                    icon: Icons.save_rounded,
                    onTap: _saveSplit,
                  ),
                ),
              ],
            ),
    );
  }
} 
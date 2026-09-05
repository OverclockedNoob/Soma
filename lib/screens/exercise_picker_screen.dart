import 'package:flutter/material.dart';
import 'package:workout_tracker/data/exercise_data.dart';
import '../core/premium_ui.dart';

class ExercisePickerScreen extends StatefulWidget {
  final List<String> alreadyAdded; // To prevent adding the same exercise twice

  const ExercisePickerScreen({super.key, this.alreadyAdded = const []});

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  String selectedCategory = "All";
  String searchQuery = "";
  late final TextEditingController _searchController;

  static const List<String> categories = [
    "All",
    "Chest",
    "Back",
    "Legs",
    "Arms",
    "Shoulders",
    "Core",
    "Cardio",
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredExercises {
    var exercises = List<Map<String, dynamic>>.from(ExerciseData.allExercises);
    if (selectedCategory != "All") {
      exercises = exercises.where((e) => e["muscle"] == selectedCategory).toList();
    }
    if (searchQuery.isNotEmpty) {
      exercises = exercises
          .where((e) =>
              (e["name"] as String).toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }
    exercises.sort((a, b) => (a["name"] as String).compareTo(b["name"] as String));
    return exercises;
  }

  @override
  Widget build(BuildContext context) {
    final exercises = filteredExercises;

    return PremiumScaffold(
      title: 'Select Exercise',
      body: Column(
        children: [
          // ── SEARCH BAR ─────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Glass(
              radius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.5), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: PUI.text(size: 15, weight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: "Search exercises...",
                        hintStyle: PUI.text(color: Colors.white.withOpacity(0.3)),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) => setState(() => searchQuery = value),
                    ),
                  ),
                  if (searchQuery.isNotEmpty)
                    Pressable(
                      onTap: () {
                        _searchController.clear();
                        setState(() => searchQuery = "");
                      },
                      child: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.5), size: 20),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── CATEGORY CHIPS ─────────────────────
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Pressable(
                    onTap: () => setState(() => selectedCategory = category),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(colors: [PUI.primary, PUI.primaryDeep])
                            : null,
                        color: isSelected ? null : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? PUI.primary.withOpacity(0.5) : Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Text(
                        category,
                        style: PUI.text(
                          size: 13,
                          weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // ── EXERCISE LIST ──────────────────────
          Expanded(
            child: exercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: Colors.white.withOpacity(0.2)),
                        const SizedBox(height: 12),
                        Text("No exercises found", style: PUI.text(size: 16, color: Colors.white.withOpacity(0.5))),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      final isAdded = widget.alreadyAdded.contains(exercise["name"]);
                      final muscleColor = ExerciseData.getMuscleColor(exercise["muscle"] as String?);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: IgnorePointer(
                          ignoring: isAdded,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: isAdded ? 0.4 : 1.0,
                            child: Pressable(
                              onTap: isAdded
                                  ? null
                                  : () {
                                      Navigator.pop(context, {
                                        'name': exercise["name"],
                                        'muscle': exercise["muscle"],
                                        'difficulty': exercise["difficulty"],
                                      });
                                    },
                              child: Glass(
                                radius: 16,
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: muscleColor.withOpacity(isAdded ? 0.05 : 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        ExerciseData.getMuscleIcon(exercise["muscle"] as String?),
                                        color: muscleColor,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            exercise["name"] as String,
                                            style: PUI.text(size: 15, weight: FontWeight.w700),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            exercise["muscle"] as String,
                                            style: PUI.text(
                                              size: 12,
                                              weight: FontWeight.w600,
                                              color: muscleColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    isAdded
                                        ? Icon(Icons.check_circle, color: PUI.mint.withOpacity(0.6), size: 20)
                                        : Icon(Icons.add_circle_rounded, color: muscleColor, size: 26),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:workout_tracker/data/exercise_data.dart';

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

  List<Map<String, String>> get filteredExercises {
    var exercises = List<Map<String, String>>.from(ExerciseData.allExercises);
    if (selectedCategory != "All") {
      exercises =
          exercises.where((e) => e["muscle"] == selectedCategory).toList();
    }
    if (searchQuery.isNotEmpty) {
      exercises =
          exercises
              .where(
                (e) => e["name"]!.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ),
              )
              .toList();
    }
    exercises.sort((a, b) => a["name"]!.compareTo(b["name"]!));
    return exercises;
  }

  @override
  Widget build(BuildContext context) {
    final exercises = filteredExercises;

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
          'Select Exercise',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E3F),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6C5CE7).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: Colors.white.withOpacity(0.5),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: "Search exercises...",
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                          ),
                          border: InputBorder.none,
                        ),
                        onChanged:
                            (value) => setState(() => searchQuery = value),
                      ),
                    ),
                    if (searchQuery.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => searchQuery = "");
                        },
                      ),
                  ],
                ),
              ),
            ),

            // Category Chips
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = selectedCategory == category;
                  return Container(
                    margin: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      onTap: () => setState(() => selectedCategory = category),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient:
                              isSelected
                                  ? const LinearGradient(
                                    colors: [
                                      Color(0xFF6C5CE7),
                                      Color(0xFF9B59B6),
                                    ],
                                  )
                                  : null,
                          color: isSelected ? null : const Color(0xFF1E1E3F),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                isSelected
                                    ? Colors.transparent
                                    : const Color(0xFF6C5CE7).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color:
                                isSelected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.7),
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Exercise List
            Expanded(
              child:
                  exercises.isEmpty
                      ? Center(
                        child: Text(
                          "No exercises found",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = exercises[index];
                          final isAdded = widget.alreadyAdded.contains(
                            exercise["name"],
                          );
                          final muscleColor = ExerciseData.getMuscleColor(
                            exercise["muscle"],
                          );

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E3F),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    isAdded
                                        ? Colors.white.withOpacity(0.1)
                                        : muscleColor.withOpacity(0.3),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: muscleColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  ExerciseData.getMuscleIcon(
                                    exercise["muscle"],
                                  ),
                                  color: muscleColor,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                exercise["name"]!,
                                style: TextStyle(
                                  color:
                                      isAdded
                                          ? Colors.white.withOpacity(0.4)
                                          : Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                exercise["muscle"]!,
                                style: TextStyle(
                                  color:
                                      isAdded
                                          ? Colors.white.withOpacity(0.3)
                                          : muscleColor,
                                  fontSize: 12,
                                ),
                              ),
                              trailing:
                                  isAdded
                                      ? Text(
                                        'Added',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.3),
                                          fontSize: 12,
                                        ),
                                      )
                                      : Icon(
                                        Icons.add_circle,
                                        color: muscleColor,
                                        size: 28,
                                      ),
                              onTap:
                                  isAdded
                                      ? null
                                      : () {
                                        Navigator.pop(context, {
                                          'name': exercise["name"],
                                          'muscle': exercise["muscle"],
                                          'difficulty': exercise["difficulty"],
                                        });
                                      },
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

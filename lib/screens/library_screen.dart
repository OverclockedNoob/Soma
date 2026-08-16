import 'package:flutter/material.dart';
import 'package:workout_tracker/data/exercise_data.dart';
import 'exercise_detail_screen.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  String selectedCategory = "All";
  String selectedDifficulty = "All";
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
  static const List<String> difficulties = [
    "All",
    "Beginner",
    "Intermediate",
    "Advanced",
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

  List<Map<String, String>> getFilteredExercises() {
    var exercises = List<Map<String, String>>.from(ExerciseData.allExercises);
    if (selectedCategory != "All")
      exercises =
          exercises.where((e) => e["muscle"] == selectedCategory).toList();
    if (selectedDifficulty != "All")
      exercises =
          exercises
              .where((e) => e["difficulty"] == selectedDifficulty)
              .toList();
    if (searchQuery.isNotEmpty) {
      exercises =
          exercises
              .where(
                (e) =>
                    e["name"]!.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ||
                    e["muscle"]!.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ),
              )
              .toList();
    }
    exercises.sort((a, b) => a["name"]!.compareTo(b["name"]!));
    return exercises;
  }

  bool get hasActiveFilters =>
      selectedCategory != "All" ||
      selectedDifficulty != "All" ||
      searchQuery.isNotEmpty;

  void _clearAllFilters() {
    setState(() {
      selectedCategory = "All";
      selectedDifficulty = "All";
      searchQuery = "";
      _searchController.clear();
    });
  }

  void _clearSearch() {
    setState(() {
      searchQuery = "";
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredExercises = getFilteredExercises();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Exercise",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "Library",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                "${filteredExercises.length}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "of ${ExerciseData.allExercises.length} total",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: Colors.white.withOpacity(0.7),
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
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                              ),
                              onChanged:
                                  (value) =>
                                      setState(() => searchQuery = value),
                            ),
                          ),
                          if (searchQuery.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              onPressed: _clearSearch,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Categories",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (hasActiveFilters)
                        TextButton(
                          onPressed: _clearAllFilters,
                          child: const Text(
                            "Clear Filters",
                            style: TextStyle(
                              color: Color(0xFFE91E63),
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder:
                          (context, index) =>
                              _buildCategoryChip(categories[index]),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: difficulties.length,
                      itemBuilder:
                          (context, index) =>
                              _buildDifficultyChip(difficulties[index]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "${filteredExercises.length} exercise${filteredExercises.length == 1 ? '' : 's'} found",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child:
                  filteredExercises.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: filteredExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = filteredExercises[index];
                          return _buildExerciseCard(
                            context,
                            exercise["name"]!,
                            exercise["muscle"]!,
                            exercise["difficulty"]!,
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = selectedCategory == label;
    final count = ExerciseData.getCountForCategory(label);
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap:
            () => setState(() {
              selectedCategory = label;
              searchQuery = "";
              _searchController.clear();
            }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient:
                isSelected
                    ? const LinearGradient(
                      colors: [Color(0xFF6C5CE7), Color(0xFF9B59B6)],
                    )
                    : null,
            color: isSelected ? null : const Color(0xFF1E1E3F),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isSelected
                      ? Colors.transparent
                      : const Color(0xFF6C5CE7).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ExerciseData.getMuscleIcon(label == "All" ? null : label),
                color: isSelected ? Colors.white : const Color(0xFF6C5CE7),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color:
                      isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? Colors.white.withOpacity(0.25)
                          : const Color(0xFF6C5CE7).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF6C5CE7),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(String difficulty) {
    final isSelected = selectedDifficulty == difficulty;
    final color =
        difficulty == "All"
            ? const Color(0xFF6C5CE7)
            : ExerciseData.getDifficultyColor(difficulty);
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: () => setState(() => selectedDifficulty = difficulty),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color:
                isSelected ? color.withOpacity(0.2) : const Color(0xFF1E1E3F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            difficulty,
            style: TextStyle(
              color: isSelected ? color : Colors.white.withOpacity(0.5),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            "No exercises found",
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty
                ? 'No results for "$searchQuery"'
                : selectedCategory != "All" && selectedDifficulty != "All"
                ? 'No $selectedDifficulty $selectedCategory exercises'
                : selectedCategory != "All"
                ? 'No exercises in $selectedCategory'
                : 'No $selectedDifficulty exercises',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: _clearAllFilters,
            icon: const Icon(Icons.refresh, color: Color(0xFF6C5CE7)),
            label: const Text(
              'Clear all filters',
              style: TextStyle(color: Color(0xFF6C5CE7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    String name,
    String muscle,
    String difficulty,
  ) {
    final muscleColor = ExerciseData.getMuscleColor(muscle);
    final muscleIcon = ExerciseData.getMuscleIcon(muscle);
    final difficultyColor = ExerciseData.getDifficultyColor(difficulty);
    final difficultyIcon = ExerciseData.getDifficultyIcon(difficulty);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1E3F),
            const Color(0xFF1E1E3F).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: muscleColor.withOpacity(0.3), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ExerciseDetailScreen(
                        name: name,
                        muscle: muscle,
                        difficulty: difficulty,
                      ),
                ),
              ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        muscleColor.withOpacity(0.3),
                        muscleColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(muscleIcon, color: muscleColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: muscleColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              muscle,
                              style: TextStyle(
                                color: muscleColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            difficultyIcon,
                            color: difficultyColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            difficulty,
                            style: TextStyle(
                              color: difficultyColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: muscleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: muscleColor,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

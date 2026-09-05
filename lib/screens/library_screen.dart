import 'package:flutter/material.dart';
import 'package:workout_tracker/data/exercise_data.dart';
import 'exercise_detail_screen.dart';
import '../core/premium_ui.dart';

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
    "Shoulders",
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

  List<Map<String, dynamic>> getFilteredExercises() {
    var exercises = List<Map<String, dynamic>>.from(ExerciseData.allExercises);
    if (selectedCategory != "All") {
      exercises = exercises.where((e) => e["muscle"] == selectedCategory).toList();
    }
    if (selectedDifficulty != "All") {
      exercises = exercises.where((e) => e["difficulty"] == selectedDifficulty).toList();
    }
    if (searchQuery.isNotEmpty) {
      exercises = exercises
          .where((e) =>
              (e["name"] as String).toLowerCase().contains(searchQuery.toLowerCase()) ||
              (e["muscle"] as String).toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }
    exercises.sort((a, b) => (a["name"] as String).compareTo(b["name"] as String));
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

    return PremiumScaffold(
      aurora: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "EXERCISE LIBRARY",
                        style: PUI.text(
                          size: 11,
                          weight: FontWeight.w600,
                          letterSpacing: 2.2,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      GradientText("Find Your\nNext Move", size: 28),
                    ],
                  ),
                  _buildStatsBadge(filteredExercises.length),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildSearchBar(),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SectionTitle(
                "Filters",
                actionLabel: hasActiveFilters ? "Clear All" : null,
                onAction: hasActiveFilters ? _clearAllFilters : null,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) => _buildCategoryChip(categories[index]),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: difficulties.length,
                itemBuilder: (context, index) => _buildDifficultyChip(difficulties[index]),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "${filteredExercises.length} exercise${filteredExercises.length == 1 ? '' : 's'}",
                style: PUI.text(
                  size: 14,
                  weight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (filteredExercises.isEmpty)
              _buildEmptyState()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: filteredExercises.length,
                itemBuilder: (context, index) {
                  final exercise = filteredExercises[index];
                  return _buildExerciseCard(
                    context,
                    exercise["name"] as String,
                    exercise["muscle"] as String,
                    exercise["difficulty"] as String,
                  );
                },
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBadge(int count) {
    return Glass(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            "$count",
            style: PUI.text(size: 24, weight: FontWeight.w800, color: PUI.primary),
          ),
          Text(
            "of ${ExerciseData.allExercises.length}",
            style: PUI.text(size: 10, color: Colors.white.withOpacity(0.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Glass(
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.white.withOpacity(0.5), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: PUI.text(size: 15, color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search exercises...",
                hintStyle: PUI.text(size: 15, color: Colors.white.withOpacity(0.4)),
                border: InputBorder.none,
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          if (searchQuery.isNotEmpty)
            Pressable(
              onTap: _clearSearch,
              child: Icon(Icons.close, color: Colors.white.withOpacity(0.6), size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = selectedCategory == label;
    final count = ExerciseData.getCountForCategory(label);
    final muscleColor = label == "All" ? PUI.primary : ExerciseData.getMuscleColor(label);

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Pressable(
        onTap: () => setState(() {
          selectedCategory = label;
          searchQuery = "";
          _searchController.clear();
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: [muscleColor, muscleColor.withOpacity(0.6)])
                : null,
            color: isSelected ? null : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? muscleColor.withOpacity(0.5) : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ExerciseData.getMuscleIcon(label == "All" ? null : label),
                color: isSelected ? Colors.white : muscleColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: PUI.text(
                  size: 13,
                  weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : muscleColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: PUI.text(
                    size: 10,
                    weight: FontWeight.w700,
                    color: isSelected ? Colors.white : muscleColor,
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
    final color = difficulty == "All" ? PUI.primary : ExerciseData.getDifficultyColor(difficulty);

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Pressable(
        onTap: () => setState(() => selectedDifficulty = difficulty),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.white.withOpacity(0.08),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            difficulty,
            style: PUI.text(
              size: 12,
              weight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? color : Colors.white.withOpacity(0.4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: PUI.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 64,
                color: PUI.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No exercises found",
              style: PUI.text(size: 20, weight: FontWeight.w700),
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
              style: PUI.text(size: 14, color: Colors.white.withOpacity(0.5)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Pressable(
              onTap: _clearAllFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: PUI.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: PUI.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, color: PUI.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Clear all filters',
                      style: PUI.text(size: 14, weight: FontWeight.w600, color: PUI.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Pressable(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseDetailScreen(
              name: name,
              muscle: muscle,
              difficulty: difficulty,
            ),
          ),
        ),
        child: Glass(
          radius: 20,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      muscleColor.withOpacity(0.35),
                      muscleColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(muscleIcon, color: muscleColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: PUI.text(size: 16, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: muscleColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            muscle,
                            style: PUI.text(size: 11, weight: FontWeight.w700, color: muscleColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(difficultyIcon, color: difficultyColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          difficulty,
                          style: PUI.text(size: 11, weight: FontWeight.w600, color: difficultyColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
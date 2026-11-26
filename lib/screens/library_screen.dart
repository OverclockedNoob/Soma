import 'dart:async';

import 'package:flutter/material.dart';

import '../core/premium_ui.dart';
import '../data/exercise_data.dart';
import '../models/workout_models.dart';
import 'exercise_detail_screen.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  String selectedCategory = 'All';
  String selectedDifficulty = 'All';
  String searchQuery = '';
  late final TextEditingController _searchController;

  static const List<String> categories = <String>[
    'All',
    'Chest',
    'Back',
    'Legs',
    'Arms',
    'Shoulders',
    'Core',
    'Cardio',
  ];

  static const List<String> difficulties = <String>[
    'All',
    'Beginner',
    'Intermediate',
    'Advanced',
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

  List<ExerciseItem> getFilteredExercises() {
    final all = ExerciseData.items;
    final trimmedQuery = searchQuery.trim().toLowerCase();

    if (selectedCategory == 'All' &&
        selectedDifficulty == 'All' &&
        trimmedQuery.isEmpty) {
      return all;
    }

    return all.where((ExerciseItem e) {
      if (selectedCategory != 'All' && e.muscle != selectedCategory) {
        return false;
      }
      if (selectedDifficulty != 'All' && e.difficulty != selectedDifficulty) {
        return false;
      }
      if (trimmedQuery.isNotEmpty) {
        final matchesName = e.name.toLowerCase().contains(trimmedQuery);
        final matchesMuscle = e.muscle.toLowerCase().contains(trimmedQuery);
        final matchesTarget = e.target.toLowerCase().contains(trimmedQuery);
        final matchesEquip = e.equipment.toLowerCase().contains(trimmedQuery);
        if (!matchesName && !matchesMuscle && !matchesTarget && !matchesEquip) {
          return false;
        }
      }
      return true;
    }).toList(growable: false);
  }

  bool get hasActiveFilters =>
      selectedCategory != 'All' ||
      selectedDifficulty != 'All' ||
      searchQuery.trim().isNotEmpty;

  void _clearAllFilters() {
    setState(() {
      selectedCategory = 'All';
      selectedDifficulty = 'All';
      searchQuery = '';
      _searchController.clear();
    });
  }

  void _clearSearch() {
    setState(() {
      searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredExercises = getFilteredExercises();
    final totalCatalogCount = ExerciseData.items.length;

    return PremiumScaffold(
      aurora: true,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'EXERCISE LIBRARY',
                            style: PUI.text(
                              size: 11,
                              weight: FontWeight.w600,
                              letterSpacing: 2.2,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const GradientText('Find Your\nNext Move', size: 28),
                        ],
                      ),
                      _buildStatsBadge(
                        filteredExercises.length,
                        totalCatalogCount,
                      ),
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
                    'Filters',
                    actionLabel: hasActiveFilters ? 'Clear All' : null,
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
                    itemBuilder: (BuildContext context, int index) =>
                        _buildCategoryChip(categories[index]),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    scrollDirection: Axis.horizontal,
                    itemCount: difficulties.length,
                    itemBuilder: (BuildContext context, int index) =>
                        _buildDifficultyChip(difficulties[index]),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    '${filteredExercises.length} exercise${filteredExercises.length == 1 ? '' : 's'}',
                    style: PUI.text(
                      size: 14,
                      weight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          if (filteredExercises.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              sliver: SliverList.builder(
                itemCount: filteredExercises.length,
                itemBuilder: (BuildContext context, int index) {
                  return _buildExerciseCard(context, filteredExercises[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsBadge(int count, int totalCount) {
    return Glass(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            '$count',
            style: PUI.text(
              size: 24,
              weight: FontWeight.w800,
              color: PUI.primary,
            ),
          ),
          Text(
            'of $totalCount',
            style: PUI.text(
              size: 10,
              color: Colors.white.withValues(alpha: 0.4),
            ),
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
        children: <Widget>[
          Icon(
            Icons.search,
            color: Colors.white.withValues(alpha: 0.5),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: PUI.text(size: 15, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name, muscle, or equipment...',
                hintStyle: PUI.text(
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
              ),
              onChanged: (String value) => setState(() => searchQuery = value),
            ),
          ),
          if (searchQuery.isNotEmpty)
            Pressable(
              onTap: _clearSearch,
              child: Icon(
                Icons.close,
                color: Colors.white.withValues(alpha: 0.6),
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = selectedCategory == label;
    final count = ExerciseData.getCountForCategory(label);
    final muscleColor = label == 'All'
        ? PUI.primary
        : ExerciseData.getMuscleColor(label);

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Pressable(
        onTap: () => setState(() => selectedCategory = label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: <Color>[
                      muscleColor,
                      muscleColor.withValues(alpha: 0.6),
                    ],
                  )
                : null,
            color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? muscleColor.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                ExerciseData.getMuscleIcon(label == 'All' ? null : label),
                color: isSelected ? Colors.white : muscleColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: PUI.text(
                  size: 13,
                  weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : muscleColor.withValues(alpha: 0.15),
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
    final color = difficulty == 'All'
        ? PUI.primary
        : ExerciseData.getDifficultyColor(difficulty);

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Pressable(
        onTap: () => setState(() => selectedDifficulty = difficulty),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.white.withValues(alpha: 0.08),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            difficulty,
            style: PUI.text(
              size: 12,
              weight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? color : Colors.white.withValues(alpha: 0.4),
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
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: PUI.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 64,
                color: PUI.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No exercises found',
              style: PUI.text(size: 20, weight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.trim().isNotEmpty
                  ? 'No results for "${searchQuery.trim()}"'
                  : selectedCategory != 'All' && selectedDifficulty != 'All'
                      ? 'No $selectedDifficulty $selectedCategory exercises'
                      : selectedCategory != 'All'
                          ? 'No exercises in $selectedCategory'
                          : 'No $selectedDifficulty exercises',
              style: PUI.text(
                size: 14,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Pressable(
              onTap: _clearAllFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: PUI.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: PUI.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.refresh, color: PUI.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Clear all filters',
                      style: PUI.text(
                        size: 14,
                        weight: FontWeight.w600,
                        color: PUI.primary,
                      ),
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

  Widget _buildExerciseCard(BuildContext context, ExerciseItem item) {
    final muscleColor = ExerciseData.getMuscleColor(item.muscle);
    final muscleIcon = ExerciseData.getMuscleIcon(item.muscle);
    final difficultyColor = ExerciseData.getDifficultyColor(item.difficulty);
    final difficultyIcon = ExerciseData.getDifficultyIcon(item.difficulty);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Pressable(
        onTap: () => unawaited(
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ExerciseDetailScreen(
                exerciseId: item.id,
                name: item.name,
                muscle: item.muscle,
                difficulty: item.difficulty,
              ),
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PUI.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      muscleColor.withValues(alpha: 0.35),
                      muscleColor.withValues(alpha: 0.1),
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
                  children: <Widget>[
                    Text(
                      item.name,
                      style: PUI.text(size: 16, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: muscleColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.muscle,
                            style: PUI.text(
                              size: 11,
                              weight: FontWeight.w700,
                              color: muscleColor,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              difficultyIcon,
                              color: difficultyColor,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.difficulty,
                              style: PUI.text(
                                size: 11,
                                weight: FontWeight.w600,
                                color: difficultyColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

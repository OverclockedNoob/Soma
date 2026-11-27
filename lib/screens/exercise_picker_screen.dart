import 'package:flutter/material.dart';

import '../core/premium_ui.dart';
import '../data/exercise_data.dart';
import '../models/workout_models.dart';

class ExercisePickerScreen extends StatefulWidget {
  final List<String> alreadyAdded;

  const ExercisePickerScreen({
    super.key,
    this.alreadyAdded = const <String>[],
  });

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  String selectedCategory = 'All';
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

  List<ExerciseItem> get filteredExercises {
    final all = ExerciseData.items;
    final trimmed = searchQuery.trim().toLowerCase();
    if (selectedCategory == 'All' && trimmed.isEmpty) {
      return all;
    }
    return all.where((ExerciseItem e) {
      if (selectedCategory != 'All' && e.muscle != selectedCategory) {
        return false;
      }
      if (trimmed.isNotEmpty) {
        final byName = e.name.toLowerCase().contains(trimmed);
        final byTarget = e.target.toLowerCase().contains(trimmed);
        final byEquipment = e.equipment.toLowerCase().contains(trimmed);
        if (!byName && !byTarget && !byEquipment) return false;
      }
      return true;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final exercises = filteredExercises;
    final addedSet = widget.alreadyAdded
        .map((String s) => s.toLowerCase())
        .toSet();

    return PremiumScaffold(
      title: 'Select Exercise',
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 8.0,
            ),
            child: Glass(
              radius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: PUI.text(size: 15, weight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Search 500 local exercises...',
                        hintStyle: PUI.text(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: (String value) =>
                          setState(() => searchQuery = value),
                    ),
                  ),
                  if (searchQuery.isNotEmpty)
                    Pressable(
                      onTap: () {
                        _searchController.clear();
                        setState(() => searchQuery = '');
                      },
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: categories.length,
              itemBuilder: (BuildContext context, int index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Pressable(
                    onTap: () => setState(() => selectedCategory = category),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: <Color>[PUI.primary, PUI.primaryDeep],
                              )
                            : null,
                        color: isSelected
                            ? null
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? PUI.primary.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        category,
                        style: PUI.text(
                          size: 13,
                          weight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: exercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No exercises found',
                          style: PUI.text(
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: exercises.length,
                    itemBuilder: (BuildContext context, int index) {
                      final exercise = exercises[index];
                      final isAdded = addedSet.contains(
                        exercise.name.toLowerCase(),
                      );
                      final muscleColor =
                          ExerciseData.getMuscleColor(exercise.muscle);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: IgnorePointer(
                          ignoring: isAdded,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 250),
                            opacity: isAdded ? 0.4 : 1.0,
                            child: Pressable(
                              onTap: isAdded
                                  ? null
                                  : () {
                                      Navigator.pop(
                                        context,
                                        <String, dynamic>{
                                          'exerciseId': exercise.id,
                                          'name': exercise.name,
                                          'muscle': exercise.muscle,
                                          'difficulty': exercise.difficulty,
                                          'equipment': exercise.equipment,
                                        },
                                      );
                                    },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: PUI.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: muscleColor.withValues(
                                          alpha: isAdded ? 0.05 : 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        ExerciseData.getMuscleIcon(
                                          exercise.muscle,
                                        ),
                                        color: muscleColor,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            exercise.name,
                                            style: PUI.text(
                                              size: 15,
                                              weight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${exercise.muscle} • ${exercise.difficulty}',
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
                                        ? Icon(
                                            Icons.check_circle,
                                            color: PUI.mint.withValues(
                                              alpha: 0.6,
                                            ),
                                            size: 20,
                                          )
                                        : Icon(
                                            Icons.add_circle_rounded,
                                            color: muscleColor,
                                            size: 26,
                                          ),
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

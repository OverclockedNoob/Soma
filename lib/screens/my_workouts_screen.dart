import 'package:flutter/material.dart';
import 'package:workout_tracker/services/storage_services.dart';
import 'active_workout_screen.dart';
import '../core/premium_ui.dart';

class MyWorkoutsScreen extends StatefulWidget {
  const MyWorkoutsScreen({super.key});

  @override
  State<MyWorkoutsScreen> createState() => _MyWorkoutsScreenState();
}

class _MyWorkoutsScreenState extends State<MyWorkoutsScreen> {
  List<Map<String, dynamic>> _workouts = [];

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  void _loadWorkouts() {
    setState(() {
      _workouts = CustomWorkoutStorage.getAllCustomWorkouts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      aurora: true,
      title: 'My Workouts',
      body: _workouts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center, size: 80, color: PUI.primary.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text("No custom workouts yet", style: PUI.text(size: 18, weight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text("Go to the Library and add exercises!", style: PUI.text(color: Colors.white.withOpacity(0.5))),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _workouts.length,
              itemBuilder: (context, i) {
                final w = _workouts[i];
                final exercises = w['exercises'] as List<dynamic>? ?? [];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Pressable(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActiveWorkoutScreen(
                            customExercises: List<Map<String, dynamic>>.from(exercises),
                          ),
                        ),
                      ).then((_) => _loadWorkouts());
                    },
                    child: Glass(
                      radius: 20,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w['name'] as String,
                            style: PUI.text(size: 20, weight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "${exercises.length} exercise${exercises.length == 1 ? '' : 's'}",
                            style: PUI.text(size: 14, color: PUI.primary, weight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...exercises.take(3).map((ex) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    ex['name'] as String,
                                    style: PUI.text(size: 12, weight: FontWeight.w600),
                                  ),
                                );
                              }),
                              if (exercises.length > 3)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: PUI.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "+${exercises.length - 3} more",
                                    style: PUI.text(size: 12, weight: FontWeight.w700, color: PUI.primary),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
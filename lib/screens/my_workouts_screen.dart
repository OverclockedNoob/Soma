import 'package:flutter/material.dart';
import 'package:workout_tracker/services/storage_services.dart';
import 'active_workout_screen.dart';
import '../core/premium_ui.dart';

// Just a list view over whatever's saved in CustomWorkoutStorage. Nothing
// fancy — no sorting, no search yet. Add those if this ever gets used for
// more than a handful of saved routines.
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
      final rawWorkouts = CustomWorkoutStorage.getAllCustomWorkouts();
      // Hive hands back a Map<dynamic, dynamic> under the hood, so we cast
      // to Map<String, dynamic> here or literally everything downstream
      // that expects string keys blows up
      _workouts = rawWorkouts.map((w) => Map<String, dynamic>.from(w as Map)).toList();
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
                final rawExercises = w['exercises'] as List? ?? [];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Pressable(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActiveWorkoutScreen(
                            customExercises: rawExercises.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
                          ),
                        ),
                        // reload when they come back in case they logged
                        // a workout and something here needs to reflect that
                        // later (not used for much right now, but cheap to do)
                      ).then((_) => _loadWorkouts());
                    },
                    child: Glass(
                      radius: 20,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w['name'] as String? ?? 'Untitled', style: PUI.text(size: 20, weight: FontWeight.w800)),
                          const SizedBox(height: 12),
                          Text("${rawExercises.length} exercise${rawExercises.length == 1 ? '' : 's'}", style: PUI.text(size: 14, color: PUI.primary, weight: FontWeight.w600)),
                          const SizedBox(height: 16),
                          // only show the first 3 exercise chips + a "+N more"
                          // pill, otherwise long workouts blow out the card height
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...rawExercises.take(3).map((ex) {
                                final exMap = Map<String, dynamic>.from(ex as Map);
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                                  child: Text(exMap['name'] as String? ?? '', style: PUI.text(size: 12, weight: FontWeight.w600)),
                                );
                              }),
                              if (rawExercises.length > 3)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: PUI.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                                  child: Text("+${rawExercises.length - 3} more", style: PUI.text(size: 12, weight: FontWeight.w700, color: PUI.primary)),
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
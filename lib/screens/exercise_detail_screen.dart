import 'package:flutter/material.dart';
import 'package:workout_tracker/data/exercise_data.dart';
import 'package:workout_tracker/services/exercisedb_service.dart';
import 'package:workout_tracker/services/storage_services.dart';
import '../core/premium_ui.dart';
import 'active_workout_screen.dart';

// Shows the details for a single exercise — sets/reps/rest recommendations,
// primary + secondary muscles worked, a description, step-by-step form
// instructions, and buttons to either quick-start it solo or add it into an
// existing/new custom workout.
//
// Note: this screen used to render a "GIF demo" via CachedNetworkImage with a
// RapidAPI key header. That whole path was dead code — the bundled dataset has
// no media URLs (0 of 500 entries), and the api_keys.dart file it imported is
// gitignored, so fresh clones of the repo didn't even compile. Removed along
// with the cached_network_image dependency; the styled placeholder below is
// what every exercise was showing anyway.
class ExerciseDetailScreen extends StatelessWidget {
  final String name;
  final String muscle;
  final String difficulty;

  const ExerciseDetailScreen({super.key, required this.name, required this.muscle, required this.difficulty});

  Color get muscleColor => ExerciseData.getMuscleColor(muscle);
  IconData get muscleIcon => ExerciseData.getMuscleIcon(muscle);
  IconData get difficultyIcon => ExerciseData.getDifficultyIcon(difficulty);
  Color get difficultyColor => ExerciseData.getDifficultyColor(difficulty);

  // matching purely by name against the cached exercise list — works fine
  // since names are unique in our dataset, but if that ever changes we'd
  // want to pass an actual id into this screen instead
  ExerciseDbExercise? get _apiExercise {
    try { return ExerciseDbService.getCached().firstWhere((e) => e.name == name); } catch (_) { return null; }
  }

  String? get equipment => _apiExercise?.equipment;
  String? get target => _apiExercise?.target;
  List<String> get apiInstructions => _apiExercise?.instructions ?? [];
  String? get description => _apiExercise?.description;
  String? get category => _apiExercise?.category;
  List<String> get apiSecondaryMuscles => _apiExercise?.secondaryMuscles ?? const [];

  String get recommendedSets {
    switch (difficulty) {
      case 'Beginner': return '2-3';
      case 'Intermediate': return '3-4';
      case 'Advanced': return '4-5';
      default: return '3-4';
    }
  }

  String get recommendedReps {
    if (muscle == 'Cardio') return '30-60s';
    if (muscle == 'Core') {
      switch (difficulty) { case 'Beginner': return '20-30s'; case 'Intermediate': return '30-60s'; default: return '45-90s'; }
    }
    switch (difficulty) { case 'Beginner': return '10-15'; case 'Intermediate': return '8-12'; case 'Advanced': return '6-10'; default: return '8-12'; }
  }

  String get recommendedRest {
    switch (difficulty) { case 'Beginner': return '60s'; case 'Intermediate': return '45s'; case 'Advanced': return '30s'; default: return '60s'; }
  }

  // Last-resort fallback only. Every one of the 500 bundled exercises ships
  // real step-by-step instructions (see apiInstructions below), and the UI
  // prefers those — this hardcoded text only shows if an exercise somehow
  // isn't found in the cache by name, so the old "only 3 exercises have real
  // steps" TODO no longer applies.
  String get instructions {
    switch (name) {
      case 'Push-ups': return '1. Start in a plank position with hands slightly wider than shoulders.\n\n2. Keep your body in a straight line from head to heels.\n\n3. Lower your body until your chest nearly touches the floor.\n\n4. Push yourself back up to the starting position.\n\n5. Repeat for desired reps.';
      case 'Squats': return '1. Stand with feet shoulder-width apart, toes slightly out.\n\n2. Keep your chest up and core engaged.\n\n3. Lower your body by bending knees and pushing hips back.\n\n4. Go down until thighs are parallel to the floor.\n\n5. Push through your heels to return to standing.';
      case 'Plank': return '1. Start on your forearms and toes.\n\n2. Keep your body in a perfectly straight line.\n\n3. Engage your core and squeeze your glutes.\n\n4. Hold without letting hips sag or rise.\n\n5. Breathe steadily throughout the hold.';
      default: return '1. Set up in the correct starting position.\n\n2. Engage your core throughout the movement.\n\n3. Move through the full range of motion.\n\n4. Control the movement on the way back.\n\n5. Breathe steadily and maintain good form.';
    }
  }

  // static for now, same 3 tips on every exercise regardless of muscle group.
  // could eventually be smarter (e.g. different tips for cardio vs strength)
  List<Map<String, dynamic>> get proTips {
    return [
      {'title': 'Focus on Form', 'description': 'Quality over quantity - maintain proper form', 'icon': Icons.check_circle, 'color': PUI.mint},
      {'title': 'Breathe Right', 'description': 'Exhale on exertion, inhale on release', 'icon': Icons.air, 'color': PUI.primary},
      {'title': 'Stay Hydrated', 'description': 'Drink water before, during, and after', 'icon': Icons.water_drop, 'color': PUI.amber},
    ];
  }

  // Real secondary-muscle data from the bundled dataset (every entry has it —
  // 'triceps', 'shoulders', 'forearms', etc.). Falls back to the old generic
  // 'Core' placeholder only if the exercise isn't found in the cache.
  Map<String, List<String>> get musclesWorked {
    final secondary = apiSecondaryMuscles
        .where((m) => m.toLowerCase() != muscle.toLowerCase())
        .toList();
    return {
      'Primary': [muscle],
      'Secondary': secondary.isNotEmpty ? secondary : ['Core'],
    };
  }

  // not wired up to anything right now — leaving it here since I remember
  // wanting a "favorite this exercise" or "report an issue" button that
  // would use this, just haven't gotten to it
  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🚀 $feature is being upgraded next!', style: PUI.text(weight: FontWeight.w600)), backgroundColor: PUI.surface, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  void _quickStart(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ActiveWorkoutScreen(customExercises: [{'name': name, 'muscle': muscle, 'difficulty': difficulty, 'sets': 3, 'targetReps': 10}])));
  }

  void _showAddToWorkoutSheet(BuildContext context) async {
    final rawWorkouts = CustomWorkoutStorage.getAllCustomWorkouts();
    final workouts = rawWorkouts.map((w) => Map<String, dynamic>.from(w as Map)).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: PUI.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Text("Add to Workout", style: PUI.text(size: 22, weight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text("Where do you want to put $name?", style: PUI.text(size: 14, color: Colors.white.withOpacity(0.6))),
            const SizedBox(height: 24),
            if (workouts.isEmpty)
              Center(child: Text("No custom workouts yet. Create one!", style: PUI.text(color: Colors.white.withOpacity(0.5))))
            else
              // Overflow fix: this used to be a ConstrainedBox with a fixed
              // maxHeight of 300, which overflowed on smaller screens once
              // someone had 4+ saved workouts in their vault. Flexible lets
              // the list take whatever room is actually left after the
              // header and the "Create New" button below, and scrolls
              // internally instead of trying to force a fixed height.
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: workouts.length,
                  itemBuilder: (context, i) {
                    final w = workouts[i];
                    return Pressable(
                      onTap: () {
                        // mutating the map directly and re-saving the whole
                        // workout — a bit heavy-handed but storage layer
                        // doesn't support partial updates right now
                        final rawExercises = w['exercises'] as List? ?? [];
                        final exercises = rawExercises.map((e) => Map<String, dynamic>.from(e as Map)).toList();
                        exercises.add({'name': name, 'muscle': muscle, 'difficulty': difficulty, 'sets': 3, 'targetReps': 10});
                        w['exercises'] = exercises;
                        CustomWorkoutStorage.saveCustomWorkout(w);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added to ${w['name']}!"), backgroundColor: PUI.mint));
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
                        child: Row(children: [const Icon(Icons.fitness_center, color: PUI.primary), const SizedBox(width: 12), Expanded(child: Text(w['name'] as String? ?? '', style: PUI.text(weight: FontWeight.w700))), const Icon(Icons.add_circle_outline, color: PUI.mint)]),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () { Navigator.pop(context); _createNewWorkoutWithExercise(context); },
                style: ElevatedButton.styleFrom(backgroundColor: PUI.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                icon: const Icon(Icons.add),
                label: Text("Create New Workout", style: PUI.text(weight: FontWeight.w700)),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _createNewWorkoutWithExercise(BuildContext context) async {
    final controller = TextEditingController();
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PUI.surface,
        title: Text("New Workout", style: PUI.text(weight: FontWeight.w700)),
        content: TextField(controller: controller, decoration: InputDecoration(hintText: "e.g. Push Day", hintStyle: PUI.text(color: Colors.white38)), style: PUI.text()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: PUI.text(color: Colors.white54))),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), style: ElevatedButton.styleFrom(backgroundColor: PUI.primary), child: Text("Create", style: PUI.text(weight: FontWeight.w700)))
        ],
      ),
    );

    // no trimming/validation on newName here — an all-whitespace name would
    // technically slip through. low priority, but worth a look eventually
    if (newName != null && newName.isNotEmpty) {
      final newWorkout = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': newName,
        'exercises': [{'name': name, 'muscle': muscle, 'difficulty': difficulty, 'sets': 3, 'targetReps': 10}],
      };
      CustomWorkoutStorage.saveCustomWorkout(newWorkout);
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Created '$newName' with $name!"), backgroundColor: PUI.mint));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: 'Exercise',
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: difficultyColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: difficultyColor.withOpacity(0.4))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(difficultyIcon, color: difficultyColor, size: 14), const SizedBox(width: 6), Text(difficulty, style: PUI.text(size: 12, weight: FontWeight.w700, color: difficultyColor))]),
        ),
      ],
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 20), child: _buildDemoBanner()),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GradientText(name, size: 30, weight: FontWeight.w900),
                  const SizedBox(height: 12),
                  if (equipment != null || target != null || category != null) Wrap(spacing: 8, runSpacing: 8, children: [if (equipment != null && equipment!.isNotEmpty) _buildInfoChip(Icons.construction, _titleCase(equipment!)), if (target != null && target!.isNotEmpty) _buildInfoChip(Icons.track_changes, _titleCase(target!)), if (category != null && category!.isNotEmpty) _buildInfoChip(Icons.category_outlined, _titleCase(category!))]),
                  // short blurb from the dataset ("This exercise primarily
                  // targets...") — new, the data was always there but unused
                  if (description != null && description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(description!, style: PUI.text(size: 14, color: Colors.white.withOpacity(0.7)).copyWith(height: 1.5)),
                  ],
                  const SizedBox(height: 20),
                  Row(children: [Expanded(child: _buildStatCard(recommendedSets, "Sets", Icons.repeat)), const SizedBox(width: 12), Expanded(child: _buildStatCard(recommendedReps, "Reps", Icons.fitness_center)), const SizedBox(width: 12), Expanded(child: _buildStatCard(recommendedRest, "Rest", Icons.timer))]),
                  const SizedBox(height: 28),
                  const SectionTitle("Muscles Worked"),
                  const SizedBox(height: 12),
                  Glass(
                    radius: 20, padding: const EdgeInsets.all(16),
                    child: Column(
                      children: musclesWorked.entries.map((entry) {
                        final isPrimary = entry.key == 'Primary';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 80, child: Text(entry.key, style: PUI.text(size: 13, weight: FontWeight.w700, color: isPrimary ? muscleColor : Colors.white.withOpacity(0.4)))),
                              Expanded(
                                child: Wrap(
                                  spacing: 6, runSpacing: 6,
                                  children: entry.value.map((m) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: isPrimary ? muscleColor.withOpacity(0.2) : Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)), child: Text(m, style: PUI.text(size: 12, weight: FontWeight.w600, color: isPrimary ? muscleColor : Colors.white.withOpacity(0.4))))).toList(),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const SectionTitle("Form Instructions"),
                  const SizedBox(height: 12),
                  // prefer the API's step-by-step instructions when we have
                  // them, only fall back to our hardcoded generic text
                  // when the API has nothing for this exercise
                  Glass(
                    radius: 20, padding: const EdgeInsets.all(20),
                    child: apiInstructions.isNotEmpty
                        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            for (int i = 0; i < apiInstructions.length; i++) Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: muscleColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Text('${i + 1}', style: PUI.text(size: 12, weight: FontWeight.w800, color: muscleColor))),
                                const SizedBox(width: 12),
                                Expanded(child: Text(apiInstructions[i], style: PUI.text(size: 14, color: Colors.white.withOpacity(0.8)).copyWith(height: 1.5))),
                              ]),
                            ),
                          ])
                        : Text(instructions, style: PUI.text(size: 15, color: Colors.white.withOpacity(0.8)).copyWith(height: 1.6)),
                  ),
                  const SizedBox(height: 28),
                  const SectionTitle("Pro Tips"),
                  const SizedBox(height: 12),
                  ...proTips.map((tip) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildTipCard(tip['title'] as String, tip['description'] as String, tip['icon'] as IconData, tip['color'] as Color))),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Row(
              children: [
                Expanded(
                  child: Pressable(
                    onTap: () => _quickStart(context),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(color: muscleColor.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: muscleColor.withOpacity(0.5), width: 2)),
                      child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.play_arrow, color: muscleColor, size: 20), const SizedBox(width: 4), Text("Quick Start", style: PUI.text(size: 14, weight: FontWeight.w800, color: muscleColor))])),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Pressable(
                    onTap: () => _showAddToWorkoutSheet(context),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [muscleColor, muscleColor.withOpacity(0.7)]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: muscleColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))]),
                      child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.add_circle, color: Colors.white), const SizedBox(width: 8), Text("Add to Workout", style: PUI.text(size: 15, weight: FontWeight.w800))])),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _titleCase(String s) => s.split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: PUI.mint, size: 14), const SizedBox(width: 6), Text(label, style: PUI.text(size: 12, weight: FontWeight.w600, color: Colors.white.withOpacity(0.7)))]),
    );
  }

  // Renamed from _buildVideoPlayer — it never actually played anything. The
  // bundled dataset ships no demo media (see the note at the top of this
  // file), so this is the styled muscle-icon banner every exercise shows.
  Widget _buildDemoBanner() {
    return Container(
      width: double.infinity, height: 240,
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [PUI.surface, PUI.bg]), borderRadius: BorderRadius.circular(24), border: Border.all(color: muscleColor.withOpacity(0.3), width: 1), boxShadow: [BoxShadow(color: muscleColor.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Stack(
        children: [
          Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(24), child: CustomPaint(painter: _GridPainter(color: Colors.white.withOpacity(0.03))))),
          Positioned(
            top: 16, left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(20), border: Border.all(color: muscleColor.withOpacity(0.6))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.local_fire_department, color: muscleColor, size: 16), const SizedBox(width: 6), Text("Target: $muscle", style: PUI.text(size: 12, weight: FontWeight.w700, color: muscleColor))]),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(muscleIcon, size: 80, color: muscleColor.withOpacity(0.8)),
                const SizedBox(height: 8),
                Text("See form instructions below", style: PUI.text(size: 12, color: Colors.white.withOpacity(0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Glass(
      radius: 16, padding: const EdgeInsets.all(14),
      child: Column(children: [Icon(icon, color: muscleColor, size: 22), const SizedBox(height: 8), GradientText(value, size: 18, colors: [Colors.white, muscleColor]), const SizedBox(height: 4), Text(label, style: PUI.text(size: 12, color: Colors.white.withOpacity(0.6)))]),
    );
  }

  Widget _buildTipCard(String title, String description, IconData icon, Color color) {
    return Glass(
      radius: 16, padding: const EdgeInsets.all(16),
      child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: PUI.text(size: 15, weight: FontWeight.w700)), const SizedBox(height: 4), Text(description, style: PUI.text(size: 13, color: Colors.white.withOpacity(0.6)))]))]),
    );
  }
}

// faint background grid on the video/GIF placeholder, purely decorative
class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1;
    const spacing = 20.0;
    for (double i = 0; i < size.width; i += spacing) canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    for (double i = 0; i < size.height; i += spacing) canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
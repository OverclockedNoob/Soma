import 'package:flutter/material.dart';
import 'package:workout_tracker/data/exercise_data.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final String name;
  final String muscle;
  final String difficulty;

  const ExerciseDetailScreen({
    super.key,
    required this.name,
    required this.muscle,
    required this.difficulty,
  });

  Color get muscleColor => ExerciseData.getMuscleColor(muscle);
  IconData get muscleIcon => ExerciseData.getMuscleIcon(muscle);
  IconData get difficultyIcon => ExerciseData.getDifficultyIcon(difficulty);
  Color get difficultyColor => ExerciseData.getDifficultyColor(difficulty);

  String get recommendedSets {
    switch (difficulty) {
      case 'Beginner':
        return '2-3';
      case 'Intermediate':
        return '3-4';
      case 'Advanced':
        return '4-5';
      default:
        return '3-4';
    }
  }

  String get recommendedReps {
    if (muscle == 'Cardio') return '30-60s';
    if (muscle == 'Core') {
      switch (difficulty) {
        case 'Beginner':
          return '20-30s';
        case 'Intermediate':
          return '30-60s';
        default:
          return '45-90s';
      }
    }
    switch (difficulty) {
      case 'Beginner':
        return '10-15';
      case 'Intermediate':
        return '8-12';
      case 'Advanced':
        return '6-10';
      default:
        return '8-12';
    }
  }

  String get recommendedRest {
    switch (difficulty) {
      case 'Beginner':
        return '60s';
      case 'Intermediate':
        return '45s';
      case 'Advanced':
        return '30s';
      default:
        return '60s';
    }
  }

  String get instructions {
    switch (name) {
      case 'Push-ups':
        return '1. Start in a plank position with hands slightly wider than shoulders.\n\n2. Keep your body in a straight line from head to heels.\n\n3. Lower your body until your chest nearly touches the floor.\n\n4. Push yourself back up to the starting position.\n\n5. Repeat for desired reps.';
      case 'Squats':
        return '1. Stand with feet shoulder-width apart, toes slightly out.\n\n2. Keep your chest up and core engaged.\n\n3. Lower your body by bending knees and pushing hips back.\n\n4. Go down until thighs are parallel to the floor.\n\n5. Push through your heels to return to standing.';
      case 'Plank':
        return '1. Start on your forearms and toes.\n\n2. Keep your body in a perfectly straight line.\n\n3. Engage your core and squeeze your glutes.\n\n4. Hold without letting hips sag or rise.\n\n5. Breathe steadily throughout the hold.';
      default:
        return '1. Set up in the correct starting position.\n\n2. Engage your core throughout the movement.\n\n3. Move through the full range of motion.\n\n4. Control the movement on the way back.\n\n5. Breathe steadily and maintain good form.';
    }
  }

  List<Map<String, dynamic>> get proTips {
    return [
      {
        'title': 'Focus on Form',
        'description': 'Quality over quantity - maintain proper form',
        'icon': Icons.check_circle,
        'color': const Color(0xFF4CAF50),
      },
      {
        'title': 'Breathe Right',
        'description': 'Exhale on exertion, inhale on release',
        'icon': Icons.air,
        'color': const Color(0xFF00D9FF),
      },
      {
        'title': 'Stay Hydrated',
        'description': 'Drink water before, during, and after',
        'icon': Icons.water_drop,
        'color': const Color(0xFF6C5CE7),
      },
    ];
  }

  Map<String, List<String>> get musclesWorked {
    return {
      'Primary': [muscle],
      'Secondary': ['Core'],
    };
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🚀 $feature is being upgraded next!'),
        backgroundColor: const Color(0xFF6C5CE7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(difficultyIcon, color: difficultyColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  difficulty,
                  style: TextStyle(
                    color: difficultyColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── 3D Video Player Viewport ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: _build3DVideoPlayer(),
          ),

          // ── Scrollable Details ───────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          recommendedSets,
                          "Sets",
                          Icons.repeat,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          recommendedReps,
                          "Reps",
                          Icons.fitness_center,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          recommendedRest,
                          "Rest",
                          Icons.timer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    "Muscles Worked",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E3F),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: muscleColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children:
                          musclesWorked.entries.map((entry) {
                            final isPrimary = entry.key == 'Primary';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      entry.key,
                                      style: TextStyle(
                                        color:
                                            isPrimary
                                                ? muscleColor
                                                : Colors.white.withOpacity(0.4),
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children:
                                          entry.value.map((m) {
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    isPrimary
                                                        ? muscleColor
                                                            .withOpacity(0.2)
                                                        : Colors.white
                                                            .withOpacity(0.05),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                m,
                                                style: TextStyle(
                                                  color:
                                                      isPrimary
                                                          ? muscleColor
                                                          : Colors.white
                                                              .withOpacity(0.4),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    "Form Instructions",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E3F),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: muscleColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      instructions,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    "Pro Tips",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...proTips.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildTipCard(
                        tip['title'] as String,
                        tip['description'] as String,
                        tip['icon'] as IconData,
                        tip['color'] as Color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Bottom Action Buttons ────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: muscleColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () => _showComingSoon(context, 'Quick Start'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_arrow,
                              color: muscleColor,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Quick Start",
                              style: TextStyle(
                                color: muscleColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [muscleColor, muscleColor.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: muscleColor.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed:
                          () => _showComingSoon(context, 'Workout Builder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "Add to Workout",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
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

  // ── 3D Video Player UI ───────────────────────────────────────────
  Widget _build3DVideoPlayer() {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF1A1A2E), const Color(0xFF0A0E21)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: muscleColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: muscleColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 3D Grid Background
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(color: Colors.white.withOpacity(0.03)),
            ),
          ),

          // Muscle Target Badge
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: muscleColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: muscleColor.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: muscleColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Target: $muscle",
                    style: TextStyle(
                      color: muscleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3D Model Placeholder
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(muscleIcon, size: 80, color: muscleColor.withOpacity(0.8)),
                const SizedBox(height: 8),
                Text(
                  "3D Form Demonstration",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Play Button Overlay
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: muscleColor.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: muscleColor.withOpacity(0.5),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),

          // Mock Video Progress Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: 0.3,
                        minHeight: 4,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(muscleColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "0:12 / 0:45",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: muscleColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: muscleColor, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Paints the subtle 3D grid background
class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1;
    const spacing = 20.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

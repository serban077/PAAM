/// Maps exercise names to their IDs in the free-exercise-db GitHub repository.
/// Images are 2-frame JPGs (starting position + ending position) hosted on
/// GitHub CDN: https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/
///
/// Animating between frame 0 and frame 1 creates a looping exercise demonstration.
class ExerciseGifUtils {
  static const String _base =
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/';

  /// exercise name → free-exercise-db folder ID
  static const Map<String, String> _ids = {
    // ── Chest ──────────────────────────────────────────────────────────
    'Barbell Bench Press': 'Barbell_Bench_Press_-_Medium_Grip',
    'Push-Ups': 'Pushups',
    'Dumbbell Flyes': 'Dumbbell_Flyes',
    'Incline Dumbbell Press': 'Incline_Dumbbell_Press',
    // ── Back ───────────────────────────────────────────────────────────
    'Pull-Ups': 'Pullups',
    'Barbell Deadlift': 'Barbell_Deadlift',
    'Barbell Rows': 'Bent_Over_Barbell_Row',
    'Single-Arm Dumbbell Row': 'Bent_Over_One-Arm_Long_Bar_Row',
    'Lat Pulldown': 'Wide-Grip_Lat_Pulldown',
    // ── Legs ───────────────────────────────────────────────────────────
    'Barbell Squat': 'Barbell_Squat',
    'Lunges': 'Barbell_Lunge',
    'Romanian Deadlift': 'Romanian_Deadlift',
    'Leg Press': 'Leg_Press',
    // ── Shoulders ──────────────────────────────────────────────────────
    'Overhead Press': 'Barbell_Shoulder_Press',
    'Dumbbell Lateral Raises': 'Side_Lateral_Raise',
    'Dumbbell Front Raises': 'Front_Dumbbell_Raise',
    // ── Arms ───────────────────────────────────────────────────────────
    'Barbell Bicep Curls': 'Barbell_Curl',
    'Overhead Tricep Extension': 'Lying_Triceps_Press',
    'Alternating Dumbbell Curls': 'Alternate_Hammer_Curl',
    'Tricep Dips': 'Bench_Dips',
    // ── Abs ────────────────────────────────────────────────────────────
    'Plank': 'Plank',
    'Crunches': 'Crunches',
    'Hanging Leg Raises': 'Hanging_Leg_Raise',
    'Russian Twists': 'Russian_Twist',
    'Mountain Climbers': 'Mountain_Climbers',
    // ── Romanian name aliases ──────────────────────────────────────────
    'Flotări': 'Pushups',
    'Fandări': 'Barbell_Lunge',
    'Genuflexiuni': 'Barbell_Squat',
    'Genuflexiuni cu Greutatea Corporală': 'Barbell_Squat',
  };

  /// Returns the URL for the starting-position frame (frame 0), or null if
  /// this exercise has no mapped entry.
  static String? getFrame0Url(String exerciseName) {
    final id = _ids[exerciseName];
    if (id == null) return null;
    return '$_base$id/0.jpg';
  }

  /// Returns the URL for the ending-position frame (frame 1), or null if
  /// this exercise has no mapped entry.
  static String? getFrame1Url(String exerciseName) {
    final id = _ids[exerciseName];
    if (id == null) return null;
    return '$_base$id/1.jpg';
  }
}

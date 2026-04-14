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
    'Barbell Bench Press':        'Barbell_Bench_Press_-_Medium_Grip',
    'Push-Ups':                   'Pushups',
    'Dumbbell Flyes':             'Dumbbell_Flyes',
    'Incline Dumbbell Press':     'Incline_Dumbbell_Press',
    'Decline Bench Press':        'Decline_Barbell_Bench_Press',
    'Cable Chest Fly':            'Cable_Crossover',
    'Dips (Chest-Focused)':       'Dips_-_Chest_Version',
    'Pec Deck Machine':           'Pec_Deck_Fly',
    'Close-Grip Bench Press':     'Close-Grip_Barbell_Bench_Press',

    // ── Back ───────────────────────────────────────────────────────────
    'Pull-Ups':                   'Pullups',
    'Barbell Deadlift':           'Barbell_Deadlift',
    'Barbell Rows':               'Bent_Over_Barbell_Row',
    'Single-Arm Dumbbell Row':    'Bent_Over_One-Arm_Long_Bar_Row',
    'Lat Pulldown':               'Wide-Grip_Lat_Pulldown',
    'Seated Cable Row':           'Seated_Cable_Rows',
    'T-Bar Row':                  'T-Bar_Row_with_Handle',
    'Hyperextension':             'Hyperextensions_With_No_Hyperextension_Bench',
    'Face Pull':                  'Face_Pull',
    'Inverted Row':               'Inverted_Row',

    // ── Legs ───────────────────────────────────────────────────────────
    'Barbell Squat':              'Barbell_Squat',
    'Lunges':                     'Barbell_Lunge',
    'Romanian Deadlift':          'Romanian_Deadlift',
    'Leg Press':                  'Leg_Press',
    'Bulgarian Split Squat':      'Barbell_Rear_Lunge',
    'Leg Extension':              'Leg_Extensions',
    'Leg Curl':                   'Lying_Leg_Curls',
    'Sumo Squat':                 'Dumbbell_Sumo_Squat',
    'Step-Ups':                   'Barbell_Step_Ups',
    'Hack Squat':                 'Barbell_Hack_Squat',

    // ── Glutes ─────────────────────────────────────────────────────────
    'Barbell Hip Thrust':         'Barbell_Hip_Thrust',
    'Glute Bridge':               'Glute_Bridge',
    'Cable Kickback':             'Cable_Hip_Adduction',
    'Donkey Kick':                'Donkey_Kickback',
    'Sumo Deadlift':              'Sumo_Deadlift',
    'Good Morning':               'Good_Morning',

    // ── Calves ─────────────────────────────────────────────────────────
    'Standing Calf Raise':        'Standing_Calf_Raises',
    'Seated Calf Raise':          'Seated_Calf_Raise',
    'Single-Leg Calf Raise':      'Calf_Raises',
    'Donkey Calf Raise':          'Donkey_Calf_Raises',
    'Calf Press on Leg Press':    'Calf_Press',

    // ── Shoulders ──────────────────────────────────────────────────────
    'Overhead Press':             'Barbell_Shoulder_Press',
    'Dumbbell Lateral Raises':    'Side_Lateral_Raise',
    'Arnold Press':               'Arnold_Dumbbell_Press',
    'Dumbbell Shoulder Press':    'Dumbbell_Shoulder_Press',
    'Upright Row':                'Upright_Barbell_Row',
    'Rear Delt Fly':              'Seated_Bent-Over_Rear_Delt_Raise',
    'Dumbbell Front Raise':       'Front_Dumbbell_Raise',
    'Cable Lateral Raise':        'Cable_Lateral_Raise',
    'Barbell Shrugs':             'Barbell_Shrug',

    // ── Arms ───────────────────────────────────────────────────────────
    'Barbell Bicep Curls':        'Barbell_Curl',
    'Overhead Tricep Extension':  'Lying_Triceps_Press',
    'Hammer Curls':               'Alternate_Hammer_Curl',
    'Tricep Dips':                'Bench_Dips',
    'Cable Bicep Curls':          'Cable_Curl',
    'Skull Crushers':             'EZ-Bar_Skullcrusher',
    'Preacher Curl':              'Barbell_Preacher_Curl',
    'Tricep Pushdown':            'Triceps_Pushdown',
    'Concentration Curl':         'Concentration_Curls',
    'Diamond Push-Ups':           'Close-Grip_Push-Up',

    // ── Forearms ───────────────────────────────────────────────────────
    'Wrist Curl':                 'Palms_Up_Barbell_Wrist_Curl_Over_A_Bench',
    'Reverse Wrist Curl':         'Palms_Down_Wrist_Curl_Over_A_Bench',
    'Reverse Curl':               'Reverse_Barbell_Curl',

    // ── Abs ────────────────────────────────────────────────────────────
    'Plank':                      'Plank',
    'Crunches':                   'Crunches',
    'Hanging Leg Raises':         'Hanging_Leg_Raise',
    'Russian Twists':             'Russian_Twist',
    'Mountain Climbers':          'Mountain_Climbers',
    'Bicycle Crunches':           'Bicycle_Crunch',
    'Ab Rollout':                 'Ab_Wheel_Rollout',
    'Cable Crunch':               'Cable_Crunch',

    // ── Full Body ──────────────────────────────────────────────────────
    'Barbell Thruster':           'Barbell_Thruster',
    'Kettlebell Swing':           'Kettlebell_Swing',
    'Burpees':                    'Burpees',

    // ── Plyometrics ────────────────────────────────────────────────────
    'Box Jump':                   'Box_Jump_(Multiple_Response)',
    'Jump Squat':                 'Jump_Squat',
    'Lateral Bound':              'Side_Hop',
    'Tuck Jump':                  'Tuck_Jump',

    // ── Cardio ─────────────────────────────────────────────────────────
    'High Knees':                 'High_Knees',
    'Jumping Jacks':              'Jumping_Jacks',
    'Jump Rope':                  'Jump_Rope',

    // ── Legacy Romanian aliases (backward compatibility) ───────────────
    'Flotări':                    'Pushups',
    'Fandări':                    'Barbell_Lunge',
    'Genuflexiuni':               'Barbell_Squat',
    'Genuflexiuni cu Greutatea Corporală': 'Barbell_Squat',
    'Alternating Dumbbell Curls': 'Alternate_Hammer_Curl',
    'Overhead Tricep Extension (old)': 'Lying_Triceps_Press',
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

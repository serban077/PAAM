import 'package:dio/dio.dart';
import 'dart:convert';
import '../services/supabase_service.dart';
import '../data/verified_exercises_data.dart';

class GeminiAIService {
  static final GeminiAIService _instance = GeminiAIService._internal();
  Dio? _dio;
  GeminiClient? _client;
  static const String apiKey = String.fromEnvironment('GEMINI_API_KEY');
  bool _isInitialized = false;

  factory GeminiAIService() => _instance;

  GeminiAIService._internal();

  void _initializeService() {
    if (_isInitialized) return;
    
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY must be provided via --dart-define');
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://generativelanguage.googleapis.com/v1',
        headers: {'Content-Type': 'application/json'},
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final pathSegments = options.path.split('/');
          final model = pathSegments.length > 2
              ? pathSegments[2].split(':')[0]
              : null;
          if (model != null && _requiresV1Beta(model)) {
            options.baseUrl =
            'https://generativelanguage.googleapis.com/v1beta';
          }
          if (!options.queryParameters.containsKey('key')) {
            options.queryParameters['key'] = apiKey;
          }
          handler.next(options);
        },
      ),
    );

    _client = GeminiClient(_dio!, apiKey);
    _isInitialized = true;
  }

  bool _requiresV1Beta(String modelId) {
    return modelId.contains('preview') ||
        modelId.contains('exp') ||
        modelId.contains('thinking') ||
        modelId.startsWith('imagen-') ||
        modelId.contains('image-preview') ||
        modelId.contains('tts') ||
        modelId.contains('live');
  }

  GeminiClient get client {
    _initializeService(); // Ensure initialized before use
    return _client!;
  }

  Future<Map<String, dynamic>> getUserProfileData(String userId) async {
    _initializeService(); // Ensure initialized
    
    try {
      final profileResponse = await SupabaseService.instance.client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();

      final onboardingResponse = await SupabaseService.instance.client
          .from('onboarding_responses')
          .select()
          .eq('user_id', userId);

      final onboardingMap = <String, String>{};
      for (var response in onboardingResponse) {
        onboardingMap[response['question_key']] = response['answer_value'];
      }

      return {'profile': profileResponse, 'onboarding': onboardingMap};
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPersonalizedExercises(
      String userId,
      ) async {
    _initializeService(); // Ensure initialized
    
    final userData = await getUserProfileData(userId);
    final profile = userData['profile'];
    final onboarding = userData['onboarding'] as Map<String, String>;

    final prompt = _buildExercisePrompt(profile, onboarding);

    final message = Message(role: 'user', content: prompt);
    final response = await _client!.createChat(
      messages: [message],
      model: 'gemini-2.5-flash-lite',
      temperature: 0.7,
      maxTokens: 4096,
    );

    try {
      final cleanedText = response.text.trim();
      final jsonStart = cleanedText.indexOf('[');
      final jsonEnd = cleanedText.lastIndexOf(']') + 1;

      if (jsonStart == -1 || jsonEnd <= jsonStart) {
        throw FormatException('Invalid JSON response');
      }

      final jsonString = cleanedText.substring(jsonStart, jsonEnd);
      final exercises = jsonDecode(jsonString) as List;

      return exercises.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Failed to parse exercises: $e');
    }
  }


  Future<Map<String, dynamic>> generateWeeklyWorkoutPlan(String userId) async {
    _initializeService(); // Ensure initialized
    
    final userData = await getUserProfileData(userId);
    final profile = userData['profile'];
    final onboarding = userData['onboarding'] as Map<String, String>;

    final prompt = _buildWorkoutPlanPrompt(profile, onboarding);

    final message = Message(role: 'user', content: prompt);
    final response = await _client!.createChat(
      messages: [message],
      model: 'gemini-2.5-flash-lite',
      temperature: 0.7,
      maxTokens: 4096,
    );

    try {
      final cleanedText = response.text.trim();
      final jsonStart = cleanedText.indexOf('{');
      final jsonEnd = cleanedText.lastIndexOf('}') + 1;

      if (jsonStart == -1 || jsonEnd <= jsonStart) {
        throw FormatException('Invalid JSON response');
      }

      final jsonString = cleanedText.substring(jsonStart, jsonEnd);
      final parsedPlan = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Enrich exercises with video URLs from verified database
      final enrichedPlan = _enrichPlanWithVideoUrls(parsedPlan);
      
      return enrichedPlan;
    } catch (e) {
      throw Exception('Failed to parse workout plan: $e');
    }
  }

  /// Enriches the workout plan with video URLs from verified exercises database
  Map<String, dynamic> _enrichPlanWithVideoUrls(Map<String, dynamic> plan) {
    if (plan['training_plan'] == null) return plan;
    
    final trainingPlan = plan['training_plan'] as Map<String, dynamic>;
    final enrichedTrainingPlan = <String, dynamic>{};
    
    trainingPlan.forEach((dayKey, exercises) {
      if (exercises is! List) {
        enrichedTrainingPlan[dayKey] = exercises;
        return;
      }
      
      final enrichedExercises = <Map<String, dynamic>>[];
      
      for (var exercise in exercises) {
        if (exercise is! Map<String, dynamic>) continue;
        
        final exerciseName = exercise['exercise_name'] as String?;
        if (exerciseName == null) continue;
        
        // Find matching exercise in verified database
        final verifiedExercise = VerifiedExercisesData.getExerciseByName(exerciseName);
        
        if (verifiedExercise != null) {
          // Add video URL from verified database
          enrichedExercises.add({
            ...exercise,
            'video_url': verifiedExercise['videoUrl'],
          });
        } else {
          // Exercise not found in database - try to find closest match or use default
          print('Warning: Exercise "$exerciseName" not found in verified database');
          enrichedExercises.add({
            ...exercise,
            'video_url': 'https://www.youtube.com/watch?v=IODxDxX7oi4', // Default to push-ups video
          });
        }
      }
      
      enrichedTrainingPlan[dayKey] = enrichedExercises;
    });
    
    return {
      ...plan,
      'training_plan': enrichedTrainingPlan,
    };
  }

  /// Saves the generated plan structure to Supabase tables
  Future<void> saveGeneratedPlan(String userId, Map<String, dynamic> completePlan) async {
    try {
      // 1. Clean up old custom plans
      await SupabaseService.instance.client.rpc(
        'delete_user_custom_plans',
        params: {'target_user_id': userId},
      );

      final trainingPlan = completePlan['training_plan'] as Map<String, dynamic>;
      
      // 2. Determine frequency and fitness goal from profile for metadata
      final profile = await SupabaseService.instance.client
          .from('user_profiles')
          .select('weekly_training_frequency, fitness_goal, experience_level')
          .eq('id', userId)
          .single();
          
      final daysPerWeek = int.tryParse(profile['weekly_training_frequency']?.toString() ?? '3') ?? 3;
      final fitnessGoal = profile['fitness_goal']?.toString() ?? 'general';
      final fitnessLevel = profile['experience_level']?.toString() ?? 'intermediate';

      // 3. Create new Plan
      final planRes = await SupabaseService.instance.client
          .from('workout_plans')
          .insert({
            'plan_name': 'AI Custom Plan - $fitnessGoal', // Changed 'name' to 'plan_name'
            'fitness_goal': fitnessGoal, // Map to existing 'fitness_goal'
            'weekly_frequency': daysPerWeek, // Map to existing 'weekly_frequency'
            'days_per_week': daysPerWeek, // Keep for new logic
            'goal': fitnessGoal, // Keep for code consistency if column added
            'fitness_level': fitnessLevel, // New column
            'creator_id': userId,
          })
          .select()
          .single();
          
      final planId = planRes['id'];

      // 4. Create Sessions with Smart Scheduling
      // Map "day_1", "day_2" to specific days (1=Mon, 2=Tue, etc.)
      final dayMapping = _getSmartDayMapping(daysPerWeek);
      
      int dayIndex = 0;
      for (var entry in trainingPlan.entries) {
        if (dayIndex >= dayMapping.length) break;
        
        final sessionKey = entry.key; // e.g. "day_1"
        final exercises = entry.value as List;
        final assignedDayNumber = dayMapping[dayIndex];
        
        // Determine focus area (simple heuristic from first exercise or key)
        final focusArea = _inferFocusArea(exercises, sessionKey);
        
        // Insert Session
        final sessionRes = await SupabaseService.instance.client
            .from('workout_sessions')
            .insert({
              'plan_id': planId,
              'day_number': assignedDayNumber,
              'day_of_week': assignedDayNumber, // Map to existing legacy column
              'session_name': 'Ziua ${dayIndex + 1} - $focusArea',
              'focus_area': focusArea,
              'estimated_duration_minutes': 60, // Default
            })
            .select()
            .single();
            
        final sessionId = sessionRes['id'];
        
        // 5. Insert Session Exercises
        final sessionExercises = exercises.map((ex) {
           final exerciseMap = ex as Map<String, dynamic>;
           // Logic to link to verified exercises or generic
           // For simplicity, we assume we need to link to 'exercises' table.
           // Since we can't easily find/create exercises on the fly without more logic,
           // we might need to rely on the enriched verified data or create placeholders.
           
           // CRITICAL DECISION: We need the exercise ID from the 'exercises' table.
           // Implementation: Find by name or insert new if missing (if valid).
           
           return _prepareSessionExerciseData(sessionId, exerciseMap, exercises.indexOf(ex));
        }).toList();

        // We need to execute these insert operations, possibly one by one if we need IDs
        for (var dataFuture in sessionExercises) {
           final data = await dataFuture;
           if (data != null) {
             await SupabaseService.instance.client.from('session_exercises').insert(data);
           }
        }
        
        dayIndex++;
      }

      // 6. Activate Schedule
      await SupabaseService.instance.client
          .from('user_workout_schedules')
          .insert({
            'user_id': userId,
            'plan_id': planId,
            'start_date': DateTime.now().toIso8601String(),
            'is_active': true,
          });

    } catch (e) {
      print('Error saving generated plan: $e');
      throw Exception('Could not save plan to database: $e');
    }
  }
  
  // Assigns training days based on frequency to optimize rest
  List<int> _getSmartDayMapping(int frequency) {
    switch (frequency) {
      case 1: return [1]; // Mon
      case 2: return [1, 4]; // Mon, Thu
      case 3: return [1, 3, 5]; // Mon, Wed, Fri
      case 4: return [1, 2, 4, 5]; // Mon, Tue, Thu, Fri
      case 5: return [1, 2, 3, 4, 5]; // Mon-Fri
      case 6: return [1, 2, 3, 4, 5, 6]; // Mon-Sat
      case 7: return [1, 2, 3, 4, 5, 6, 7]; // Everyday
      default: return [1, 3, 5];
    }
  }

  String _inferFocusArea(List exercises, String sessionKey) {
     if (sessionKey.toLowerCase().contains('push')) return 'Push (Împingere)';
     if (sessionKey.toLowerCase().contains('pull')) return 'Pull (Tragere)';
     if (sessionKey.toLowerCase().contains('legs')) return 'Legs (Picioare)';
     
     if (exercises.isNotEmpty) {
       final first = exercises.first as Map<String, dynamic>;
       // Try to guess from first exercise name
       final name = (first['exercise_name'] as String).toLowerCase();
       if (name.contains('bench') || name.contains('press')) return 'Piept & Umeri';
       if (name.contains('squat') || name.contains('leg')) return 'Picioare';
       if (name.contains('row') || name.contains('pull')) return 'Spate';
     }
     return 'General';
  }

  Future<Map<String, dynamic>?> _prepareSessionExerciseData(String sessionId, Map<String, dynamic> exerciseMap, int index) async {
    final name = exerciseMap['exercise_name'] as String;
    
    // 1. Try to find existing exercise ID
    final existing = await SupabaseService.instance.client
        .from('exercises')
        .select('id')
        .ilike('name', name)
        .maybeSingle();

    String exerciseId;
    if (existing != null) {
      exerciseId = existing['id'];
    } else {
      // 2. Create new exercise if not found
      // Note: Ideally we pre-seed the DB, but this makes it robust
      final newExercise = await SupabaseService.instance.client
          .from('exercises')
          .insert({
             'name': name,
             'muscle_group': 'general', // Simplified (legacy column)
             'target_muscle_groups': ['general'], // Required ARRAY field
             'equipment_required': 'sala_fitness', // Valid enum: sala_fitness, acasa_fara_echipament, etc.
             'difficulty_level': 'intermediate', // Valid enum: beginner, intermediate, advanced
             'video_url': exerciseMap['video_url'],
             'description': exerciseMap['coaching_tip'] // Use tip as desc
          })
          .select()
          .single();
      exerciseId = newExercise['id'];
    }

    // Parse sets/reps
    final sets = int.tryParse(exerciseMap['sets'].toString()) ?? 3;
    final repsStr = exerciseMap['reps'].toString();
    // Simple parsing logic for "8-12"
    int repsMin = 8, repsMax = 12;
    if (repsStr.contains('-')) {
      final parts = repsStr.split('-');
      repsMin = int.tryParse(parts[0]) ?? 8;
      repsMax = int.tryParse(parts[1]) ?? 12;
    } else {
      repsMin = int.tryParse(repsStr) ?? 10;
      repsMax = repsMin;
    }

    return {
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'sets': sets,
      'reps_min': repsMin,
      'reps_max': repsMax,
      'rest_seconds': exerciseMap['rest_seconds'] ?? 60,
      'order_in_session': index,
    };
  }


  Future<Map<String, dynamic>> generateNutritionPlan(String userId) async {
    _initializeService(); // Ensure initialized
    
    final userData = await getUserProfileData(userId);
    final profile = userData['profile'];
    final onboarding = userData['onboarding'] as Map<String, String>;

    final prompt = _buildNutritionPrompt(profile, onboarding);

    final message = Message(role: 'user', content: prompt);
    final response = await _client!.createChat(
      messages: [message],
      model: 'gemini-2.5-flash-lite',
      temperature: 0.7,
      maxTokens: 4096,
    );

    try {
      final cleanedText = response.text.trim();
      final jsonStart = cleanedText.indexOf('{');
      final jsonEnd = cleanedText.lastIndexOf('}') + 1;

      if (jsonStart == -1 || jsonEnd <= jsonStart) {
        throw FormatException('Invalid JSON response');
      }

      final jsonString = cleanedText.substring(jsonStart, jsonEnd);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to parse nutrition plan: $e');
    }
  }

  /// Generează un plan complet (workout + nutriție) pentru utilizator
  Future<Map<String, dynamic>> generateCompletePlan(String userId) async {
    try {
      // Generează planul de antrenament
      final workoutPlan = await generateWeeklyWorkoutPlan(userId);
      
      // Save the generated workout plan to database
      await saveGeneratedPlan(userId, workoutPlan);
      
      // Generează planul de nutriție
      final nutritionPlan = await generateNutritionPlan(userId);
      
      // Combină ambele planuri într-un singur răspuns
      return {
        'training_plan': workoutPlan['training_plan'],
        'nutrition_plan': nutritionPlan['nutrition_plan'],
        'notes': nutritionPlan['notes'] ?? 'Plan generat de AI personalizat pentru tine. Consultă medicul înainte de a începe.',
      };
    } catch (e) {
      throw Exception('Failed to generate complete plan: $e');
    }
  }

  String _buildExercisePrompt(
      Map<String, dynamic> profile,
      Map<String, String> onboarding,
      ) {
    return '''
Ești un antrenor personal certificat cu experiență în programare personalizată de antrenamente. Analizează următorul profil de utilizator și recomandă exerciții specifice și sigure:

PROFIL UTILIZATOR:
- Vârstă: ${profile['age'] ?? 'necunoscut'}
- Gen: ${profile['gender'] ?? 'necunoscut'}
- Greutate: ${profile['weight_kg'] ?? 'necunoscut'} kg, Înălțime: ${profile['height_cm'] ?? 'necunoscut'} cm
- Nivel fitness: ${profile['experience_level'] ?? 'necunoscut'}
- Obiectiv principal: ${profile['fitness_goal'] ?? 'necunoscut'}
- Restricții medicale: ${profile['medical_conditions'] ?? 'niciuna'}
- Echipament disponibil: ${profile['equipment_available'] ?? 'necunoscut'}
- Locație antrenament: ${onboarding['workout_location'] ?? 'necunoscut'}
- Zile disponibile: ${profile['weekly_training_frequency'] ?? 'necunoscut'}

CERINȚE:
1. Recomandă 15-20 exerciții variate care acoperă toate grupele musculare majore
2. Adaptează intensitatea la nivelul utilizatorului
3. Ține cont de restricțiile medicale - EVITĂ exercițiile contraindicate
4. Folosește DOAR echipamentul disponibil
5. Pentru fiecare exercițiu, include un link YouTube VALID și FUNCȚIONAL la un videoclip demonstrativ
6. Explică DE CE fiecare exercițiu este potrivit pentru acest utilizator specific
7. Oferă alternative pentru exercițiile mai dificile
8. Toate denumirile exercițiilor, instrucțiunile și sfaturile trebuie să fie în LIMBA ROMÂNĂ
9. Videoclipurile pot fi în engleză dacă nu există versiuni românești, dar instrucțiunile text trebuie traduse

IMPORTANT - RESTRICȚII VIDEOCLIPURI YOUTUBE:
- Folosește DOAR videoclipuri de la canale oficiale de fitness care permit embedding (ex: ATHLEAN-X, Jeff Nippard, ScottHermanFitness, Calisthenicmovement, FitnessBlender)
- EVITĂ videoclipuri care au restricții de playback în aplicații externe
- Preferă videoclipuri populare (peste 100k views) care sunt mai probabil să permită embedding
- Testează mental dacă videoclipul este de la un canal cunoscut care permite embedding
- NU folosi videoclipuri de la canale personale mici sau canale care restricționează playback-ul

Răspunde DOAR cu un array JSON valid, fără text suplimentar. Format:

[
  {
    "name": "Nume exercițiu în română",
    "bodyPart": "Piept|Spate|Picioare|Umeri|Brațe|Abdomen",
    "targetMuscles": "Mușchi țintă",
    "equipment": "Echipament necesar",
    "difficulty": "Începător|Intermediar|Avansat",
    "sets": 3,
    "reps": "10-12",
    "restSeconds": 60,
    "videoUrl": "https://www.youtube.com/watch?v=...",
    "instructions": "Instrucțiuni detaliate de execuție",
    "safetyTips": "Sfaturi de siguranță",
    "whyRecommended": "Explicație personalizată de ce acest exercițiu este recomandat pentru acest utilizator"
  }
]
''';
  }

  String _buildWorkoutPlanPrompt(
      Map<String, dynamic> profile,
      Map<String, String> onboarding,
      ) {
    final daysPerWeek = int.tryParse(profile['weekly_training_frequency']?.toString() ?? '3') ?? 3;
    final splitGuide = _getSplitGuide(daysPerWeek);
    
    return '''
### ROL ȘI OBIECTIV
Ești un antrenor personal certificat (CPT) și antrenor de forță și condiționare fizică cu cunoștințe extinse în biomecanică, hipertrofie și periodizare.

Scopul tău este să generezi planuri de antrenament extrem de personalizate și științific corecte pentru utilizatorii unei aplicații de fitness.

### DATE UTILIZATOR
${_buildUserProfileString(profile, onboarding)}

Frecvență antrenament: $daysPerWeek zile pe săptămână
Obiectiv principal: ${profile['fitness_goal'] ?? 'necunoscut'}
Nivel experiență: ${profile['experience_level'] ?? 'necunoscut'}

${_getVerifiedExercisesList()}

### SPLIT RECOMANDAT PENTRU $daysPerWeek ZILE/SĂPTĂMÂNĂ
$splitGuide

### REGULI CRITICE
1. **Limbaj Exerciții:** TREBUIE să folosești STRICT numele în ENGLEZĂ pentru exerciții (ex: "Barbell Bench Press", "Romanian Deadlift", "Face Pulls"). NU traduce numele exercițiilor!
2. **Limbaj Explicații:** Toate explicațiile, sfaturile și descrierile TREBUIE să fie în ROMÂNĂ.
3. **Logica Antrenamentului:**
   - Respectă EXACT split-ul recomandat mai sus
   - NU amesteca grupele musculare din zile diferite
   - Fiecare zi trebuie focusată pe grupele musculare specificate
   - Exemplu CORECT pentru Push: Barbell Bench Press, Overhead Press, Tricep Dips
   - Exemplu GREȘIT pentru Push: Barbell Bench Press, Pull-Ups (Pull-Ups e pentru Pull!)
4. **Selecție Exerciții:**
   - Selectează DOAR din lista de exerciții furnizată mai sus
   - Folosește EXACT numele în engleză din listă
   - NU crea exerciții noi sau nu modifica numele
   - Fiecare exercițiu din listă are deja un videoclip verificat

### PRINCIPII ȘTIINȚIFICE (OBLIGATORIU)
Bazat pe studii Schoenfeld et al. (2016, 2017, 2021):

1. **Volume Landmarks**:
   - Hipertrofie: 10-20 seturi/grupă musculară/săptămână
   - Forță: 6-12 seturi/grupă musculară/săptămână

2. **Frequency**:
   - Antrenează fiecare grupă musculară de 2x/săptămână pentru rezultate optime
   
3. **Rest Periods**:
   - Exerciții compuse (Squat, Deadlift, Bench Press): 90-120 secunde
   - Exerciții izolate (Bicep Curls, Lateral Raises): 60-90 secunde
   
4. **Rep Ranges**:
   - Obiectiv Hipertrofie: 8-12 repetări
   - Obiectiv Forță: 4-6 repetări
   - Obiectiv Rezistență: 12-15+ repetări

### FORMAT RĂSPUNS
Răspunde DOAR cu un obiect JSON valid, fără text suplimentar. Format EXACT:

{
  "training_plan": {
    "day_1": [
      {
        "exercise_name": "Barbell Bench Press",
        "sets": 4,
        "reps": "8-12",
        "rest_seconds": 90,
        "coaching_tip": "Menține umerii retrași și coboară bara controlat până la piept. Nu lăsa bara să sară."
      },
      {
        "exercise_name": "Dumbbell Flyes",
        "sets": 3,
        "reps": "10-12",
        "rest_seconds": 60,
        "coaching_tip": "Cotii ușor îndoiți, simte întinderea în piept. Nu coborî prea jos."
      }
    ],
    "day_2": [
      {
        "exercise_name": "Barbell Squat",
        "sets": 4,
        "reps": "8-12",
        "rest_seconds": 90,
        "coaching_tip": "Genunchii în linie cu degetele, coboară până coapsele sunt paralele cu solul."
      }
    ]
  }
}

### CERINȚE IMPORTANTE
- Creează exact $daysPerWeek zile (day_1, day_2, day_3, etc.)
- Fiecare zi trebuie să aibă 4-6 exerciții
- Respectă STRICT split-ul recomandat (nu amesteca grupele musculare!)
- Toate exercițiile TREBUIE să fie din lista furnizată
- Folosește NUME ÎN ENGLEZĂ pentru câmpul "exercise_name"
- Câmpul "coaching_tip" trebuie să fie în ROMÂNĂ
- NU include câmpul "video_url" (videoclipurile sunt deja în baza de date)
- Adaptează numărul de seturi/repetări la nivelul utilizatorului și obiectiv
- Asigură volum optim per grupă musculară conform studiilor științifice
''';
  }

  String _getSplitGuide(int daysPerWeek) {
    switch (daysPerWeek) {
      case 3:
        return '''
**PUSH / PULL / LEGS Split**
- Zi 1 - PUSH (Împingere): Piept + Umeri + Triceps
  * Exerciții: Barbell Bench Press, Overhead Press, Dumbbell Flyes, Dumbbell Lateral Raises, Tricep Dips
- Zi 2 - PULL (Tragere): Spate + Biceps
  * Exerciții: Pull-Ups, Barbell Rows, Single-Arm Dumbbell Row, Barbell Bicep Curls
- Zi 3 - LEGS: Picioare + Abdomen
  * Exerciții: Barbell Squat, Romanian Deadlift, Lunges, Plank, Crunches
''';
      case 4:
        return '''
**UPPER / LOWER Split**
- Zi 1 - UPPER PUSH: Piept + Umeri + Triceps
  * Exerciții: Barbell Bench Press, Overhead Press, Incline Dumbbell Press, Dumbbell Lateral Raises, Tricep Dips
- Zi 2 - LOWER: Picioare + Abdomen
  * Exerciții: Barbell Squat, Romanian Deadlift, Leg Press, Plank, Hanging Leg Raises
- Zi 3 - UPPER PULL: Spate + Biceps
  * Exerciții: Pull-Ups, Barbell Deadlift, Barbell Rows, Face Pulls, Barbell Bicep Curls
- Zi 4 - LOWER + CORE: Picioare (variante) + Abdomen
  * Exerciții: Bulgarian Split Squat, Lunges, Leg Press, Russian Twists, Mountain Climbers
''';
      case 5:
        return '''
**BRO SPLIT (Clasic)**
- Zi 1 - CHEST + TRICEPS: Piept + Triceps
  * Exerciții: Barbell Bench Press, Incline Dumbbell Press, Dumbbell Flyes, Tricep Dips, Overhead Tricep Extension
- Zi 2 - BACK + BICEPS: Spate + Biceps
  * Exerciții: Barbell Deadlift, Pull-Ups, Barbell Rows, Single-Arm Dumbbell Row, Barbell Bicep Curls
- Zi 3 - LEGS: Picioare
  * Exerciții: Barbell Squat, Romanian Deadlift, Leg Press, Bulgarian Split Squat, Lunges
- Zi 4 - SHOULDERS + ABS: Umeri + Abdomen
  * Exerciții: Overhead Press, Dumbbell Lateral Raises, Dumbbell Front Raises, Face Pulls, Plank, Hanging Leg Raises
- Zi 5 - FULL BODY / ARMS: Mix sau Focus Brațe
  * Exerciții: Push-Ups, Pull-Ups, Barbell Squat, Alternating Dumbbell Curls, Cable Bicep Curls
''';
      case 6:
        return '''
**PUSH / PULL / LEGS x2 (Avansat)**
- Zi 1 - PUSH A: Piept + Umeri + Triceps (Focus Forță)
  * Exerciții: Barbell Bench Press, Overhead Press, Incline Dumbbell Press, Dumbbell Lateral Raises, Tricep Dips
- Zi 2 - PULL A: Spate + Biceps (Focus Forță)
  * Exerciții: Barbell Deadlift, Pull-Ups, Barbell Rows, Face Pulls, Barbell Bicep Curls
- Zi 3 - LEGS A: Picioare + Abdomen (Focus Forță)
  * Exerciții: Barbell Squat, Romanian Deadlift, Leg Press, Plank, Hanging Leg Raises
- Zi 4 - PUSH B: Piept + Umeri + Triceps (Focus Hipertrofie)
  * Exerciții: Incline Dumbbell Press, Dumbbell Flyes, Dumbbell Front Raises, Overhead Tricep Extension, Push-Ups
- Zi 5 - PULL B: Spate + Biceps (Focus Hipertrofie)
  * Exerciții: Lat Pulldown, Single-Arm Dumbbell Row, Face Pulls, Alternating Dumbbell Curls, Cable Bicep Curls
- Zi 6 - LEGS B: Picioare + Abdomen (Focus Hipertrofie)
  * Exerciții: Bulgarian Split Squat, Lunges, Leg Press, Russian Twists, Mountain Climbers, Crunches
''';
      default:
        return _getSplitGuide(3); // Default to 3-day split
    }
  }

  String _buildNutritionPrompt(
      Map<String, dynamic> profile,
      Map<String, String> onboarding,
      ) {
    return '''
Ești un nutriționist specializat în nutriție sportivă. Creează un plan personalizat de mese:

PROFIL: ${_buildUserProfileString(profile, onboarding)}

CERINȚE:
1. Calculează necesarul caloric pentru obiectiv: ${profile['fitness_goal'] ?? 'general'}
2. Distribuie optim macronutrienții pentru obiectiv
3. Creează exemple de mese pentru o zi completă (Mic dejun, Prânz, Gustare, Cină)
4. Pentru FIECARE masă, oferă 2-3 OPȚIUNI diferite
5. Respectă preferințele: ${profile['dietary_preference'] ?? 'normal'}
6. Evită alergenele: ${profile['medical_conditions'] ?? 'niciuna'}
7. Include sincronizarea meselor în raport cu antrenamentele
8. Toate denumirile meselor, descrierile alimentelor în LIMBA ROMÂNĂ

Răspunde DOAR cu un obiect JSON valid, fără text suplimentar. Format EXACT:

{
  "nutrition_plan": {
    "daily_calories_goal": 2300,
    "meals": [
      {
        "meal_name": "Mic dejun",
        "options": [
          {
            "option_id": 1,
            "description": "Omletă cu 3 ouă și spanac (150g), pâine integrală (50g), avocado (50g)",
            "calories": 420,
            "protein_g": 35,
            "carbs_g": 25,
            "fat_g": 22
          },
          {
            "option_id": 2,
            "description": "Ovăz (80g) cu lapte (200ml), banană (100g), nuci (20g)",
            "calories": 450,
            "protein_g": 18,
            "carbs_g": 62,
            "fat_g": 12
          }
        ]
      },
      {
        "meal_name": "Prânz",
        "options": [
          {
            "option_id": 1,
            "description": "Piept de pui la grătar (200g), orez brun (150g), salată mixtă (100g)",
            "calories": 520,
            "protein_g": 48,
            "carbs_g": 55,
            "fat_g": 8
          },
          {
            "option_id": 2,
            "description": "Somon la cuptor (180g), cartofi dulci (200g), broccoli (150g)",
            "calories": 510,
            "protein_g": 42,
            "carbs_g": 48,
            "fat_g": 14
          }
        ]
      }
    ]
  },
  "notes": "Bea minimum 2.5L apă pe zi. Consultă medicul înainte de a începe planul."
}

IMPORTANT:
- Creează 4-5 mese pe zi (Mic dejun, Prânz, Gustare, Cină, eventual Gustare seara)
- Fiecare masă trebuie să aibă 2-3 opțiuni
- Fiecare opțiune trebuie să includă descrierea DETALIATĂ cu gramaje
- Calculează corect caloriile și macronutrienții pentru fiecare opțiune
''';
  }

  String _buildUserProfileString(
      Map<String, dynamic> profile,
      Map<String, String> onboarding,
      ) {
    return '''
Vârstă: ${profile['age'] ?? 'necunoscut'}, Gen: ${profile['gender'] ?? 'necunoscut'}
Greutate: ${profile['weight_kg'] ?? 'necunoscut'} kg, Înălțime: ${profile['height_cm'] ?? 'necunoscut'} cm
Nivel fitness: ${profile['experience_level'] ?? 'necunoscut'}
Obiectiv: ${profile['fitness_goal'] ?? 'necunoscut'}
Nivel activitate: ${profile['activity_level'] ?? 'necunoscut'}
Restricții medicale: ${profile['medical_conditions'] ?? 'niciuna'}
Echipament: ${profile['equipment_available'] ?? 'necunoscut'}
Preferințe dietetice: ${profile['dietary_preference'] ?? 'normal'}
Frecvență antrenament: ${profile['weekly_training_frequency'] ?? '3'} zile/săptămână
''';
  }

  String _getVerifiedExercisesList() {
    return VerifiedExercisesData.getExerciseListForPrompt();
  }
}

class GeminiClient {
  final Dio dio;
  final String apiKey;

  GeminiClient(this.dio, this.apiKey);

  String _getEndpointMethod(String model, {bool isStream = false}) {
    if (isStream) return ':streamGenerateContent';
    return ':generateContent';
  }

  Future<Completion> createChat({
    required List<Message> messages,
    String model = 'gemini-2.5-flash',
    int maxTokens = 1024,
    double temperature = 1.0,
    CancelToken? cancelToken,
  }) async {
    try {
      final contents = messages
          .map(
            (m) => {
          'role': m.role,
          'parts': m.content is String
              ? [
            {'text': m.content},
          ]
              : m.content,
        },
      )
          .toList();

      final endpoint = _getEndpointMethod(model);

      final response = await dio.post(
        '/models/$model$endpoint',
        data: {
          'contents': contents,
          'generationConfig': {
            'maxOutputTokens': maxTokens,
            'temperature': temperature,
          },
          'safetySettings': _getSafetySettings(),
        },
        cancelToken: cancelToken,
      );

      if (response.data['candidates'] != null &&
          response.data['candidates'].isNotEmpty &&
          response.data['candidates'][0]['content'] != null) {
        final parts = response.data['candidates'][0]['content']['parts'];
        final text = parts.isNotEmpty ? parts[0]['text'] : '';
        return Completion(text: text);
      } else {
        throw GeminiException(
          statusCode: response.statusCode ?? 500,
          message: 'Failed to parse response or empty response',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw GeminiException(
          statusCode: 499,
          message: 'Request was cancelled by user',
        );
      }
      throw GeminiException(
        statusCode: e.response?.statusCode ?? 500,
        message:
        e.response?.data?['error']?['message'] ??
            e.message ??
            'Unknown error',
      );
    }
  }

  List<Map<String, dynamic>> _getSafetySettings() {
    return [
      {
        'category': 'HARM_CATEGORY_HARASSMENT',
        'threshold': 'BLOCK_LOW_AND_ABOVE',
      },
      {
        'category': 'HARM_CATEGORY_HATE_SPEECH',
        'threshold': 'BLOCK_LOW_AND_ABOVE',
      },
      {
        'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
        'threshold': 'BLOCK_LOW_AND_ABOVE',
      },
      {
        'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
        'threshold': 'BLOCK_LOW_AND_ABOVE',
      },
    ];
  }
}

class Message {
  final String role;
  final dynamic content;

  Message({required this.role, required this.content});
}

class Completion {
  final String text;
  Completion({required this.text});
}

class GeminiException implements Exception {
  final int statusCode;
  final String message;

  GeminiException({required this.statusCode, required this.message});

  @override
  String toString() => 'GeminiException: $statusCode - $message';
}

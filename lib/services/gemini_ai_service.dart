import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../services/supabase_service.dart';
import '../services/app_cache_service.dart';
import '../data/verified_exercises_data.dart';
import '_dio_interceptors.dart';

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

    _dio!.interceptors.add(AppLogInterceptor());

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
    } catch (e, stack) {
      unawaited(Sentry.captureException(e, stackTrace: stack,
          hint: Hint.withMap({'service': 'GeminiAIService', 'method': 'getUserProfileData'})));
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
      maxTokens: 8192,
      responseMimeType: 'application/json',
    );

    try {
      final exercises = jsonDecode(response.text) as List;
      return exercises.map((e) => e as Map<String, dynamic>).toList();
    } catch (e, stack) {
      unawaited(Sentry.captureException(e, stackTrace: stack,
          hint: Hint.withMap({'service': 'GeminiAIService', 'method': 'getPersonalizedExercises', 'context': 'json_parse'})));
      throw Exception('Failed to parse exercises: $e');
    }
  }


  Future<Map<String, dynamic>> generateWeeklyWorkoutPlan(
    String userId, {
    Map<String, dynamic>? preloadedUserData,
  }) async {
    _initializeService();

    final userData = preloadedUserData ?? await getUserProfileData(userId);
    final profile = userData['profile'];
    final onboarding = userData['onboarding'] as Map<String, String>;

    final cacheKey = _buildProfileCacheKey(profile, onboarding);
    final cached = AppCacheService.instance.getWorkoutPlan(cacheKey);
    if (cached != null) return cached;

    final txn = Sentry.startTransaction('ai-workout-plan', 'task');
    try {
      final prompt = _buildWorkoutPlanPrompt(profile, onboarding);

      final message = Message(role: 'user', content: prompt);
      final response = await _client!.createChat(
        messages: [message],
        model: 'gemini-2.5-flash-lite',
        temperature: 0.7,
        maxTokens: 8192,
        responseMimeType: 'application/json',
        responseSchema: _workoutPlanSchema,
      );

      final parsedPlan = jsonDecode(response.text) as Map<String, dynamic>;
      final enrichedPlan = _enrichPlanWithVideoUrls(parsedPlan);
      AppCacheService.instance.setWorkoutPlan(cacheKey, enrichedPlan);
      txn.status = const SpanStatus.ok();
      return enrichedPlan;
    } catch (e, stack) {
      txn.status = const SpanStatus.internalError();
      unawaited(Sentry.captureException(e, stackTrace: stack,
          hint: Hint.withMap({'service': 'GeminiAIService', 'method': 'generateWeeklyWorkoutPlan'})));
      throw Exception('Failed to parse workout plan: $e');
    } finally {
      await txn.finish();
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
          debugPrint('Warning: Exercise "$exerciseName" not found in verified database');
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

        // Resolve all exercise lookups concurrently, then batch insert in one call
        final resolvedData = await Future.wait(sessionExercises);
        final validData = resolvedData.whereType<Map<String, dynamic>>().toList();
        if (validData.isNotEmpty) {
          await SupabaseService.instance.client.from('session_exercises').insert(validData);
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

    } catch (e, stack) {
      debugPrint('Error saving generated plan: $e');
      unawaited(Sentry.captureException(e, stackTrace: stack,
          hint: Hint.withMap({'service': 'GeminiAIService', 'method': 'saveGeneratedPlan'})));
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
             'equipment_required': 'gym', // Valid enum: gym, home_no_equipment, home_basic_equipment, mix
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


  Future<Map<String, dynamic>> generateNutritionPlan(
    String userId, {
    Map<String, dynamic>? preloadedUserData,
  }) async {
    _initializeService();

    final userData = preloadedUserData ?? await getUserProfileData(userId);
    final profile = userData['profile'];
    final onboarding = userData['onboarding'] as Map<String, String>;

    final cacheKey = _buildProfileCacheKey(profile, onboarding);
    final cached = AppCacheService.instance.getNutritionPlan(cacheKey);
    if (cached != null) return cached;

    final txn = Sentry.startTransaction('ai-nutrition-plan', 'task');
    try {
      final prompt = _buildNutritionPrompt(profile, onboarding);

      final message = Message(role: 'user', content: prompt);
      final response = await _client!.createChat(
        messages: [message],
        model: 'gemini-2.5-flash-lite',
        temperature: 0.7,
        maxTokens: 8192,
        responseMimeType: 'application/json',
        responseSchema: _nutritionPlanSchema,
      );

      final plan = jsonDecode(response.text) as Map<String, dynamic>;
      AppCacheService.instance.setNutritionPlan(cacheKey, plan);
      txn.status = const SpanStatus.ok();
      return plan;
    } catch (e, stack) {
      txn.status = const SpanStatus.internalError();
      unawaited(Sentry.captureException(e, stackTrace: stack,
          hint: Hint.withMap({'service': 'GeminiAIService', 'method': 'generateNutritionPlan'})));
      throw Exception('Failed to parse nutrition plan: $e');
    } finally {
      await txn.finish();
    }
  }

  /// Generează un plan complet (workout + nutriție) pentru utilizator
  Future<Map<String, dynamic>> generateCompletePlan(String userId) async {
    try {
      // Single profile fetch — passed to both generators to avoid double Supabase round-trip
      final userData = await getUserProfileData(userId);

      final workoutPlan = await generateWeeklyWorkoutPlan(userId, preloadedUserData: userData);
      await saveGeneratedPlan(userId, workoutPlan);
      final nutritionPlan = await generateNutritionPlan(userId, preloadedUserData: userData);

      return {
        'training_plan': workoutPlan['training_plan'],
        'nutrition_plan': nutritionPlan['nutrition_plan'],
        'notes': nutritionPlan['notes'] ?? 'Plan generat de AI personalizat pentru tine. Consultă medicul înainte de a începe.',
      };
    } catch (e, stack) {
      unawaited(Sentry.captureException(e, stackTrace: stack,
          hint: Hint.withMap({'service': 'GeminiAIService', 'method': 'generateCompletePlan'})));
      throw Exception('Failed to generate complete plan: $e');
    }
  }

  // ── Structured output schemas ───────────────────────────────────────

  static const _exerciseItem = {
    'type': 'OBJECT',
    'properties': {
      'exercise_name': {'type': 'STRING'},
      'sets': {'type': 'INTEGER'},
      'reps': {'type': 'STRING'},
      'rest_seconds': {'type': 'INTEGER'},
      'coaching_tip': {'type': 'STRING'},
    },
    'required': ['exercise_name', 'sets', 'reps', 'rest_seconds', 'coaching_tip'],
  };

  static const _workoutPlanSchema = {
    'type': 'OBJECT',
    'properties': {
      'training_plan': {
        'type': 'OBJECT',
        'properties': {
          'day_1': {'type': 'ARRAY', 'items': _exerciseItem},
          'day_2': {'type': 'ARRAY', 'items': _exerciseItem},
          'day_3': {'type': 'ARRAY', 'items': _exerciseItem},
          'day_4': {'type': 'ARRAY', 'items': _exerciseItem},
          'day_5': {'type': 'ARRAY', 'items': _exerciseItem},
          'day_6': {'type': 'ARRAY', 'items': _exerciseItem},
        },
      },
    },
    'required': ['training_plan'],
  };

  static const _nutritionPlanSchema = {
    'type': 'OBJECT',
    'properties': {
      'nutrition_plan': {
        'type': 'OBJECT',
        'properties': {
          'daily_calories_goal': {'type': 'INTEGER'},
          'meals': {
            'type': 'ARRAY',
            'items': {
              'type': 'OBJECT',
              'properties': {
                'meal_name': {'type': 'STRING'},
                'options': {
                  'type': 'ARRAY',
                  'items': {
                    'type': 'OBJECT',
                    'properties': {
                      'option_id': {'type': 'INTEGER'},
                      'description': {'type': 'STRING'},
                      'calories': {'type': 'INTEGER'},
                      'protein_g': {'type': 'NUMBER'},
                      'carbs_g': {'type': 'NUMBER'},
                      'fat_g': {'type': 'NUMBER'},
                    },
                    'required': [
                      'option_id', 'description', 'calories',
                      'protein_g', 'carbs_g', 'fat_g',
                    ],
                  },
                },
              },
              'required': ['meal_name', 'options'],
            },
          },
        },
        'required': ['daily_calories_goal', 'meals'],
      },
      'notes': {'type': 'STRING'},
    },
    'required': ['nutrition_plan', 'notes'],
  };

  // ── Streaming ──────────────────────────────────────────────────────

  /// Streams incremental JSON tokens for the workout plan.
  ///
  /// On a cache hit, yields the full cached JSON at once (instant).
  /// On a miss, streams tokens from Gemini and writes the enriched plan to
  /// cache when the stream completes.
  ///
  /// The caller should follow up with [generateWeeklyWorkoutPlan] after the
  /// stream ends — it will return instantly from cache.
  Stream<String> streamWeeklyWorkoutPlan(String userId) async* {
    _initializeService();

    final userData = await getUserProfileData(userId);
    final profile = userData['profile'];
    final onboarding = userData['onboarding'] as Map<String, String>;

    final cacheKey = _buildProfileCacheKey(profile, onboarding);
    final cached = AppCacheService.instance.getWorkoutPlan(cacheKey);
    if (cached != null) {
      yield jsonEncode(cached);
      return;
    }

    final prompt = _buildWorkoutPlanPrompt(profile, onboarding);
    final fullBuffer = StringBuffer();

    yield* _client!.createChatStream(
      messages: [Message(role: 'user', content: prompt)],
      model: 'gemini-2.5-flash-lite',
      temperature: 0.7,
      maxTokens: 8192,
      responseMimeType: 'application/json',
      responseSchema: _workoutPlanSchema,
    ).map((chunk) {
      fullBuffer.write(chunk);
      return chunk;
    });

    // After stream completes: enrich + cache so generateWeeklyWorkoutPlan returns instantly
    try {
      final parsedPlan = jsonDecode(fullBuffer.toString()) as Map<String, dynamic>;
      final enrichedPlan = _enrichPlanWithVideoUrls(parsedPlan);
      AppCacheService.instance.setWorkoutPlan(cacheKey, enrichedPlan);
    } catch (_) {
      // Parse failure — caller will handle via generateWeeklyWorkoutPlan error
    }
  }

  // ── Profile cache key ──────────────────────────────────────────────

  // Stable djb2 hash of user's plan-affecting profile fields.
  // Cache key changes whenever fitness goal, equipment, frequency, etc. change.
  String _buildProfileCacheKey(
    Map<String, dynamic> profile,
    Map<String, String> onboarding,
  ) {
    final canonical = [
      profile['age'],
      profile['gender'],
      profile['weight_kg'],
      profile['height_cm'],
      profile['experience_level'],
      profile['fitness_goal'],
      profile['activity_level'],
      profile['medical_conditions'],
      profile['equipment_available'],
      profile['weekly_training_frequency'],
      profile['dietary_preference'],
      onboarding['workout_location'] ?? '',
    ].map((v) => v?.toString() ?? '').join('|');

    int hash = 5381;
    for (final c in canonical.codeUnits) {
      hash = ((hash << 5) + hash) ^ c;
      hash &= 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
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
- Zi 2 - PULL (Tragere): Spate + Biceps
- Zi 3 - LEGS: Picioare + Abdomen
''';
      case 4:
        return '''
**UPPER / LOWER Split**
- Zi 1 - UPPER PUSH: Piept + Umeri + Triceps
- Zi 2 - LOWER: Picioare + Abdomen
- Zi 3 - UPPER PULL: Spate + Biceps
- Zi 4 - LOWER + CORE: Picioare (variante) + Abdomen
''';
      case 5:
        return '''
**BRO SPLIT (Clasic)**
- Zi 1 - CHEST + TRICEPS: Piept + Triceps
- Zi 2 - BACK + BICEPS: Spate + Biceps
- Zi 3 - LEGS: Picioare
- Zi 4 - SHOULDERS + ABS: Umeri + Abdomen
- Zi 5 - FULL BODY / ARMS: Mix sau Focus Brațe
''';
      case 6:
        return '''
**PUSH / PULL / LEGS x2 (Avansat)**
- Zi 1 - PUSH A: Piept + Umeri + Triceps (Focus Forță)
- Zi 2 - PULL A: Spate + Biceps (Focus Forță)
- Zi 3 - LEGS A: Picioare + Abdomen (Focus Forță)
- Zi 4 - PUSH B: Piept + Umeri + Triceps (Focus Hipertrofie)
- Zi 5 - PULL B: Spate + Biceps (Focus Hipertrofie)
- Zi 6 - LEGS B: Picioare + Abdomen (Focus Hipertrofie)
''';
      default:
        return _getSplitGuide(3);
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
3. Creează mese pentru o zi completă (Mic dejun, Prânz, Gustare, Cină, eventual Gustare seara)
4. Pentru FIECARE masă, oferă 2-3 OPȚIUNI diferite cu descrieri DETALIATE cu gramaje
5. Respectă preferințele: ${profile['dietary_preference'] ?? 'normal'}
6. Evită alergenele: ${profile['medical_conditions'] ?? 'niciuna'}
7. Include sincronizarea meselor în raport cu antrenamentele
8. Toate denumirile meselor, descrierile alimentelor în LIMBA ROMÂNĂ
9. Calculează corect caloriile și macronutrienții pentru fiecare opțiune
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

  /// Retries [fn] up to [maxAttempts] times with exponential backoff.
  /// Retries on network errors, 5xx responses, and 429 (rate limit).
  Future<T> _withRetry<T>(
    Future<T> Function() fn, {
    int maxAttempts = 3,
  }) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await fn();
      } on GeminiException catch (e) {
        final isRetryable = e.statusCode >= 500 || e.statusCode == 429;
        if (!isRetryable || attempt == maxAttempts) rethrow;
        await Future.delayed(Duration(seconds: attempt * 2));
      } on DioException catch (e) {
        final isNetwork = e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout;
        if (!isNetwork || attempt == maxAttempts) rethrow;
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    throw GeminiException(statusCode: 500, message: 'Max retries reached');
  }

  Future<Completion> createChat({
    required List<Message> messages,
    String model = 'gemini-2.5-flash',
    int maxTokens = 1024,
    double temperature = 1.0,
    CancelToken? cancelToken,
    String? responseMimeType,
    Map<String, dynamic>? responseSchema,
  }) async {
    return _withRetry(() async {
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

        final generationConfig = <String, dynamic>{
          'maxOutputTokens': maxTokens,
          'temperature': temperature,
        };
        if (responseMimeType != null) {
          generationConfig['responseMimeType'] = responseMimeType;
        }
        if (responseSchema != null) {
          generationConfig['responseSchema'] = responseSchema;
        }

        final response = await dio.post(
          '/models/$model$endpoint',
          data: {
            'contents': contents,
            'generationConfig': generationConfig,
            'safetySettings': _getSafetySettings(),
          },
          cancelToken: cancelToken,
        );

        if (response.data['candidates'] != null &&
            response.data['candidates'].isNotEmpty &&
            response.data['candidates'][0]['content'] != null) {
          final parts = response.data['candidates'][0]['content']['parts']
              as List<dynamic>;
          // Thinking models (e.g. gemini-2.5-flash) return thought parts
          // before the actual response. Pick the last non-thought part.
          String text = '';
          for (final part in parts.reversed) {
            if (part['thought'] != true && part['text'] != null) {
              text = part['text'] as String;
              break;
            }
          }
          return Completion(text: text);
        } else {
          throw GeminiException(
            statusCode: response.statusCode ?? 500,
            message: 'Failed to parse response or empty response',
          );
        }
      } on DioException catch (e) {
        // Convert to GeminiException so _withRetry can classify it
        if (e.type == DioExceptionType.cancel) {
          throw GeminiException(
            statusCode: 499,
            message: 'Request was cancelled by user',
          );
        }
        throw GeminiException(
          statusCode: e.response?.statusCode ?? 500,
          message: e.response?.data?['error']?['message'] ??
              e.message ??
              'Unknown error',
        );
      }
    });
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

  /// Streams raw text tokens from Gemini using Server-Sent Events.
  ///
  /// Yields each incremental text chunk as it arrives. The caller is
  /// responsible for assembling the full text when the stream ends.
  /// Does NOT retry on mid-stream failures (unlike [createChat]).
  Stream<String> createChatStream({
    required List<Message> messages,
    String model = 'gemini-2.5-flash-lite',
    int maxTokens = 8192,
    double temperature = 1.0,
    String? responseMimeType,
    Map<String, dynamic>? responseSchema,
    CancelToken? cancelToken,
  }) async* {
    final contents = messages.map((m) => {
      'role': m.role,
      'parts': m.content is String ? [{'text': m.content}] : m.content,
    }).toList();

    final generationConfig = <String, dynamic>{
      'maxOutputTokens': maxTokens,
      'temperature': temperature,
    };
    if (responseMimeType != null) generationConfig['responseMimeType'] = responseMimeType;
    if (responseSchema != null) generationConfig['responseSchema'] = responseSchema;

    final response = await dio.post(
      '/models/$model:streamGenerateContent',
      queryParameters: {'alt': 'sse'},
      data: {
        'contents': contents,
        'generationConfig': generationConfig,
        'safetySettings': _getSafetySettings(),
      },
      options: Options(responseType: ResponseType.stream),
      cancelToken: cancelToken,
    );

    final responseBody = response.data as ResponseBody;
    final lineBuffer = StringBuffer();

    await for (final chunk in responseBody.stream) {
      final rawChunk = utf8.decode(chunk, allowMalformed: true);
      lineBuffer.write(rawChunk);

      String buffered = lineBuffer.toString();
      // Process complete SSE events separated by double newline
      while (buffered.contains('\n\n')) {
        final idx = buffered.indexOf('\n\n');
        final event = buffered.substring(0, idx).trim();
        buffered = buffered.substring(idx + 2);
        lineBuffer.clear();
        lineBuffer.write(buffered);

        if (!event.startsWith('data: ')) continue;
        final jsonStr = event.substring(6).trim();
        if (jsonStr == '[DONE]') return;

        try {
          final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
          final candidates = parsed['candidates'] as List?;
          if (candidates == null || candidates.isEmpty) continue;
          final parts = candidates[0]['content']?['parts'] as List?;
          if (parts == null) continue;
          for (final part in parts) {
            if (part['thought'] != true && part['text'] != null) {
              yield part['text'] as String;
            }
          }
        } catch (e, s) {
          unawaited(Sentry.captureException(e, stackTrace: s,
              hint: Hint.withMap({'service': 'GeminiClient', 'method': 'createChatStream', 'context': 'sse_json_parse'})));
        }
      }
    }
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

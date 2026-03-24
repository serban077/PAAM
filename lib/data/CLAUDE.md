# lib/data/ — Data Models & Static Data

Read this file when working with AI plan models, data parsing, or the exercise database.

---

## AI Plan Models (`models/ai_plan_models.dart`)

Full response hierarchy returned by `GeminiAIService.generatePersonalizedPlan()`:

```
AIPlanResponse
├── trainingPlan: TrainingPlan
│   └── days: List<WorkoutDay>
│       ├── dayName: String          // "Monday", "Tuesday", etc.
│       ├── focus: String            // "Chest & Triceps", "Rest", etc.
│       └── exercises: List<Exercise>
│           ├── name: String
│           ├── sets: int
│           ├── reps: String         // "8-12" or "15" or "to failure"
│           ├── restSeconds: int
│           └── videoUrl: String?   // YouTube embed URL
└── nutritionPlan: NutritionPlan
    ├── dailyCalories: int
    ├── proteinGrams: int
    ├── carbGrams: int
    ├── fatGrams: int
    └── meals: List<Meal>
        ├── name: String             // "Breakfast", "Lunch", etc.
        ├── calories: int
        └── options: List<MealOption>
            ├── description: String
            └── ingredients: List<String>
```

Parsing from Gemini JSON response is handled inside `GeminiAIService` — do not duplicate parsing logic.

---

## Verified Exercises Database (`verified_exercises_data.dart`)

Static list of exercises used by `ExerciseLibrary`. Each entry is a `Map<String, dynamic>`:

```dart
{
  'id': 'bench_press',
  'name': 'Bench Press',
  'targetMuscles': 'Chest, Triceps, Shoulders',
  'equipment': 'Barbell',
  'difficulty': 'Intermediate',        // 'Beginner' | 'Intermediate' | 'Advanced'
  'category': 'Strength',              // 'Strength' | 'Cardio' | 'Flexibility'
  'image': 'https://...',              // Remote image URL
  'instructions': 'Step-by-step...',
  'videoUrl': 'https://youtube...',    // Optional
}
```

This is the **source of truth** for exercise names. When Gemini generates exercise names, they should match entries in this list for video/image linking to work.

**IMPORTANT — `bodyPart` values must stay English (M9 change):**
The `bodyPart` field uses exact `.contains()` matching in the exercise library filter. Values must match the filter chip strings in `filter_bottom_sheet_widget.dart`:
`Chest | Back | Legs | Shoulders | Arms | Abs | Cardio`

**IMPORTANT — `difficulty` values must stay English (M9 change):**
Switch cases in `exercise_card_widget.dart` and `exercise_detail_sheet.dart` match on:
`'Beginner' | 'Intermediate' | 'Advanced'`
Do NOT use Romanian values (`Începător`, `Intermediar`, `Avansat`) in this file.

---

## AIPlanService (`data/services/ai_plan_service.dart`)

Handles persisting and retrieving generated AI plans to/from Supabase.
Distinct from `GeminiAIService` (which generates) — this service saves/loads plans.

---

## Adding New Models

1. Create the model class in `lib/data/models/`
2. Add `fromMap(Map<String, dynamic>)` and `toMap()` methods
3. Keep models pure Dart — no Flutter imports, no service calls inside models
4. If the model maps to a Supabase table, column names in `toMap()` must match the table schema exactly

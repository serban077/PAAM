// Shared AI prompt fragments and nutrition policy constants.
//
// Single source of truth for the food-recognition and recipe-generation
// services. Update nutrition policy (blocklist, macro guards, preferred
// sources) here — never inline in service files.
//
// Source material: MDM Chișinău 2019 — "Ghid de bune practici: Alimentație
// rațională, siguranța alimentelor și schimbarea comportamentului alimentar".

// ── Blocked ingredients ──────────────────────────────────────────────────
//
// Items that must NEVER appear in a generated recipe, even when the client
// has them in the photo. The recipe model should skip these and list them
// in `blocklisted_ingredients_skipped`.

const List<String> kBlockedIngredients = [
  // Processed sugar
  'white sugar', 'brown sugar', 'syrup', 'candy', 'pastries', 'cookies',
  'donuts', 'sweet cereals', 'jam',
  // Bad fats
  'margarine', 'hydrogenated oil', 'palm oil', 'lard', 'trans fat',
  // Processed meat
  'deli meat', 'salami', 'bacon', 'smoked meat', 'kaiser', 'pate',
  // Heavy / processed dairy
  'processed cheese', 'cream cheese', 'fatty kefir', 'heavy cream',
  'industrial ice cream',
  // Sugary sauces
  'commercial mayonnaise', 'sweet ketchup', 'bbq sauce', 'sweet chili',
  // Drinks to avoid
  'sugary soda', 'energy drink', 'sugary juice', 'alcohol',
  // Ultra-processed snacks
  'chips', 'instant noodles', 'ramen', 'buttered popcorn', 'fried potato',
  // Refined grains
  'white bread', 'refined semolina', 'white pasta',
];

// ── Macro guards (per 100 g) ─────────────────────────────────────────────
//
// Skip thresholds: if a packaged ingredient exceeds any of these per 100 g
// of product, the model should exclude it from the recipe.

const Map<String, num> kMacroGuardsPer100g = {
  'sauce_sugar_max_g': 15,
  'dairy_sugar_max_g': 8,
  'snack_saturated_fat_max_g': 5,
  'snack_sugar_max_g': 10,
  'processed_meat_sodium_max_mg': 1200,
  'any_trans_fat_max_g': 0.5,
};

// ── Preferred sources ────────────────────────────────────────────────────
//
// Bias the recipe selection toward these when a choice exists.

const Map<String, List<String>> kPreferredSources = {
  'lean_protein': [
    'chicken breast', 'turkey', 'lean beef', 'lean fish',
    'egg whites', 'low-fat greek yogurt', 'cottage cheese',
    'urdă', 'tofu', 'tempeh',
  ],
  'fatty_fish': ['salmon', 'mackerel', 'sardines', 'tuna'],
  'plant_protein': [
    'lentils', 'chickpeas', 'black beans', 'edamame', 'quinoa',
  ],
  'whole_carbs': [
    'oats', 'brown rice', 'buckwheat', 'whole wheat pasta',
    'whole grain bread', 'sweet potato', 'bulgur',
  ],
  'healthy_fats': [
    'olive oil extra virgin', 'rapeseed oil', 'avocado',
    'raw almonds', 'walnuts', 'chia seeds', 'flaxseeds',
  ],
  'vegetables': [
    'broccoli', 'cauliflower', 'kale', 'spinach',
    'bell pepper', 'zucchini', 'tomato',
  ],
  'fruits': ['berries', 'apple', 'pear', 'kiwi', 'pomegranate', 'citrus'],
};

// ── Taste boosters ───────────────────────────────────────────────────────
//
// Flavor tools that keep "healthy" recipes from being bland.

const Map<String, List<String>> kTasteBoosters = {
  'herbs': [
    'parsley', 'dill', 'basil', 'oregano', 'thyme',
    'rosemary', 'mint', 'coriander',
  ],
  'spices': ['garlic', 'ginger', 'turmeric+pepper', 'paprika', 'cumin'],
  'umami_acid': [
    'lemon', 'balsamic vinegar', 'natural mustard',
    'low-sodium soy sauce', 'tomato paste',
  ],
  'techniques': ['roasted', 'grilled', 'pan-seared', 'baked', 'steamed'],
};

// ── Quantity reference (Vision anchors) ──────────────────────────────────

const Map<String, int> kQuantityReferenceG = {
  'standard jar': 400,
  'egg carton of 10': 600,
  'milk bottle 1L': 1000,
  'ketchup bottle': 450,
  'mayo jar': 230,
  'beer can': 330,
  'yogurt cup single': 150,
  'cheese block': 200,
};

// ── Hard per-serving recipe constraints ──────────────────────────────────

class RecipeConstraints {
  static const int minProteinG = 25;           // ≥ 35 for muscle_gain
  static const int minProteinMuscleGainG = 35;
  static const int maxFatG = 20;               // ≤ 25 for muscle_gain
  static const int maxFatMuscleGainG = 25;
  static const int maxSaturatedFatG = 5;
  static const int maxAddedSugarG = 10;
  static const int maxSodiumMg = 600;
  static const int minFiberG = 5;
}

// ── Food recognition prompt (documentation style) ────────────────────────

const String kFoodRecognitionPrompt = '''
ROLE: Food ingredient recognition for one photo. Output ONLY a JSON array.

FIELDS (per item):
- name        lowercase English, WHAT the food is (not the container).
              OK: "greek yogurt", "arrabbiata sauce", "chicken breast".
              NO: "jar", "bottle", "package".
- estimated_quantity_g   NUMBER, total grams visible.
- category    one of: protein | carb | fat | vegetable | fruit | dairy | condiment

CATEGORY GUIDE:
protein=meat/fish/eggs/tofu/legumes/protein powder   carb=bread/rice/pasta/oats/potato/cereal
fat=oil/butter/nuts/seeds                            vegetable=greens/cruciferous/peppers/squash
fruit=berries/citrus/apples/bananas/tropical         dairy=milk/yogurt/cheese/cream
condiment=sauces/mayo/mustard/dressings/spreads

RULES:
1. Read every visible brand / label before naming an item.
2. Same item repeated (e.g. 2 egg cartons): ONE entry with summed quantity.
3. Skip non-food objects (plates, shelves, hands, appliances).
4. Partially occluded item: include if still identifiable.
5. If no food is visible: return [].

QUANTITY ANCHORS (scale by visible fill level):
jar ~400g | egg carton of 10 ~600g | 1L milk ~1000g | ketchup bottle ~450g
mayo jar ~230g | beer can ~330ml | yogurt cup ~150g | cheese block ~200g
chicken breast ~200g | steak ~250g | banana ~120g | apple ~180g | tomato ~120g
bread loaf ~500g | pasta bag ~500g | rice bag ~1000g | oil bottle ~750g

AMBIGUITY:
- Meat unclear (pork vs beef)? Pick the more likely one, don't invent fields.
- Can't read label? Describe by appearance: "red sauce in jar".
- Can't tell if it's food at all? Skip.

EXAMPLE — 2 egg cartons + milk + mayo jar:
[{"name":"eggs","estimated_quantity_g":1200,"category":"protein"},
 {"name":"milk","estimated_quantity_g":1000,"category":"dairy"},
 {"name":"mayonnaise","estimated_quantity_g":230,"category":"condiment"}]
''';

// ── Recipe prompt sections ───────────────────────────────────────────────

const String kRecipePromptRole = '''
### ROLE
You are a certified sports nutritionist AND head chef.

### TASK
Generate EXACTLY 3 high-protein recipes using ONLY the listed ingredients.
Each recipe MUST pass every hard constraint below.
Recipe names, descriptions, and cooking steps MUST be written in Romanian.
Ingredient names should stay in lowercase English (matching the input list).
''';

const String kRecipeHardConstraintsSection = '''
### HARD CONSTRAINTS (per serving — self-reject if violated)
- protein_g        ≥ 25    (≥ 35 when fitness_goal = muscle_gain)
- fat_g            ≤ 20    (≤ 25 when fitness_goal = muscle_gain)
- saturated_fat_g  ≤ 5
- added_sugar_g    ≤ 10
- sodium_mg        ≤ 600
- fiber_g          ≥ 5
Set macro_compliance = true only when every rule above is satisfied.
If you had to compromise, set macro_compliance = false AND populate warning.
''';

const String kRecipeMacroGuardsSection = '''
### MACRO GUARDS (skip the ingredient if ANY threshold exceeded)
- sauce with sugar          > 15 g / 100 g  → skip, list in blocklisted_ingredients_skipped
- dairy with added sugar    >  8 g / 100 g  → skip
- snack with saturated fat  >  5 g / 100 g  → skip
- snack with sugar          > 10 g / 100 g  → skip
- processed meat sodium     > 1200 mg / 100 g → skip
- anything with trans fat   >  0.5 g / 100 g → skip
''';

const String kRecipePreferredSourcesSection = '''
### PREFERRED SOURCES (bias toward these when a choice exists)
protein    → chicken breast, turkey, lean fish, salmon, eggs, egg whites,
             low-fat greek yogurt, cottage cheese, tofu, lentils, chickpeas
carbs      → oats, brown rice, buckwheat, whole wheat pasta, sweet potato, bulgur
fats       → olive oil EV, avocado, raw almonds, walnuts, chia seeds
vegetables → broccoli, cauliflower, kale, spinach, bell pepper, zucchini, tomato
fruits     → berries, apple, pear, kiwi, pomegranate, citrus
''';

const String kRecipeTasteBoostersSection = '''
### TASTE BOOSTERS (use liberally — bland recipes are a failure)
herbs      → parsley, dill, basil, oregano, thyme, rosemary, mint, coriander
spices     → garlic, ginger, turmeric+pepper, paprika, cumin
umami/acid → lemon, balsamic vinegar, natural mustard, low-sodium soy, tomato paste
methods    → roasted, grilled, pan-seared, baked, steamed — NEVER deep-fried
''';

const String kRecipeDietaryOverridesSection = '''
### DIETARY OVERRIDES
- vegan / vegetarian → no animal products; pair legumes + grains for complete protein
- gluten_free        → exclude wheat, rye, barley, spelt, regular pasta, regular bread
- dairy_free         → exclude cheese, milk, yogurt, cream, butter
''';

const String kRecipeFailureModesSection = '''
### FAILURE MODES (self-check before emitting each recipe)
- If you can't hit protein ≥ 25 g with only these ingredients:
  emit the recipe, set macro_compliance = false, fill warning with the reason.
- If a recipe would REQUIRE a blocklisted item to work: DO NOT emit that recipe.
- If only 1 or 2 recipes are achievable: emit fewer — NEVER pad with junk.

### OUTPUT FIELDS (extended schema)
For each recipe:
  name, description, prep_time_minutes, cook_time_minutes, servings,
  difficulty, ingredients[], steps[] (max 5), macros_per_serving,
  warning (STRING, nullable — human-readable reason for any compromise),
  macro_compliance (BOOLEAN — true iff every hard constraint is satisfied),
  blocklisted_ingredients_skipped (ARRAY<STRING> — blocked items the client had
                                   that you refused to use; may be empty),
  protein_density (NUMBER — protein_g per 100 kcal in this recipe).
difficulty ∈ {"easy", "medium", "hard"}.
Steps must be in Romanian, max 5 steps per recipe, each step ≤ 140 chars.
''';

/// Builds the full recipe prompt by stitching together the policy sections
/// with user-specific context (ingredients, macro targets, fitness goal,
/// dietary preference). Called from [SmartRecipeService.generateRecipes].
String buildRecipePrompt({
  required String ingredientLines,
  required String macroContext,
  required String fitnessGoal,
  required String dietaryPreference,
}) {
  final blocklistCsv = kBlockedIngredients.join(', ');
  return '''
$kRecipePromptRole
### USER CONTEXT
Available ingredients:
$ingredientLines
$macroContext
fitness_goal: $fitnessGoal
dietary_preference: $dietaryPreference

$kRecipeHardConstraintsSection
### INGREDIENT BLOCKLIST (never include, even if client has them)
$blocklistCsv

$kRecipeMacroGuardsSection
$kRecipePreferredSourcesSection
$kRecipeTasteBoostersSection
$kRecipeDietaryOverridesSection
$kRecipeFailureModesSection
''';
}

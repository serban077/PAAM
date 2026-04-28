// Shared AI prompt fragments and nutrition policy constants.
//
// Single source of truth for the food-recognition, recipe-generation,
// workout-plan, and nutrition-plan services. Update policy (blocklist,
// macro guards, preferred sources, medical safety, plan structure) here —
// never inline in service files.
//
// Source material: MDM Chișinău 2019 — "Ghid de bune practici: Alimentație
// rațională, siguranța alimentelor și schimbarea comportamentului alimentar";
// see also `_medical_conditions_kb.dart` for evidence-based condition rules.

import '_medical_conditions_kb.dart';

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
You are a certified sports nutritionist (RD + CISSN) AND a professional chef
with 15+ years experience. You apply evidence-based nutrition: WHO/EFSA macro
distribution guidelines, ISSN protein recommendations (1.6–2.2 g/kg bodyweight
for active adults), Mediterranean-diet principles, and the MDM Chișinău 2019
rational-nutrition guide. You protect the user from hidden sugars, saturated/
trans fats, refined grains, and ultra-processed foods while maximizing
satiety, micronutrient density, and flavor.

### TASK
Generate EXACTLY 3 high-protein recipes using ONLY the listed ingredients.
Each recipe MUST pass every hard constraint below.
Recipe names, descriptions, and cooking steps MUST be written in Romanian.
Ingredient names should stay in lowercase English (matching the input list).
''';

const String kNutritionKnowledgeSection = '''
### NUTRITION KNOWLEDGE YOU APPLY

FAT QUALITY (this is the single most common failure mode — watch it closely):
- SATURATED fat (butter, lard, fatty red meat, palm/coconut oil, cheese fat):
  cap at 5 g / serving. Raises LDL cholesterol when above 10 % of daily kcal.
- TRANS fat (hydrogenated oils, margarine, industrial pastries): ZERO.
  WHO target is < 1 % of daily kcal; no safe intake exists. Skip any item
  showing "partially hydrogenated" or > 0.5 g trans fat / 100 g.
- MONOUNSATURATED fat (olive oil EV, avocado, almonds, hazelnuts,
  macadamia): PREFER these — lower LDL, protect HDL, anti-inflammatory.
- POLYUNSATURATED fat (walnuts, chia/flax/hemp seeds, fatty fish):
  PREFER — provide essential omega-3 (EPA/DHA/ALA) and omega-6.
  Target omega-6 : omega-3 ratio ≤ 4 : 1.
- Cooking fat rule: use EV olive oil or rapeseed oil for low/medium heat,
  avocado oil for high heat. NEVER re-use fried oil — oxidation creates
  harmful aldehydes. Prefer non-stick pan + 1 tsp oil over pool-frying.

PROTEIN QUALITY:
- Complete proteins (all 9 essential amino acids): eggs (gold standard,
  DIAAS 1.13), whey, chicken breast, fish, lean beef, greek yogurt.
- Plant proteins usually limit on lysine (grains) or methionine (legumes):
  combine legumes + grains in one meal (e.g. lentils + brown rice,
  chickpeas + bulgur, beans + quinoa) for complete amino profile.
- Leucine threshold for muscle protein synthesis: ≥ 2.5 g / meal
  ⇒ ~25 g animal protein OR ~40 g plant protein.
- Avoid processed meats (salami, bacon, hot dogs, pate) — IARC Group 1
  carcinogen (colorectal cancer risk at ~50 g/day).

CARB QUALITY:
- Prefer WHOLE carbs: oats, brown rice, buckwheat, quinoa, bulgur,
  whole-wheat pasta, sweet potato, legumes. Low glycemic load, high fiber,
  slow insulin response, sustained energy.
- Refined carbs (white bread, white pasta, pastries, sugary cereals,
  instant noodles): AVOID — spike insulin, short satiety, nutrient-poor.
- Added sugar ceiling: WHO strong recommendation < 25 g/day (6 tsp).
  Fruit sugar in whole fruit is NOT added sugar — fiber matrix offsets it.
- Fiber target: adults 25–30 g/day. Prioritize soluble (oats, lentils,
  chia, apples) + insoluble (whole grains, vegetables, nuts).

SODIUM:
- Upper limit 2000 mg/day (≈ 5 g salt); per-meal cap 600 mg.
- Hidden sodium sources: soy sauce (~900 mg / tbsp), bouillon cubes,
  processed cheese, deli meats, canned soups. Prefer LOW-SODIUM variants
  or substitute with lemon + herbs + garlic for flavor.

MICRONUTRIENT DENSITY (aim to cover per-meal):
- Vitamin C: bell pepper, citrus, berries, broccoli, kiwi.
- Vitamin A (beta-carotene): sweet potato, carrot, spinach, kale.
- Folate: leafy greens, legumes, asparagus.
- Iron (heme + non-heme): lean red meat, liver OR lentils + vitamin C
  source (absorption boost of ~3×). Pair spinach with lemon juice.
- Calcium: low-fat dairy, sardines, tofu, fortified plant milks, kale.
- Vitamin D: fatty fish, egg yolk, fortified foods (supplement in winter).
- Potassium (for BP control, counterbalances sodium): potato, banana,
  spinach, white beans, yogurt.
- Omega-3: salmon, sardines, mackerel, walnuts, chia, flaxseed.

COOKING METHODS (ranked from best to worst for health):
1. BEST — steaming, boiling, poaching, sous-vide: preserve micronutrients,
   add no fat, no harmful compounds.
2. GOOD — baking, roasting, grilling (≤ 200 °C), pan-searing with ≤ 1 tbsp
   oil, air-frying.
3. ACCEPTABLE — stir-frying with EV olive / rapeseed oil, fast + hot.
4. AVOID — deep frying, pan-frying in abundant oil, charring, smoking.
   Produces acrylamide (starches > 120 °C), HCAs + PAHs (charred meat),
   oxidized fats. Deep-fried food may NEVER appear in these recipes.

HYDRATION & TIMING (recipe descriptions may mention this when relevant):
- Pair high-protein meals with ~500 ml water — aids digestion + satiety.
- Post-workout window: 25–40 g protein + 30–60 g complex carbs within
  2 h supports muscle protein synthesis and glycogen resynthesis.

SATIETY DESIGN (use to hit protein ≥ 25 g without calorie creep):
- Protein + fiber + water volume = highest satiety per kcal
  (e.g. greek yogurt + berries + oats > pastry of equal kcal).
- Avoid liquid calories (juice, smoothies with added sugar) — low satiety.
- Include a crunchy element (raw veg, nuts, seeds) — chewing prolongs meal
  and signals fullness.
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
### PREFERRED SOURCES (bias toward these — reasons included)
LEAN PROTEIN (low saturated fat, complete AA profile):
  chicken breast (skinless), turkey breast, lean beef (round/sirloin),
  white fish (cod, hake, sea bass), egg whites, low-fat greek yogurt
  (0–2 % fat), cottage cheese, tofu, tempeh, urdă.
FATTY FISH (omega-3 EPA/DHA, 2×/week per cardiology guidelines):
  salmon, mackerel, sardines, herring, tuna (fresh or in water).
PLANT PROTEIN (high fiber, low sat fat, combine with grains):
  lentils, chickpeas, black/red/white beans, edamame, quinoa,
  hemp seeds, pumpkin seeds.
COMPLEX / WHOLE CARBS (low GI, fiber, B-vitamins):
  rolled oats, steel-cut oats, brown rice, buckwheat, whole-wheat pasta,
  whole-grain bread (≥ 6 g fiber / 100 g), sweet potato, bulgur, barley,
  quinoa, freekeh.
HEALTHY FATS (mono + polyunsaturated, ≤ 20 g total fat per serving):
  EV olive oil (cold use), rapeseed/canola oil (cooking), avocado,
  raw almonds, walnuts, hazelnuts, pistachios, chia/flax/hemp seeds,
  tahini (natural, no added sugar).
VEGETABLES (volume, micronutrients, fiber — aim ≥ 200 g per serving):
  broccoli, cauliflower, kale, spinach, arugula, bell pepper, zucchini,
  tomato, cucumber, carrot, beetroot, asparagus, green beans, eggplant,
  onion, garlic, mushrooms.
FRUITS (whole, not juiced — fiber keeps sugar response low):
  berries (lowest GI), apple, pear, kiwi, pomegranate, citrus, peach,
  plum, cherries. Bananas OK post-workout.
''';

const String kRecipeTasteBoostersSection = '''
### TASTE BOOSTERS (use liberally — bland "healthy" food is the #1 reason
### people abandon a diet)
HERBS (fresh or dried, unlimited, near-zero kcal):
  parsley, dill, basil, oregano, thyme, rosemary, mint, coriander, chives,
  sage, tarragon, bay leaf.
SPICES (anti-inflammatory + flavor, unlimited):
  garlic, ginger, turmeric + black pepper (piperine boosts curcumin
  absorption ~20×), paprika (sweet/smoked), cumin, coriander seed, chili
  flakes, cinnamon, nutmeg, cardamom, fennel seed, sumac.
UMAMI / ACID (depth without calories or sodium bombs):
  lemon juice + zest, lime, balsamic vinegar, red-wine vinegar, apple
  cider vinegar, natural mustard (Dijon), low-sodium soy sauce or tamari
  (use sparingly — still salty), tomato paste, nutritional yeast, miso
  (low-sodium), anchovy paste (trace amounts).
COOKING METHODS (ranked):
  steaming, poaching, sous-vide > roasting, grilling (≤ 200 °C),
  pan-searing with ≤ 1 tbsp oil, air-frying > stir-frying > STOP.
  NEVER deep-fry, NEVER pan-fry in pooled oil, NEVER char meat
  (acrylamide, HCAs, PAHs). Reuse of cooking oil is forbidden.
AROMATIC BASE (Romanian mirepoix that keeps dishes familiar):
  onion + garlic + carrot + celery, sweated in 1 tsp EV olive oil,
  deglazed with lemon juice or tomato paste. Forms the base of soups,
  stews, braises without heavy cream or butter.
''';

const String kRecipeDietaryOverridesSection = '''
### DIETARY OVERRIDES
- vegan / vegetarian → no animal products; pair legumes + grains for complete protein
- gluten_free        → exclude wheat, rye, barley, spelt, regular pasta, regular bread
- dairy_free         → exclude cheese, milk, yogurt, cream, butter
''';

const String kRecipeFailureModesSection = '''
### FAILURE MODES — SELF-CHECK BEFORE EMITTING EACH RECIPE
Run this checklist on every recipe before writing it to output:

1. CALORIES: if macros_per_serving.calories differs from
   (protein_g × 4 + carbs_g × 4 + fat_g × 9) by more than 5 %, recompute.
2. PROTEIN: does it hit the fitness_goal threshold?
   weight_loss / maintenance / general → ≥ 25 g.  muscle_gain → ≥ 35 g.
3. FAT: total ≤ 20 g (muscle_gain ≤ 25 g).  Saturated ≤ 5 g.  Trans ZERO.
4. SUGAR: added sugar ≤ 10 g. Whole-fruit sugar doesn't count.
5. SODIUM: ≤ 600 mg.  If you used soy sauce / broth cubes / deli anything,
   re-check — one tablespoon of regular soy sauce is already ~900 mg.
6. FIBER: ≥ 5 g. If not, add a vegetable serving OR switch refined to whole
   grain. Adjust both ingredients and macros.
7. BLOCKLIST: if a recipe REQUIRES a blocklisted item to work → DO NOT emit it.
8. COOKING METHOD: if steps mention frying in abundant oil, deep-frying,
   charring, or reused oil → REWRITE the steps.
9. DIETARY OVERRIDE: re-verify vegan/vegetarian/gluten_free/dairy_free
   (scan every ingredient against the override list).
10. NUMBER OF RECIPES: if only 1–2 recipes are truly achievable, emit fewer.
    NEVER pad with a sugary or ultra-processed filler recipe.

If you had to compromise on ANY constraint, set macro_compliance = false AND
populate `warning` with a clear Romanian explanation of what was compromised
and why (e.g. "Nu se poate atinge 25 g proteină doar cu ingredientele date —
adăugați un ou sau 30 g piept de pui pentru conformitate").

### OUTPUT FIELDS (extended schema)
For each recipe:
  name, description, prep_time_minutes, cook_time_minutes, servings,
  difficulty, ingredients[], steps[] (max 5), macros_per_serving,
  warning (STRING, nullable — Romanian explanation of any compromise),
  macro_compliance (BOOLEAN — true iff every hard constraint is satisfied),
  blocklisted_ingredients_skipped (ARRAY<STRING> — blocked items the client had
                                   that you refused to use; may be empty),
  protein_density (NUMBER — protein_g per 100 kcal in this recipe,
                   round to 1 decimal; target ≥ 8 g / 100 kcal).
difficulty ∈ {"easy", "medium", "hard"}.
Steps must be in Romanian, max 5 steps per recipe, each step ≤ 140 chars.
Description (Romanian, 1 sentence) should highlight the nutritional win
(e.g. "Bogat în omega-3 și fibre solubile, grăsimi saturate sub 3 g").
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

$kNutritionKnowledgeSection
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

// ─────────────────────────────────────────────────────────────────────────
// WORKOUT PLAN PROMPT — atomic sections, sequential subtasks
// ─────────────────────────────────────────────────────────────────────────

const String kWorkoutPromptRole = '''
### ROLE
You are a certified personal trainer (NSCA-CPT / ACSM-CPT) and strength &
conditioning coach (CSCS) with deep applied knowledge of biomechanics,
hypertrophy science (Schoenfeld 2016 / 2017 / 2021), periodization, and
clinical exercise prescription. You write programs that are SAFE first,
EFFECTIVE second, and ENJOYABLE third.

### TASK
Generate a personalized weekly workout split for a single user. Output is
strict JSON conforming to the provided response schema. You must:
  - apply every contraindication implied by the user's medical_conditions,
  - select exercises ONLY from the verified library provided,
  - respect the recommended split for the user's frequency,
  - balance weekly volume per muscle group,
  - emit Romanian coaching tips and a Romanian safety_notes string.
''';

const String kWorkoutScientificPrinciples = '''
### SCIENTIFIC PRINCIPLES (MANDATORY)
Volume (per Schoenfeld et al., systematic reviews):
- Hypertrophy: 10–20 working sets / muscle group / week
- Strength: 6–12 working sets / muscle group / week, heavier load
- Beginners stay at the lower end; advanced trainees toward the upper end.

Frequency:
- Train each major muscle group 2× / week minimum where the split allows.

Rep ranges by goal:
- Strength: 3–6 reps @ RPE 7–9
- Hypertrophy: 6–12 reps @ RPE 7–9 (effective range can extend to 5–30 with
  proximity to failure, but 6–12 is the default for this app)
- Muscular endurance / toning: 12–20 reps @ RPE 6–8
- Body recomposition / general fitness: 8–12 reps @ RPE 7–8

Rest periods:
- Compound multi-joint (squat, deadlift, bench, row, OHP): 90–180 s
- Isolation single-joint (curl, extension, raise): 45–90 s
- Strength focus: 2–5 min between heavy sets

Progression:
- Recommend small, consistent increments (~2.5 kg upper, ~5 kg lower) when
  RIR ≥ 2 on the last set across all sets. Beginners can progress weekly;
  intermediates every 1–2 weeks; advanced via planned mesocycles.

Warm-up + cool-down:
- 5–10 min general aerobic warm-up + 1–2 ramp sets per major lift
- Static stretching only POST workout (≤ 30 s holds), not pre.
''';

const String kWorkoutSelectionAlgorithm = '''
### SELECTION ALGORITHM — PERFORM THESE STEPS IN ORDER
Do not skip steps. Each step builds on the previous. Show no working out —
only emit the final JSON — but execute the algorithm internally.

STEP 1 — PARSE PROFILE
Read every field in the USER CONTEXT block. Note: age, gender, weight, height,
goal, level, equipment, frequency, dietary preference, and the FREE-TEXT
medical_conditions field.

STEP 2 — APPLY MEDICAL SAFETY PROTOCOL
Run the 5-step algorithm in the MEDICAL CONDITIONS KNOWLEDGE BASE block.
Build an internal forbidden_movements list (e.g. {Valsalva, deep loaded
flexion, behind-neck press, ...}) AND record each detected condition for
the safety_notes output. If ANY condition triggers DOCTOR_CONSULT, jump to
the doctor-consult emit path: set requires_doctor_consult=true, populate
safety_notes with a clear Romanian explanation, emit minimal valid JSON,
and STOP.

STEP 3 — PICK SPLIT
Use the SPLIT recommended for the user's weekly_training_frequency. Do NOT
mix muscle groups across days outside the split definition.

STEP 4 — ALLOCATE WEEKLY VOLUME
For each major muscle group hit by the split, choose a weekly working-set
target (10–20 hypertrophy / 6–12 strength) consistent with the user's
experience level and goal. Distribute the sets across the days that train
that group.

STEP 5 — SELECT EXERCISES FROM THE VERIFIED LIBRARY
HARD RULE — no exception, no creativity allowed at this step:
The EXERCISE LIBRARY block above is the ONLY universe of allowed
exercises. Every single `exercise_name` you emit MUST appear,
character-for-character (case-sensitive, exact spelling, exact spacing),
in that block. If the perfect movement you want (e.g. "Dead Bug",
"Goblet Squat", "Pallof Press") is not in the list — DO NOT EMIT IT.
Find the closest substitute that IS in the list and use that name
verbatim. It is better to repeat a verified exercise across days than
to invent a name the app cannot resolve.

For each day:
- pick 4–6 exercises from the EXERCISE LIBRARY block,
- start with a heavy compound, then a secondary compound, then 2–3
  isolation / accessory movements,
- skip any exercise that conflicts with the forbidden_movements list,
- prefer the substitutes recommended by the medical-condition rules
  when the primary choice is forbidden,
- use EXACT English names from the library (the cache + DB lookups
  fail completely on any deviation — even "Dead Bug" vs "Deadbug" is
  a hard failure).

STEP 6 — PRESCRIBE SETS / REPS / REST
Set sets, reps, rest_seconds for each exercise based on the user's goal,
level, and the rep-range rules above. Beginners default to 3 sets ×
8–12 reps × 60–90 s rest on most lifts.

STEP 7 — WRITE COACHING TIP (ROMANIAN)
For each exercise emit a coaching_tip in Romanian that is specific to the
movement (cue + 1 safety reminder when relevant), max 140 characters.

STEP 8 — SELF-CHECK (FAILURE MODES BLOCK)
Run the failure-modes checklist. If any item fails, regenerate that day
before emitting.
''';

const String kWorkoutFailureModes = '''
### WORKOUT FAILURE MODES — SELF-CHECK BEFORE EMITTING
Before returning the JSON, verify each item:

1. SAFETY: every exercise on every day is compatible with the
   forbidden_movements list derived from medical_conditions. If you cannot
   build a day without using a forbidden movement, replace it with the
   safest accessory from the library that targets the same group.
2. LIBRARY: every exercise_name is present, character-for-character, in the
   EXERCISE LIBRARY block. Do NOT invent names. Do NOT translate names.
   Do NOT emit common-but-absent picks like "Dead Bug", "Goblet Squat",
   "Pallof Press", "Bird Dog" if the library does not list them — the
   client-side validator will silently DROP every name that doesn't match,
   which can leave a day with only 1–2 exercises. If you find yourself
   wanting an exercise that isn't in the list, pick the closest match
   that IS in the list (e.g. "Plank" instead of "Dead Bug", "Dumbbell
   Squat" instead of "Goblet Squat") and emit THAT exact name.
3. SPLIT INTEGRITY: each day trains ONLY the muscle groups the split
   defines for it (no biceps work on Push day, no quad work on Pull day).
4. VOLUME BALANCE: total weekly working sets per muscle group fall inside
   the goal-appropriate landmark (10–20 hypertrophy / 6–12 strength).
5. NUMBER OF DAYS: emit EXACTLY weekly_training_frequency day_X keys
   (day_1, day_2, ..., day_N) and no more.
6. EXERCISES PER DAY: 4–6 inclusive.
7. REP / REST CONSISTENCY: rep ranges match the user's goal (no 4-rep sets
   on a "muscular endurance" plan).
8. ROMANIAN COACHING: coaching_tip is Romanian, ≤ 140 characters, specific
   to the movement (not generic "execută corect").
9. SAFETY NOTES: safety_notes lists each detected condition + the rule
   applied. If no condition was declared, write
   "Nicio afecțiune declarată — plan general aplicat".
10. requires_doctor_consult: true only when a DOCTOR_CONSULT condition was
    detected; otherwise false.

### OUTPUT FIELDS
training_plan: { day_1: [...], day_2: [...], ... }   (keys exactly day_1..day_N)
each exercise:
  exercise_name (English, EXACTLY from library),
  sets (INTEGER),
  reps (STRING — e.g. "8-12" or "5"),
  rest_seconds (INTEGER),
  coaching_tip (Romanian, ≤ 140 chars).
safety_notes (STRING, Romanian) — required.
requires_doctor_consult (BOOLEAN) — required.
''';

/// Builds the full workout-plan prompt. Called from
/// [GeminiAIService.generateWeeklyWorkoutPlan] and the streaming variant.
String buildWorkoutPlanPrompt({
  required String userContext,
  required int daysPerWeek,
  required String splitGuide,
  required String exerciseLibrary,
  required String fitnessGoal,
  required String experienceLevel,
}) {
  return '''
$kWorkoutPromptRole

### USER CONTEXT
$userContext
weekly_training_frequency: $daysPerWeek days
fitness_goal: $fitnessGoal
experience_level: $experienceLevel

${buildMedicalKnowledgeSection()}

### EXERCISE LIBRARY (whitelist — pick ONLY from these)
$exerciseLibrary

### SPLIT FOR $daysPerWeek DAYS / WEEK
$splitGuide

$kWorkoutScientificPrinciples

$kWorkoutSelectionAlgorithm

$kWorkoutFailureModes
''';
}

// ─────────────────────────────────────────────────────────────────────────
// NUTRITION PLAN PROMPT — atomic sections, sequential subtasks
// ─────────────────────────────────────────────────────────────────────────

const String kNutritionPromptRole = '''
### ROLE
You are a registered dietitian + sports nutritionist (RD + CISSN) with deep
clinical and applied knowledge: WHO/EFSA macro-distribution guidelines, ISSN
protein recommendations (1.6–2.2 g / kg / day for active adults), Mediterranean
and DASH dietary patterns, ADA Standards of Care 2025, KDIGO 2024 (CKD
nutrition), the Monash low-FODMAP framework, ACOG pregnancy nutrition, and
the MDM Chișinău 2019 rational-nutrition guide.

### TASK
Generate a personalized one-day nutrition plan with 4–5 meals (Mic dejun,
Prânz, Gustare, Cină, optional Gustare seara). Each meal has 2–3 options
written in Romanian with concrete grams / ml. Emit strict JSON conforming
to the provided response schema. You must:
  - apply every dietary constraint implied by medical_conditions,
  - respect the user's dietary_preference (vegan / vegetarian / gluten_free /
    dairy_free / normal),
  - hit the calorie + macro target derived for the user's goal,
  - write food names + descriptions in Romanian,
  - emit a Romanian safety_notes string and a requires_doctor_consult flag.
''';

const String kNutritionMacroMath = '''
### CALORIE & MACRO MATH — DO THIS FIRST
Step A — BMR via Mifflin-St Jeor:
- men:   BMR = 10·weight_kg + 6.25·height_cm − 5·age + 5
- women: BMR = 10·weight_kg + 6.25·height_cm − 5·age − 161

Step B — TDEE = BMR × activity_factor:
- sedentary           1.2
- lightly_active      1.375
- moderately_active   1.55
- very_active         1.725
- extremely_active    1.9

Step C — apply the GOAL adjustment to TDEE:
- weight_loss         −500 kcal (≈ 0.5 kg / week)   floor: 1500 men / 1200 women
- toning              −250 kcal
- maintenance         ±0
- general_fitness     ±0
- endurance           ±0 to +200
- muscle_gain         +300 to +500 (lean bulk)
- body_recomposition  ±0 with high protein

Step D — macros (per kg body weight unless noted):
- weight_loss:        protein 1.8–2.2 g/kg | fat 0.6–0.8 g/kg | carbs fill remainder
- toning:             protein 1.6–2.0 g/kg | fat 0.7–0.9 g/kg | carbs fill remainder
- maintenance:        protein 1.4–1.8 g/kg | fat 0.8–1.0 g/kg | carbs fill remainder
- muscle_gain:        protein 1.6–2.2 g/kg | fat 0.8–1.0 g/kg | carbs fill remainder
- endurance:          protein 1.4–1.6 g/kg | fat 0.8–1.0 g/kg | carbs 5–7 g/kg
- body_recomp:        protein 2.0–2.4 g/kg | fat 0.6–0.8 g/kg | carbs fill remainder

Verify: protein·4 + carbs·4 + fat·9 must match daily_calories_goal within ±5 %.
''';

const String kNutritionMealDistribution = '''
### MEAL DISTRIBUTION & TIMING
Default 4–5 meals / day. Suggested split (% of daily kcal):
- Mic dejun (breakfast) 25 %
- Gustare dimineața     10 % (optional — used when 5 meals)
- Prânz (lunch)         30 %
- Gustare după-amiază   10 %
- Cină (dinner)         25 %

Workout-day timing:
- Pre-workout (60–90 min before): moderate carbs + lean protein, low fat /
  fiber.
- Post-workout (within 60–90 min): 25–40 g protein + 30–60 g complex carbs
  for muscle protein synthesis + glycogen resynthesis.

Per-meal protein floor: 25 g (animal sources) or 35 g (plant — for
leucine threshold).

If user has DIABETES: distribute carbs more evenly across meals (avoid
60+ g carb single bolus); pair carbs with protein + fat + fiber to flatten
glucose response.
''';

const String kNutritionHardConstraints = '''
### HARD CONSTRAINTS — APPLY TO EVERY MEAL OPTION
- daily protein hits the goal-appropriate g/kg target,
- fiber ≥ 25–30 g / day total (≥ 5 g per main meal),
- added sugar ≤ 25 g / day (WHO),
- sodium ≤ 2000 mg / day (≤ 1500 mg if hypertension / heart failure / CKD),
- saturated fat ≤ 10 % of daily kcal (≤ 7 % if dyslipidemia / CAD),
- trans fat = ZERO,
- when meal includes added oil for cooking, default to EV olive oil or
  rapeseed oil; never re-used / pre-fried oil; never deep-frying,
- apply medical_conditions overrides on top of these constraints.

If a constraint cannot be met given the dietary_preference + medical
context, choose the closest compliant option AND mention the compromise
in safety_notes.
''';

const String kNutritionSelectionAlgorithm = '''
### SELECTION ALGORITHM — PERFORM THESE STEPS IN ORDER
STEP 1 — PARSE PROFILE
Read every field in USER CONTEXT, including the FREE-TEXT
medical_conditions and any dietary_preference / activity_level fields.

STEP 2 — APPLY MEDICAL DIETARY PROTOCOL
Run the 5-step algorithm in the MEDICAL CONDITIONS KNOWLEDGE BASE block.
Build an internal forbidden_foods list (e.g. {high-sodium, high-purine,
high-FODMAP, gluten, lactose, ...}) AND record each detected condition
for safety_notes. If ANY DOCTOR_CONSULT condition is detected without
medical clearance, set requires_doctor_consult=true, populate
safety_notes, emit minimal valid JSON, and STOP.

STEP 3 — APPLY DIETARY PREFERENCE OVERRIDE
- vegan: no animal products; pair legumes + grains for complete protein.
- vegetarian: no meat / fish / poultry; eggs + dairy OK.
- gluten_free: exclude wheat, rye, barley, spelt; switch breads / pastas.
- dairy_free: exclude milk / cheese / yogurt / cream / butter.
- normal: no override.

STEP 4 — RUN CALORIE & MACRO MATH (block above)
Compute BMR → TDEE → goal-adjusted daily_calories_goal → macro grams.

STEP 5 — DISTRIBUTE CALORIES + MACROS ACROSS MEALS
Use the meal-distribution block. Adjust for diabetes (even carb spread)
and for workout timing if mentioned in profile.

STEP 6 — DRAFT 2–3 OPTIONS PER MEAL
Each option includes a Romanian description with concrete grams / ml,
calories (rounded to integer), protein_g, carbs_g, fat_g (one decimal).
Prefer foods from PREFERRED SOURCES; never use BLOCKED INGREDIENTS;
never use any item from the forbidden_foods list built in Step 2.
Substitute per the condition rules (e.g. dairy → fortified plant milk).

STEP 7 — SELF-CHECK (FAILURE MODES BLOCK)
Run the failure-modes checklist. Regenerate any option that fails.
''';

const String kNutritionFailureModes = '''
### NUTRITION FAILURE MODES — SELF-CHECK BEFORE EMITTING
1. CALORIE MATCH: sum of all options' calories per meal × meal share
   should land within ±5 % of daily_calories_goal when the user picks
   one option per meal.
2. MACRO MATCH: protein·4 + carbs·4 + fat·9 within ±5 % of the option's
   calories field.
3. PROTEIN FLOOR: every main meal hits ≥ 25 g protein (≥ 35 g for plant
   eaters or for muscle_gain users).
4. FIBER: each main meal includes ≥ 5 g fiber.
5. SODIUM: total estimated sodium ≤ user's limit (default 2000 mg, lower
   for HTN / HF / CKD).
6. CONDITION COMPLIANCE: scan every ingredient against the
   forbidden_foods list built from medical_conditions. If any forbidden
   item slipped in, replace it with a compliant substitute.
7. PREFERENCE COMPLIANCE: vegan → no animal products anywhere;
   gluten_free → no wheat / rye / barley anywhere, etc.
8. SUGAR: added sugar across the day ≤ 25 g.
9. ROMANIAN: meal_name and option description are in Romanian.
10. SAFETY NOTES: safety_notes lists each detected condition + applied
    rule (Romanian). If none declared, "Nicio afecțiune declarată — plan
    general aplicat".

### OUTPUT FIELDS
nutrition_plan:
  daily_calories_goal (INTEGER),
  meals: [
    {
      meal_name (STRING, Romanian — e.g. "Mic dejun"),
      options: [
        {
          option_id (INTEGER),
          description (STRING, Romanian, with grams / ml),
          calories (INTEGER, rounded),
          protein_g (NUMBER, 1 decimal),
          carbs_g (NUMBER, 1 decimal),
          fat_g (NUMBER, 1 decimal),
        }
      ]
    }
  ]
notes (STRING, Romanian) — short overall guidance + hydration reminder.
safety_notes (STRING, Romanian) — required.
requires_doctor_consult (BOOLEAN) — required.
''';

/// Builds the full nutrition-plan prompt. Called from
/// [GeminiAIService.generateNutritionPlan].
String buildNutritionPlanPrompt({
  required String userContext,
  required String fitnessGoal,
  required String dietaryPreference,
  required String activityLevel,
}) {
  final blocklistCsv = kBlockedIngredients.join(', ');
  return '''
$kNutritionPromptRole

### USER CONTEXT
$userContext
fitness_goal: $fitnessGoal
dietary_preference: $dietaryPreference
activity_level: $activityLevel

${buildMedicalKnowledgeSection()}

$kNutritionKnowledgeSection

$kNutritionMacroMath

$kNutritionMealDistribution

$kNutritionHardConstraints

### INGREDIENT BLOCKLIST (never include, even if otherwise OK)
$blocklistCsv

$kRecipePreferredSourcesSection

$kRecipeTasteBoostersSection

$kNutritionSelectionAlgorithm

$kNutritionFailureModes
''';
}

// ─────────────────────────────────────────────────────────────────────────
// PERSONALIZED EXERCISE-RECOMMENDATIONS PROMPT (used by getPersonalizedExercises)
// ─────────────────────────────────────────────────────────────────────────

/// Builds the prompt for the broader 15–20 exercise recommendation list
/// (separate from the weekly plan). Called from
/// [GeminiAIService.getPersonalizedExercises].
String buildPersonalizedExercisesPrompt({
  required String userContext,
  required String fitnessGoal,
  required String experienceLevel,
}) {
  return '''
### ROLE
You are a certified personal trainer (NSCA-CPT) with applied biomechanics
expertise. Your job is to recommend 15–20 individual exercises a user can
plug into their training, NOT a weekly split.

### TASK
Generate a JSON array of 15–20 exercises tailored to the user. Apply the
medical-conditions safety protocol below. Use Romanian for descriptions /
instructions / safety tips, and EXACT English names where the user's
exercise database expects them.

### USER CONTEXT
$userContext
fitness_goal: $fitnessGoal
experience_level: $experienceLevel

${buildMedicalKnowledgeSection()}

### REQUIREMENTS
1. Cover all major muscle groups (chest, back, legs, shoulders, arms, abs)
   when not in conflict with medical contraindications.
2. Match exercise difficulty to experience_level.
3. Skip every movement on the forbidden_movements list derived from
   medical_conditions; substitute the safest equivalent the rules suggest.
4. Use ONLY the equipment available to the user.
5. For each exercise emit a YouTube videoUrl from a recognized fitness
   channel (ATHLEAN-X, Jeff Nippard, ScottHermanFitness, FitnessBlender,
   Calisthenicmovement). Avoid private / restricted-playback channels.
6. Romanian instructions + safety tips + whyRecommended; videos may be
   English.

### OUTPUT (JSON array)
Each entry:
  name (Romanian),
  bodyPart (Piept|Spate|Picioare|Umeri|Brațe|Abdomen),
  targetMuscles (Romanian),
  equipment (Romanian short),
  difficulty (Începător|Intermediar|Avansat),
  sets (INTEGER),
  reps (STRING — e.g. "8-12"),
  restSeconds (INTEGER),
  videoUrl (STRING),
  instructions (Romanian),
  safetyTips (Romanian — name the medical-condition rule applied if any),
  whyRecommended (Romanian — why for THIS user specifically).
''';
}

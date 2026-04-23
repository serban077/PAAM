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

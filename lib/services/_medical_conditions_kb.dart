// Medical Conditions Knowledge Base — evidence-based reference for AI plan
// generation.
//
// PURPOSE
// -------
// The user's free-text `medical_conditions` field (entered during onboarding)
// MUST drive both the workout plan and the nutrition plan. This file gives
// the AI a structured, condition-by-condition rulebook so that:
//
//   1. exercises that are dangerous for a given condition are never selected,
//   2. foods that worsen a given condition are never recommended,
//   3. truly serious conditions trigger a "consult your doctor" gate instead
//      of a generated plan.
//
// HOW THE AI USES IT
// ------------------
// The full Markdown block returned by [buildMedicalKnowledgeSection] is
// injected verbatim into both the workout and nutrition prompts. The model
// is instructed to:
//   a) lowercase the user's medical_conditions text,
//   b) scan it against every KEYWORDS line below (Romanian + English),
//   c) for every condition it detects, apply the EXERCISE + NUTRITION rules,
//   d) emit the detected conditions back in `safety_notes` (Romanian),
//   e) set `requires_doctor_consult: true` for any DOCTOR_CONSULT condition.
//
// SOURCES (selection — most recent / authoritative)
// -------------------------------------------------
// - ACSM 2024 FITT recommendations for hypertension
// - American Diabetes Association — Standards of Care 2025
// - ACOG Committee Opinion 804 — Physical Activity in Pregnancy
// - KDIGO 2024 Clinical Practice Guideline for CKD
// - OARSI 2023 — exercise for knee/hip OA
// - Pisters et al. — comorbidity-adapted exercise protocols
// - LIFTMOR / LIFTMOR-M trials — high-intensity training in osteoporosis
// - "Too Fit to Fracture" 2014 + 2024 update — osteoporosis exercise
// - ATS 2013 / NAEPP 2020 — exercise-induced bronchoconstriction
// - Monash University Low FODMAP Diet 2024
// - ACR 2020 + 2024 update — gout management
// - ESC 2024 — CV disease primary + secondary prevention
// - WHO 2020 Physical Activity Guidelines
// - MDM Chișinău 2019 — Rational Nutrition Guide
//
// MAINTENANCE
// -----------
// Update an entry when the underlying guideline changes (cite the new source
// in the EVIDENCE line). Do NOT inline this content in service files —
// import [buildMedicalKnowledgeSection] from this file only.

// ── CARDIOVASCULAR ──────────────────────────────────────────────────────

const String _hypertension = '''
#### HYPERTENSION (HIPERTENSIUNE ARTERIALĂ)
KEYWORDS: hipertensiune, HTA, tensiune mare, tensiune crescută, presiune mare, hipertensiv, hipertensivă, hypertension, high blood pressure, elevated bp
SEVERITY: requires_modification (≥180/110 mmHg uncontrolled → DOCTOR_CONSULT)
EXERCISE:
- DO: aerobic 90–150 min / week at moderate intensity (walking, cycling, swimming, elliptical), 5 days / week, 20–30 min / session. Add dynamic resistance training 2–3 days / week, 8–12 reps, RIR ≥ 2.
- AVOID: Valsalva maneuver (any breath-holding under load), 1RM attempts, heavy isometric holds > 15 s, near-maximal sets, supine heavy pressing, head-down inverted positions. Cap RPE at 6–7 / 10.
- WARM-UP / COOL-DOWN: 5 min minimum each — stopping suddenly risks BP swing.
- SIGNS TO STOP: chest pain, palpitations, dizziness, severe headache, BP > 200/110 → end session.
NUTRITION:
- DO: DASH-style. Sodium ≤ 2000 mg / day (≈ 5 g salt). Potassium 4700 mg / day (banana, sweet potato, beans, leafy greens). Magnesium (nuts, whole grains). Calcium (low-fat dairy, sardines).
- AVOID: deli meats, bouillon cubes, salty cheeses, processed soups, pickles, soy sauce > 1 tbsp. Limit alcohol to ≤ 2 drinks / day men, ≤ 1 / day women — preferably zero.
- MACROS: standard for goal; saturated fat ≤ 7 % of kcal.
EVIDENCE: ACSM 2024 FITT — Pescatello et al.; AHA 2023 BP guidelines.
''';

const String _coronaryArteryDisease = '''
#### CORONARY ARTERY DISEASE / POST-MI / ANGINA (BOALĂ CORONARIANĂ / INFARCT / ANGINĂ)
KEYWORDS: infarct, post infarct, ima, sca, sindrom coronarian, angină, angina pectorală, boală cardiacă ischemică, by-pass, bypass coronarian, stent, ateroscleroză coronariană, cardiopatie ischemică, coronary artery disease, cad, post-mi, heart attack, angina, ischemic heart disease
SEVERITY: DOCTOR_CONSULT — requires cardiac rehab clearance and exercise stress test before unsupervised training.
EXERCISE:
- If user has cardiology clearance: aerobic at ≤ 70 % HRmax (or ≤ HR at angina threshold − 10 bpm), no resistance > 60 % 1RM, no Valsalva, no isometric work, gradual ramp.
- Without clearance: do NOT generate a workout plan. Output requires_doctor_consult = true and Romanian safety_note explaining that supervised cardiac rehab is required first.
NUTRITION:
- DO: Mediterranean diet (PREDIMED). Olive oil EV as main fat. Fatty fish 2× / week. Nuts 30 g / day (especially walnuts). Whole grains, legumes, vegetables, fruit.
- AVOID: trans fats (any), saturated fat > 7 % kcal, processed meat, sugary drinks, refined carbs.
- MACROS: omega-3 EPA + DHA ≥ 1 g / day combined; soluble fiber ≥ 10 g / day.
EVIDENCE: ESC 2024 CV prevention; AHA 2021 dietary guidelines; PREDIMED 2018.
''';

const String _heartFailure = '''
#### HEART FAILURE (INSUFICIENȚĂ CARDIACĂ)
KEYWORDS: insuficiență cardiacă, ic, fevs scăzută, cardiomiopatie, fracție de ejecție, edem cardiac, dispnee de efort, heart failure, hf, low ejection fraction, cardiomyopathy
SEVERITY: DOCTOR_CONSULT for NYHA III–IV. NYHA I–II requires_modification under medical supervision.
EXERCISE:
- NYHA I–II only, with prior cardiac rehab: low-intensity aerobic (walking, cycling) 20–30 min, 3–5 days / week, RPE 11–13 / 20.
- AVOID: any heavy resistance, Valsalva, supine exercise > 5 min, exercise in heat / dehydration, sudden position changes.
- STOP IF: weight gain > 1.5 kg overnight, increased dyspnea, leg swelling, fatigue out of proportion.
NUTRITION:
- DO: sodium ≤ 1500–2000 mg / day. Fluid restriction if prescribed (typically 1.5–2 L / day). High-quality protein at ≥ 1.0–1.2 g / kg to prevent cardiac cachexia.
- AVOID: high-sodium prepared foods, alcohol, large meals (increase preload).
EVIDENCE: ESC 2023 HF guidelines; HFSA 2024 nutrition statement.
''';

const String _stroke = '''
#### STROKE / POST-STROKE (AVC / ACCIDENT VASCULAR CEREBRAL)
KEYWORDS: avc, accident vascular cerebral, ischemic, hemoragic, post avc, hemipareză, hemiplegie, stroke, post-stroke, hemiparesis
SEVERITY: DOCTOR_CONSULT — requires neuro / rehab clearance.
EXERCISE:
- Without rehab clearance: do NOT generate workout. Output requires_doctor_consult = true.
- With clearance: low-intensity aerobic + balance + functional training; avoid heavy bilateral loaded movements until symmetric strength returns.
NUTRITION:
- Same as Coronary Artery Disease (Mediterranean / DASH). Sodium ≤ 2000 mg.
EVIDENCE: AHA / ASA 2023 stroke rehabilitation guidelines.
''';

const String _arrhythmia = '''
#### ARRHYTHMIA (ARITMIE / FIBRILAȚIE ATRIALĂ)
KEYWORDS: aritmie, fibrilație atrială, fia, flutter atrial, extrasistole, palpitații frecvente, tahicardie supraventriculară, bradicardie simptomatică, arrhythmia, atrial fibrillation, afib, palpitations
SEVERITY: requires_modification; DOCTOR_CONSULT for symptomatic / uncontrolled rhythms.
EXERCISE:
- Avoid maximal-effort efforts and competitive sport without cardiology clearance. Use RPE-based pacing (target 12–14 / 20). Stop on palpitations, dyspnea, dizziness.
- AVOID: stimulants pre-workout (high-dose caffeine, ephedra), HIIT in first weeks of new arrhythmia.
NUTRITION:
- Limit caffeine to ≤ 200 mg / day. Avoid alcohol entirely if AFib (potent trigger). Adequate magnesium + potassium.
EVIDENCE: ESC 2024 AF guidelines.
''';

// ── METABOLIC / ENDOCRINE ───────────────────────────────────────────────

const String _type2Diabetes = '''
#### TYPE 2 DIABETES (DIABET ZAHARAT TIP 2)
KEYWORDS: diabet, diabet zaharat, dz tip 2, dz2, diabetic, glicemie mare, hiperglicemie, prediabet, rezistență la insulină, type 2 diabetes, t2dm, prediabetes, insulin resistance
SEVERITY: requires_modification; DOCTOR_CONSULT if HbA1c > 10 % or active diabetic complications.
EXERCISE:
- DO: ≥ 150 min / week moderate aerobic + resistance 2–3 days / week + reduce sedentary time (break sitting every 30 min). Train both fasted-friendly walks AND post-meal walks (10–15 min after lunch / dinner — drops post-prandial glucose 20–30 %).
- TIMING: prefer post-meal exercise to blunt glucose spikes. If on insulin / sulfonylurea: monitor glucose before; have 15 g fast carbs ready (hypo risk).
- AVOID: prolonged fasted intense training in users on sulfonylurea / insulin; barefoot training (foot neuropathy risk).
NUTRITION:
- DO: low / medium GI carbs, vegetables ½ plate, lean protein ¼ plate, whole grain / legumes ¼ plate. Fiber ≥ 30 g / day. Mediterranean pattern.
- AVOID: sugary drinks (zero), white bread / white rice / pastries, fruit juice, sweets.
- MACROS: protein 1.0–1.5 g / kg; carbs prioritized whole; sat fat ≤ 7 %.
- WEIGHT LOSS GOAL: 5–7 % body weight delays progression; ≥ 10 % can produce remission.
EVIDENCE: ADA Standards of Care 2025; Colberg et al. 2016 ADA exercise position.
''';

const String _type1Diabetes = '''
#### TYPE 1 DIABETES (DIABET ZAHARAT TIP 1)
KEYWORDS: diabet tip 1, dz tip 1, dz1, insulinodependent, type 1 diabetes, t1dm
SEVERITY: requires_modification — strict glucose monitoring + insulin adjustment.
EXERCISE:
- DO: same volume as healthy adult (150 min / week + resistance), but ALWAYS check glucose pre / mid / post.
- Pre-exercise glucose target 90–250 mg/dL (5–14 mmol/L). If < 90 mg/dL: 15–30 g carbs first. If > 250 mg/dL with ketones: do NOT exercise.
- Aerobic typically lowers glucose; resistance / HIIT can transiently raise it. Plan accordingly with endocrinologist.
NUTRITION:
- Carb counting + insulin matching is medical territory. Provide consistent meal carb amounts; flag any need to adjust insulin to user's diabetes team.
- Protein 1.2–1.6 g / kg; emphasize fiber and slow-digesting carbs.
EVIDENCE: ISPAD 2022; Riddell et al. 2017 Lancet position statement.
''';

const String _dyslipidemia = '''
#### DYSLIPIDEMIA / HIGH CHOLESTEROL (DISLIPIDEMIE / COLESTEROL MARE)
KEYWORDS: colesterol, colesterol mărit, hipercolesterolemie, ldl mare, trigliceride mari, dislipidemie, dyslipidemia, high cholesterol, high ldl, high triglycerides, hyperlipidemia
SEVERITY: monitorable.
EXERCISE: standard aerobic + resistance (150–300 min / week moderate aerobic) lowers LDL and TG, raises HDL.
NUTRITION:
- DO: soluble fiber 10–25 g / day (oats, barley, beans, apples, citrus). Plant sterols 2 g / day (fortified margarine alternatives). Nuts 30–60 g / day. Fatty fish 2× / week. Olive oil EV as primary fat.
- AVOID: trans fats (zero), saturated fat ≤ 6 % of kcal, fried foods, full-fat processed cheese, fatty / processed meat, refined sugars (TG driver).
- ALCOHOL: zero or ≤ 1 drink / day if TG elevated.
EVIDENCE: ESC / EAS 2019 dyslipidaemia guidelines; AHA 2021 dietary guidelines.
''';

const String _metabolicSyndrome = '''
#### METABOLIC SYNDROME (SINDROM METABOLIC)
KEYWORDS: sindrom metabolic, metabolic syndrome
SEVERITY: monitorable.
EXERCISE: combined aerobic + resistance, ≥ 250 min / week moderate aerobic for clinically meaningful weight + visceral-fat loss; HIIT 1–2× / week if no cardiac contraindications.
NUTRITION: Mediterranean / DASH overlap; whole foods, low added sugar (< 25 g / day), protein 1.2–1.6 g / kg, fiber ≥ 30 g.
EVIDENCE: AHA / NHLBI 2005 criteria; updated 2023.
''';

const String _hypothyroidism = '''
#### HYPOTHYROIDISM / HASHIMOTO (HIPOTIROIDISM / HASHIMOTO)
KEYWORDS: hipotiroidism, hipotiroidian, hashimoto, tiroidită autoimună, levothyroxine, euthyrox, hypothyroidism, hashimoto's, underactive thyroid
SEVERITY: monitorable when treated; requires_modification if untreated and very symptomatic.
EXERCISE: standard programming once euthyroid. Energy may be lower if undertreated → start at lower volume, progress slowly. Heart-rate response can be blunted — use RPE.
NUTRITION:
- DO: adequate iodine (150 µg / day from iodized salt, fish, seaweed in moderation), selenium (Brazil nuts 1–2 / day), zinc, iron. Adequate protein 1.2–1.6 g / kg.
- AVOID: large soy isoflavone doses with levothyroxine (separate by ≥ 4 h); large cruciferous goitrogen loads if iodine-deficient.
- TIMING: take levothyroxine 30–60 min before breakfast on empty stomach (no coffee in this window).
EVIDENCE: ATA 2014 hypothyroidism guidelines; updated 2023.
''';

const String _hyperthyroidism = '''
#### HYPERTHYROIDISM / GRAVES (HIPERTIROIDISM / GRAVES)
KEYWORDS: hipertiroidism, hipertiroidian, graves, basedow, tiroidă hiperactivă, hyperthyroidism, graves' disease, overactive thyroid
SEVERITY: requires_modification; DOCTOR_CONSULT if untreated / thyrotoxic.
EXERCISE: low-to-moderate intensity only until euthyroid. Avoid high-intensity / heat exposure (cardiovascular and arrhythmia risk).
NUTRITION:
- DO: increase calories (basal hypermetabolic state), adequate protein 1.5–1.8 g / kg, calcium + vitamin D (bone-loss risk).
- AVOID: stimulants (caffeine high doses), excessive iodine (kelp, large iodized supplements).
EVIDENCE: ATA 2016 hyperthyroidism guidelines.
''';

const String _pcos = '''
#### POLYCYSTIC OVARY SYNDROME (SINDROMUL OVARELOR POLICHISTICE / PCOS)
KEYWORDS: pcos, sop, sindrom ovare polichistice, ovar polichistic, ovare polichistice, sindrom ovarian polichistic, polycystic ovary, polycystic ovaries
SEVERITY: monitorable.
EXERCISE:
- DO: ≥ 150 min / week moderate aerobic + 2 days resistance training. Strength training improves insulin sensitivity and androgen profile.
- WEIGHT-LOSS PROTOCOL if BMI > 25: ≥ 250 min / week moderate aerobic; combine with caloric deficit.
NUTRITION:
- DO: low-GI / low-glycemic-load eating pattern. High protein 1.4–1.8 g / kg (satiety + lean mass). Fiber ≥ 30 g / day. Anti-inflammatory: omega-3 fatty fish, olive oil, berries, leafy greens, turmeric.
- AVOID: refined carbs and added sugar (insulin spikes worsen androgens). Limit dairy if acne-prone. Limit alcohol.
- MACROS: carbs 35–45 % kcal mostly low-GI; protein 25–30 %; fat 25–35 % mostly mono / poly.
EVIDENCE: International Evidence-Based PCOS Guideline 2023 (Monash); ESHRE 2023.
''';

// ── MUSCULOSKELETAL ─────────────────────────────────────────────────────

const String _lumbarDiscHerniation = '''
#### LUMBAR DISC HERNIATION (HERNIE DE DISC LOMBARĂ)
KEYWORDS: hernie de disc, hernie discală, hernie lombară, discopatie, protruzie discală, lumbar disc herniation, slipped disc, herniated disc, bulging disc lumbar
SEVERITY: requires_modification; DOCTOR_CONSULT for cauda equina signs (saddle anesthesia, bowel/bladder incontinence, progressive weakness, foot drop).
EXERCISE:
- DO: McKenzie extension-bias exercises (prone press-ups, sphinx) when pain centralizes with extension. Walking, hip hinge with NEUTRAL spine, dead bug, bird dog, side plank, glute bridge, anti-rotation core (Pallof press).
- AVOID: loaded spinal flexion (sit-ups, crunches, toe touches), heavy back squat, conventional deadlift, bent-over barbell row, leg press with hips rolling under (lumbar flexion under load), Olympic lifts, kettlebell swings until cleared.
- ALTERNATIVES: leg press with neutral spine + small ROM, Romanian deadlift with light load + hip hinge cue, goblet squat to box, chest-supported row, lat pulldown.
- INTENSITY: load light to moderate; progression by symptom centralization, not by RPE.
NUTRITION: anti-inflammatory pattern (Mediterranean), adequate protein 1.4–1.8 g / kg (tissue repair), vitamin D 800–2000 IU / day, magnesium, omega-3.
EVIDENCE: McKenzie MDT (Mechanical Diagnosis & Therapy); NICE NG59 2020 low back pain.
''';

const String _cervicalDiscHerniation = '''
#### CERVICAL DISC HERNIATION (HERNIE DE DISC CERVICALĂ)
KEYWORDS: hernie cervicală, hernie de disc cervicală, discopatie cervicală, cervicalgie, brahialgie, cervical disc herniation, cervical radiculopathy, neck herniation
SEVERITY: requires_modification; DOCTOR_CONSULT if myelopathy signs (gait disturbance, hand clumsiness, hyperreflexia).
EXERCISE:
- AVOID: barbell back squat with bar on neck (use safety squat bar / front squat / goblet), behind-neck press, behind-neck pulldown, heavy upright row, neck bridges, weighted shrugs > moderate load, headstand / inversion.
- DO: chin tucks, scapular retractions, deep cervical flexor activation, light face pulls, band pull-aparts, isometric neck work in pain-free range.
NUTRITION: same as lumbar disc.
EVIDENCE: NASS 2020 cervical disc guideline.
''';

const String _chronicLowBackPain = '''
#### CHRONIC LOW BACK PAIN (LOMBALGIE CRONICĂ / DURERI DE SPATE)
KEYWORDS: lombalgie, dureri lombare, dureri de spate cronice, durere zona lombară, mă doare spatele, chronic low back pain, clbp, chronic lbp, lower back pain
SEVERITY: monitorable.
EXERCISE: hip-hinge education, glute bridge, dead bug, bird dog, side plank, farmer carry, goblet squat, RDL with light load, walking. Avoid early heavy axial loading; progress by tolerance not RPE alone. McGill big-three core daily.
NUTRITION: anti-inflammatory pattern; weight loss if BMI > 27 reduces axial load.
EVIDENCE: NICE NG59 2020; AHRQ 2020 systematic review.
''';

const String _sciatica = '''
#### SCIATICA (SCIATICĂ)
KEYWORDS: sciatică, sciatica, nevralgie sciatică, durere pe traiectul sciaticului, sciatic pain
SEVERITY: requires_modification; DOCTOR_CONSULT for progressive weakness, foot drop, or cauda equina signs.
EXERCISE: same as lumbar disc — directional preference (extension OR flexion bias by centralization). Add nerve glides (sciatic flossing) if no symptom escalation. Avoid loaded spinal flexion.
NUTRITION: same as lumbar disc.
EVIDENCE: NICE NG59 2020.
''';

const String _kneeOsteoarthritis = '''
#### KNEE OSTEOARTHRITIS (GONARTROZĂ / ARTROZĂ GENUNCHI)
KEYWORDS: gonartroză, artroză genunchi, artroza la genunchi, uzura cartilaj genunchi, knee osteoarthritis, knee oa, knee arthritis
SEVERITY: monitorable.
EXERCISE:
- DO: leg press (partial ROM as tolerated), seated leg extension light load high reps, leg curl, step-ups (low box), wall sit, stationary bike (key modality), swimming, terminal-knee-extension band, glute / hip strengthening.
- AVOID: deep loaded squats / lunges if causing pain, plyometrics on hard surfaces, jumping rope on concrete, prolonged running on pavement (low-impact bike or elliptical preferred), full-depth Bulgarian split squats with heavy load.
- KEY: keep knee tracking over 2nd–3rd toe; pain ≤ 4 / 10 during and not worsening 24 h after.
NUTRITION:
- DO: weight loss (1 kg lost = 4 kg less knee load). Anti-inflammatory: omega-3, EV olive oil, turmeric + black pepper, berries, leafy greens. Adequate vitamin D + calcium.
- COLLAGEN PEPTIDES 10–15 g / day with vitamin C — modest evidence for joint comfort.
EVIDENCE: OARSI 2023 guideline; ACR 2019.
''';

const String _meniscusAcl = '''
#### MENISCUS / ACL INJURY (MENISC / LIGAMENT ÎNCRUCIȘAT)
KEYWORDS: menisc, leziune menisc, ruptură menisc, ligament încrucișat, lca, lcp, acl, pcl, meniscus tear, meniscus injury, acl tear, mcl, lcl
SEVERITY: requires_modification post-rehab; DOCTOR_CONSULT if acute / pre-surgery / unstable knee.
EXERCISE:
- POST-REHAB only: bilateral leg press / squat with controlled depth, leg curl, hip thrust, calf raises, terminal knee extension. Single-leg work added late.
- AVOID until cleared: deep squat under heavy load, plyometrics, cutting / pivoting drills, deep lunges with twist.
NUTRITION: collagen peptides + vitamin C, omega-3, vitamin D, protein 1.6–2.0 g / kg during rehab.
EVIDENCE: KNGF 2018; APTA 2018.
''';

const String _patellofemoralPain = '''
#### PATELLOFEMORAL PAIN SYNDROME (DURERE PATELOFEMURALĂ / RUNNER'S KNEE)
KEYWORDS: durere patelofemurală, condromalacie, sindrom rotulian, durere sub rotulă, runners knee, patellofemoral pain, pfps, chondromalacia
SEVERITY: monitorable.
EXERCISE: hip abductor / external rotator strengthening (clamshells, side-lying leg raise, banded walks, single-leg bridge), short-arc quad work, leg press 0–60° ROM, step-down progressions. Avoid deep loaded squats and lunges, downhill running.
NUTRITION: same as Knee OA.
EVIDENCE: 2018 PFP Consensus statement; APTA 2019.
''';

const String _shoulderImpingement = '''
#### SHOULDER IMPINGEMENT / ROTATOR CUFF (SINDROM IMPINGEMENT / COIF ROTATOR)
KEYWORDS: impingement, sindrom de impingement, coif rotator, leziune coif rotator, supraspinos, durere umăr, tendinită umăr, shoulder impingement, rotator cuff, supraspinatus tendinopathy, shoulder tendinitis
SEVERITY: requires_modification; DOCTOR_CONSULT if full-thickness tear / surgical candidate.
EXERCISE:
- AVOID: behind-neck press, behind-neck pulldown, upright row above 90° elbow, wide-grip bench press at deep ROM, dips (sternal compression), lateral raise > shoulder height, kipping pull-ups.
- DO: face pulls, prone Y-T-W, external rotation with band, scapular retraction, push-up plus, neutral-grip dumbbell press in scapular plane (≤ 90°), landmine press, cable row (chest-supported), lat pulldown to chest (not behind neck).
NUTRITION: anti-inflammatory; collagen + vitamin C; protein for tendon repair.
EVIDENCE: AAOS 2023; APTA shoulder CPG 2019.
''';

const String _frozenShoulder = '''
#### FROZEN SHOULDER (CAPSULITĂ ADEZIVĂ / UMĂR ÎNGHEȚAT)
KEYWORDS: capsulită adezivă, umăr înghețat, frozen shoulder, adhesive capsulitis
SEVERITY: requires_modification.
EXERCISE: pendulum, table slides, wall walks, doorway stretches, banded ER. Avoid heavy overhead loading and end-range stretches that produce sharp pain.
NUTRITION: anti-inflammatory; tighter glycemic control if diabetic (strong association).
EVIDENCE: APTA shoulder CPG 2013 update 2019.
''';

const String _hipOa = '''
#### HIP OSTEOARTHRITIS / FAI (COXARTROZĂ / ARTROZĂ ȘOLD / FAI)
KEYWORDS: coxartroză, artroză șold, artroza de șold, fai, conflict femuro-acetabular, hip osteoarthritis, hip oa, femoroacetabular impingement
SEVERITY: monitorable.
EXERCISE: hip abduction (banded clams, side leg raise), bridge, terminal hip extension, half kneeling Pallof press, partial-depth squat, leg press partial ROM, swimming. Avoid deep loaded squats with hip flexion past pain threshold and high-impact running.
NUTRITION: same as Knee OA.
EVIDENCE: OARSI 2023.
''';

const String _osteoporosis = '''
#### OSTEOPOROSIS (OSTEOPOROZĂ / OSTEOPENIE)
KEYWORDS: osteoporoză, osteopenie, dexa scăzut, t-score scăzut, osteoporosis, osteopenia, low bone density
SEVERITY: requires_modification; DOCTOR_CONSULT for prior vertebral fracture or T-score < -3.0.
EXERCISE:
- DO (per Too-Fit-to-Fracture + LIFTMOR): progressive resistance training 2–3× / week (deadlift, overhead press, squat — performed with strict neutral-spine technique, RPE 7–8 with experienced supervision), impact training (drop jumps, hopping) ONLY when no vertebral fracture history, balance training daily, postural exercises (back extensors).
- AVOID: spinal flexion under load (sit-ups, toe touches with weights, machine crunches), spinal twisting under load (Russian twists with weight, weighted side bends), loaded forward bending (golf swing with heavy follow-through, kettlebell swing if recent vertebral fracture), high-fall-risk activities for users with prior fracture.
- VERY HIGH RISK (multiple fragility fractures, T < -3.5): low-load supervised work only; refer to DEXA-informed physiotherapist.
NUTRITION:
- DO: calcium 1000–1200 mg / day (low-fat dairy, sardines, tofu, kale, fortified plant milks). Vitamin D 800–2000 IU / day (more if deficient; consider serum 25-OH-D test). Protein 1.0–1.2 g / kg minimum (under-eating protein accelerates bone loss). Adequate magnesium, vitamin K2, potassium.
- AVOID: excess sodium (> 2300 mg → calciuria), excess caffeine (> 400 mg / day), heavy alcohol, sugary soda (phosphoric acid).
EVIDENCE: LIFTMOR 2018 (Watson et al.); Too Fit To Fracture 2014 update 2024; IOF 2024.
''';

const String _rheumatoidArthritis = '''
#### RHEUMATOID ARTHRITIS (POLIARTRITĂ REUMATOIDĂ)
KEYWORDS: poliartrită reumatoidă, par, artrită reumatoidă, rheumatoid arthritis, ra
SEVERITY: requires_modification; DOCTOR_CONSULT during active flare.
EXERCISE: low-impact aerobic (swimming, cycling), resistance training light-to-moderate at RPE 6–7, range-of-motion work daily. Avoid training affected joints during acute flare; switch to unaffected joints + breathing / mobility.
NUTRITION: anti-inflammatory Mediterranean; omega-3 ≥ 2 g EPA + DHA / day; turmeric + piperine; limit red / processed meat; moderate alcohol.
EVIDENCE: ACR 2021 RA management; EULAR 2023 lifestyle.
''';

const String _scoliosis = '''
#### SCOLIOSIS (SCOLIOZĂ)
KEYWORDS: scolioză, scoliotic, cifoscolioză, scoliosis, kyphoscoliosis
SEVERITY: monitorable for stable adult; DOCTOR_CONSULT for progressive curve > 40° or pulmonary involvement.
EXERCISE: Schroth-method principles when possible (curve-specific). Resistance training generally safe with strict neutral-spine technique. Avoid heavy asymmetric loading (one-arm farmer carry on the convex side without compensation, single-side overhead heavy work).
NUTRITION: standard; adequate calcium / D / protein.
EVIDENCE: SOSORT 2016 + 2023 update.
''';

const String _tendinopathy = '''
#### TENDINOPATHY (TENDINITĂ / TENDINOPATIE / EPICONDILITĂ / FASCEITĂ PLANTARĂ)
KEYWORDS: tendinită, tendinopatie, epicondilită, cot de tenisman, cot de golfist, fasceită plantară, tendinită ahileană, tendinită rotuliană, tendinopathy, tendinitis, epicondylitis, plantar fasciitis, achilles tendinitis, jumper's knee, patellar tendinopathy
SEVERITY: monitorable.
EXERCISE: heavy slow resistance and / or eccentric loading 3× / week (e.g. Alfredson protocol for Achilles). Pain ≤ 5 / 10 during loading and not worse 24 h later is acceptable. Avoid stretching the irritated tendon aggressively in early phase.
NUTRITION: protein 1.6–2.0 g / kg, collagen peptides 15 g + vitamin C 50 mg taken 30–60 min before loading session, omega-3, adequate vitamin D.
EVIDENCE: Alfredson 1998; Beyer 2015 HSR vs eccentric; Shaw 2017 collagen-vitC tendon study.
''';

const String _carpalTunnel = '''
#### CARPAL TUNNEL SYNDROME (SINDROM DE TUNEL CARPIAN)
KEYWORDS: tunel carpian, sindrom de tunel carpian, parestezii mâini, amorțeli mâini, carpal tunnel, carpal tunnel syndrome, cts
SEVERITY: monitorable.
EXERCISE: avoid sustained wrist hyperflexion / hyperextension (e.g. heavy front squat with cracked-back rack, heavy reverse curls, push-up on flat hand if symptomatic — use push-up handles or fists). Use straps and false grip on heavy pulls. Median nerve glides 3× / day.
NUTRITION: vitamin B6 not in megadoses (toxicity); standard.
EVIDENCE: AAOS 2016 CTS guideline.
''';

const String _inguinalHernia = '''
#### INGUINAL / UMBILICAL HERNIA (HERNIE INGHINALĂ / HERNIE OMBILICALĂ)
KEYWORDS: hernie inghinală, hernie ombilicală, hernie abdominală, hernie de perete abdominal, inguinal hernia, umbilical hernia, abdominal hernia
SEVERITY: requires_modification; DOCTOR_CONSULT if painful, expanding, or non-reducible (incarceration risk).
EXERCISE: avoid Valsalva maneuver entirely, heavy axial-loading lifts (deadlift, back squat, overhead press at 1RM intensity), heavy strict crunches, max-effort coughing-style core work. Use moderate loads with diaphragmatic breathing — exhale on exertion, never hold breath.
NUTRITION: high-fiber + adequate fluids to prevent constipation (straining = pressure spike); manage weight if BMI > 27.
EVIDENCE: HerniaSurge International Guidelines 2018.
''';

const String _hiatalHernia = '''
#### HIATAL HERNIA (HERNIE HIATALĂ)
KEYWORDS: hernie hiatală, hernie hiatus, hiatal hernia, hiatus hernia
SEVERITY: monitorable; often coexists with GERD.
EXERCISE: avoid Valsalva, very heavy abdominal compression (max squats / deadlifts pre-meal), inverted positions (handstand, deep yoga inversions). Wait ≥ 2 h after meals before training.
NUTRITION: see GERD entry.
EVIDENCE: ACG 2022 GERD / hiatal hernia guideline.
''';

const String _recentSurgery = '''
#### RECENT SURGERY (OPERAȚIE RECENTĂ — ULTIMELE 3 LUNI)
KEYWORDS: operație recentă, postoperator, post operatie, intervenție chirurgicală, chirurgie recentă, recovery, recent surgery, post-op, post-operative, recent operation
SEVERITY: DOCTOR_CONSULT — do NOT generate a workout plan without surgeon clearance.
EXERCISE: output requires_doctor_consult = true with Romanian message: "După o intervenție chirurgicală recentă, planul trebuie aprobat de medicul chirurg sau de un kinetoterapeut. Te rugăm să te consulți înainte de a începe."
NUTRITION:
- Increased protein 1.5–2.0 g / kg for tissue healing for 4–8 weeks post-op.
- Vitamin C 200–500 mg, zinc 15–30 mg, vitamin A adequate, fluid 30–35 mL / kg, fiber for bowel regularity.
- Avoid alcohol while on opioid analgesics; limit if on antibiotics.
EVIDENCE: ASPEN / ESPEN perioperative nutrition 2021.
''';

// ── RESPIRATORY ─────────────────────────────────────────────────────────

const String _asthma = '''
#### ASTHMA / EXERCISE-INDUCED BRONCHOCONSTRICTION (ASTM / BRONHOSPASM LA EFORT)
KEYWORDS: astm, astm bronșic, astm la efort, bronhospasm, eib, dispnee la efort, asthma, exercise-induced asthma, exercise-induced bronchoconstriction, eib
SEVERITY: requires_modification; DOCTOR_CONSULT if uncontrolled (frequent rescue inhaler use, prior intubation).
EXERCISE:
- DO: extended warm-up (15–20 min progressive intensity — protective via refractory period). Indoor training in cold weather (or wear scarf / mask). Pre-exercise SABA (albuterol) 15–20 min before per asthma plan if prescribed. Aerobic + resistance both safe.
- AVOID: cold dry-air outdoor training, high-pollen / high-pollution outdoor sessions, prolonged maximal effort without warm-up.
- STOP: wheezing at rest, severe dyspnea, peak flow < 80 % personal best.
NUTRITION:
- DO: Mediterranean / DASH; omega-3, vitamin D, antioxidants (berries, leafy greens). Maintain healthy weight (excess fat worsens asthma).
- AVOID: known food triggers per the user's allergist (e.g. sulfites in wine / dried fruit, MSG in some users). Avoid heavy meals before training.
EVIDENCE: ATS 2013 EIB guideline; GINA 2024 asthma report; NAEPP 2020.
''';

const String _copd = '''
#### COPD (BPOC — BRONHOPNEUMOPATIE OBSTRUCTIVĂ CRONICĂ)
KEYWORDS: bpoc, emfizem, bronșită cronică, copd, emphysema, chronic bronchitis
SEVERITY: requires_modification; DOCTOR_CONSULT for GOLD III–IV, on supplemental O2, or recent exacerbation.
EXERCISE: pulmonary rehab program preferred. Interval-style aerobic (walking 1 min on / 1 min off), resistance for major muscle groups, breathing exercises (pursed-lip, diaphragmatic). Use Borg dyspnea ≤ 4–6 / 10.
NUTRITION: adequate protein 1.2–1.5 g / kg (cachexia risk). Vitamin D, calcium. Smaller, more frequent meals if dyspnea worsens with large meals.
EVIDENCE: GOLD 2024 COPD report; ATS / ERS PR statement 2013.
''';

const String _sleepApnea = '''
#### OBSTRUCTIVE SLEEP APNEA (APNEE ÎN SOMN)
KEYWORDS: apnee în somn, apnee de somn, sas, cpap, sleep apnea, osa, obstructive sleep apnea
SEVERITY: monitorable.
EXERCISE: weight loss is primary lever — combined aerobic + resistance, ≥ 250 min / week moderate aerobic if BMI > 27. Tongue / oropharyngeal exercises (myofunctional therapy) optional adjunct.
NUTRITION: weight-loss caloric deficit 500–750 kcal / day; avoid alcohol within 3 h of bedtime; avoid heavy late-evening meals.
EVIDENCE: AASM 2021 OSA treatment guideline.
''';

// ── DIGESTIVE ───────────────────────────────────────────────────────────

const String _ibs = '''
#### IRRITABLE BOWEL SYNDROME (SINDROM DE COLON IRITABIL / SII)
KEYWORDS: sii, sindrom colon iritabil, colon iritabil, ibs, irritable bowel syndrome
SEVERITY: monitorable.
EXERCISE: regular moderate activity reduces symptoms. Walking, yoga, swimming. Avoid extreme endurance during flare (can worsen GI).
NUTRITION:
- Low FODMAP DIET (Monash 3-phase): phase 1 elimination 2–6 weeks, phase 2 reintroduction, phase 3 personalization. Ideally with a dietitian.
- AVOID (high FODMAP): garlic + onion (use garlic-infused olive oil instead), wheat in large amounts, lactose-rich dairy (milk, soft cheese), apples, pears, mango, honey, agave, high-fructose corn syrup, beans (chickpeas, lentils in large servings), cauliflower, mushrooms, sugar alcohols (sorbitol, mannitol, xylitol).
- DO (low FODMAP): rice, quinoa, oats, sourdough spelt bread, firm tofu, eggs, plain meat / poultry / fish, lactose-free dairy / aged hard cheese, carrot, cucumber, eggplant, green beans, lettuce, potato, zucchini, kiwi, orange, strawberry, blueberry.
- HYDRATION: ≥ 2 L water / day; soluble fiber (psyllium, oats) often beneficial.
EVIDENCE: Monash University Low FODMAP Program 2024; ACG IBS guideline 2021.
''';

const String _ibd = '''
#### INFLAMMATORY BOWEL DISEASE (CROHN / RECTOCOLITĂ ULCEROHEMORAGICĂ)
KEYWORDS: boala crohn, crohn, rectocolită, rectocolita ulcerohemoragică, rcuh, colită ulcerativă, ibd, inflammatory bowel disease, ulcerative colitis, crohn's
SEVERITY: requires_modification; DOCTOR_CONSULT during active flare or post-resection.
EXERCISE: light-to-moderate during remission; reduce volume during flare; avoid jarring high-impact during flare.
NUTRITION:
- DO during REMISSION: Mediterranean pattern, omega-3, soluble fiber as tolerated, adequate protein 1.2–1.5 g / kg.
- DO during FLARE: low-residue / low-fiber TEMPORARILY (white rice, lean cooked meat, peeled cooked vegetables, eggs, lactose-free if intolerant), small frequent meals.
- AVOID: known triggers for the individual (often: raw cruciferous, popcorn, seeds with skin, very spicy foods, alcohol, large dairy in lactose-intolerant subset).
- SUPPLEMENTS commonly low: iron (anemia), vitamin B12 (Crohn ileal), vitamin D, calcium, zinc.
EVIDENCE: ECCO IBD guidelines 2023; ESPEN clinical nutrition in IBD 2023.
''';

const String _gerd = '''
#### GERD / ESOPHAGITIS (REFLUX GASTROESOFAGIAN / ESOFAGITĂ)
KEYWORDS: reflux, reflux gastroesofagian, brge, esofagită, pirozis, arsuri stomac, gerd, acid reflux, esophagitis, heartburn
SEVERITY: monitorable.
EXERCISE: wait ≥ 2 h after meals. Avoid heavy abdominal compression near full stomach (sit-ups, deep crunches, Valsalva), prone positions immediately after eating, deep yoga inversions.
NUTRITION:
- AVOID: large late-evening meals (last meal ≥ 3 h before bed), high-fat fried foods, chocolate, peppermint (relaxes LES), tomato sauce, citrus, coffee in large amounts, carbonated drinks, alcohol, very spicy foods.
- DO: smaller more frequent meals, sleep with head elevated 15–20 cm, weight loss if BMI > 27.
EVIDENCE: ACG 2022 GERD guideline.
''';

const String _celiac = '''
#### CELIAC DISEASE (BOALA CELIACĂ / CELIACHIE)
KEYWORDS: celiachie, boala celiacă, intoleranță la gluten autoimună, celiac disease, celiac
SEVERITY: requires_modification — strictly gluten-free diet for life.
EXERCISE: standard programming; ensure no untreated nutrient deficiencies (iron, B12, D) before high training volume.
NUTRITION:
- AVOID: wheat (grâu), rye (secară), barley (orz), spelt, kamut, triticale, regular pasta, regular bread, regular beer, soy sauce (use tamari), bulgur, couscous, semolina, malt, breaded / floured products, hidden gluten (sauces, processed meats — read labels).
- DO: certified gluten-free oats, rice, quinoa, buckwheat, millet, amaranth, corn, sorghum, teff, gluten-free bread / pasta.
- WATCH cross-contamination in shared kitchens.
- COMMON deficiencies: iron, calcium, B12, folate, vitamin D, magnesium, zinc — supplement as needed.
EVIDENCE: ACG 2023 celiac guideline; ESPGHAN 2020.
''';

const String _lactoseIntolerance = '''
#### LACTOSE INTOLERANCE (INTOLERANȚĂ LA LACTOZĂ)
KEYWORDS: intoleranță la lactoză, intoleranta la lapte, intolerant lactoză, lactose intolerance, lactose intolerant
SEVERITY: monitorable.
EXERCISE: standard.
NUTRITION:
- AVOID full-lactose: regular cow milk, soft cheeses, ice cream, custard, condensed milk in large amounts.
- TOLERATED by most: aged hard cheese (parmesan, cheddar — < 0.5 g lactose / 30 g), butter, lactose-free milk, kefir / yogurt with live cultures (often tolerated up to ~12 g / serving), plant milks (almond, oat, soy).
- ENSURE calcium 1000–1200 mg / day from non-dairy or lactose-free sources (sardines with bones, tofu set with calcium, kale, fortified plant milks, almonds).
EVIDENCE: NIH consensus 2010; updated reviews 2023.
''';

const String _nafld = '''
#### FATTY LIVER (NAFLD / MASLD — STEATOZĂ HEPATICĂ / FICAT GRAS)
KEYWORDS: ficat gras, steatoză hepatică, steatoza hepatica, nafld, masld, fatty liver, hepatic steatosis
SEVERITY: monitorable; DOCTOR_CONSULT if NASH / fibrosis confirmed.
EXERCISE: ≥ 250 min / week moderate aerobic + resistance 2× / week. 7–10 % body weight loss reverses much of the steatosis.
NUTRITION: Mediterranean diet first-line. Eliminate sugar-sweetened beverages and fructose excess. Limit alcohol to zero (or ≤ minimal). Coffee 2–3 cups / day shows hepatoprotective signal. Omega-3 supportive.
EVIDENCE: AASLD 2023 MASLD practice guidance; EASL-EASD-EASO 2024.
''';

const String _gallstones = '''
#### GALLSTONES / CHOLECYSTITIS HISTORY (CALCULI BILIARI / COLECISTITĂ)
KEYWORDS: calculi biliari, pietre la fiere, colecistită, colecist scos, colecistectomie, gallstones, cholecystitis, cholecystectomy
SEVERITY: monitorable post-cholecystectomy; DOCTOR_CONSULT during acute attack.
EXERCISE: standard post-recovery.
NUTRITION: avoid very high-fat single meals (especially if cholecyst still present); favor smaller frequent meals; soluble fiber; healthy fats spread across the day; adequate hydration.
EVIDENCE: World Gastroenterology Organization 2017.
''';

// ── RENAL / METABOLIC EXCRETORY ─────────────────────────────────────────

const String _ckd = '''
#### CHRONIC KIDNEY DISEASE (BOALĂ RENALĂ CRONICĂ / IRC)
KEYWORDS: boală renală cronică, brc, irc, insuficiență renală, insuficienta renala, renal cronic, dializă, chronic kidney disease, ckd, kidney failure, dialysis
SEVERITY: DOCTOR_CONSULT — nephrologist + renal dietitian co-management required.
EXERCISE:
- DO: moderate aerobic 30 min most days, light-to-moderate resistance 2× / week (improves muscle mass + insulin sensitivity, reduces mortality).
- AVOID: heavy-load max-effort lifting on dialysis days, dehydration, NSAIDs pre-workout.
NUTRITION (CKD G3–G5 not on dialysis):
- PROTEIN: 0.8 g / kg / day (avoid > 1.3 g / kg in CKD at risk of progression). Very-low-protein 0.3–0.4 g / kg + ketoacid analogs only with renal dietitian supervision and only in metabolically stable patients.
- SODIUM: < 2000 mg / day (BP + proteinuria control).
- POTASSIUM: not routinely restricted unless persistent hyperkalemia — KDIGO 2024 update; first correct medications / acidosis. If high K+ documented, limit banana, orange juice, potato (or boil potatoes to leach K), tomato sauce, dried fruit, beans in large amounts.
- PHOSPHORUS: individualized; limit phosphate additives (deli meats, dark colas, processed cheese, baked goods with phosphate dough conditioners) before limiting natural phosphorus from whole foods.
- DIALYSIS users: protein increases to 1.0–1.2 g / kg (HD) or 1.2–1.3 g / kg (PD); phosphate binders coordinate with meals.
- AVOID: NSAID self-medication; herbal "kidney cleanse" supplements; very-high-protein "anabolic" diets.
EVIDENCE: KDIGO 2024 CKD guideline; KDOQI nutrition 2020.
''';

const String _kidneyStones = '''
#### KIDNEY STONES (CALCULI RENALI / PIETRE LA RINICHI)
KEYWORDS: calculi renali, pietre la rinichi, litiază renală, nefrolitiază, oxalat, kidney stones, nephrolithiasis, calcium oxalate stones
SEVERITY: monitorable.
EXERCISE: standard; emphasize hydration before / during.
NUTRITION:
- DO (calcium oxalate type — most common): 2.5–3 L water / day (urine output > 2 L). Adequate dietary calcium (binds oxalate in gut) — 1000–1200 mg / day with meals. Citrate (lemon water, oranges). Reduce sodium < 2300 mg / day. Moderate animal protein (1.0–1.2 g / kg).
- LIMIT high-oxalate foods if oxalate stones documented: spinach in large amounts, rhubarb, beets, almonds in excess, raw soy products, dark chocolate excess. Pair oxalate foods with calcium source to bind in gut.
- LIMIT sugar-sweetened beverages, excess fructose; reduce purine-rich foods if uric acid stones.
EVIDENCE: AUA 2014 + 2024 update; EAU 2024 urolithiasis.
''';

const String _gout = '''
#### GOUT / HYPERURICEMIA (GUTĂ / ACID URIC MARE)
KEYWORDS: gută, guta, acid uric mare, hiperuricemie, podagră, gout, hyperuricemia, high uric acid
SEVERITY: monitorable.
EXERCISE: standard during inter-critical period; avoid intense training during acute flare (rest + RICE + medication).
NUTRITION:
- AVOID: organ meats (liver, kidney, sweetbread), shellfish + sardines / anchovies / mackerel in excess, beer + spirits (any alcohol → flares), high-fructose-corn-syrup beverages and added-sugar sodas, large red-meat servings.
- LIMIT: red meat to ≤ 100 g / day, lamb, pork, large servings of game.
- DO: low-fat dairy (lowers urate), cherries / tart cherry juice (modest evidence), coffee 2–3 cups / day, vitamin C 500 mg / day, plenty of water (≥ 2 L), whole grains, vegetables (including high-purine veg like spinach / asparagus — plant purines do NOT raise gout risk like animal purines do), plant proteins (lentils, beans, tofu).
- TARGET: serum urate < 6 mg / dL.
EVIDENCE: ACR 2020 gout guideline; 2024 review on diet impact.
''';

// ── REPRODUCTIVE / SPECIAL STATES ───────────────────────────────────────

const String _pregnancy = '''
#### PREGNANCY (SARCINĂ)
KEYWORDS: sarcină, însărcinată, gravidă, trimestru, pregnant, pregnancy, gestation
SEVERITY: requires_modification; DOCTOR_CONSULT for any absolute contraindication below.
EXERCISE — IF NO CONTRAINDICATIONS:
- DO: 150 min / week moderate aerobic (walking, swimming, stationary bike, prenatal yoga / Pilates), pelvic-floor and core work, light-to-moderate resistance training. RPE 12–14 / 20. "Talk test" — should be able to converse.
- TRIMESTER 2 + 3: avoid supine positions > a few minutes (vena cava compression), avoid extreme balance challenges.
- AVOID at any point: contact sports (basketball, football), activities with fall risk (skiing, horse riding), scuba diving, hot yoga, training in heat / dehydration, heavy 1RM lifts, prolonged Valsalva, supine after first trimester.
ABSOLUTE CONTRAINDICATIONS to aerobic exercise (per ACOG 804) — set requires_doctor_consult = true:
- hemodynamically significant heart disease, restrictive lung disease
- incompetent cervix or cerclage
- multiple gestation at risk of premature labor
- persistent second / third trimester bleeding
- placenta previa after 26 weeks
- premature labor in current pregnancy
- ruptured membranes
- preeclampsia / pregnancy-induced hypertension
- severe anemia
NUTRITION:
- ENERGY: +0 kcal trimester 1; +340 kcal trimester 2; +452 kcal trimester 3.
- PROTEIN: ≥ 1.1 g / kg / day (≈ 71 g / day minimum).
- IRON: 27 mg / day; FOLATE: 600 µg / day (400 µg supplement minimum); CHOLINE 450 mg; IODINE 220 µg; CALCIUM 1000 mg; vitamin D 600 IU.
- DHA: ≥ 200 mg / day for fetal brain development (low-mercury fish 2–3 servings / week).
- AVOID: raw or undercooked meat / fish / eggs (toxoplasma, listeria, salmonella), unpasteurized dairy, deli meats unless steaming-hot, high-mercury fish (shark, swordfish, king mackerel, tilefish), raw sprouts, alcohol (zero), > 200 mg caffeine / day, herbal supplements without OB approval.
EVIDENCE: ACOG Committee Opinion 804 (2020); IOM 2009 weight gain; AAP / ACOG 2017.
''';

const String _postpartum = '''
#### POSTPARTUM (POSTPARTUM / LĂUZIE)
KEYWORDS: postpartum, lăuzie, lauzie, după naștere, dupa nastere, recent mom, postpartum, post-natal
SEVERITY: requires_modification.
EXERCISE: gradual return after OB clearance (typically 6 weeks vaginal, 8–12 weeks C-section). Start with walking + diaphragmatic breathing + pelvic-floor / transverse abdominis re-engagement. Screen for diastasis recti + pelvic floor dysfunction before crunches / planks. Avoid heavy axial loading until core / pelvic floor restored.
NUTRITION: lactating mothers add ~330–400 kcal / day; protein 1.3 g / kg; continue iron / folate / DHA / vitamin D; ≥ 3 L fluid if lactating.
EVIDENCE: ACOG Committee Opinion 804; IOM 2009.
''';

const String _menopause = '''
#### MENOPAUSE / PERIMENOPAUSE (MENOPAUZĂ / PERIMENOPAUZĂ)
KEYWORDS: menopauză, menopauza, perimenopauză, postmenopauză, climax, menopause, perimenopause, postmenopause
SEVERITY: monitorable.
EXERCISE: progressive resistance training 2–3× / week is THE priority — preserves muscle and bone. Add aerobic for CV health; balance training for fall prevention.
NUTRITION: protein ≥ 1.2 g / kg (sarcopenia prevention); calcium 1200 mg / day; vitamin D 800–2000 IU; phytoestrogens (soy, flax) optional adjunct; limit alcohol (vasomotor + bone effects); maintain healthy weight.
EVIDENCE: NAMS 2022 menopause hormone position; IOM bone nutrition 2011.
''';

// ── NEUROLOGICAL / MENTAL HEALTH ────────────────────────────────────────

const String _migraine = '''
#### MIGRAINE (MIGRENĂ)
KEYWORDS: migrenă, migrene, cefalee migrenoasă, durere de cap cronică, migraine, chronic headache
SEVERITY: monitorable.
EXERCISE: regular moderate aerobic (3–5× / week) is preventive. Avoid sudden maximal effort, which can trigger exertional headache. Stay hydrated.
NUTRITION:
- AVOID common triggers (individualized): aged cheeses (tyramine), processed / cured meats (nitrates), MSG, artificial sweeteners (especially aspartame), red wine, chocolate in some users, prolonged fasting (skipped meals).
- DO: regular meal timing, magnesium 400–500 mg / day shows moderate evidence, riboflavin 400 mg / day, CoQ10 100 mg 3× / day; adequate hydration (≥ 2 L water).
EVIDENCE: AHS 2021 migraine prevention; AAN 2012 nutraceuticals (still current).
''';

const String _epilepsy = '''
#### EPILEPSY (EPILEPSIE)
KEYWORDS: epilepsie, convulsii, crize epileptice, epilepsy, seizures
SEVERITY: requires_modification; DOCTOR_CONSULT for poorly-controlled seizures or recent seizure event.
EXERCISE: most exercise is safe and beneficial. AVOID solo high-risk activities (climbing, scuba, swimming alone, heavy lifting alone); prefer supervised settings. Adequate sleep + hydration are critical (deprivation lowers seizure threshold).
NUTRITION: ketogenic / modified Atkins diet only under neurologist + RD supervision (refractory epilepsy adjunct). Otherwise normal balanced diet; limit alcohol; consistent meal timing; some AEDs require vitamin D / K supplementation.
EVIDENCE: ILAE 2017; AAN 2018 KD position.
''';

const String _depressionAnxiety = '''
#### DEPRESSION / ANXIETY (DEPRESIE / ANXIETATE)
KEYWORDS: depresie, anxietate, tulburare anxioasă, atacuri de panică, depression, anxiety, panic attacks, generalized anxiety
SEVERITY: monitorable; DOCTOR_CONSULT if user mentions suicidal ideation or severe symptoms.
EXERCISE: aerobic 150–300 min / week + resistance 2× / week — exercise has antidepressant + anxiolytic effect (effect size comparable to SSRI in meta-analyses). Outdoor / nature exposure adds benefit. Start small if low energy; consistency > intensity.
NUTRITION: Mediterranean pattern (SMILES trial); omega-3 EPA ≥ 1 g / day; vitamin D if deficient; B vitamins (folate, B12); minimize alcohol; avoid excess caffeine (anxiety amplifier).
EVIDENCE: Singh et al. BJSM 2023 exercise meta-analysis; SMILES trial 2017.
''';

// ── ONCOLOGY / EATING DISORDERS / OTHER GATES ───────────────────────────

const String _cancer = '''
#### CANCER / ONCOLOGY (CANCER / ONCOLOGIC / CHIMIOTERAPIE)
KEYWORDS: cancer, oncologic, oncologie, neoplasm, tumoră malignă, chimioterapie, radioterapie, leucemie, limfom, cancer, oncology, chemotherapy, radiation therapy, leukemia, lymphoma, tumor
SEVERITY: DOCTOR_CONSULT — output requires_doctor_consult = true.
EXERCISE: do NOT generate a generic plan. Cancer + treatment status + cancer-rehab clearance is required. Output Romanian message: "Pentru pacienți oncologici sau în tratament, planul de antrenament și nutriție trebuie aprobat de medicul oncolog și de un specialist în reabilitare oncologică. Te rugăm să te consulți înainte de a începe."
NUTRITION: do NOT generate a generic plan. Same doctor-consult message.
EVIDENCE: ACSM 2019 Roundtable on Exercise Guidelines for Cancer Survivors; ESPEN 2021.
''';

const String _eatingDisorder = '''
#### EATING DISORDER (TULBURARE DE COMPORTAMENT ALIMENTAR)
KEYWORDS: anorexie, bulimie, tulburare alimentară, tulburare de comportament alimentar, binge eating, mâncat compulsiv, anorexia, bulimia, eating disorder, ed, binge eating disorder, orthorexia
SEVERITY: DOCTOR_CONSULT — output requires_doctor_consult = true.
EXERCISE / NUTRITION: do NOT generate any caloric-deficit plan or volume / intensity prescription. Output Romanian message: "Pentru tulburări de comportament alimentar, planurile de antrenament și nutriție trebuie coordonate de un medic psihiatru, un dietetician specializat și un psihoterapeut. Te rugăm să te consulți cu o echipă specializată."
EVIDENCE: APA 2023 ED practice guideline.
''';

// ── ALLERGIES (handled differently — keyword-driven exclusion list) ─────

const String _allergiesGeneral = '''
#### FOOD ALLERGIES (ALERGII ALIMENTARE)
KEYWORDS: alergie, alergic la, alergii alimentare, food allergy, allergic to
EXTRACT each named allergen (e.g. arahide / peanuts, ouă / eggs, soia / soy, lactate / dairy, gluten, pește / fish, crustacee / shellfish, fructe cu coajă lemnoasă / tree nuts, susan / sesame). For every detected allergen:
- exclude any ingredient containing it from the nutrition plan,
- list the excluded categories in safety_notes (Romanian).
- substitute: nut-allergy → seeds (sunflower, pumpkin); egg-allergy → flax egg in baking + protein from meat / fish / legumes; dairy-allergy → fortified plant milks + almonds / sardines for calcium; shellfish-allergy → other lean fish + lean meat.
EVIDENCE: NIAID 2010 + 2017 update on food allergy management.
''';

// ── PUBLIC API ──────────────────────────────────────────────────────────

const List<String> _allConditions = [
  // Cardiovascular
  _hypertension, _coronaryArteryDisease, _heartFailure, _stroke, _arrhythmia,
  // Metabolic / endocrine
  _type2Diabetes, _type1Diabetes, _dyslipidemia, _metabolicSyndrome,
  _hypothyroidism, _hyperthyroidism, _pcos,
  // Musculoskeletal
  _lumbarDiscHerniation, _cervicalDiscHerniation, _chronicLowBackPain,
  _sciatica, _kneeOsteoarthritis, _meniscusAcl, _patellofemoralPain,
  _shoulderImpingement, _frozenShoulder, _hipOa, _osteoporosis,
  _rheumatoidArthritis, _scoliosis, _tendinopathy, _carpalTunnel,
  _inguinalHernia, _hiatalHernia, _recentSurgery,
  // Respiratory
  _asthma, _copd, _sleepApnea,
  // Digestive
  _ibs, _ibd, _gerd, _celiac, _lactoseIntolerance, _nafld, _gallstones,
  // Renal / excretory
  _ckd, _kidneyStones, _gout,
  // Reproductive / special states
  _pregnancy, _postpartum, _menopause,
  // Neuro / mental health
  _migraine, _epilepsy, _depressionAnxiety,
  // Doctor-consult gates
  _cancer, _eatingDisorder,
  // Allergies
  _allergiesGeneral,
];

const String _kbHeader = '''
### MEDICAL CONDITIONS KNOWLEDGE BASE — APPLY TO EVERY PLAN

The user's free-text `medical_conditions` field is the SINGLE most important
input for safety. Treat the field as authoritative even when it is short or
informal. Apply this 5-step algorithm BEFORE writing any exercise or meal:

1. LOWERCASE the user's medical_conditions text.
2. SCAN it against every KEYWORDS line below. Match Romanian + English
   keywords, partial matches, common typos, and obvious paraphrases (e.g.
   "ma doare spatele" → chronic low back pain; "tensiune mare" → hypertension).
3. For EVERY condition you detect, apply BOTH the EXERCISE and the NUTRITION
   rule blocks. When two conditions conflict, the more restrictive rule wins.
4. If ANY detected condition has SEVERITY: DOCTOR_CONSULT and the user has not
   indicated medical clearance, set `requires_doctor_consult: true` in the
   output AND populate `safety_notes` with a clear Romanian message that names
   the condition and explains why a specialist must approve the plan first.
   In this case still emit the schema's required fields with empty / minimal
   defaults so the output remains valid JSON.
5. List EVERY detected condition in `safety_notes` (Romanian, one short
   sentence per condition) explaining what protective rule was applied.
   Example: "Hipertensiune detectată — am eliminat exerciții cu apnee
   (Valsalva) și am limitat sodiul la 2 g / zi."

If the field is empty, "niciuna", "nimic", "none", or similar → treat as no
condition detected, skip the safety_notes condition list (use a one-line
"Nicio afecțiune declarată — plan general aplicat"), and proceed with the
standard plan.

CONDITIONS:
''';

/// Returns the full Markdown medical-conditions knowledge block that gets
/// injected into both the workout and the nutrition prompt. The string is
/// computed once at first call and cached for the process lifetime.
String buildMedicalKnowledgeSection() {
  return _kbHeader + _allConditions.join('\n');
}

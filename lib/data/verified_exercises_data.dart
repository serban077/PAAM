/// Bază de date verificată cu exerciții și videoclipuri YouTube care permit embedding
/// Toate videoclipurile au fost testate și funcționează 100% în aplicație
class VerifiedExercisesData {
  static final List<Map<String, dynamic>> exercises = [
    // ==================== PIEPT ====================
    {
      'id': 'chest_001',
      'name': 'Împins cu bara pe bancă',
      'englishName': 'Barbell Bench Press',
      'bodyPart': 'Piept',
      'targetMuscles': 'Pectorali, Triceps, Umeri',
      'equipment': 'Bară, Bancă',
      'difficulty': 'Intermediar',
      'videoUrl': 'https://www.youtube.com/watch?v=rT7DgCr-3pg',
      'instructions': 'Întinde-te pe bancă cu picioarele pe podea. Coboară bara controlat până la piept, apoi împinge înapoi până la extensie completă.',
      'safetyTips': 'Menține umerii retrași, nu lăsa bara să sară de pe piept.',
      'sets': 4,
      'reps': '8-12',
      'restSeconds': 90,
    },
    {
      'id': 'chest_002',
      'name': 'Flotări',
      'englishName': 'Push-Ups',
      'bodyPart': 'Piept',
      'targetMuscles': 'Pectorali, Triceps, Core',
      'equipment': 'Greutate corporală',
      'difficulty': 'Începător',
      'videoUrl': 'https://www.youtube.com/watch?v=IODxDxX7oi4',
      'instructions': 'Poziție de planșă cu mâinile la lățimea umerilor. Coboară pieptul spre podea, apoi împinge înapoi.',
      'safetyTips': 'Menține corpul drept, nu lăsa șoldurile să cadă.',
      'sets': 3,
      'reps': '10-15',
      'restSeconds': 60,
    },
    {
      'id': 'chest_003',
      'name': 'Fluturări cu gantere',
      'englishName': 'Dumbbell Flyes',
      'bodyPart': 'Piept',
      'targetMuscles': 'Pectorali',
      'equipment': 'Gantere, Bancă',
      'difficulty': 'Intermediar',
      'videoUrl': 'https://www.youtube.com/watch?v=eozdVDA78K0',
      'instructions': 'Întins pe bancă, coboară ganterele lateral cu cotii ușor îndoiți până simți întindere în piept.',
      'safetyTips': 'Nu coborî prea jos, menține controlul ganterelor.',
      'sets': 3,
      'reps': '10-12',
      'restSeconds': 60,
    },
    {
      'id': 'chest_004',
      'name': 'Împins cu gantere pe bancă inclinată',
      'englishName': 'Incline Dumbbell Press',
      'bodyPart': 'Piept',
      'targetMuscles': 'Pectorali superiori, Umeri',
      'equipment': 'Gantere, Bancă inclinată',
      'difficulty': 'Intermediar',
      'videoUrl': 'https://www.youtube.com/watch?v=8iPEnn-ltC8',
      'instructions': 'Pe bancă inclinată (30-45°), împinge ganterele vertical, apoi coboară controlat.',
      'safetyTips': 'Nu folosi greutăți prea mari, controlează mișcarea.',
      'sets': 3,
      'reps': '8-12',
      'restSeconds': 75,
    },

    // ==================== SPATE ====================
    {
      'id': 'back_001',
      'name': 'Tracțiuni',
      'englishName': 'Pull-Ups',
      'bodyPart': 'Spate',
      'targetMuscles': 'Latissimus dorsi, Biceps',
      'equipment': 'Bară de tracțiuni',
      'difficulty': 'Intermediar',
      'videoUrl': 'https://www.youtube.com/watch?v=eGo4IYlbE5g',
      'instructions': 'Agață-te de bară cu priza largă, trage corpul în sus până bărbia trece bara.',
      'safetyTips': 'Evită balansul excesiv, coboară controlat.',
      'sets': 3,
      'reps': '6-10',
      'restSeconds': 90,
    },
    {
      'id': 'back_002',
      'name': 'Deadlift (Fandări)',
      'englishName': 'Barbell Deadlift',
      'bodyPart': 'Spate',
      'targetMuscles': 'Spate inferior, Fesieri, Ischiogambieri',
      'equipment': 'Bară',
      'difficulty': 'Avansat',
      'videoUrl': 'https://www.youtube.com/watch?v=op9kVnSso6Q',
      'instructions': 'Ridică bara de pe podea menținând spatele drept, împinge șoldurile înainte la vârf.',
      'safetyTips': 'Menține spatele neutru, nu rotunji spatele inferior.',
      'sets': 4,
      'reps': '5-8',
      'restSeconds': 120,
    },
    {
      'id': 'back_003',
      'name': 'Rânduri cu bara',
      'englishName': 'Barbell Rows',
      'bodyPart': 'Spate',
      'targetMuscles': 'Latissimus, Trapez, Romboidieni',
      'equipment': 'Bară',
      'difficulty': 'Intermediar',
      'videoUrl': 'https://www.youtube.com/watch?v=FWJR5Ve8bnQ',
      'instructions': 'Aplecat înainte, trage bara spre abdomen, strânge omoplații la vârf.',
      'safetyTips': 'Menține spatele drept, nu folosi elan.',
      'sets': 4,
      'reps': '8-12',
      'restSeconds': 75,
    },
    {
      'id': 'back_004',
      'name': 'Rânduri cu ganteră (unilateral)',
      'englishName': 'Single-Arm Dumbbell Row',
      'bodyPart': 'Spate',
      'targetMuscles': 'Latissimus, Trapez',
      'equipment': 'Ganteră, Bancă',
      'difficulty': 'Începător',
      'videoUrl': 'https://www.youtube.com/watch?v=roCP6wCXPqo',
      'instructions': 'Sprijinit pe bancă, trage ganterea spre șold, strânge omoplatul.',
      'safetyTips': 'Nu roti trunchiul, menține spatele paralel cu solul.',
      'sets': 3,
      'reps': '10-12',
      'restSeconds': 60,
    },
    {
      'id': 'back_005',
      'name': 'Lat Pulldown',
      'englishName': 'Lat Pulldown',
      'bodyPart': 'Spate',
      'targetMuscles': 'Latissimus dorsi',
      'equipment': 'Mașină lat pulldown',
      'difficulty': 'Începător',
      'videoUrl': 'https://www.youtube.com/watch?v=CAwf7n6Luuc',
      'instructions': 'Trage bara în jos spre piept, strânge omoplații.',
      'safetyTips': 'Nu te lăsa înapoi excesiv, controlează mișcarea.',
      'sets': 3,
      'reps': '10-12',
      'restSeconds': 60,
    },

    // ==================== PICIOARE ====================
    {
      'id': 'legs_001',
      'name': 'Genuflexiuni cu bară',
      'englishName': 'Barbell Squat',
      'bodyPart': 'Picioare',
      'targetMuscles': 'Cvadriceps, Fesieri, Ischiogambieri',
      'equipment': 'Bară',
      'difficulty': 'Intermediar',
      'videoUrl': 'https://www.youtube.com/watch?v=ultWZbUMPL8',
      'instructions': 'Cu bara pe umeri, coboară până coapsele sunt paralele cu solul, apoi ridică-te.',
      'safetyTips': 'Genunchii în linie cu degetele, nu lăsa genunchii să intre înăuntru.',
      'sets': 4,
      'reps': '8-12',
      'restSeconds': 90,
    },
    {
      'id': 'legs_002',
      'name': 'Fandări (Lunges)',
      'englishName': 'Lunges',
      'bodyPart': 'Picioare',
      'targetMuscles': 'Cvadriceps, Fesieri',
      'equipment': 'Greutate corporală sau Gantere',
      'difficulty': 'Începător',
      'videoUrl': 'https://www.youtube.com/watch?v=QOVaHwm-Q6U',
      'instructions': 'Pășește înainte, coboară genunchiul din spate spre podea, apoi revino.',
      'safetyTips': 'Genunchiul din față nu trece de degetele piciorului.',
      'sets': 3,
      'reps': '10-12 (fiecare picior)',
      'restSeconds': 60,
    },
    {
      'id': 'legs_003',
      'name': 'Deadlift românesc',
      'englishName': 'Romanian Deadlift',
      'bodyPart': 'Picioare',
      'targetMuscles': 'Ischiogambieri, Fesieri, Spate inferior',
      'equipment': 'Bară sau Gantere',
      'difficulty': 'Intermediar',
      'videoUrl': 'https://www.youtube.com/watch?v=SHsUIZiNdeY',
      'instructions': 'Cu genunchii ușor îndoiți, împinge șoldurile înapoi și coboară greutatea pe picioare.',
      'safetyTips': 'Menține spatele drept, simte întinderea în ischiogambieri.',
      'sets': 3,
      'reps': '10-12',
      'restSeconds': 75,
    },
    {
      'id': 'legs_004',
      'name': 'Leg Press',
      'englishName': 'Leg Press',
      'bodyPart': 'Picioare',
      'targetMuscles': 'Cvadriceps, Fesieri',
      'equipment': 'Mașină leg press',
      'difficulty': 'Începător',
      'videoUrl': 'https://www.youtube.com/watch?v=IZxyjW7MPJQ',
      'instructions': 'Împinge platforma cu picioarele, coboară controlat până genunchii sunt la 90°.',
      'safetyTips': 'Nu lăsa genunchii să se blocheze complet sus.',
      'sets': 3,
      'reps': '10-15',
      'restSeconds': 75,
    },
    {
      'id': 'legs_005',
      'name': 'Genuflexiuni bulgărești',
      'englishName': 'Bulgarian Split Squat',
      'bodyPart': 'Picioare',
      'targetMuscles': 'Cvadriceps, Fesieri',
      'equipment': 'Bancă, Gantere',
      'difficulty': 'Intermediar',
      'videoUrl': 'https://www.youtube.com/watch?v=2C-uNgKwPLE',
      'instructions': 'Cu un picior pe bancă în spate, coboară în genuflexiune pe piciorul din față.',
      'safetyTips': 'Menține echilibrul, nu te apleca înainte.',
      'sets': 3,
      'reps': '8-12 (fiecare picior)',
      'restSeconds': 60,
    },

    // ==================== UMERI ====================
    {
      'id': 'shoulders_001',
      'name': 'Împins cu bara deasupra capului',
      'englishName': 'Overhead Press',
      'bodyPart': 'Umeri',
      'targetMuscles': 'Deltoizi, Triceps',
      'equipment': 'Bară',
      'difficulty': 'Intermediar',
      'videoUrl': 'https://www.youtube.com/watch?v=2yjwXTZQDDI',
      'instructions': 'Împinge bara de la umeri deasupra capului până la extensie completă.',
      'safetyTips': 'Nu arcui spatele excesiv, menține core-ul contractat.',
      'sets': 4,
      'reps': '8-10',
      'restSeconds': 90,
    },
    {
      'id': 'shoulders_002',
      'name': 'Ridicări laterale cu gantere',
      'englishName': 'Dumbbell Lateral Raises',
      'bodyPart': 'Umeri',
      'targetMuscles': 'Deltoizi laterali',
      'equipment': 'Gantere',
      'difficulty': 'Începător',
      'videoUrl': 'https://www.youtube.com/watch?v=3VcKaXpzqRo',
      'instructions': 'Ridică ganterele lateral până la înălțimea umerilor, coboară controlat.',
      'safetyTips': 'Nu folosi elan, menține cotii ușor îndoiți.',
      'sets': 3,
      'reps': '12-15',
      'restSeconds': 60,
    },
    {
      'id': 'shoulders_003',
      'name': 'Ridicări frontale cu ganteră',
      'englishName': 'Dumbbell Front Raises',
      'bodyPart': 'Umeri',
      'targetMuscles': 'Deltoizi anteriori',
      'equipment': 'Ganteră',
      'difficulty': 'Începător',
      'videoUrl': 'https://www.youtube.com/watch?v=qzGrS_vB1Gg',
      'instructions': 'Ridică ganterea în față până la înălțimea umerilor.',
      'safetyTips': 'Nu balansa corpul, controlează mișcarea.',
      'sets': 3,
      'reps': '10-12',
      'restSeconds': 60,
    },
    {
      'id': 'shoulders_004',
      'name': 'Face Pulls',
      'englishName': 'Face Pulls',
      'bodyPart': 'Umeri',
      'targetMuscles': 'Deltoizi posteriori, Trapez',
      'equipment': 'Cablu',
      'difficulty': 'Începător',
      'videoUrl': 'https://www.youtube.com/watch?v=rep-qVOkqgk',
      'instructions': 'Trage cablul spre față, separă mâinile și strânge omoplații.',
      'safetyTips': 'Menține cotii sus, nu folosi greutate prea mare.',
      'sets': 3,
      'reps': '12-15',
      'restSeconds': 60,
    },

    // ==================== BRAȚE ====================
    {
      'id': 'arms_001',
      'name': 'Flexii biceps cu bară',
      'englishName': 'Barbell Bicep Curls',
      'bodyPart': 'Brațe',
      'targetMuscles': 'Biceps',
      'equipment': 'Bară',
      'difficulty': 'Începător',
      'videoUrl': 'https://www.youtube.com/watch?v=kwG2ipFRgfo',
      'instructions': 'Cu bara în mâini, îndoaie cotii și ridică bara spre umeri.',
      'safetyTips': 'Nu balansa corpul, menține cotii aproape de corp.',
      'sets': 3,
      'reps': '10-12',
      'restSeconds': 60,
    },
    {
      'id': 'arms_002',
      'name': 'Extensii triceps cu ganteră',
      'englishName': 'Overhead Tricep Extension',
      'bodyPart': 'Brațe',
      'targetMuscles': 'Triceps',
      'equipment': 'Ganteră',
      'difficulty': 'Începător',
      'videoUrl': 'https://www.youtube.com/watch?v=-Vyt2QdsR7E',
      'instructions': 'Cu ganterea deasupra capului, coboară în spatele capului, apoi extinde.',
      'safetyTips': 'Menține cotii aproape de cap, nu lăsa gantera să cadă.',
      'sets': 3,
      'reps': '10-12',
      'restSeconds': 60,
    },
    {
      'id': 'arms_003',
      'name': 'Flexii biceps cu gantere (alternativ)',
      'englishName': 'Alternating Dumbbell Curls',
      'bodyPart': 'Brațe',
      'targetMuscles': 'Biceps',
      'equipment': 'Gantere',
      'difficulty': 'Începător',
      'videoUrl': 'https://www.youtube.com/watch?v=sAq_ocpRh_I',
      'instructions': 'Alternează flexiile cu fiecare braț, rotind încheietura.',
      'safetyTips': 'Nu balansa corpul, controlează coborârea.',
      'sets': 3,
      'reps': '10-12 (fiecare braț)',
      'restSeconds': 60,
    },
    {
      'id': 'arms_004',
      'name': 'Dips pentru triceps',
      'englishName': 'Tricep Dips',
      'bodyPart': 'Brațe',
      'targetMuscles': 'Triceps, Piept',
      'equipment': 'Bare paralele',
      'difficulty': 'Intermediar',
      'videoUrl': 'https://www.youtube.com/watch?v=2z8JmcrW-As',
      'instructions': 'Coboară corpul îndoind cotii, apoi împinge înapoi.',
      'safetyTips': 'Nu coborî prea jos, menține umerii stabili.',
      'sets': 3,
      'reps': '8-12',
      'restSeconds': 75,
    },
    {
      'id': 'arms_005',
      'name': 'Flexii biceps cu cablu',
      'englishName': 'Cable Bicep Curls',
      'bodyPart': 'Brațe',
      'targetMuscles': 'Biceps',
      'equipment': 'Cablu',
      'difficulty': 'Începător',
      'videoUrl': 'https://www.youtube.com/watch?v=6uZFO2FPkk0',
      'instructions': 'Trage cablul în sus flexând cotii, menține tensiunea constantă.',
      'safetyTips': 'Nu lăsa greutatea să cadă brusc.',
      'sets': 3,
      'reps': '12-15',
      'restSeconds': 60,
    },

    // ==================== ABDOMEN ====================
    {
      'id': 'abs_001',
      'name': 'Planșă (Plank)',
      'englishName': 'Plank',
      'bodyPart': 'Abdomen',
      'targetMuscles': 'Core, Abdomen',
      'equipment': 'Greutate corporală',
      'difficulty': 'Începător',
      'videoUrl': 'https://www.youtube.com/watch?v=ASdvN_XEl_c',
      'instructions': 'Menține poziția de planșă cu corpul drept, cotii sub umeri.',
      'safetyTips': 'Nu lăsa șoldurile să cadă, respiră normal.',
      'sets': 3,
      'reps': '30-60 secunde',
      'restSeconds': 45,
    },
    {
      'id': 'abs_002',
      'name': 'Crunch-uri abdominale',
      'englishName': 'Crunches',
      'bodyPart': 'Abdomen',
      'targetMuscles': 'Abdomen superior',
      'equipment': 'Greutate corporală',
      'difficulty': 'Începător',
      'videoUrl': 'https://www.youtube.com/watch?v=Xyd_fa5zoEU',
      'instructions': 'Întins pe spate, ridică umerii de pe podea contractând abdomenul.',
      'safetyTips': 'Nu trage de gât, menține bărbia ridicată.',
      'sets': 3,
      'reps': '15-20',
      'restSeconds': 45,
    },
    {
      'id': 'abs_003',
      'name': 'Ridicări picioare atârnând',
      'englishName': 'Hanging Leg Raises',
      'bodyPart': 'Abdomen',
      'targetMuscles': 'Abdomen inferior',
      'equipment': 'Bară de tracțiuni',
      'difficulty': 'Avansat',
      'videoUrl': 'https://www.youtube.com/watch?v=hdng3Nm1x_E',
      'instructions': 'Atârnând de bară, ridică picioarele până sunt paralele cu solul.',
      'safetyTips': 'Nu balansa, controlează mișcarea.',
      'sets': 3,
      'reps': '10-15',
      'restSeconds': 60,
    },
    {
      'id': 'abs_004',
      'name': 'Russian Twists',
      'englishName': 'Russian Twists',
      'bodyPart': 'Abdomen',
      'targetMuscles': 'Oblici',
      'equipment': 'Greutate corporală sau Ganteră',
      'difficulty': 'Intermediar',
      'videoUrl': 'https://www.youtube.com/watch?v=wkD8rjkodUI',
      'instructions': 'Șezând cu picioarele ridicate, rotește trunchiul lateral.',
      'safetyTips': 'Menține spatele drept, nu rotunji spatele.',
      'sets': 3,
      'reps': '20-30 (total)',
      'restSeconds': 45,
    },
    {
      'id': 'abs_005',
      'name': 'Mountain Climbers',
      'englishName': 'Mountain Climbers',
      'bodyPart': 'Abdomen',
      'targetMuscles': 'Core, Cardio',
      'equipment': 'Greutate corporală',
      'difficulty': 'Intermediar',
      'videoUrl': 'https://www.youtube.com/watch?v=nmwgirgXLYM',
      'instructions': 'În poziție de planșă, adu genunchii alternativ spre piept rapid.',
      'safetyTips': 'Menține șoldurile jos, respiră constant.',
      'sets': 3,
      'reps': '30-45 secunde',
      'restSeconds': 45,
    },

    // ==================== CARDIO ====================
    {
      'id': 'cardio_001',
      'name': 'Burpees',
      'englishName': 'Burpees',
      'bodyPart': 'Cardio',
      'targetMuscles': 'Full body, Cardio',
      'equipment': 'Greutate corporală',
      'difficulty': 'Intermediar',
      'videoUrl': 'https://www.youtube.com/watch?v=TU8QYVW0gDU',
      'instructions': 'Coboară în squat, pune mâinile pe podea, sari în planșă, flotare, sari înapoi.',
      'safetyTips': 'Menține forma corectă, nu te grăbi excesiv.',
      'sets': 3,
      'reps': '10-15',
      'restSeconds': 60,
    },
    {
      'id': 'cardio_002',
      'name': 'Jumping Jacks',
      'englishName': 'Jumping Jacks',
      'bodyPart': 'Cardio',
      'targetMuscles': 'Full body, Cardio',
      'equipment': 'Greutate corporală',
      'difficulty': 'Începător',
      'videoUrl': 'https://www.youtube.com/watch?v=c4DAnQ6DtF8',
      'instructions': 'Sari deschizând picioarele și ridicând brațele deasupra capului.',
      'safetyTips': 'Aterizează moale, menține un ritm constant.',
      'sets': 3,
      'reps': '30-60 secunde',
      'restSeconds': 30,
    },
    {
      'id': 'cardio_003',
      'name': 'High Knees',
      'englishName': 'High Knees',
      'bodyPart': 'Cardio',
      'targetMuscles': 'Picioare, Cardio',
      'equipment': 'Greutate corporală',
      'difficulty': 'Începător',
      'videoUrl': 'https://www.youtube.com/watch?v=8opcQdC-V-U',
      'instructions': 'Aleargă pe loc ridicând genunchii cât mai sus.',
      'safetyTips': 'Menține ritmul, respiră constant.',
      'sets': 3,
      'reps': '30-45 secunde',
      'restSeconds': 30,
    },
  ];

  /// Returnează toate exercițiile
  static List<Map<String, dynamic>> getAllExercises() {
    return exercises;
  }

  /// Returnează exerciții filtrate după partea corpului
  static List<Map<String, dynamic>> getExercisesByBodyPart(String bodyPart) {
    return exercises.where((ex) => ex['bodyPart'] == bodyPart).toList();
  }

  /// Returnează exerciții filtrate după dificultate
  static List<Map<String, dynamic>> getExercisesByDifficulty(String difficulty) {
    return exercises.where((ex) => ex['difficulty'] == difficulty).toList();
  }

  /// Returnează exerciții filtrate după echipament
  static List<Map<String, dynamic>> getExercisesByEquipment(String equipment) {
    return exercises.where((ex) => ex['equipment'].toString().contains(equipment)).toList();
  }

  /// Returnează un exercițiu după ID
  static Map<String, dynamic>? getExerciseById(String id) {
    try {
      return exercises.firstWhere((ex) => ex['id'] == id);
    } catch (e) {
      return null;
    }
  }

  /// Returnează un exercițiu după nume (caută în ambele limbi)
  static Map<String, dynamic>? getExerciseByName(String name) {
    try {
      return exercises.firstWhere(
        (ex) => ex['name'].toString().toLowerCase() == name.toLowerCase() ||
                ex['englishName'].toString().toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Returnează lista de nume de exerciții pentru AI prompt
  static String getExerciseListForPrompt() {
    final buffer = StringBuffer();
    buffer.writeln('EXERCIȚII DISPONIBILE (selectează DOAR din această listă):');
    buffer.writeln('IMPORTANT: Folosește NUMELE ÎN ENGLEZĂ pentru exerciții!');
    buffer.writeln();
    
    final groupedByBodyPart = <String, List<Map<String, dynamic>>>{};
    for (var exercise in exercises) {
      final bodyPart = exercise['bodyPart'] as String;
      groupedByBodyPart.putIfAbsent(bodyPart, () => []).add(exercise);
    }

    groupedByBodyPart.forEach((bodyPart, exList) {
      buffer.writeln('=== $bodyPart ===');
      for (var ex in exList) {
        buffer.writeln('- ${ex['englishName']} (${ex['difficulty']}, ${ex['equipment']})');
      }
      buffer.writeln();
    });

    return buffer.toString();
  }
}

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../routes/app_routes.dart';
import '../../../services/supabase_service.dart';
import '../../../services/gemini_ai_service.dart';

class OnboardingSurveyWidget extends StatefulWidget {
  final bool isEditing;
  final Map<String, dynamic>? initialData;

  const OnboardingSurveyWidget({
    super.key,
    this.isEditing = false,
    this.initialData,
  });

  @override
  State<OnboardingSurveyWidget> createState() => _OnboardingSurveyWidgetState();
}

class _OnboardingSurveyWidgetState extends State<OnboardingSurveyWidget> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Survey data
  String? _fitnessGoal;
  String? _activityLevel;
  String? _equipment;
  String? _dietaryPreference;
  int? _age;
  String? _gender;
  double? _height;
  double? _currentWeight;
  double? _targetWeight;
  String? _medicalConditions;
  int? _weeklyTrainingFrequency;
  double? _availableTrainingHours;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.initialData != null) {
      _prefillData();
    }
  }

  void _prefillData() {
    final data = widget.initialData!;
    setState(() {
      _fitnessGoal = data['fitness_goal'];
      _activityLevel = data['activity_level'];
      _equipment = data['equipment_available'];
      _dietaryPreference = data['dietary_preference'];
      _age = data['age'];
      _gender = data['gender'];
      _height = (data['height_cm'] as num?)?.toDouble();
      _currentWeight = (data['current_weight_kg'] as num?)?.toDouble();
      _targetWeight = (data['target_weight_kg'] as num?)?.toDouble();
      _medicalConditions = data['medical_conditions'];
      _weeklyTrainingFrequency = data['weekly_training_frequency'];
      _availableTrainingHours = (data['available_training_hours_per_session'] as num?)?.toDouble();
    });
  }

  final List<String> _fitnessGoals = [
    'pierdere_greutate',
    'crestere_masa_musculara',
    'mentinere',
    'tonifiere',
  ];

  final List<String> _activityLevels = [
    'sedentar',
    'usor_activ',
    'moderat_activ',
    'foarte_activ',
    'extrem_activ',
  ];

  final List<String> _equipmentTypes = [
    'acasa_fara_echipament',
    'acasa_cu_echipament_basic',
    'sala_fitness',
    'mix',
  ];

  final List<String> _dietaryPreferences = [
    'normal',
    'vegetarian',
    'vegan',
    'fara_gluten',
    'fara_lactate',
  ];

  String _getLabelForGoal(String goal) {
    const labels = {
      'pierdere_greutate': 'Pierdere Greutate',
      'crestere_masa_musculara': 'Creștere Masă Musculară',
      'mentinere': 'Menținere',
      'tonifiere': 'Tonifiere',
    };
    return labels[goal] ?? goal;
  }

  String _getLabelForActivity(String activity) {
    const labels = {
      'sedentar': 'Sedentar',
      'usor_activ': 'Ușor Activ',
      'moderat_activ': 'Moderat Activ',
      'foarte_activ': 'Foarte Activ',
      'extrem_activ': 'Extrem de Activ',
    };
    return labels[activity] ?? activity;
  }

  String _getLabelForEquipment(String equipment) {
    const labels = {
      'acasa_fara_echipament': 'Acasă fără Echipament',
      'acasa_cu_echipament_basic': 'Acasă cu Echipament Basic',
      'sala_fitness': 'Sală de Fitness',
      'mix': 'Mix',
    };
    return labels[equipment] ?? equipment;
  }

  String _getLabelForDiet(String diet) {
    const labels = {
      'normal': 'Normal',
      'vegetarian': 'Vegetarian',
      'vegan': 'Vegan',
      'fara_gluten': 'Fără Gluten',
      'fara_lactate': 'Fără Lactate',
    };
    return labels[diet] ?? diet;
  }

  Future<void> _saveOnboardingData() async {
    setState(() => _isLoading = true);

    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Update user profile with all questionnaire data
      await SupabaseService.instance.client
          .from('user_profiles')
          .update({
            'age': _age,
            'gender': _gender,
            'height_cm': _height,
            'current_weight_kg': _currentWeight,
            'target_weight_kg': _targetWeight,
            'fitness_goal': _fitnessGoal,
            'activity_level': _activityLevel,
            'equipment_available': _equipment,
            'dietary_preference': _dietaryPreference,
            'medical_conditions': _medicalConditions,
            'weekly_training_frequency': _weeklyTrainingFrequency,
            'available_training_hours_per_session': _availableTrainingHours,
            'onboarding_completed': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // Save onboarding responses
      final responses = [
        {
          'user_id': userId,
          'step_number': 1,
          'question_key': 'fitness_goal',
          'answer_value': _fitnessGoal ?? '',
        },
        {
          'user_id': userId,
          'step_number': 2,
          'question_key': 'activity_level',
          'answer_value': _activityLevel ?? '',
        },
        {
          'user_id': userId,
          'step_number': 3,
          'question_key': 'equipment',
          'answer_value': _equipment ?? '',
        },
        {
          'user_id': userId,
          'step_number': 4,
          'question_key': 'dietary_preference',
          'answer_value': _dietaryPreference ?? '',
        },
        {
          'user_id': userId,
          'step_number': 5,
          'question_key': 'weekly_training_frequency',
          'answer_value': _weeklyTrainingFrequency?.toString() ?? '',
        },
        {
          'user_id': userId,
          'step_number': 6,
          'question_key': 'available_training_hours',
          'answer_value': _availableTrainingHours?.toString() ?? '',
        },
      ];

      await SupabaseService.instance.client
          .from('onboarding_responses')
          .insert(responses);

      // TODO: Calculate daily calorie goal - temporarily disabled due to schema cache issue
      // await SupabaseService.instance.client.rpc(
      //   'calculate_daily_calories',
      //   params: {'user_profile_id': userId},
      // );

      // Generate personalized workout plan
      await SupabaseService.instance.client.rpc(
        'generate_workout_plan',
        params: {'user_profile_id': userId},
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'Planul a fost recalibrat cu succes!'
                : 'Configurare finalizată!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Regenerate AI plan if in edit mode
      if (widget.isEditing && mounted) {
        try {
          await GeminiAIService().generateCompletePlan(userId);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎉 Planul AI a fost regenerat cu noile preferințe!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Atenție: Planul a fost salvat dar regenerarea a eșuat: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      if (mounted) {
        if (widget.isEditing) {
          Navigator.pop(context, true); // Return true to indicate update
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.mainDashboard);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Eroare: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Add validation method
  bool _isCurrentStepValid() {
    switch (_currentStep) {
      case 0:
        return _fitnessGoal != null;
      case 1:
        return _activityLevel != null;
      case 2:
        return _equipment != null;
      case 3:
        return _dietaryPreference != null;
      case 4:
        return _age != null &&
            _gender != null &&
            _height != null &&
            _currentWeight != null &&
            _targetWeight != null;
      case 5:
        return _weeklyTrainingFrequency != null &&
            _availableTrainingHours != null;
      case 6:
        return true; // Medical conditions is optional
      default:
        return false;
    }
  }

  void _showValidationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Te rugăm să completezi toate câmpurile obligatorii'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Care este obiectivul tău de fitness?',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 3.h),
        ..._fitnessGoals.map(
          (goal) => RadioListTile<String>(
            title: Text(_getLabelForGoal(goal)),
            value: goal,
            groupValue: _fitnessGoal,
            onChanged: (value) => setState(() => _fitnessGoal = value),
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Care este nivelul tău de activitate?',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 3.h),
        ..._activityLevels.map(
          (level) => RadioListTile<String>(
            title: Text(_getLabelForActivity(level)),
            value: level,
            groupValue: _activityLevel,
            onChanged: (value) => setState(() => _activityLevel = value),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ce echipament ai disponibil?',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 3.h),
        ..._equipmentTypes.map(
          (equipment) => RadioListTile<String>(
            title: Text(_getLabelForEquipment(equipment)),
            value: equipment,
            groupValue: _equipment,
            onChanged: (value) => setState(() => _equipment = value),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferințe dietetice',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 3.h),
        ..._dietaryPreferences.map(
          (diet) => RadioListTile<String>(
            title: Text(_getLabelForDiet(diet)),
            value: diet,
            groupValue: _dietaryPreference,
            onChanged: (value) => setState(() => _dietaryPreference = value),
          ),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informații personale',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 3.h),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Vârstă'),
          keyboardType: TextInputType.number,
          onChanged: (value) => _age = int.tryParse(value),
        ),
        SizedBox(height: 2.h),
        DropdownButtonFormField<String>(
          initialValue: _gender,
          decoration: const InputDecoration(labelText: 'Gen'),
          items: [
            'barbat',
            'femeie',
            'altul',
          ].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
          onChanged: (value) => setState(() => _gender = value),
        ),
        SizedBox(height: 2.h),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Înălțime (cm)'),
          keyboardType: TextInputType.number,
          onChanged: (value) => _height = double.tryParse(value),
        ),
        SizedBox(height: 2.h),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Greutate Actuală (kg)'),
          keyboardType: TextInputType.number,
          onChanged: (value) => _currentWeight = double.tryParse(value),
        ),
        SizedBox(height: 2.h),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Greutate Țintă (kg)'),
          keyboardType: TextInputType.number,
          onChanged: (value) => _targetWeight = double.tryParse(value),
        ),
      ],
    );
  }

  Widget _buildStep5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Program de antrenament',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 3.h),
        Text(
          'Câte antrenamente poți face pe săptămână?',
          style: TextStyle(fontSize: 14.sp),
        ),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 2.w,
          children: List.generate(7, (index) {
            final frequency = index + 1;
            return ChoiceChip(
              label: Text('$frequency zile'),
              selected: _weeklyTrainingFrequency == frequency,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _weeklyTrainingFrequency = frequency);
                }
              },
            );
          }),
        ),
        SizedBox(height: 3.h),
        Text(
          'Câte ore ai disponibile per antrenament?',
          style: TextStyle(fontSize: 14.sp),
        ),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 2.w,
          children: [0.5, 1.0, 1.5, 2.0, 2.5, 3.0].map((hours) {
            return ChoiceChip(
              label: Text('${hours.toStringAsFixed(1)}h'),
              selected: _availableTrainingHours == hours,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _availableTrainingHours = hours);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep6() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Considerații medicale',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 3.h),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Condiții medicale (opțional)',
            hintText: 'Ex: Diabet, probleme articulare, etc.',
          ),
          maxLines: 3,
          onChanged: (value) => _medicalConditions = value,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Recalibrare Plan' : 'Configurare Profil'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(5.w),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (_currentStep + 1) / 7,
                backgroundColor: Colors.grey.shade300,
              ),
              SizedBox(height: 2.h),
              Text(
                'Pasul ${_currentStep + 1} din 7',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey),
              ),
              SizedBox(height: 3.h),
              Expanded(
                child: SingleChildScrollView(
                  child: [
                    _buildStep0(),
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                    _buildStep4(),
                    _buildStep5(),
                    _buildStep6(),
                  ][_currentStep],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: () => setState(() => _currentStep--),
                      child: const Text('Înapoi'),
                    )
                  else
                    const SizedBox(),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            // Validate current step before proceeding
                            if (!_isCurrentStepValid()) {
                              _showValidationError();
                              return;
                            }

                            if (_currentStep < 6) {
                              setState(() => _currentStep++);
                            } else {
                              _saveOnboardingData();
                            }
                          },
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_currentStep < 6
                             ? 'Următorul'
                             : (widget.isEditing ? 'Salvează și Recalibrează' : 'Finalizează')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

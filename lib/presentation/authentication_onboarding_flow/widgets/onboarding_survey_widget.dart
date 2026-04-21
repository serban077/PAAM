import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../routes/app_routes.dart';
import '../../../services/analytics_service.dart';
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
      // Normalize legacy Romanian gender values to English
      const genderMap = {'barbat': 'male', 'femeie': 'female', 'altul': 'other'};
      final rawGender = data['gender']?.toString();
      _gender = genderMap[rawGender] ?? rawGender;
      _height = (data['height_cm'] as num?)?.toDouble();
      _currentWeight = (data['current_weight_kg'] as num?)?.toDouble();
      _targetWeight = (data['target_weight_kg'] as num?)?.toDouble();
      _medicalConditions = data['medical_conditions'];
      _weeklyTrainingFrequency = data['weekly_training_frequency'];
      _availableTrainingHours = (data['available_training_hours_per_session'] as num?)?.toDouble();
    });
  }

  final List<String> _fitnessGoals = [
    'weight_loss',
    'muscle_gain',
    'maintenance',
    'toning',
    'endurance',
    'body_recomposition',
  ];

  final List<String> _activityLevels = [
    'sedentary',
    'lightly_active',
    'moderately_active',
    'very_active',
    'extremely_active',
  ];

  final List<String> _equipmentTypes = [
    'home_no_equipment',
    'home_basic_equipment',
    'gym',
    'mix',
  ];

  final List<String> _dietaryPreferences = [
    'normal',
    'vegetarian',
    'vegan',
    'gluten_free',
    'dairy_free',
  ];

  String _getLabelForGoal(String goal) {
    const labels = {
      'weight_loss': 'Weight Loss',
      'muscle_gain': 'Muscle Gain',
      'maintenance': 'Maintenance',
      'toning': 'Toning',
      'endurance': 'Endurance',
      'body_recomposition': 'Body Recomposition',
    };
    return labels[goal] ?? goal;
  }

  String _getLabelForActivity(String activity) {
    const labels = {
      'sedentary': 'Sedentary',
      'lightly_active': 'Lightly Active',
      'moderately_active': 'Moderately Active',
      'very_active': 'Very Active',
      'extremely_active': 'Extremely Active',
    };
    return labels[activity] ?? activity;
  }

  String _getLabelForEquipment(String equipment) {
    const labels = {
      'home_no_equipment': 'Home (No Equipment)',
      'home_basic_equipment': 'Home (Basic Equipment)',
      'gym': 'Gym',
      'mix': 'Mix',
    };
    return labels[equipment] ?? equipment;
  }

  String _getLabelForDiet(String diet) {
    const labels = {
      'normal': 'Standard',
      'vegetarian': 'Vegetarian',
      'vegan': 'Vegan',
      'gluten_free': 'Gluten-Free',
      'dairy_free': 'Dairy-Free',
    };
    return labels[diet] ?? diet;
  }

  String _getLabelForGender(String gender) {
    const labels = {
      'male': 'Male',
      'female': 'Female',
      'other': 'Other',
      'prefer_not_to_say': 'Prefer Not to Say',
    };
    return labels[gender] ?? gender;
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

      // Log current weight to body_measurements for history tracking
      if (_currentWeight != null) {
        await SupabaseService.instance.client
            .from('body_measurements')
            .insert({
              'user_id': userId,
              'measurement_type': 'weight',
              'value': _currentWeight,
              'measured_at': DateTime.now().toIso8601String(),
            });
      }

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
                ? 'Plan recalibrated successfully!'
                : 'Setup complete!'),
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
                content: Text('AI plan regenerated with new preferences!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Warning: Plan saved but regeneration failed: $e'),
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
          unawaited(AnalyticsService.instance.track('onboarding_completed'));
          Navigator.pushReplacementNamed(context, AppRoutes.mainDashboard);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
        content: Text('Please complete all required fields'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What is your fitness goal?',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 3.h),
        RadioGroup<String>(
          groupValue: _fitnessGoal,
          onChanged: (value) => setState(() => _fitnessGoal = value),
          child: Column(
            children: _fitnessGoals.map(
              (goal) => RadioListTile<String>(
                title: Text(_getLabelForGoal(goal)),
                value: goal,
              ),
            ).toList(),
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
          'What is your activity level?',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 3.h),
        RadioGroup<String>(
          groupValue: _activityLevel,
          onChanged: (value) => setState(() => _activityLevel = value),
          child: Column(
            children: _activityLevels.map(
              (level) => RadioListTile<String>(
                title: Text(_getLabelForActivity(level)),
                value: level,
              ),
            ).toList(),
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
          'What equipment do you have available?',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 3.h),
        RadioGroup<String>(
          groupValue: _equipment,
          onChanged: (value) => setState(() => _equipment = value),
          child: Column(
            children: _equipmentTypes.map(
              (equipment) => RadioListTile<String>(
                title: Text(_getLabelForEquipment(equipment)),
                value: equipment,
              ),
            ).toList(),
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
          'Dietary preferences',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 3.h),
        RadioGroup<String>(
          groupValue: _dietaryPreference,
          onChanged: (value) => setState(() => _dietaryPreference = value),
          child: Column(
            children: _dietaryPreferences.map(
              (diet) => RadioListTile<String>(
                title: Text(_getLabelForDiet(diet)),
                value: diet,
              ),
            ).toList(),
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
          'Personal information',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 3.h),
        TextFormField(
          initialValue: _age?.toString() ?? '',
          decoration: const InputDecoration(labelText: 'Age'),
          keyboardType: TextInputType.number,
          onChanged: (value) => _age = int.tryParse(value),
        ),
        SizedBox(height: 2.h),
        DropdownButtonFormField<String>(
          initialValue: _gender,
          decoration: const InputDecoration(labelText: 'Gender'),
          items: [
            'male',
            'female',
            'other',
            'prefer_not_to_say',
          ]
              .map((g) => DropdownMenuItem(
                    value: g,
                    child: Text(_getLabelForGender(g)),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _gender = value),
        ),
        SizedBox(height: 2.h),
        TextFormField(
          initialValue: _height != null ? _height!.toStringAsFixed(0) : '',
          decoration: const InputDecoration(labelText: 'Height (cm)'),
          keyboardType: TextInputType.number,
          onChanged: (value) => _height = double.tryParse(value),
        ),
        SizedBox(height: 2.h),
        TextFormField(
          initialValue: _currentWeight != null ? _currentWeight!.toStringAsFixed(1) : '',
          decoration: const InputDecoration(labelText: 'Current Weight (kg)'),
          keyboardType: TextInputType.number,
          onChanged: (value) => _currentWeight = double.tryParse(value),
        ),
        SizedBox(height: 2.h),
        TextFormField(
          initialValue: _targetWeight != null ? _targetWeight!.toStringAsFixed(1) : '',
          decoration: const InputDecoration(labelText: 'Target Weight (kg)'),
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
          'Training schedule',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 3.h),
        Text(
          'How many workouts can you do per week?',
          style: TextStyle(fontSize: 14.sp),
        ),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 2.w,
          children: List.generate(7, (index) {
            final frequency = index + 1;
            return ChoiceChip(
              label: Text('$frequency days'),
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
          'How many hours are available per session?',
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
          'Medical considerations',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 3.h),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Medical conditions (optional)',
            hintText: 'E.g.: Diabetes, joint problems, etc.',
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
        title: Text(widget.isEditing ? 'Recalibrate Plan' : 'Setup Profile'),
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
                'Step ${_currentStep + 1} of 7',
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
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox(),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
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
                            ? 'Next'
                            : (widget.isEditing
                                ? 'Save & Recalibrate'
                                : 'Finish')),
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

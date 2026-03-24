import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../routes/app_routes.dart';

class OnboardingSurveyScreen extends StatefulWidget {
  const OnboardingSurveyScreen({super.key});

  @override
  State<OnboardingSurveyScreen> createState() => _OnboardingSurveyScreenState();
}

class _OnboardingSurveyScreenState extends State<OnboardingSurveyScreen> {
  final _authService = AuthService();
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;

  // Form data
  DateTime? _dateOfBirth;
  String? _gender;
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  String? _fitnessGoal;
  String? _experienceLevel;

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _submitOnboarding() async {
    setState(() => _isLoading = true);

    try {
      await _authService.updateUserProfile(
        profileData: {
          'date_of_birth': _dateOfBirth?.toIso8601String(),
          'gender': _gender,
          'height_cm': double.tryParse(_heightController.text),
          'weight_kg': double.tryParse(_weightController.text),
          'target_weight_kg':
              double.tryParse(_targetWeightController.text),
          'fitness_goal': _fitnessGoal,
          'experience_level': _experienceLevel,
          'onboarding_completed': true,
        },
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.mainDashboard);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onStepContinue() {
    bool isValid = false;
    switch (_currentStep) {
      case 0:
        if (_formKeyStep1.currentState!.validate()) {
          if (_dateOfBirth != null) {
            isValid = true;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select your date of birth.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;
      case 1:
        if (_formKeyStep2.currentState!.validate()) {
          isValid = true;
        }
        break;
      case 2:
        if (_formKeyStep3.currentState!.validate()) {
          _submitOnboarding();
        }
        break;
    }

    if (isValid) {
      setState(() => _currentStep++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Setup'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _onStepContinue,
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : details.onStepContinue,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _currentStep == 2 ? 'Finish' : 'Continue',
                          ),
                  ),
                  if (_currentStep > 0) ...[
                    SizedBox(width: 2.w),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Personal Info'),
              isActive: _currentStep >= 0,
              state:
                  _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Form(
                key: _formKeyStep1,
                child: Column(
                  children: [
                    // Date of Birth
                    ListTile(
                      title: const Text('Date of Birth'),
                      subtitle: Text(
                        _dateOfBirth != null
                            ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                            : 'Select date',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now()
                              .subtract(const Duration(days: 365 * 25)),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _dateOfBirth = date);
                        }
                      },
                    ),
                    SizedBox(height: 2.h),
                    // Gender
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      value: _gender,
                      items: const [
                        DropdownMenuItem(
                          value: 'male',
                          child: Text('Male'),
                        ),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                        DropdownMenuItem(
                          value: 'prefer_not_to_say',
                          child: Text('Prefer not to say'),
                        ),
                      ],
                      onChanged: (value) => setState(() => _gender = value),
                      validator: (value) =>
                          value == null ? 'Select gender' : null,
                    ),
                  ],
                ),
              ),
            ),
            Step(
              title: const Text('Body Measurements'),
              isActive: _currentStep >= 1,
              state:
                  _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: Form(
                key: _formKeyStep2,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Height (cm)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your height';
                        }
                        final height = double.tryParse(value);
                        if (height == null || height < 100 || height > 250) {
                          return 'Invalid height';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 2.h),
                    TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Current Weight (kg)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your weight';
                        }
                        final weight = double.tryParse(value);
                        if (weight == null || weight < 30 || weight > 300) {
                          return 'Invalid weight';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 2.h),
                    TextFormField(
                      controller: _targetWeightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Target Weight (kg)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final weight = double.tryParse(value);
                          if (weight == null || weight < 30 || weight > 300) {
                            return 'Invalid target weight';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            Step(
              title: const Text('Fitness Goals'),
              isActive: _currentStep >= 2,
              content: Form(
                key: _formKeyStep3,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Fitness Goal',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      value: _fitnessGoal,
                      items: const [
                        DropdownMenuItem(
                          value: 'weight_loss',
                          child: Text('Weight Loss'),
                        ),
                        DropdownMenuItem(
                          value: 'muscle_gain',
                          child: Text('Muscle Gain'),
                        ),
                        DropdownMenuItem(
                          value: 'endurance',
                          child: Text('Endurance'),
                        ),
                        DropdownMenuItem(
                          value: 'flexibility',
                          child: Text('Flexibility'),
                        ),
                        DropdownMenuItem(
                          value: 'general_fitness',
                          child: Text('General Fitness'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _fitnessGoal = value),
                      validator: (value) =>
                          value == null ? 'Select a goal' : null,
                    ),
                    SizedBox(height: 2.h),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Experience Level',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      value: _experienceLevel,
                      items: const [
                        DropdownMenuItem(
                          value: 'beginner',
                          child: Text('Beginner'),
                        ),
                        DropdownMenuItem(
                          value: 'intermediate',
                          child: Text('Intermediate'),
                        ),
                        DropdownMenuItem(
                          value: 'advanced',
                          child: Text('Advanced'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _experienceLevel = value),
                      validator: (value) =>
                          value == null ? 'Select a level' : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
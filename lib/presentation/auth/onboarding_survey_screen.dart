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
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.updateUserProfile(
        profileData: {
          'date_of_birth': _dateOfBirth?.toIso8601String(),
          'gender': _gender,
          'height_cm': double.tryParse(_heightController.text),
          'weight_kg': double.tryParse(_weightController.text),
          'target_weight_kg': double.tryParse(_targetWeightController.text),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurare Profil'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Stepper(
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 2) {
                setState(() => _currentStep++);
              } else {
                _submitOnboarding();
              }
            },
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
                              _currentStep == 2 ? 'Finalizează' : 'Continuă',
                            ),
                    ),
                    if (_currentStep > 0) ...[
                      SizedBox(width: 2.w),
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Înapoi'),
                      ),
                    ],
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('Informații Personale'),
                isActive: _currentStep >= 0,
                state: _currentStep > 0
                    ? StepState.complete
                    : StepState.indexed,
                content: Column(
                  children: [
                    // Date of Birth
                    ListTile(
                      title: const Text('Data Nașterii'),
                      subtitle: Text(
                        _dateOfBirth != null
                            ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                            : 'Selectează data',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(
                            const Duration(days: 365 * 25),
                          ),
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
                        labelText: 'Gen',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      initialValue: _gender,
                      items: const [
                        DropdownMenuItem(
                          value: 'male',
                          child: Text('Masculin'),
                        ),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text('Feminin'),
                        ),
                        DropdownMenuItem(value: 'other', child: Text('Altul')),
                        DropdownMenuItem(
                          value: 'prefer_not_to_say',
                          child: Text('Prefer să nu spun'),
                        ),
                      ],
                      onChanged: (value) => setState(() => _gender = value),
                      validator: (value) =>
                          value == null ? 'Selectează genul' : null,
                    ),
                  ],
                ),
              ),
              Step(
                title: const Text('Măsurători Corporale'),
                isActive: _currentStep >= 1,
                state: _currentStep > 1
                    ? StepState.complete
                    : StepState.indexed,
                content: Column(
                  children: [
                    TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Înălțime (cm)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Introdu înălțimea';
                        }
                        final height = double.tryParse(value);
                        if (height == null || height < 100 || height > 250) {
                          return 'Înălțime invalidă';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 2.h),
                    TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Greutate Actuală (kg)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Introdu greutatea';
                        }
                        final weight = double.tryParse(value);
                        if (weight == null || weight < 30 || weight > 300) {
                          return 'Greutate invalidă';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 2.h),
                    TextFormField(
                      controller: _targetWeightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Greutate Țintă (kg)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Step(
                title: const Text('Obiective Fitness'),
                isActive: _currentStep >= 2,
                content: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Obiectiv Fitness',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      initialValue: _fitnessGoal,
                      items: const [
                        DropdownMenuItem(
                          value: 'weight_loss',
                          child: Text('Pierdere în Greutate'),
                        ),
                        DropdownMenuItem(
                          value: 'muscle_gain',
                          child: Text('Creștere Musculară'),
                        ),
                        DropdownMenuItem(
                          value: 'endurance',
                          child: Text('Rezistență'),
                        ),
                        DropdownMenuItem(
                          value: 'flexibility',
                          child: Text('Flexibilitate'),
                        ),
                        DropdownMenuItem(
                          value: 'general_fitness',
                          child: Text('Fitness General'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _fitnessGoal = value),
                      validator: (value) =>
                          value == null ? 'Selectează obiectivul' : null,
                    ),
                    SizedBox(height: 2.h),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Nivel Experiență',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      initialValue: _experienceLevel,
                      items: const [
                        DropdownMenuItem(
                          value: 'beginner',
                          child: Text('Începător'),
                        ),
                        DropdownMenuItem(
                          value: 'intermediate',
                          child: Text('Intermediar'),
                        ),
                        DropdownMenuItem(
                          value: 'advanced',
                          child: Text('Avansat'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _experienceLevel = value),
                      validator: (value) =>
                          value == null ? 'Selectează nivelul' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

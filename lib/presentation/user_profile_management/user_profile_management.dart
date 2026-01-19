import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';
import '../../services/gemini_ai_service.dart';
import '../../routes/app_routes.dart';
import './widgets/personal_info_section_widget.dart';
import './widgets/fitness_preferences_section_widget.dart';
import './widgets/notification_settings_section_widget.dart';
import './widgets/account_management_section_widget.dart';
import '../authentication_onboarding_flow/widgets/onboarding_survey_widget.dart';

/// User Profile Management Screen
/// Enables comprehensive account customization and preference management
class UserProfileManagement extends StatefulWidget {
  const UserProfileManagement({super.key});

  @override
  State<UserProfileManagement> createState() => _UserProfileManagementState();
}

class _UserProfileManagementState extends State<UserProfileManagement> {
  bool _isLoading = true;
  bool _isRegenerating = false;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() => _isLoading = true);

      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await SupabaseService.instance.client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      setState(() {
        _userProfile = response;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Regenerate AI workout plan based on updated preferences
  Future<void> _regenerateAIPlan() async {
    try {
      if (!mounted) return;
      setState(() => _isRegenerating = true);

      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _isRegenerating = false);
        return;
      }

      // Generate new plan with updated preferences
      await GeminiAIService().generateCompletePlan(userId);

      if (!mounted) return;
      setState(() => _isRegenerating = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Planul tău a fost actualizat cu noile preferințe!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRegenerating = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eroare la regenerarea planului: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Update session durations for active workout plan
  Future<void> _updateSessionDurations(String userId, int newDurationMinutes) async {
    try {
      // Get active plan ID
      final scheduleResponse = await SupabaseService.instance.client
          .from('user_workout_schedules')
          .select('plan_id')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (scheduleResponse == null) return;

      final planId = scheduleResponse['plan_id'];

      // Update all sessions for this plan
      await SupabaseService.instance.client
          .from('workout_sessions')
          .update({'estimated_duration_minutes': newDurationMinutes})
          .eq('plan_id', planId);

      debugPrint('Updated session durations to $newDurationMinutes minutes');
    } catch (e) {
      debugPrint('Error updating session durations: $e');
    }
  }

  Future<void> _handleLogout() async {
    try {
      await SupabaseService.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.authenticationOnboardingFlow,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Eroare la deconectare: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: const Center(child: Text('Profil indisponibil')),
      );
    }

    final fullName = _userProfile!['full_name'] ?? 'Utilizator';
    final email = _userProfile!['email'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Profilul meu'), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profile header
            CircleAvatar(
              radius: 15.w,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                style: TextStyle(fontSize: 28.sp, color: Colors.white),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              fullName,
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              email,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),

            // Sections
            PersonalInfoSectionWidget(
              age: _userProfile!['age'] ?? 0,
              weight: (_userProfile!['weight_kg'] ?? 0.0).toDouble(),
              height: (_userProfile!['height_cm'] ?? 0.0).toDouble(),
              targetWeight: (_userProfile!['target_weight_kg'] as num?)?.toDouble(),
              targetTimeframeWeeks: _userProfile!['target_timeframe_weeks'] as int?,
              activityLevel: _userProfile!['activity_level']?.toString() ?? 'moderat_activ',
              onUpdate: (data) async {
                try {
                  final userId = SupabaseService.instance.client.auth.currentUser?.id;
                  if (userId == null) return;

                  await SupabaseService.instance.client
                      .from('user_profiles')
                      .update({
                        'age': data['age'],
                        'weight_kg': data['weight'],
                        'height_cm': data['height'],
                        'current_weight_kg': data['weight'],
                        'target_weight_kg': data['targetWeight'],
                        'target_timeframe_weeks': data['targetTimeframeWeeks'],
                        'activity_level': data['activityLevel'],
                      })
                      .eq('id', userId);

                  // TODO: Recalculate calories - temporarily disabled due to schema cache issue
                  // Uncomment after Supabase schema refresh or manual calorie update
                  // await SupabaseService.instance.client.rpc(
                  //   'calculate_daily_calories',
                  //   params: {'target_user_id': userId},
                  // );

                  await _loadUserProfile();
                  
                  if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Informațiile personale au fost salvate!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Eroare: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
            SizedBox(height: 2.h),

            FitnessPreferencesSectionWidget(
              workoutFrequency: _userProfile!['weekly_training_frequency'] ?? 3,
              sessionDuration: ((_userProfile!['available_training_hours_per_session'] ?? 1.0) * 60).toInt(),
              availableEquipment: _userProfile!['equipment_available'] != null 
                  ? [_userProfile!['equipment_available'].toString()]
                  : ['sala_fitness'],
              fitnessGoal: _userProfile!['fitness_goal']?.toString() ?? 'recompunere_corporala',
              onUpdate: (data) async {
                try {
                  final userId = SupabaseService.instance.client.auth.currentUser?.id;
                  if (userId == null) return;

                  // Check if training frequency or session duration changed
                  final oldFrequency = _userProfile!['weekly_training_frequency'];
                  final oldDuration = _userProfile!['available_training_hours_per_session'];
                  final newFrequency = data['workoutFrequency'];
                  final newDuration = data['sessionDuration'] / 60.0;
                  
                  final shouldRegenerate = (oldFrequency != newFrequency) || 
                                          ((oldDuration ?? 1.0) != newDuration);

                  await SupabaseService.instance.client
                      .from('user_profiles')
                      .update({
                        'weekly_training_frequency': newFrequency,
                        'available_training_hours_per_session': newDuration,
                        'equipment_available': data['availableEquipment'].isNotEmpty 
                            ? data['availableEquipment'][0] 
                            : 'sala_fitness',
                        'fitness_goal': data['fitnessGoal'],
                      })
                      .eq('id', userId);

                  await _loadUserProfile();

                  // Update session durations if duration changed (but not frequency)
                  if (!shouldRegenerate && (oldDuration ?? 1.0) != newDuration && mounted) {
                    await _updateSessionDurations(userId, (newDuration * 60).toInt());
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Preferințele au fost salvate!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }

                  // Trigger plan regeneration if frequency or duration changed
                  if (shouldRegenerate && mounted) {
                    await _regenerateAIPlan();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Eroare: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
            SizedBox(height: 2.h),

            NotificationSettingsSectionWidget(
              workoutReminders: _userProfile!['workout_reminders'] ?? true,
              progressUpdates: _userProfile!['progress_updates'] ?? true,
              motivationalMessages: _userProfile!['motivational_messages'] ?? true,
              onUpdate: (data) async {
                // Încercăm să salvăm setările de notificări
                // Dacă coloanele nu există în Supabase, va apărea eroarea exactă în consolă/SnackBar
                try {
                  final userId = SupabaseService.instance.client.auth.currentUser?.id;
                  if (userId == null) return;

                  debugPrint('Saving notifications for user $userId: $data');

                  await SupabaseService.instance.client
                      .from('user_profiles')
                      .update({
                        'workout_reminders': data['workoutReminders'],
                        'progress_updates': data['progressUpdates'],
                        'motivational_messages': data['motivationalMessages'],
                      })
                      .eq('id', userId);

                  await _loadUserProfile();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Setările de notificări au fost salvate!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  // Logăm eroarea completă în consolă pentru debugging
                  debugPrint('Supabase Error saving notifications: $e');
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Eroare Supabase: $e'), 
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              },
            ),
            SizedBox(height: 2.h),

            // Recalibrate Button
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Navigate to Onboarding Survey in Edit Mode
                  // We need to import the widget first if not imported, but it is likely in a different file.
                  // We will use a MaterialPageRoute for direct navigation or a named route if set up.
                  // Since OnboardingSurveyWidget is in authentication_onboarding_flow keys, let's verify imports.
                  // Assuming we can import it or use a route.
                  // Using direct navigation for now as it's cleaner for passing data
                  
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OnboardingSurveyWidget( // This requires import
                        isEditing: true,
                        initialData: _userProfile,
                      ),
                    ),
                  );

                  if (result == true) {
                    _loadUserProfile(); // Refresh profile if updated
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Recalibrează Planul AI'),
              ),
            ),
            SizedBox(height: 2.h),

            const AccountManagementSectionWidget(),
          ],
        ),
      ),
    );
  }
}
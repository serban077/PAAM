import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Fitness Preferences Section Widget
/// Allows modification of workout frequency, session duration, equipment, and goals
class FitnessPreferencesSectionWidget extends StatefulWidget {
  final int workoutFrequency;
  final int sessionDuration;
  final List<String> availableEquipment;
  final String fitnessGoal;
  final Function(Map<String, dynamic>) onUpdate;

  const FitnessPreferencesSectionWidget({
    super.key,
    required this.workoutFrequency,
    required this.sessionDuration,
    required this.availableEquipment,
    required this.fitnessGoal,
    required this.onUpdate,
  });

  @override
  State<FitnessPreferencesSectionWidget> createState() =>
      _FitnessPreferencesSectionWidgetState();
}

class _FitnessPreferencesSectionWidgetState
    extends State<FitnessPreferencesSectionWidget> {
  bool _isExpanded = false;
  late int _workoutFrequency;
  late int _sessionDuration;
  late List<String> _selectedEquipment;
  late String _selectedGoal;

  final List<String> _equipmentOptions = [
    "Gantere",
    "Bandă de alergare",
    "Bicicletă staționară",
    "Bare de tracțiuni",
    "Saltea de yoga",
    "Benzi de rezistență",
  ];

  final List<String> _goalOptions = [
    "Pierdere în greutate",
    "Creștere musculară",
    "Rezistență",
    "Recompunere corporală",
  ];

  // Map DB values to Display values for Goals
  final Map<String, String> _dbGoalToDisplay = {
    'pierdere_greutate': 'Pierdere în greutate',
    'crestere_masa_musculara': 'Creștere musculară', // Changed from crestere_musculara
    'mentinere': 'Rezistență', // Mapped mentinere to Rezistenta (closest) or should allow 'Mentinere'
    'tonifiere': 'Recompunere corporală', // Mapped tonifiere to Recompunere
  };

  // Map Display values to DB values for Goals
  final Map<String, String> _displayGoalToDb = {
    'Pierdere în greutate': 'pierdere_greutate',
    'Creștere musculară': 'crestere_masa_musculara',
    'Rezistență': 'mentinere',
    'Recompunere corporală': 'tonifiere',
  };

  @override
  void initState() {
    super.initState();
    _workoutFrequency = widget.workoutFrequency;
    _sessionDuration = widget.sessionDuration;
    _selectedEquipment = List.from(widget.availableEquipment);
    
    // Map goal to display value - try both English and potential fallback
    _selectedGoal = _dbGoalToDisplay[widget.fitnessGoal] ?? 
                   (widget.fitnessGoal == 'recompunere_corporala' ? 'Recompunere corporală' : "Recompunere corporală");
  }

  void _handleSave() {
    if (_selectedEquipment.isEmpty) {
      _showValidationError('Selectați cel puțin un echipament');
      return;
    }

    widget.onUpdate({
      'workoutFrequency': _workoutFrequency,
      'sessionDuration': _sessionDuration,
      'availableEquipment': _selectedEquipment,
      'fitnessGoal': _displayGoalToDb[_selectedGoal] ?? 'body_recomposition',
    });

    setState(() {
      _isExpanded = false;
    });
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: 'fitness_center',
                      color: theme.colorScheme.secondary,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preferințe Fitness',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          '$_workoutFrequency zile/săptămână • $_sessionDuration min/sesiune',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CustomIconWidget(
                    iconName: _isExpanded ? 'expand_less' : 'expand_more',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          _isExpanded
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Divider(height: 1, color: theme.colorScheme.outline),
                    Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Workout Frequency Slider
                          Text(
                            'Frecvență Antrenament',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _workoutFrequency.toDouble(),
                                  min: 2,
                                  max: 7,
                                  divisions: 5,
                                  label: '$_workoutFrequency zile',
                                  onChanged: (value) {
                                    setState(() {
                                      _workoutFrequency = value.toInt();
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                '$_workoutFrequency',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),

                          // Session Duration Slider
                          Text(
                            'Durată Sesiune',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _sessionDuration.toDouble(),
                                  min: 30,
                                  max: 120,
                                  divisions: 9,
                                  label: '$_sessionDuration min',
                                  onChanged: (value) {
                                    setState(() {
                                      _sessionDuration = value.toInt();
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                '$_sessionDuration',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),

                          // Equipment Selection
                          Text(
                            'Echipament Disponibil',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Wrap(
                            spacing: 2.w,
                            runSpacing: 1.h,
                            children: _equipmentOptions.map((equipment) {
                              final isSelected = _selectedEquipment.contains(
                                equipment,
                              );
                              return FilterChip(
                                label: Text(equipment),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    selected
                                        ? _selectedEquipment.add(equipment)
                                        : _selectedEquipment.remove(equipment);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 2.h),

                          // Fitness Goal Dropdown
                          Text(
                            'Obiectiv Fitness',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedGoal,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 4.w,
                                vertical: 1.5.h,
                              ),
                            ),
                            items: _goalOptions.map((goal) {
                              return DropdownMenuItem(
                                value: goal,
                                child: Text(goal),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedGoal = value;
                                });
                              }
                            },
                          ),
                          SizedBox(height: 3.h),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _handleSave,
                              child: Text('Salvează Modificările'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}

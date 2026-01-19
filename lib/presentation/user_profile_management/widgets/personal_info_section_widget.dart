import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Personal Information Section Widget
/// Displays and allows editing of user's personal information
class PersonalInfoSectionWidget extends StatefulWidget {
  final int age;
  final double weight;
  final double height;
  final double? targetWeight;
  final int? targetTimeframeWeeks;
  final String activityLevel;
  final Function(Map<String, dynamic>) onUpdate;

  const PersonalInfoSectionWidget({
    super.key,
    required this.age,
    required this.weight,
    required this.height,
    this.targetWeight,
    this.targetTimeframeWeeks,
    required this.activityLevel,
    required this.onUpdate,
  });

  @override
  State<PersonalInfoSectionWidget> createState() =>
      _PersonalInfoSectionWidgetState();
}

class _PersonalInfoSectionWidgetState extends State<PersonalInfoSectionWidget> {
  bool _isExpanded = false;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _targetWeightController;
  late TextEditingController _targetTimeframeController;
  String _selectedActivityLevel = "Moderat Activ";

  final List<String> _activityLevels = [
    "Sedentar",
    "Ușor Activ",
    "Moderat Activ",
    "Foarte Activ",
    "Extrem de Activ",
  ];

  // Map DB values to Display values
  final Map<String, String> _dbToDisplay = {
    'sedentar': 'Sedentar',
    'usor_activ': 'Ușor Activ',
    'moderat_activ': 'Moderat Activ',
    'foarte_activ': 'Foarte Activ',
    'extrem_activ': 'Extrem de Activ',
  };

  // Map Display values to DB values
  final Map<String, String> _displayToDb = {
    'Sedentar': 'sedentar',
    'Ușor Activ': 'usor_activ',
    'Moderat Activ': 'moderat_activ',
    'Foarte Activ': 'foarte_activ',
    'Extrem de Activ': 'extrem_activ',
  };

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(text: widget.age.toString());
    _weightController = TextEditingController(
      text: widget.weight.toStringAsFixed(1),
    );
    _heightController = TextEditingController(
      text: widget.height.toStringAsFixed(0),
    );
    _targetWeightController = TextEditingController(
      text: widget.targetWeight?.toStringAsFixed(1) ?? '',
    );
    _targetTimeframeController = TextEditingController(
      text: widget.targetTimeframeWeeks?.toString() ?? '12',
    );
    // Convert DB value to Display value, default to "Moderat Activ" if not found
    _selectedActivityLevel = _dbToDisplay[widget.activityLevel] ?? "Moderat Activ";
  }

  @override
  void didUpdateWidget(PersonalInfoSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controllers when widget data changes (after profile reload)
    bool needsRebuild = false;
    
    if (oldWidget.weight != widget.weight) {
      _weightController.text = widget.weight.toStringAsFixed(1);
      needsRebuild = true;
    }
    if (oldWidget.height != widget.height) {
      _heightController.text = widget.height.toStringAsFixed(0);
      needsRebuild = true;
    }
    if (oldWidget.age != widget.age) {
      _ageController.text = widget.age.toString();
      needsRebuild = true;
    }
    if (oldWidget.targetWeight != widget.targetWeight) {
      _targetWeightController.text = widget.targetWeight?.toStringAsFixed(1) ?? '';
      needsRebuild = true;
    }
    if (oldWidget.targetTimeframeWeeks != widget.targetTimeframeWeeks) {
      _targetTimeframeController.text = widget.targetTimeframeWeeks?.toString() ?? '12';
      needsRebuild = true;
    }
    if (oldWidget.activityLevel != widget.activityLevel) {
      _selectedActivityLevel = _dbToDisplay[widget.activityLevel] ?? "Moderat Activ";
      needsRebuild = true;
    }
    
    // Force rebuild to update header display
    if (needsRebuild && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _targetWeightController.dispose();
    _targetTimeframeController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final age = int.tryParse(_ageController.text) ?? widget.age;
    final weight = double.tryParse(_weightController.text) ?? widget.weight;
    final height = double.tryParse(_heightController.text) ?? widget.height;
    final targetWeight = double.tryParse(_targetWeightController.text);
    final targetTimeframe = int.tryParse(_targetTimeframeController.text) ?? 12;

    if (age < 18 || age > 100) {
      _showValidationError('Vârsta trebuie să fie între 18 și 100 de ani');
      return;
    }

    if (weight < 40 || weight > 200) {
      _showValidationError('Greutatea trebuie să fie între 40 și 200 kg');
      return;
    }

    if (targetWeight != null && (targetWeight < 40 || targetWeight > 200)) {
      _showValidationError('Greutatea țintă trebuie să fie între 40 și 200 kg');
      return;
    }

    if (targetTimeframe < 1 || targetTimeframe > 104) {
      _showValidationError('Perioada trebuie să fie între 1 și 104 săptămâni');
      return;
    }

    if (height < 140 || height > 220) {
      _showValidationError('Înălțimea trebuie să fie între 140 și 220 cm');
      return;
    }

    widget.onUpdate({
      'age': age,
      'weight': weight,
      'height': height,
      'targetWeight': targetWeight,
      'targetTimeframeWeeks': targetTimeframe,
      'activityLevel': _displayToDb[_selectedActivityLevel] ?? 'moderat_activ',
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
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: 'person',
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informații Personale',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          '${_ageController.text} ani • ${_weightController.text} kg • ${_heightController.text} cm',
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
                        children: [
                          // Age Field
                          _buildTextField(
                            controller: _ageController,
                            label: 'Vârstă',
                            suffix: 'ani',
                            keyboardType: TextInputType.number,
                            theme: theme,
                          ),
                          SizedBox(height: 2.h),

                          // Weight Field
                          _buildTextField(
                            controller: _weightController,
                            label: 'Greutate',
                            suffix: 'kg',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            theme: theme,
                          ),
                          SizedBox(height: 2.h),

                          // Height Field
                          _buildTextField(
                            controller: _heightController,
                            label: 'Înălțime',
                            suffix: 'cm',
                            keyboardType: TextInputType.number,
                            theme: theme,
                          ),
                          SizedBox(height: 2.h),

                          // Target Weight Field
                          _buildTextField(
                            controller: _targetWeightController,
                            label: 'Greutate Țintă (opțional)',
                            suffix: 'kg',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            theme: theme,
                          ),
                          SizedBox(height: 2.h),

                          // Target Timeframe Field
                          _buildTextField(
                            controller: _targetTimeframeController,
                            label: 'Perioadă Obiectiv',
                            suffix: 'săptămâni',
                            keyboardType: TextInputType.number,
                            theme: theme,
                          ),
                          SizedBox(height: 2.h),

                          // Activity Level Dropdown
                          _buildActivityLevelDropdown(theme),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required TextInputType keyboardType,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 1.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: keyboardType == TextInputType.number
              ? [FilteringTextInputFormatter.digitsOnly]
              : [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))],
          decoration: InputDecoration(
            suffixText: suffix,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 4.w,
              vertical: 1.5.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityLevelDropdown(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nivel de Activitate',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 1.h),
        DropdownButtonFormField<String>(
          initialValue: _selectedActivityLevel,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 4.w,
              vertical: 1.5.h,
            ),
          ),
          items: _activityLevels.map((level) {
            return DropdownMenuItem(value: level, child: Text(level));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedActivityLevel = value;
              });
            }
          },
        ),
      ],
    );
  }
}

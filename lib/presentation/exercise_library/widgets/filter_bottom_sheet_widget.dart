import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class FilterBottomSheetWidget extends StatefulWidget {
  final Map<String, List<String>> activeFilters;
  final Function(Map<String, List<String>>) onApplyFilters;

  const FilterBottomSheetWidget({
    super.key,
    required this.activeFilters,
    required this.onApplyFilters,
  });

  @override
  State<FilterBottomSheetWidget> createState() =>
      _FilterBottomSheetWidgetState();
}

class _FilterBottomSheetWidgetState extends State<FilterBottomSheetWidget> {
  late Map<String, List<String>> _tempFilters;
  final Map<String, bool> _expandedSections = {
    'bodyPart': true,
    'equipment': false,
    'difficulty': false,
    'restrictions': false,
  };

  final Map<String, List<String>> _filterOptions = {
    'bodyPart': ['Piept', 'Spate', 'Picioare', 'Umeri', 'Brațe', 'Abdomen'],
    'equipment': [
      'Bară',
      'Gantere',
      'Mașină',
      'Cablu',
      'Greutate Corporală',
      'Bară Tracțiuni',
      'Paralele',
    ],
    'difficulty': ['Începător', 'Intermediar', 'Avansat'],
    'restrictions': [
      'Probleme Cardiovasculare',
      'Diabet',
      'Probleme Articulare',
    ],
  };

  final Map<String, String> _sectionTitles = {
    'bodyPart': 'Partea Corpului',
    'equipment': 'Echipament',
    'difficulty': 'Dificultate',
    'restrictions': 'Restricții Medicale',
  };

  @override
  void initState() {
    super.initState();
    _tempFilters = Map.from(
      widget.activeFilters.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      ),
    );
  }

  void _toggleFilter(String category, String value) {
    setState(() {
      if (_tempFilters[category]!.contains(value)) {
        _tempFilters[category]!.remove(value);
      } else {
        _tempFilters[category]!.add(value);
      }
    });
  }

  void _clearAllFilters() {
    setState(() {
      _tempFilters = {
        'bodyPart': [],
        'equipment': [],
        'difficulty': [],
        'restrictions': [],
      };
    });
  }

  void _applyFilters() {
    widget.onApplyFilters(_tempFilters);
    Navigator.pop(context);
  }

  int _getTotalSelectedFilters() {
    return _tempFilters.values.fold(0, (sum, list) => sum + list.length);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtre',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    if (_getTotalSelectedFilters() > 0)
                      TextButton(
                        onPressed: _clearAllFilters,
                        child: Text(
                          'Șterge tot',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: CustomIconWidget(
                        iconName: 'close',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Column(
                children: _filterOptions.keys.map((category) {
                  return _buildFilterSection(
                    category,
                    _sectionTitles[category]!,
                    _filterOptions[category]!,
                    theme,
                  );
                }).toList(),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  child: Text(
                    _getTotalSelectedFilters() > 0
                        ? 'Aplică Filtre (${_getTotalSelectedFilters()})'
                        : 'Aplică Filtre',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    String category,
    String title,
    List<String> options,
    ThemeData theme,
  ) {
    final isExpanded = _expandedSections[category] ?? false;
    final selectedCount = _tempFilters[category]!.length;

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedSections[category] = !isExpanded;
            });
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 1.5.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (selectedCount > 0) ...[
                      SizedBox(width: 2.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          selectedCount.toString(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                CustomIconWidget(
                  iconName: isExpanded ? 'expand_less' : 'expand_more',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: options.map((option) {
              final isSelected = _tempFilters[category]!.contains(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (_) => _toggleFilter(category, option),
                selectedColor: theme.colorScheme.primaryContainer,
                checkmarkColor: theme.colorScheme.primary,
                labelStyle: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              );
            }).toList(),
          ),
        Divider(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          height: 2.h,
        ),
      ],
    );
  }
}

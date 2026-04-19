import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sizer/sizer.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/app_export.dart';
import '../../../data/verified_exercises_data.dart';
import '../../../utils/exercise_gif_utils.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/exercise_card_widget.dart';
import './widgets/exercise_detail_sheet.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/filter_chip_widget.dart';

class ExerciseLibrary extends StatefulWidget {
  const ExerciseLibrary({super.key});

  @override
  State<ExerciseLibrary> createState() => _ExerciseLibraryState();
}

class _ExerciseLibraryState extends State<ExerciseLibrary> {
  static const Map<String, dynamic> _dummyExercise = {
    'name': 'Exercise Name Placeholder',
    'bodyPart': 'Chest',
    'targetMuscles': 'Pectorals, Triceps',
    'equipment': 'Barbell',
    'difficulty': 'Beginner',
    'image': null,
  };

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _exercises = [];
  List<Map<String, dynamic>> _filteredExercises = [];
  Map<String, List<String>> _activeFilters = {
    'bodyPart': [],
    'equipment': [],
    'difficulty': [],
    'restrictions': [],
  };
  String _selectedCategory = 'All';

  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  final int _itemsPerPage = 20;

  static const List<Map<String, String>> _categories = [
    {'label': 'All',         'icon': 'apps'},
    {'label': 'Chest',       'icon': 'fitness_center'},
    {'label': 'Back',        'icon': 'accessibility_new'},
    {'label': 'Legs',        'icon': 'directions_run'},
    {'label': 'Glutes',      'icon': 'airline_seat_recline_extra'},
    {'label': 'Calves',      'icon': 'directions_walk'},
    {'label': 'Shoulders',   'icon': 'sports'},
    {'label': 'Arms',        'icon': 'pan_tool'},
    {'label': 'Forearms',    'icon': 'back_hand'},
    {'label': 'Abs',         'icon': 'adjust'},
    {'label': 'Full Body',   'icon': 'boy'},
    {'label': 'Stretching',  'icon': 'self_improvement'},
    {'label': 'Plyometrics', 'icon': 'flash_on'},
    {'label': 'Cardio',      'icon': 'favorite'},
  ];

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore) {
      _loadMoreExercises();
    }
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    // Short delay so the shimmer skeleton is visible for a polished feel
    await Future.delayed(const Duration(milliseconds: 350));
    final exercises = VerifiedExercisesData.getAllExercises();
    setState(() {
      _exercises = exercises;
      _filteredExercises = exercises.take(_itemsPerPage).toList();
      _currentPage = 1;
      _isLoading = false;
    });
    // Warm the image cache for the first visible exercises
    if (mounted) {
      for (final ex in _filteredExercises.take(10)) {
        final url = ExerciseGifUtils.getFrame0Url(ex['name'] as String? ?? '');
        if (url != null) precacheImage(NetworkImage(url), context);
      }
    }
  }

  Future<void> _loadMoreExercises() async {
    if (_isLoadingMore || _filteredExercises.length >= _exercises.length) {
      return;
    }
    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(milliseconds: 300));
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _exercises.length);
    setState(() {
      _filteredExercises.addAll(_exercises.sublist(startIndex, endIndex));
      _currentPage++;
      _isLoadingMore = false;
    });
  }

  Future<void> _refreshExercises() async {
    HapticFeedback.mediumImpact();
    // Force a clean reload from the static database
    setState(() {
      _exercises = [];
      _filteredExercises = [];
      _currentPage = 0;
    });
    await _loadExercises();
  }

  void _applyFilters() {
    setState(() {
      _filteredExercises = _exercises.where((exercise) {
        // Category chip filter (independent from modal bodyPart filter)
        if (_selectedCategory != 'All' &&
            exercise['bodyPart'] != _selectedCategory) {
          return false;
        }
        if (_activeFilters['bodyPart']!.isNotEmpty &&
            !_activeFilters['bodyPart']!.contains(exercise['bodyPart'])) {
          return false;
        }
        if (_activeFilters['equipment']!.isNotEmpty &&
            !_activeFilters['equipment']!.contains(exercise['equipment'])) {
          return false;
        }
        if (_activeFilters['difficulty']!.isNotEmpty &&
            !_activeFilters['difficulty']!.contains(exercise['difficulty'])) {
          return false;
        }
        if (_activeFilters['restrictions']!.isNotEmpty) {
          for (var restriction in _activeFilters['restrictions']!) {
            if ((exercise['restrictions'] as List).contains(restriction)) {
              return false;
            }
          }
        }
        final searchQuery = _searchController.text.toLowerCase();
        if (searchQuery.isNotEmpty) {
          return exercise['name']
                  .toString()
                  .toLowerCase()
                  .contains(searchQuery) ||
              exercise['targetMuscles']
                  .toString()
                  .toLowerCase()
                  .contains(searchQuery);
        }
        return true;
      }).toList();

      _currentPage = 0;
      _filteredExercises = _filteredExercises.take(_itemsPerPage).toList();
      _currentPage = 1;
    });
  }

  void _onCategoryTap(String category) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCategory = category;
      _applyFilters();
    });
  }

  void _removeFilter(String category, String value) {
    setState(() {
      _activeFilters[category]!.remove(value);
      _applyFilters();
    });
  }

  void _clearAllFilters() {
    setState(() {
      _activeFilters = {
        'bodyPart': [],
        'equipment': [],
        'difficulty': [],
        'restrictions': [],
      };
      _selectedCategory = 'All';
      _searchController.clear();
      _applyFilters();
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheetWidget(
        activeFilters: _activeFilters,
        onApplyFilters: (filters) {
          setState(() {
            _activeFilters = filters;
            _applyFilters();
          });
        },
      ),
    );
  }

  void _onExerciseTap(Map<String, dynamic> exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseDetailSheet(exercise: exercise),
    );
  }

  void _onExerciseLongPress(Map<String, dynamic> exercise) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildQuickActionsSheet(exercise),
    );
  }

  Widget _buildQuickActionsSheet(Map<String, dynamic> exercise) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withAlpha(50),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            exercise['name'],
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'favorite_border',
              color: theme.colorScheme.primary,
              size: 24,
            ),
            title: Text('Add to Favorites', style: theme.textTheme.bodyLarge),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${exercise['name']} added to favorites'),
                ),
              );
            },
          ),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'add_circle_outline',
              color: theme.colorScheme.primary,
              size: 24,
            ),
            title:
                Text('Add to Workout', style: theme.textTheme.bodyLarge),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${exercise['name']} added to workout'),
                ),
              );
            },
          ),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'share',
              color: theme.colorScheme.primary,
              size: 24,
            ),
            title:
                Text('Share Exercise', style: theme.textTheme.bodyLarge),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share feature coming soon'),
                ),
              );
            },
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  int _getTotalActiveFilters() {
    return _activeFilters.values.fold(0, (sum, list) => sum + list.length);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── Search + Filter bar ──
        Container(
          padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 1.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 6.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => _applyFilters(),
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Search exercises...',
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant
                              .withAlpha(153),
                        ),
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(1.5.w),
                          child: CustomIconWidget(
                            iconName: 'search',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: CustomIconWidget(
                                  iconName: 'clear',
                                  color:
                                      theme.colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _applyFilters();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 1.5.h,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Container(
                  height: 6.h,
                  width: 6.h,
                  decoration: BoxDecoration(
                    color: _getTotalActiveFilters() > 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getTotalActiveFilters() > 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      IconButton(
                        icon: CustomIconWidget(
                          iconName: 'filter_list',
                          color: _getTotalActiveFilters() > 0
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                        onPressed: _showFilterBottomSheet,
                      ),
                      if (_getTotalActiveFilters() > 0)
                        Positioned(
                          right: 1.w,
                          top: 1.w,
                          child: Container(
                            padding: EdgeInsets.all(0.5.w),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: BoxConstraints(
                              minWidth: 4.w,
                              minHeight: 4.w,
                            ),
                            child: Center(
                              child: Text(
                                _getTotalActiveFilters().toString(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onError,
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Category chip bar ──
        _buildCategoryBar(theme),

        // ── Active filter chips (from modal) ──
        if (_getTotalActiveFilters() > 0)
          Container(
            height: 6.h,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._activeFilters.entries.expand((entry) {
                  return entry.value.map(
                    (value) => FilterChipWidget(
                      label: value,
                      onDeleted: () => _removeFilter(entry.key, value),
                    ),
                  );
                }),
                if (_getTotalActiveFilters() > 1)
                  Padding(
                    padding: EdgeInsets.only(left: 2.w),
                    child: ActionChip(
                      label: Text(
                        'Clear All',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      onPressed: _clearAllFilters,
                      backgroundColor: theme.colorScheme.errorContainer,
                      side: BorderSide.none,
                    ),
                  ),
              ],
            ),
          ),

        // ── Results count ──
        Padding(
          padding: EdgeInsets.fromLTRB(4.w, 1.2.h, 4.w, 0.4.h),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_filteredExercises.length} exercises',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        // ── Exercise list ──
        Expanded(
          child: _isLoading
              ? _buildLoadingState()
              : _filteredExercises.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _refreshExercises,
                  child: ListView.builder(
                    controller: _scrollController,
                    cacheExtent: 500,
                    padding: EdgeInsets.only(top: 0.5.h, bottom: 10.h),
                    itemCount: _filteredExercises.length +
                        (_isLoadingMore ? 3 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _filteredExercises.length) {
                        return Skeletonizer(
                          enabled: true,
                          child: ExerciseCardWidget(
                            exercise: _dummyExercise,
                            onTap: () {},
                            onLongPress: () {},
                          ),
                        );
                      }
                      return ExerciseCardWidget(
                        exercise: _filteredExercises[index],
                        onTap: () =>
                            _onExerciseTap(_filteredExercises[index]),
                        onLongPress: () => _onExerciseLongPress(
                            _filteredExercises[index]),
                      )
                          .animate(
                            delay: Duration(
                                milliseconds: (index % 10) * 40),
                          )
                          .fade(duration: 300.ms)
                          .slideY(
                            begin: 0.08,
                            end: 0,
                            duration: 300.ms,
                            curve: Curves.easeOut,
                          );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryBar(ThemeData theme) {
    return Container(
      height: 6.5.h,
      color: theme.colorScheme.surface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => SizedBox(width: 2.w),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat['label'];
          return GestureDetector(
            onTap: () => _onCategoryTap(cat['label']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                horizontal: 3.w,
                vertical: 0.5.h,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: cat['icon']!,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 14,
                  ),
                  SizedBox(width: 1.5.w),
                  Text(
                    cat['label']!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: EdgeInsets.only(top: 0.5.h, bottom: 4.h),
      itemCount: 6,
      itemBuilder: (context, index) => Skeletonizer(
        enabled: true,
        child: ExerciseCardWidget(
          exercise: _dummyExercise,
          onTap: () {},
          onLongPress: () {},
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'search_off',
              color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
              size: 80,
            ),
            SizedBox(height: 2.h),
            Text(
              'No exercises found',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              _getTotalActiveFilters() > 0 || _selectedCategory != 'All'
                  ? 'Try removing some filters to see more results'
                  : 'Try a different search term',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withAlpha(178),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            if (_getTotalActiveFilters() > 0 || _selectedCategory != 'All')
              ElevatedButton.icon(
                onPressed: _clearAllFilters,
                icon: CustomIconWidget(
                  iconName: 'clear_all',
                  color: theme.colorScheme.onPrimary,
                  size: 20,
                ),
                label: const Text('Clear Filters'),
              ),
          ],
        ),
      ),
    );
  }

}

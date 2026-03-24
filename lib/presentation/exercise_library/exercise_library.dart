import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
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

  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  final int _itemsPerPage = 20;

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

    await Future.delayed(const Duration(milliseconds: 500));

    final exercises = _generateMockExercises();
    setState(() {
      _exercises = exercises;
      _filteredExercises = exercises.take(_itemsPerPage).toList();
      _currentPage = 1;
      _isLoading = false;
    });
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
    await _loadExercises();
  }

  void _applyFilters() {
    setState(() {
      _filteredExercises = _exercises.where((exercise) {
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
          return exercise['name'].toString().toLowerCase().contains(
                searchQuery,
              ) ||
              exercise['targetMuscles'].toString().toLowerCase().contains(
                searchQuery,
              );
        }

        return true;
      }).toList();

      _currentPage = 0;
      _filteredExercises = _filteredExercises.take(_itemsPerPage).toList();
      _currentPage = 1;
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
            title: Text(
              'Add to Workout',
              style: theme.textTheme.bodyLarge,
            ),
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
            title: Text(
              'Share Exercise',
              style: theme.textTheme.bodyLarge,
            ),
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
                          color: theme.colorScheme.onSurfaceVariant.withAlpha(153),
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
                                  color: theme.colorScheme.onSurfaceVariant,
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
                      _getTotalActiveFilters() > 0
                          ? Positioned(
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
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _getTotalActiveFilters() > 0
            ? Container(
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
              )
            : const SizedBox.shrink(),
        Expanded(
          child: _isLoading
              ? _buildLoadingState()
              : _filteredExercises.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _refreshExercises,
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(4.w),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 3.w,
                      mainAxisSpacing: 3.w,
                    ),
                    itemCount:
                        _filteredExercises.length + (_isLoadingMore ? 2 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _filteredExercises.length) {
                        return _buildSkeletonCard();
                      }
                      return ExerciseCardWidget(
                        exercise: _filteredExercises[index],
                        onTap: () => _onExerciseTap(_filteredExercises[index]),
                        onLongPress: () =>
                            _onExerciseLongPress(_filteredExercises[index]),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      padding: EdgeInsets.all(4.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 3.w,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha(51),
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 20.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(76),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 2.h,
                    width: 30.w,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withAlpha(76),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Container(
                    height: 1.5.h,
                    width: 20.w,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withAlpha(76),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
              _getTotalActiveFilters() > 0
                  ? 'Try removing some filters to see more results'
                  : 'Try a different search term',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withAlpha(178),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            if (_getTotalActiveFilters() > 0)
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

  List<Map<String, dynamic>> _generateMockExercises() {
    return [
      {
        "id": 1,
        "name": "Barbell Squat",
        "bodyPart": "Legs",
        "targetMuscles": "Quadriceps, Glutes, Hamstrings",
        "equipment": "Barbell",
        "difficulty": "Intermediate",
        "videoId": "U3HlEF_E9fo",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_11751f112-1764780890698.png",
        "semanticLabel": "Person performing barbell squat in gym",
        "restrictions": [],
      },
      {
        "id": 2,
        "name": "Bench Press",
        "bodyPart": "Chest",
        "targetMuscles": "Pectorals, Triceps, Anterior Deltoid",
        "equipment": "Barbell",
        "difficulty": "Intermediate",
        "videoId": "rT7DgCr-3pg",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_157fe155b-1767766857700.png",
        "semanticLabel": "Athlete performing bench press with barbell",
        "restrictions": [],
      },
      {
        "id": 3,
        "name": "Deadlift",
        "bodyPart": "Back",
        "targetMuscles": "Lower Back, Glutes, Hamstrings",
        "equipment": "Barbell",
        "difficulty": "Advanced",
        "videoId": "op9kVnSso6Q",
        "image": "https://images.unsplash.com/photo-1674748596342-8fd299450a71",
        "semanticLabel": "Athlete lifting heavy barbell in deadlift position",
        "restrictions": ["Cardiovascular Issues"],
      },
      {
        "id": 4,
        "name": "Push-Ups",
        "bodyPart": "Chest",
        "targetMuscles": "Pectorals, Triceps, Shoulders",
        "equipment": "Bodyweight",
        "difficulty": "Beginner",
        "videoId": "IODxDxX7oi4",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_188114a93-1766957011899.png",
        "semanticLabel": "Person performing push-ups on yoga mat",
        "restrictions": [],
      },
      {
        "id": 5,
        "name": "Pull-Ups",
        "bodyPart": "Back",
        "targetMuscles": "Latissimus Dorsi, Biceps",
        "equipment": "Pull-up Bar",
        "difficulty": "Intermediate",
        "videoId": "eGo4IYlbE5g",
        "image": "https://images.unsplash.com/photo-1646743934945-df7b66e28b7d",
        "semanticLabel": "Athlete performing pull-ups on bar in park",
        "restrictions": ["Joint Issues"],
      },
      {
        "id": 6,
        "name": "Dumbbell Shoulder Press",
        "bodyPart": "Shoulders",
        "targetMuscles": "Deltoids, Triceps",
        "equipment": "Dumbbells",
        "difficulty": "Intermediate",
        "videoId": "qEwKCR5JCog",
        "image": "https://images.unsplash.com/photo-1639653818637-d061a28959ad",
        "semanticLabel": "Athlete pressing dumbbells overhead",
        "restrictions": [],
      },
      {
        "id": 7,
        "name": "Lunges",
        "bodyPart": "Legs",
        "targetMuscles": "Quadriceps, Glutes",
        "equipment": "Bodyweight",
        "difficulty": "Beginner",
        "videoId": "L8fvwPVQovQ",
        "image": "https://images.unsplash.com/photo-1732127836278-edb32d6e5044",
        "semanticLabel": "Person performing lunges in fitness studio",
        "restrictions": ["Joint Issues"],
      },
      {
        "id": 8,
        "name": "Barbell Bicep Curl",
        "bodyPart": "Arms",
        "targetMuscles": "Biceps",
        "equipment": "Barbell",
        "difficulty": "Beginner",
        "videoId": "ykJmrZ5v0Oo",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_1498d38fc-1766707658426.png",
        "semanticLabel": "Athlete performing bicep curl with EZ bar",
        "restrictions": [],
      },
      {
        "id": 9,
        "name": "Plank",
        "bodyPart": "Core",
        "targetMuscles": "Core, Abs, Shoulders",
        "equipment": "Bodyweight",
        "difficulty": "Beginner",
        "videoId": "pSHjTRCQxIw",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_128b7af95-1766522935960.png",
        "semanticLabel": "Person holding plank position on mat",
        "restrictions": [],
      },
      {
        "id": 10,
        "name": "Tricep Pushdown",
        "bodyPart": "Arms",
        "targetMuscles": "Triceps",
        "equipment": "Cable",
        "difficulty": "Beginner",
        "videoId": "2-LAMcpzODU",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_13f7b5f5c-1767766857617.png",
        "semanticLabel": "Athlete performing tricep pushdown at cable machine",
        "restrictions": [],
      },
      {
        "id": 11,
        "name": "Barbell Row",
        "bodyPart": "Back",
        "targetMuscles": "Latissimus Dorsi, Trapezius, Rhomboids",
        "equipment": "Barbell",
        "difficulty": "Intermediate",
        "videoId": "G8l_8chR5BE",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_1d6fb5c8f-1764636197383.png",
        "semanticLabel": "Athlete performing bent-over barbell row",
        "restrictions": [],
      },
      {
        "id": 12,
        "name": "Leg Press",
        "bodyPart": "Legs",
        "targetMuscles": "Quadriceps, Glutes",
        "equipment": "Machine",
        "difficulty": "Beginner",
        "videoId": "IZxyjW7MPJQ",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_1d21818c8-1764678265894.png",
        "semanticLabel": "Person using leg press machine in gym",
        "restrictions": ["Cardiovascular Issues"],
      },
      {
        "id": 13,
        "name": "Lateral Raises",
        "bodyPart": "Shoulders",
        "targetMuscles": "Lateral Deltoids",
        "equipment": "Dumbbells",
        "difficulty": "Beginner",
        "videoId": "3VcKaXpzqRo",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_16dcdcec5-1767041840073.png",
        "semanticLabel": "Athlete performing lateral raises with dumbbells",
        "restrictions": [],
      },
      {
        "id": 14,
        "name": "Crunch",
        "bodyPart": "Core",
        "targetMuscles": "Abs",
        "equipment": "Bodyweight",
        "difficulty": "Beginner",
        "videoId": "Xyd_fa5zoEU",
        "image":
            "https://images.unsplash.com/photo-1593204108461-60094c677448",
        "semanticLabel": "Person performing crunches on yoga mat",
        "restrictions": [],
      },
      {
        "id": 15,
        "name": "Hammer Curl",
        "bodyPart": "Arms",
        "targetMuscles": "Biceps, Forearms",
        "equipment": "Dumbbells",
        "difficulty": "Beginner",
        "videoId": "zC3nLlEvin4",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_1498d38fc-1766707658426.png",
        "semanticLabel": "Athlete performing hammer curls with dumbbells",
        "restrictions": [],
      },
      {
        "id": 16,
        "name": "Dumbbell Chest Press",
        "bodyPart": "Chest",
        "targetMuscles": "Pectorals, Triceps",
        "equipment": "Dumbbells",
        "difficulty": "Intermediate",
        "videoId": "8iPEnn-ltC8",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_157fe155b-1767766857700.png",
        "semanticLabel": "Athlete performing dumbbell chest press on bench",
        "restrictions": [],
      },
      {
        "id": 17,
        "name": "Bulgarian Split Squat",
        "bodyPart": "Legs",
        "targetMuscles": "Quadriceps, Glutes",
        "equipment": "Dumbbells",
        "difficulty": "Intermediate",
        "videoId": "2C-uNgKwPLE",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_1547b077e-1764914416872.png",
        "semanticLabel":
            "Person performing Bulgarian split squat with rear foot elevated",
        "restrictions": ["Joint Issues"],
      },
      {
        "id": 18,
        "name": "Face Pull",
        "bodyPart": "Back",
        "targetMuscles": "Rear Deltoids, Trapezius, Rotator Cuff",
        "equipment": "Cable",
        "difficulty": "Intermediate",
        "videoId": "HSoHeSt2o7A",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_18811f704-1767016553350.png",
        "semanticLabel": "Athlete performing face pull at cable machine",
        "restrictions": [],
      },
      {
        "id": 19,
        "name": "Dips",
        "bodyPart": "Chest",
        "targetMuscles": "Pectorals, Triceps",
        "equipment": "Parallel Bars",
        "difficulty": "Intermediate",
        "videoId": "2z8JmcrW-As",
        "image": "https://images.unsplash.com/photo-1666961184601-9088aab7bd75",
        "semanticLabel": "Athlete performing dips on parallel bars",
        "restrictions": ["Joint Issues"],
      },
      {
        "id": 20,
        "name": "Leg Curl",
        "bodyPart": "Legs",
        "targetMuscles": "Hamstrings",
        "equipment": "Machine",
        "difficulty": "Beginner",
        "videoId": "Orxoeast-AF",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_1b08e5e60-1766503707279.png",
        "semanticLabel": "Person using leg curl machine in gym",
        "restrictions": [],
      },
    ];
  }
}

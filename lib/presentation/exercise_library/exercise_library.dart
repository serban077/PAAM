import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import '../ai_plan/ai_plan_screen.dart';
import './widgets/exercise_card_widget.dart';
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
    // Navighează la ecranul AI Plan pentru a vedea planul complet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AIPlanScreen(),
      ),
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
            title: Text('Adaugă la Favorite', style: theme.textTheme.bodyLarge),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${exercise['name']} adăugat la favorite'),
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
              'Adaugă la Antrenament',
              style: theme.textTheme.bodyLarge,
            ),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${exercise['name']} adăugat la antrenament'),
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
              'Distribuie Exercițiu',
              style: theme.textTheme.bodyLarge,
            ),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcție de distribuire în curând'),
                ),
              );
            },
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  void _createCustomWorkout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcție de creare antrenament personalizat în curând'),
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
                        hintText: 'Caută exerciții...',
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
                            'Șterge tot',
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
              'Nu am găsit exerciții',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              _getTotalActiveFilters() > 0
                  ? 'Încearcă să ștergi câteva filtre pentru a vedea mai multe rezultate'
                  : 'Încearcă o căutare diferită',
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
                label: const Text('Șterge Filtrele'),
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
        "name": "Genuflexiuni cu Bară",
        "bodyPart": "Picioare",
        "targetMuscles": "Cvadriceps, Fesieri",
        "equipment": "Bară",
        "difficulty": "Intermediar",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_11751f112-1764780890698.png",
        "semanticLabel":
            "Persoană executând genuflexiuni cu bară pe umeri în sală de sport",
        "restrictions": [],
      },
      {
        "id": 2,
        "name": "Împins Bancă",
        "bodyPart": "Piept",
        "targetMuscles": "Pectorali, Triceps",
        "equipment": "Bară",
        "difficulty": "Intermediar",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_157fe155b-1767766857700.png",
        "semanticLabel":
            "Atlet executând împins bancă cu bară în sala de forță",
        "restrictions": [],
      },
      {
        "id": 3,
        "name": "Deadlift",
        "bodyPart": "Spate",
        "targetMuscles": "Spate Inferior, Fesieri",
        "equipment": "Bară",
        "difficulty": "Avansat",
        "image": "https://images.unsplash.com/photo-1674748596342-8fd299450a71",
        "semanticLabel": "Sportiv ridicând greutăți în poziție deadlift",
        "restrictions": ["Probleme Cardiovasculare"],
      },
      {
        "id": 4,
        "name": "Flotări",
        "bodyPart": "Piept",
        "targetMuscles": "Pectorali, Triceps, Umeri",
        "equipment": "Greutate Corporală",
        "difficulty": "Începător",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_188114a93-1766957011899.png",
        "semanticLabel": "Persoană executând flotări pe covor de yoga",
        "restrictions": [],
      },
      {
        "id": 5,
        "name": "Tracțiuni",
        "bodyPart": "Spate",
        "targetMuscles": "Dorsali, Biceps",
        "equipment": "Bară Tracțiuni",
        "difficulty": "Intermediar",
        "image": "https://images.unsplash.com/photo-1646743934945-df7b66e28b7d",
        "semanticLabel": "Atlet executând tracțiuni la bară în parc",
        "restrictions": ["Probleme Articulare"],
      },
      {
        "id": 6,
        "name": "Presa Umeri cu Gantere",
        "bodyPart": "Umeri",
        "targetMuscles": "Deltoizi",
        "equipment": "Gantere",
        "difficulty": "Intermediar",
        "image": "https://images.unsplash.com/photo-1639653818637-d061a28959ad",
        "semanticLabel": "Sportiv ridicând gantere deasupra capului",
        "restrictions": [],
      },
      {
        "id": 7,
        "name": "Fandări",
        "bodyPart": "Picioare",
        "targetMuscles": "Cvadriceps, Fesieri",
        "equipment": "Greutate Corporală",
        "difficulty": "Începător",
        "image": "https://images.unsplash.com/photo-1732127836278-edb32d6e5044",
        "semanticLabel": "Persoană executând fandări în sala de fitness",
        "restrictions": ["Probleme Articulare"],
      },
      {
        "id": 8,
        "name": "Biceps Curl cu Bară",
        "bodyPart": "Brațe",
        "targetMuscles": "Biceps",
        "equipment": "Bară",
        "difficulty": "Începător",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_1498d38fc-1766707658426.png",
        "semanticLabel": "Atlet executând curl biceps cu bară EZ",
        "restrictions": [],
      },
      {
        "id": 9,
        "name": "Plank",
        "bodyPart": "Abdomen",
        "targetMuscles": "Core, Abdominali",
        "equipment": "Greutate Corporală",
        "difficulty": "Începător",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_128b7af95-1766522935960.png",
        "semanticLabel": "Persoană menținând poziția plank pe covor",
        "restrictions": [],
      },
      {
        "id": 10,
        "name": "Extensii Triceps",
        "bodyPart": "Brațe",
        "targetMuscles": "Triceps",
        "equipment": "Cablu",
        "difficulty": "Începător",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_13f7b5f5c-1767766857617.png",
        "semanticLabel": "Sportiv executând extensii triceps la cablu",
        "restrictions": [],
      },
      {
        "id": 11,
        "name": "Rânduri cu Bară",
        "bodyPart": "Spate",
        "targetMuscles": "Dorsali, Trapez",
        "equipment": "Bară",
        "difficulty": "Intermediar",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_1d6fb5c8f-1764636197383.png",
        "semanticLabel": "Atlet executând rânduri cu bară în poziție îndoită",
        "restrictions": [],
      },
      {
        "id": 12,
        "name": "Leg Press",
        "bodyPart": "Picioare",
        "targetMuscles": "Cvadriceps, Fesieri",
        "equipment": "Mașină",
        "difficulty": "Începător",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_1d21818c8-1764678265894.png",
        "semanticLabel": "Persoană folosind mașina leg press în sală",
        "restrictions": ["Probleme Cardiovasculare"],
      },
      {
        "id": 13,
        "name": "Ridicări Laterale",
        "bodyPart": "Umeri",
        "targetMuscles": "Deltoizi Laterali",
        "equipment": "Gantere",
        "difficulty": "Începător",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_16dcdcec5-1767041840073.png",
        "semanticLabel": "Sportiv executând ridicări laterale cu gantere",
        "restrictions": [],
      },
      {
        "id": 14,
        "name": "Crunch Abdomen",
        "bodyPart": "Abdomen",
        "targetMuscles": "Abdominali",
        "equipment": "Greutate Corporală",
        "difficulty": "Începător",
        "image":
            "https://images.unsplash.com/photo-1593204108461-60094c677448",
        "semanticLabel": "Persoană executând crunch-uri pe covor de yoga",
        "restrictions": [],
      },
      {
        "id": 15,
        "name": "Hammer Curl",
        "bodyPart": "Brațe",
        "targetMuscles": "Biceps, Antebrațe",
        "equipment": "Gantere",
        "difficulty": "Începător",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_1498d38fc-1766707658426.png",
        "semanticLabel": "Atlet executând hammer curl cu gantere",
        "restrictions": [],
      },
      {
        "id": 16,
        "name": "Presa Piept cu Gantere",
        "bodyPart": "Piept",
        "targetMuscles": "Pectorali",
        "equipment": "Gantere",
        "difficulty": "Intermediar",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_157fe155b-1767766857700.png",
        "semanticLabel": "Sportiv executând presa piept cu gantere pe bancă",
        "restrictions": [],
      },
      {
        "id": 17,
        "name": "Genuflexiuni Bulgare",
        "bodyPart": "Picioare",
        "targetMuscles": "Cvadriceps, Fesieri",
        "equipment": "Gantere",
        "difficulty": "Intermediar",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_1547b077e-1764914416872.png",
        "semanticLabel":
            "Persoană executând genuflexiuni bulgare cu picior pe bancă",
        "restrictions": ["Probleme Articulare"],
      },
      {
        "id": 18,
        "name": "Face Pull",
        "bodyPart": "Spate",
        "targetMuscles": "Trapez, Deltoizi Posteriori",
        "equipment": "Cablu",
        "difficulty": "Intermediar",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_18811f704-1767016553350.png",
        "semanticLabel": "Atlet executând face pull la cablu",
        "restrictions": [],
      },
      {
        "id": 19,
        "name": "Dips",
        "bodyPart": "Piept",
        "targetMuscles": "Pectorali, Triceps",
        "equipment": "Paralele",
        "difficulty": "Intermediar",
        "image": "https://images.unsplash.com/photo-1666961184601-9088aab7bd75",
        "semanticLabel": "Sportiv executând dips la paralele",
        "restrictions": ["Probleme Articulare"],
      },
      {
        "id": 20,
        "name": "Leg Curl",
        "bodyPart": "Picioare",
        "targetMuscles": "Ischiogambieri",
        "equipment": "Mașină",
        "difficulty": "Începător",
        "image":
            "https://img.rocket.new/generatedImages/rocket_gen_img_1b08e5e60-1766503707279.png",
        "semanticLabel": "Persoană folosind mașina leg curl în sală",
        "restrictions": [],
      },
    ];
  }
}

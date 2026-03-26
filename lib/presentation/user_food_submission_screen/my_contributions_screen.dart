import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/nutrition_service.dart';
import '../../services/supabase_service.dart';

/// Displays all foods contributed by the current user.
/// Supports pull-to-refresh and swipe-to-delete with confirmation.
class MyContributionsScreen extends StatefulWidget {
  const MyContributionsScreen({super.key});

  @override
  State<MyContributionsScreen> createState() => _MyContributionsScreenState();
}

class _MyContributionsScreenState extends State<MyContributionsScreen> {
  final _nutritionService = NutritionService(SupabaseService.instance.client);

  List<Map<String, dynamic>> _contributions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContributions();
  }

  Future<void> _loadContributions() async {
    setState(() => _isLoading = true);
    try {
      final data = await _nutritionService.getMyContributions();
      if (!mounted) return;
      setState(() {
        _contributions = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load contributions: $e')),
      );
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, Map<String, dynamic> food) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Product?'),
        content: Text(
            'Remove "${food['name']}" from the database? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _deleteContribution(food);
  }

  Future<void> _deleteContribution(Map<String, dynamic> food) async {
    try {
      await _nutritionService.deleteContribution(food['id'] as String);
      if (!mounted) return;
      setState(() => _contributions.removeWhere((f) => f['id'] == food['id']));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product removed.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Food Contributions'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadContributions,
        child: _isLoading
            ? _buildSkeleton(theme)
            : _contributions.isEmpty
                ? _buildEmptyState(theme)
                : _buildList(theme),
      ),
    );
  }

  Widget _buildList(ThemeData theme) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      itemCount: _contributions.length,
      separatorBuilder: (_, __) => SizedBox(height: 1.h),
      itemBuilder: (context, index) {
        final food = _contributions[index];
        return Dismissible(
          key: ValueKey(food['id']),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) async {
            await _confirmDelete(context, food);
            return false; // We handle removal ourselves
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 5.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.delete_outline,
                color: theme.colorScheme.error, size: 6.w),
          ),
          child: _ContributionCard(food: food, theme: theme),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return ListView(
      children: [
        SizedBox(height: 15.h),
        Center(
          child: Column(
            children: [
              Icon(Icons.restaurant_outlined,
                  size: 15.w,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
              SizedBox(height: 2.h),
              Text(
                "You haven't added any products yet.",
                style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),
              Text(
                'Scan a barcode to get started.',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      itemCount: 5,
      separatorBuilder: (_, __) => SizedBox(height: 1.h),
      itemBuilder: (_, __) => Container(
        height: 9.h,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _ContributionCard extends StatelessWidget {
  final Map<String, dynamic> food;
  final ThemeData theme;
  const _ContributionCard({required this.food, required this.theme});

  @override
  Widget build(BuildContext context) {
    final name = food['name'] as String? ?? 'Unknown';
    final brand = (food['brand'] as String? ?? '').trim();
    final barcode = food['barcode'] as String?;
    final calories = food['calories'] as num?;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Food icon
          Container(
            width: 11.w,
            height: 11.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.fastfood_outlined,
              size: 5.5.w,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(width: 3.w),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (brand.isNotEmpty) ...[
                  SizedBox(height: 0.2.h),
                  Text(
                    brand,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.55)),
                  ),
                ],
                if (barcode != null && barcode.isNotEmpty) ...[
                  SizedBox(height: 0.2.h),
                  Text(
                    barcode,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontFamily: 'monospace',
                      fontSize: 9.sp,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Right side: calories + pending badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (calories != null)
                Text(
                  '${calories.round()} kcal',
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary),
                ),
              SizedBox(height: 0.4.h),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer
                      .withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Pending Review',
                  style: TextStyle(
                    fontSize: 8.sp,
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../routes/app_routes.dart';

/// Full-screen page shown when a barcode scan returns no product in any
/// lookup tier (Supabase + Open Food Facts + USDA).
/// Offers two actions: scan again or add the product manually.
class ProductNotFoundScreen extends StatelessWidget {
  final String barcode;

  const ProductNotFoundScreen({super.key, required this.barcode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Not Found'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 22.w,
                height: 22.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer
                      .withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.qr_code_scanner_outlined,
                  size: 11.w,
                  color: theme.colorScheme.error,
                ),
              ),
              SizedBox(height: 3.h),

              // Heading
              Text(
                'No product found',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),

              // Barcode display
              if (barcode.isNotEmpty) ...[
                Text(
                  'Barcode: $barcode',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 1.5.h),
              ],

              // Subtext
              Text(
                'This barcode is not yet in our database.\nBe the first to add it and help the community!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 5.h),

              // "Add This Product" CTA (primary)
              SizedBox(
                width: double.infinity,
                height: 6.5.h,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.userFoodSubmission,
                    arguments: {'barcode': barcode},
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(
                    'Add This Product',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.tertiary,
                    foregroundColor: theme.colorScheme.onTertiary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 1.5.h),

              // "Scan Again" secondary action
              SizedBox(
                width: double.infinity,
                height: 6.5.h,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(
                    'Scan Again',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

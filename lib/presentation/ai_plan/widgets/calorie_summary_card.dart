import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class CalorieSummaryCard extends StatelessWidget {
  final int dailyGoal;
  final int caloriesEaten;

  const CalorieSummaryCard({
    super.key,
    required this.dailyGoal,
    required this.caloriesEaten,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = dailyGoal - caloriesEaten;
    final progress = (caloriesEaten / dailyGoal).clamp(0.0, 1.0);
    
    return Container(
      margin: EdgeInsets.all(2.h),
      padding: EdgeInsets.all(2.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Daily Calorie Goal',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 1.h),
          
          // Circular progress indicator
          SizedBox(
            height: 150,
            width: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 150,
                  width: 150,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: Colors.white30,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      remaining >= 0 ? Colors.white : Colors.red,
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$caloriesEaten',
                      style: GoogleFonts.inter(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'of $dailyGoal cal',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: 2.h),
          
          // Remaining calories
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              remaining >= 0
                  ? '$remaining calories remaining'
                  : '${remaining.abs()} calories over goal',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

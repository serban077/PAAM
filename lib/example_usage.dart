// Example usage of the AI Plan Screen
// Add this to your navigation logic

import 'package:flutter/material.dart';
import 'presentation/ai_plan/ai_plan_screen.dart';

// Example: Navigate to AI Plan Screen from a button
void navigateToAIPlan(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const AIPlanScreen(),
    ),
  );
}

// Example: Add a button in your existing UI
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmartFit AI')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => navigateToAIPlan(context),
          icon: const Icon(Icons.fitness_center),
          label: const Text('Planul Meu AI'),
        ),
      ),
    );
  }
}

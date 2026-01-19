import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../data/models/ai_plan_models.dart';
import '../../services/gemini_ai_service.dart';
import '../../services/supabase_service.dart';
import 'widgets/workout_tab.dart';

class AIPlanScreen extends StatefulWidget {
  const AIPlanScreen({super.key});

  @override
  State<AIPlanScreen> createState() => _AIPlanScreenState();
}

class _AIPlanScreenState extends State<AIPlanScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  // ... (existing code variables)

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
  final GeminiAIService _geminiService = GeminiAIService();
  
  AIPlanResponse? _aiPlan;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Profile monitoring state
  int? _currentFrequency;
  Stream<List<Map<String, dynamic>>>? _profileStream;

  @override
  void initState() {
    super.initState();
    _loadAIPlan();
    _startProfileMonitoring();
  }

  Future<void> _loadAIPlan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Obține utilizatorul curent din Supabase
      final user = SupabaseService.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Nu ești autentificat. Te rugăm să te loghezi.');
      }
      
      final planData = await _geminiService.generateCompletePlan(user.id);
      final plan = AIPlanResponse.fromJson(planData);
      
      // Get current frequency from profile
      final profileData = await SupabaseService.instance.client
          .from('user_profiles')
          .select('weekly_training_frequency')
          .eq('id', user.id)
          .single();
      
      setState(() {
        _aiPlan = plan;
        _isLoading = false;
        _currentFrequency = profileData['weekly_training_frequency'] as int?;
        
        // Initialize tab controller after we know how many workout days we have
        final workoutDaysCount = plan.trainingPlan.days.length;
        _tabController = TabController(
          length: workoutDaysCount, // Only workout days, no nutrition tab
          vsync: this,
        );
      });
    } on GeminiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startProfileMonitoring() {
    final user = SupabaseService.instance.client.auth.currentUser;
    if (user == null) return;

    // Listen to profile changes
    _profileStream = SupabaseService.instance.client
        .from('user_profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user.id);

    _profileStream!.listen((data) {
      if (data.isEmpty) return;
      
      final newFrequency = data[0]['weekly_training_frequency'] as int?;
      
      // Check if frequency changed
      if (_currentFrequency != null && 
          newFrequency != null && 
          newFrequency != _currentFrequency &&
          mounted) {
        _showRegenerateDialog(newFrequency);
      }
    });
  }

  void _showRegenerateDialog(int newFrequency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Frecvență schimbată'),
        content: Text(
          'Ai schimbat frecvența antrenamentelor de la $_currentFrequency zile/săptămână la $newFrequency zile/săptămână.\n\n'
          'Vrei să regenerezi planul de antrenament pentru a se potrivi noii frecvențe?'
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _currentFrequency = newFrequency;
              });
              Navigator.pop(context);
            },
            child: const Text('Nu acum'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _regeneratePlan();
            },
            child: const Text('Da, regenerează'),
          ),
        ],
      ),
    );
  }

  Future<void> _regeneratePlan() async {
    await _loadAIPlan();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Planul a fost regenerat cu succes!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your AI Plan'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Regenerează planul',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Regenerează planul'),
                    content: const Text(
                      'Vrei să regenerezi planul de antrenament și nutriție? '
                      'Acest lucru va crea un plan nou bazat pe profilul tău actual.'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Anulează'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _regeneratePlan();
                        },
                        child: const Text('Regenerează'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
        bottom: _aiPlan != null
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: [
                  // Workout day tabs only
                  ..._aiPlan!.trainingPlan.days.keys.map(
                    (day) => Tab(
                      text: day.replaceAll('_', ' ').toUpperCase(),
                    ),
                  ),
                ],
              )
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red),
            SizedBox(height: 2.h),
            Text('Error: $_errorMessage'),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: _loadAIPlan,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_aiPlan == null) {
      return const Center(child: Text('No plan available'));
    }

    return TabBarView(
      controller: _tabController,
      children: [
        // Workout day tabs only
        ..._aiPlan!.trainingPlan.days.entries.map(
          (entry) => WorkoutTab(
            dayName: entry.key,
            exercises: entry.value,
          ),
        ),
      ],
    );
  }
}

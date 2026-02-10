import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../models/plan_model.dart';
import '../models/user_model.dart';
import '../providers/settings_provider.dart';
import '../services/auth_service.dart';
import '../services/plan_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DailyPlan? _dailyPlan;
  bool _isLoadingPlan = true;
  final PlanService _planService = PlanService();
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDailyPlan();
    });
  }
  
  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyPlan() async {
    final user = AuthService().currentUser;
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    if (user != null) {
      // Sync local settings if needed
      if (settingsProvider.dailyGoalMinutes != user.dailyStudyMinutes) {
          // Update provider to match Firestore user data (Source of Truth)
          // We do this in post frame callback to avoid build conflicts if needed, 
          // or just call setDailyGoal (which notifies listeners).
          // Since we are in an async method _loadDailyPlan, we can call it.
          settingsProvider.setDailyGoal(user.dailyStudyMinutes);
      }

      try {
        // Pass empty list since we don't use library content generation anymore
        final plan = await _planService.getOrGenerateDailyPlan(user, []);
        
        if (mounted) {
          setState(() {
            _dailyPlan = plan;
            _isLoadingPlan = false;
          });
        }
      } catch (e) {
        debugPrint("Error loading plan: $e");
        if (mounted) setState(() => _isLoadingPlan = false);
      }
    }
  }

  Future<void> _toggleTaskCompletion(DailyTask task, bool? value) async {
    if (_dailyPlan == null || value == null) return;

    final user = AuthService().currentUser;
    if (user == null) return;

    // Optimistic update
    setState(() {
      final tasks = _dailyPlan!.tasks.map((t) {
        if (t.id == task.id) {
          return t.copyWith(isCompleted: value);
        }
        return t;
      }).toList();
      
      _dailyPlan = DailyPlan(
        date: _dailyPlan!.date,
        tasks: tasks,
        totalDurationMinutes: _dailyPlan!.totalDurationMinutes,
        completedDurationMinutes: _dailyPlan!.completedDurationMinutes, 
      );
    });

    await _planService.updateTaskStatus(user.id, _dailyPlan!.date, task.id, value);
    
    // Check for celebration
    if (_dailyPlan!.tasks.every((t) => t.isCompleted)) {
      _confettiController.play();
      _showCelebrationDialog();
    }
  }
  
  void _showCelebrationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Congratulations!'),
        content: const Text('You have completed your daily plan! Great job keeping up with your English studies.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  String _getMotivationMessage(int streak) {
    if (streak == 0) return "Let’s start your first day!";
    if (streak == 1) return "Great start! Day 1 completed 🎉";
    if (streak <= 3) return "Nice! You’re building a habit 🔥";
    if (streak <= 6) return "Awesome! Almost a full week 👏";
    if (streak == 7) return "1 WEEK STREAK! Amazing work! 🏆";
    if (streak <= 13) return "Incredible consistency 💪";
    if (streak == 14) return "TWO WEEKS STRAIGHT! 🚀";
    if (streak <= 29) return "Impressive discipline!";
    if (streak == 30) return "30 DAYS STREAK! LEGENDARY 🏅";
    return "You’re unstoppable 🔥";
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        if (_dailyPlan != null && !_isLoadingPlan) {
            int settingMinutes = settings.dailyGoalMinutes;
            if (_dailyPlan!.totalDurationMinutes != settingMinutes) {
               WidgetsBinding.instance.addPostFrameCallback((_) { 
                  if(mounted && !_isLoadingPlan) {
                     setState(() => _isLoadingPlan = true);
                     _loadDailyPlan();
                  }
               });
            }
        }
      
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            Scaffold(
              appBar: AppBar(
                title: const Text('Across English'),
                automaticallyImplyLeading: false, 
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () async {
                      await AuthService().signOut();
                    },
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(user),
                    const SizedBox(height: 20),
                    _buildStreakSection(user),
                    const SizedBox(height: 30),
                    _buildDailyPlanSection(),
                  ],
                ),
              ),
            ),
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false, 
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ],
        );
      }
    );
  }

  Widget _buildHeader(UserModel? user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user?.username ?? "User"}!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              user?.level ?? "Beginner",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
         Container(
           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
           decoration: BoxDecoration(
             color: Colors.deepPurple.withOpacity(0.1),
             borderRadius: BorderRadius.circular(20),
           ),
           child: Row(
             children: [
               const Icon(Icons.access_time, size: 16, color: Colors.deepPurple),
               const SizedBox(width: 4),
               Text(
                 '${user?.dailyStudyMinutes ?? 30} min Goal',
                 style: const TextStyle(
                   color: Colors.deepPurple,
                   fontWeight: FontWeight.bold
                 ),
               ),
             ],
           ),
         )
      ],
    );
  }

  Widget _buildStreakSection(UserModel? user) {
    int streak = user?.currentStreak ?? 0;
    int best = user?.bestStreak ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade100, Colors.orange.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                   const Text("Current Streak", style: TextStyle(color: Colors.black54, fontSize: 12)),
                   const SizedBox(height: 4),
                   Row(
                     children: [
                       const Text("🔥", style: TextStyle(fontSize: 20)),
                       const SizedBox(width: 6),
                       Text(
                         "$streak days", 
                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.orange)
                       ),
                     ],
                   )
                ],
              ),
              Container(width: 1, height: 40, color: Colors.orange.shade200),
              Column(
                 children: [
                   const Text("Best Streak", style: TextStyle(color: Colors.black54, fontSize: 12)),
                   const SizedBox(height: 4),
                   Row(
                     children: [
                       const Text("🏆", style: TextStyle(fontSize: 20)),
                       const SizedBox(width: 6),
                       Text(
                         "$best days", 
                         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.orange.shade800)
                       ),
                     ],
                   )
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getMotivationMessage(streak),
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.orange.shade900,
              fontWeight: FontWeight.w600
            ),
            textAlign: TextAlign.center,
          ),
        ],
      )
    );
  }

  Widget _buildDailyPlanSection() {
    if (_isLoadingPlan) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_dailyPlan == null) {
      return const Text("Could not generate plan.");
    }

    int completedCount = _dailyPlan!.tasks.where((t) => t.isCompleted).length;
    double progress = _dailyPlan!.tasks.isEmpty ? 0 : completedCount / _dailyPlan!.tasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             const Text(
              "Today's Plan",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "${(progress * 100).toInt()}% Done",
               style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple
              ),
            )
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: progress, backgroundColor: Colors.grey[200], borderRadius: BorderRadius.circular(4),),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _dailyPlan!.tasks.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final task = _dailyPlan!.tasks[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: CheckboxListTile(
                title: Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted ? Colors.grey : null,
                  ),
                ),
                subtitle: Text(
                  "${task.category} • ${task.durationMinutes} min",
                  style: TextStyle(
                    fontSize: 12,
                     decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                value: task.isCompleted,
                onChanged: (val) => _toggleTaskCompletion(task, val),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: task.type == 'input' ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    task.type == 'input' ? Icons.headphones : Icons.mic,
                    color: task.type == 'input' ? Colors.blue : Colors.orange,
                    size: 20,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../models/content_model.dart';
import '../models/plan_model.dart';
import '../models/user_model.dart';
import '../providers/content_provider.dart';
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
    final contentProvider = Provider.of<ContentProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    if (user != null) {
      // Sync local settings with user model if needed, or just rely on what PlanService does.
      // Ideally, PlanService reads from Firestore User. 
      // Ensure daily goal is consistent.
      if (settingsProvider.dailyGoalHours != user.dailyStudyGoal) {
          // If local settings differ (e.g. just changed), we might need to update user first?
          // For now, assuming SettingsPage updates Firestore, so User model is fresh.
      }

      try {
        final plan = await _planService.getOrGenerateDailyPlan(user, contentProvider.contents);
        
        if (mounted) {
          setState(() {
            _dailyPlan = plan;
            _isLoadingPlan = false;
          });
          
          // Check for new content suggested by PlanService
          _checkForNewContent(plan);
        }
      } catch (e) {
        debugPrint("Error loading plan: $e");
        if (mounted) setState(() => _isLoadingPlan = false);
      }
    }
  }

  void _checkForNewContent(DailyPlan plan) {
    final contentProvider = Provider.of<ContentProvider>(context, listen: false);
    for (var task in plan.tasks) {
      if (task.userContentData != null && task.userContentData!['new_content'] == 'true') {
        final data = task.userContentData!;
        // Add to library
        contentProvider.addNewContent(ContentModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(), // Generate ID
          title: data['title'] ?? 'Unknown',
          imageUrl: '', // Placeholder
          type: data['type'] ?? 'book',
          level: 'Intermediate', // Default
        ));
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

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    
    // Listen to settings to trigger reload if goal changes
    // We use a Consumer here to check if goal changed compared to plan
    
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        // Simple check: If plan exists and duration mismatch, reload.
        // Note: This might cause loop if not careful. 
        // User.dailyStudyGoal should be updated by SettingsPage.
        // If _dailyPlan.totalDuration != settings.dailyGoal * 60, reload.
        if (_dailyPlan != null && !_isLoadingPlan) {
            int settingMinutes = settings.dailyGoalHours * 60;
            // Allow small buffer or exact match
            if (_dailyPlan!.totalDurationMinutes != settingMinutes) {
               // Trigger reload (microtask to avoid build error)
               WidgetsBinding.instance.addPostFrameCallback((_) { 
                 // Ensure we don't spam reloads. Set loading true immediately.
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
                    const SizedBox(height: 30),
                    _buildDailyPlanSection(),
                    const SizedBox(height: 30),
                    _buildLibrarySection(context),
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
                 '${user?.dailyStudyGoal ?? 1}h Goal',
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

  Widget _buildLibrarySection(BuildContext context) {
    return Consumer<ContentProvider>(
      builder: (context, contentProvider, child) {
        // Show active content (not completed logic handles completion locally until refreshed, 
        // but markAsCompleted updates the list, so it will disappear from this list automatically if we filter?
        // Let's show All logic or just Active logic. Requirement: "Library'de olması gerekenler şu an tüketiyor olduğumuz içerikler olmalı."
        // So we show active content.
        
        final contents = contentProvider.activeContent;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Library (In Progress)",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            contents.isEmpty 
              ? const Text("No active content. Check your plan for suggestions!")
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: contents.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final content = contents[index];
                    return _buildSimpleContentCard(content, context);
                  },
                ),
          ],
        );
      },
    );
  }

  Widget _buildSimpleContentCard(ContentModel content, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1))
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          content.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: content.type == 'book' ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  content.type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: content.type == 'book' ? Colors.blue : Colors.green,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                content.level,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        trailing: content.isCompleted
            ? const Icon(Icons.check_circle, color: Colors.green, size: 30)
            : IconButton(
                icon: const Icon(Icons.check_circle_outline),
                tooltip: 'Mark as Finished',
                onPressed: () {
                  _showCompletionDialog(context, content);
                },
              ),
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, ContentModel content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finished this content?'),
        content: Text('Did you finish reading/watching "${content.title}" completely?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Provider.of<ContentProvider>(context, listen: false).markAsCompleted(content.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Marked "${content.title}" as completed!')),
              );
              
              // Trigger plan reload to get new content!
              setState(() => _isLoadingPlan = true);
              await _loadDailyPlan();
            },
            child: const Text('Yes, Finished'),
          ),
        ],
      ),
    );
  }
}


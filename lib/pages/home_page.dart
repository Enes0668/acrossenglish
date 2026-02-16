import 'dart:async';
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

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  DailyPlan? _dailyPlan;
  bool _isLoadingPlan = true;
  final PlanService _planService = PlanService();
  late ConfettiController _confettiController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 800)
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Sync local settings with user data ONCE on mount
      final user = AuthService().currentUser;
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      if (user != null && settingsProvider.dailyGoalMinutes != user.dailyStudyMinutes) {
          settingsProvider.setDailyGoal(user.dailyStudyMinutes);
      }
      _loadDailyPlan();
    });
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyPlan() async {
    final user = AuthService().currentUser;
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    if (user != null) {

      try {
        final plan = await _planService.getOrGenerateDailyPlan(
          user, 
          [], 
          targetMinutes: settingsProvider.dailyGoalMinutes
        );
        
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

  Timer? _debounceTimer;

  Future<void> _toggleTaskCompletion(DailyTask task, bool? value) async {
    if (_dailyPlan == null || value == null) return;

    final user = AuthService().currentUser;
    if (user == null) return;

    // 1. Optimistic update (UI updates immediately)
    setState(() {
      final tasks = _dailyPlan!.tasks.map((t) {
        if (t.id == task.id) {
          return t.copyWith(isCompleted: value);
        }
        return t;
      }).toList();
      
      // Recalculate completed duration for local state
      int completedMinutes = 0;
      for (var t in tasks) {
        if (t.isCompleted) completedMinutes += t.durationMinutes;
      }

      _dailyPlan = DailyPlan(
        date: _dailyPlan!.date,
        tasks: tasks,
        totalDurationMinutes: _dailyPlan!.totalDurationMinutes,
        completedDurationMinutes: completedMinutes, 
      );
    });

    // 2. Cancellation of previous timer (Debounce)
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    // 3. Start new timer to sync with DB
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
       if (_dailyPlan != null) {
          await _planService.updateDailyPlan(user, _dailyPlan!);
       }
    });
    
    // Check for celebration (Immediate UI feedback)
    if (_dailyPlan!.tasks.every((t) => t.isCompleted)) {
      _confettiController.play();
      _showCelebrationDialog();
    }
  }
  
  void _showCelebrationDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              const Text(
                'Congratulations!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
               'You have completed your daily plan! Great job keeping up with your English studies.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Awesome!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  Widget build(BuildContext context) {
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
      
        return StreamBuilder<UserModel?>(
          stream: AuthService().authStateChanges,
          initialData: AuthService().currentUser,
          builder: (context, snapshot) {
            final user = snapshot.data;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final backgroundColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8F9FD);

            return Stack(
              alignment: Alignment.topCenter,
              children: [
                Scaffold(
                  backgroundColor: backgroundColor,
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    toolbarHeight: 0, // Hide default appbar but keep status bar control
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(0), 
                      child: Container(),
                    ),
                  ),
                  body: SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      child: FadeTransition(
                        opacity: _animationController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            _buildModernHeader(user, isDark),
                            const SizedBox(height: 30),
                            
                            // Streak Card
                            _buildModernStreakCard(user, isDark),
                            const SizedBox(height: 30),
                            
                            // Daily Plan
                            _buildModernDailyPlanSection(isDark),
                            
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
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
    );
  }

  Widget _buildModernHeader(UserModel? user, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white60 : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.username ?? "User",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF2D3436),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
            ],
            border: Border.all(color: isDark ? Colors.white24 : Colors.grey[100]!),
          ),
          child: IconButton(
            icon: Icon(Icons.logout_rounded, color: isDark ? Colors.white70 : Colors.grey[700]),
            onPressed: () async => await AuthService().signOut(),
            tooltip: 'Sign Out',
          ),
        ),
      ],
    );
  }

  Widget _buildModernStreakCard(UserModel? user, bool isDark) {
    int streak = user?.currentStreak ?? 0;
    int best = user?.bestStreak ?? 0;
    
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9966), Color(0xFFFF5E62)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5E62).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.local_fire_department_rounded,
              size: 150,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                       decoration: BoxDecoration(
                         color: Colors.white.withValues(alpha: 0.2),
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: Row(
                         children: [
                           const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 16),
                           const SizedBox(width: 6),
                           Text(
                             "Best: $best",
                             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                           ),
                         ],
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 12),
                 Row(
                   crossAxisAlignment: CrossAxisAlignment.end,
                   children: [
                     Text(
                       "$streak",
                       style: const TextStyle(
                         fontSize: 48,
                         fontWeight: FontWeight.bold,
                         color: Colors.white,
                         height: 1,
                       ),
                     ),
                     const SizedBox(width: 8),
                     const Padding(
                       padding: EdgeInsets.only(bottom: 8.0),
                       child: Text(
                         "Day Streak",
                         style: TextStyle(
                           fontSize: 18,
                           fontWeight: FontWeight.w600,
                           color: Colors.white,
                         ),
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 8),
                 Text(
                   streak == 0 ? "Start your streak today!" : "Keep the flame burning!",
                   style: TextStyle(
                     color: Colors.white.withValues(alpha: 0.9),
                     fontSize: 14,
                     fontWeight: FontWeight.w500,
                   ),
                 ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDailyPlanSection(bool isDark) {
    if (_isLoadingPlan) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    if (_dailyPlan == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            "Could not generate plan.",
            style: TextStyle(color: isDark ? Colors.white60 : Colors.grey),
          ),
        ),
      );
    }

    int completedCount = _dailyPlan!.tasks.where((t) => t.isCompleted).length;
    int totalCount = _dailyPlan!.tasks.length;
    double progress = totalCount == 0 ? 0 : completedCount / totalCount;
    bool isAllCompleted = progress == 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Plan",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF2D3436),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isAllCompleted 
                    ? Colors.green.withValues(alpha: 0.1)
                    : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isAllCompleted ? "Completed" : "${(progress * 100).toInt()}% Done",
                style: TextStyle(
                  color: isAllCompleted ? Colors.green : Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress, 
            minHeight: 8,
            backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
            color: isAllCompleted ? Colors.green : Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 24),

        // Tasks List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _dailyPlan!.tasks.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final task = _dailyPlan!.tasks[index];
            return _buildTaskCard(task, isDark);
          },
        ),
      ],
    );
  }

  Widget _buildTaskCard(DailyTask task, bool isDark) {
    bool isInput = task.type == 'input';
    Color iconColor = isInput ? Colors.blue : Colors.orange;
    Color accentColor = isInput ? const Color(0xFFE3F2FD) : const Color(0xFFFFF3E0);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A3D) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: task.isCompleted 
              ? (isDark ? Colors.green.withValues(alpha: 0.3) : Colors.green.withValues(alpha: 0.2))
              : (isDark ? Colors.white10 : Colors.transparent),
          width: task.isCompleted ? 1.5 : 1
        ),
        boxShadow: [
          if (!isDark && !task.isCompleted)
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: task.isCompleted ? null : () => _toggleTaskCompletion(task, !task.isCompleted),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Box
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? iconColor.withValues(alpha: 0.2) : accentColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isInput ? Icons.headphones_rounded : Icons.mic_rounded,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: task.isCompleted 
                              ? (isDark ? Colors.white38 : Colors.grey[400])
                              : (isDark ? Colors.white : const Color(0xFF2D3436)),
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${task.category} • ${task.durationMinutes} min",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Checkbox/Status
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.isCompleted ? Colors.green : Colors.transparent,
                    border: Border.all(
                      color: task.isCompleted ? Colors.green : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: task.isCompleted 
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

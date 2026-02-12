import 'package:acrossenglish/pages/history_page.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/plan_model.dart';
import '../services/plan_service.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    // In a real app we might want to listen to changes or fetch fresh stats.
    // User model has streak data, but we might want "Total Study Minutes" etc.
    // For V1, "Total Minutes" can be calculated from History logic or stored in User?
    // We don't have total minutes in user model yet. We have 'dailyStudyMinutes' (goal). 
    // We can assume we need to calculate it from history or just show what we have.
    // Limitation: We didn't add 'totalStudyMinutes' to user model in the plan.
    // BUT we have 'getCompletedTasksHistory'. We can sum it up or just show what we have.
    // Let's rely on what we have + history at the bottom.
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               if (user != null) _buildSummaryCards(context, user),
               const SizedBox(height: 20),
               const Padding(
                 padding: EdgeInsets.symmetric(horizontal: 16.0),
                 child: Text(
                   "History",
                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                 ),
               ),
               const SizedBox(height: 10),
               const HistoryPage(),
            ],
        ),
      )
    );
  }

  Widget _buildSummaryCards(BuildContext context, UserModel user) {
     return StreamBuilder<List<DailyPlan>>(
       stream: PlanService().getCompletedTasksHistoryStream(user.id),
       builder: (context, snapshot) {
         int todayMinutes = 0;
         int dailyGoal = user.dailyStudyMinutes;
         
         if (snapshot.hasData) {
            final nowStr = DateTime.now().toIso8601String().split('T').first;
            final todayPlan = snapshot.data!.firstWhere(
              (p) => p.date == nowStr, 
              orElse: () => DailyPlan(date: nowStr, tasks: [], totalDurationMinutes: 0, completedDurationMinutes: 0)
            );
            todayMinutes = todayPlan.completedDurationMinutes;
            // Use plan's target if available and greater than 0, otherwise user's setting
            if (todayPlan.totalDurationMinutes > 0) {
               dailyGoal = todayPlan.totalDurationMinutes;
            }
         }

         return Padding(
           padding: const EdgeInsets.all(16.0),
           child: Column(
             children: [
               Row(
                 children: [
                   Expanded(child: _buildStatCard(context, "Current Streak", "${user.currentStreak} Days", Icons.local_fire_department, Colors.orange)),
                   const SizedBox(width: 16),
                   Expanded(child: _buildStatCard(context, "Best Streak", "${user.bestStreak} Days", Icons.emoji_events, Colors.yellow.shade800)),
                 ],
               ),
               const SizedBox(height: 16),
               Row(
                 children: [
                   Expanded(child: _buildStatCard(context, "Today's Progress", "$todayMinutes / $dailyGoal min", Icons.timer, Colors.blue)),
                   const SizedBox(width: 16),
                   Expanded(child: _buildStatCard(context, "Level", user.level, Icons.trending_up, Colors.purple)),
                 ],
               ),
             ],
           ),
         );
       }
     );
  }
  
  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.1),
             blurRadius: 10,
             offset: const Offset(0, 4),
           )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }
}

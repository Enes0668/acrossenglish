import 'package:acrossenglish/models/plan_model.dart';
import 'package:acrossenglish/providers/content_provider.dart';
import 'package:acrossenglish/services/auth_service.dart';
import 'package:acrossenglish/services/plan_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity History'),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Daily Activity'),
                Tab(text: 'Completed Content'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Daily Activity Tab
                  _buildDailyActivityTab(user?.id),
                  
                  // Completed Content Tab
                  _buildCompletedContentTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyActivityTab(String? userId) {
    if (userId == null) return const Center(child: Text("Please login first."));

    return FutureBuilder<List<DailyPlan>>(
      future: PlanService().getCompletedTasksHistory(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading history."));
        }

        final history = snapshot.data ?? [];

        if (history.isEmpty) {
          return const Center(child: Text('No activity yet.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final plan = history[index];
            final completedTasks = plan.tasks.where((t) => t.isCompleted).toList();
            
            // Skip empty days if desired, or show them as "No activity"
            if (completedTasks.isEmpty) {
               return ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.grey),
                title: Text(DateFormat.yMMMMEEEEd().format(DateTime.parse(plan.date))),
                subtitle: const Text("No tasks completed."),
              );
            }

            return ExpansionTile(
              leading: const Icon(Icons.check_circle, color: Colors.deepPurple),
              title: Text(DateFormat.yMMMMEEEEd().format(DateTime.parse(plan.date))),
              subtitle: Text('${completedTasks.length}/${plan.tasks.length} tasks completed'),
              children: completedTasks.map((task) => ListTile(
                title: Text(task.title),
                subtitle: Text(task.category),
                trailing: Text("${task.durationMinutes} min"),
                dense: true,
              )).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildCompletedContentTab() {
    return Consumer<ContentProvider>(
      builder: (context, contentProvider, child) {
        final completedContent = contentProvider.contents.where((c) => c.isCompleted).toList();
        
        if (completedContent.isEmpty) {
          return const Center(child: Text('No content completed yet.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: completedContent.length,
          itemBuilder: (context, index) {
            final content = completedContent[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                    width: 40,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Icon(Icons.book, color: Colors.grey),
                  ),
                title: Text(content.title),
                subtitle: Text('${content.type.toUpperCase()} • ${content.level}'),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
            );
          },
        );
      },
    );
  }
}

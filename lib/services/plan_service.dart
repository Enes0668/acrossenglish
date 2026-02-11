import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plan_model.dart';
import '../models/user_model.dart';
import '../models/content_model.dart';

class PlanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Generation Logic ---

  Future<DailyPlan> getOrGenerateDailyPlan(UserModel user, List<ContentModel> libraryContents) async {
    final today = DateTime.now().toIso8601String().split('T').first; // YYYY-MM-DD
    final planRef = _firestore
        .collection('users')
        .doc(user.id)
        .collection('daily_plans')
        .doc(today);

    final doc = await planRef.get();
    
    // Check for streak reset on new day open
    await _checkStreakOnAppOpen(user, today);

    if (doc.exists) {
      // Check if we need to update duration because of settings change
      DailyPlan existingPlan = DailyPlan.fromMap(doc.data()!);
      int targetMinutes = user.dailyStudyMinutes > 0 ? user.dailyStudyMinutes : 30;
      
      if (existingPlan.totalDurationMinutes != targetMinutes) {
         return _updatePlanDuration(existingPlan, targetMinutes, user);
      }
      return existingPlan;
    }

    // Generate new plan
    final plan = _generatePlan(user, today);
    
    // Save to Firestore
    await planRef.set(plan.toMap());
    
    return plan;
  }

  Future<void> _checkStreakOnAppOpen(UserModel user, String today) async {
    // If last completed date was yesterday, streak is safe.
    // If last completed date was today, streak is safe.
    // If last completed date was before yesterday, streak = 0.
    
    if (user.lastCompletedDate.isEmpty) return; // New user or never completed

    DateTime lastCompleted = DateTime.parse(user.lastCompletedDate);
    DateTime now = DateTime.parse(today);
    
    // Difference in days
    int difference = now.difference(lastCompleted).inDays;
    
    if (difference > 1) {
       if (user.currentStreak > 0) {
          await _firestore.collection('users').doc(user.id).update({
            'currentStreak': 0,
          });
       }
    }
  }
  
  // Method to re-balance plan if settings change
  Future<DailyPlan> _updatePlanDuration(DailyPlan oldPlan, int newTotalMinutes, UserModel user) async {
      // Regenerate plan structure
      final newPlan = _generatePlan(user, oldPlan.date);
      
      // Attempt to preserve completion status if tasks match (by title/type)
      List<DailyTask> mergedTasks = [];
      
      for (var newTask in newPlan.tasks) {
        bool completed = false;
        // Find matching task in old plan
        for(var oldTask in oldPlan.tasks) {
           if (oldTask.title == newTask.title && oldTask.isCompleted) {
             completed = true;
             break;
           }
        }
        mergedTasks.add(newTask.copyWith(isCompleted: completed));
      }
      
      final mergedPlan = DailyPlan(
        date: newPlan.date,
        tasks: mergedTasks,
        totalDurationMinutes: newPlan.totalDurationMinutes,
        completedDurationMinutes: mergedTasks.where((t) => t.isCompleted).fold(0, (sum, t) => sum + t.durationMinutes),
      );

       final planRef = _firestore
        .collection('users')
        .doc(user.id)
        .collection('daily_plans')
        .doc(oldPlan.date);
        
      await planRef.set(mergedPlan.toMap());
      return mergedPlan;
  }
  
  Future<void> updateDailyPlan(String userId, DailyPlan plan) async {
    final planRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('daily_plans')
        .doc(plan.date);

    await planRef.set(plan.toMap());

    // Check for Streak Increment if all tasks are completed
    bool allCompleted = plan.tasks.every((t) => t.isCompleted);
    if (allCompleted) {
      await _updateStreak(userId, plan.date);
    }
  }

  Future<void> updateTaskStatus(String userId, String date, String taskId, bool isCompleted) async {
     final planRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('daily_plans')
        .doc(date);
    
    // Check if plan exists
    final doc = await planRef.get();
    if (!doc.exists) return;
    
    DailyPlan plan = DailyPlan.fromMap(doc.data()!);
    
    // Update the specific task
    List<DailyTask> updatedTasks = plan.tasks.map((t) {
      if (t.id == taskId) {
        return t.copyWith(isCompleted: isCompleted);
      }
      return t;
    }).toList();
    
    // Recalculate completed minutes
    int completedMinutes = 0;
    bool allCompleted = true;
    for (var t in updatedTasks) {
      if (t.isCompleted) {
        completedMinutes += t.durationMinutes;
      } else {
        allCompleted = false;
      }
    }

    final updatedPlan = DailyPlan(
      date: plan.date,
      tasks: updatedTasks,
      totalDurationMinutes: plan.totalDurationMinutes,
      completedDurationMinutes: completedMinutes,
    );
    
    await planRef.update(updatedPlan.toMap());
    
    // Check for Streak Increment
    if (allCompleted && isCompleted) {
       await _updateStreak(userId, date);
    }
  }

  Future<void> _updateStreak(String userId, String today) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return; 
    
    UserModel user = UserModel.fromMap(userDoc.data()!, userId);
    
    if (user.lastCompletedDate == today) {
      return;
    }
    
    // Calculate new streak
    int newStreak = user.currentStreak;
    
    if (user.lastCompletedDate.isEmpty) {
      newStreak = 1;
    } else {
      DateTime lastDate = DateTime.parse(user.lastCompletedDate);
      DateTime nowDate = DateTime.parse(today);
      int diff = nowDate.difference(lastDate).inDays;
      
      if (diff == 1) {
        newStreak += 1;
      } else if (diff == 0) {
        // Same day
      } else {
        newStreak = 1;
      }
    }
    
    int newBest = user.bestStreak;
    if (newStreak > newBest) {
      newBest = newStreak;
    }
    
    await _firestore.collection('users').doc(userId).update({
      'currentStreak': newStreak,
      'bestStreak': newBest,
      'lastCompletedDate': today,
    });
  }

  Future<List<DailyPlan>> getCompletedTasksHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_plans')
          .orderBy('date', descending: true)
          .limit(30) // Last 30 days
          .get();

      return snapshot.docs.map((doc) => DailyPlan.fromMap(doc.data())).toList();
    } catch (e) {
      print("Error fetching history: $e");
      return [];
    }
  }

  DailyPlan _generatePlan(UserModel user, String date) {
    int totalMinutes = user.dailyStudyMinutes > 0 ? user.dailyStudyMinutes : 30;
    
    String level = user.level; 
    double inputRatio = 0.65; // Default Intermediate
    List<String> outputTypes = ['Paragraph Writing', 'Speaking Practice', 'Interaction Output']; // Defaults

    if (level.toLowerCase().contains('beginner') || level.contains('A1') || level.contains('A2')) {
      inputRatio = 0.85;
      outputTypes = ['Shadowing', 'Mini writing'];
    } else if (level.toLowerCase().contains('advanced') || level.contains('C1') || level.contains('C2')) {
       inputRatio = 0.45;
       outputTypes = ['Paragraph Writing', 'Speaking Practice', 'Interaction Output'];
    }

    int inputMinutes = (totalMinutes * inputRatio).round();
    int outputMinutes = totalMinutes - inputMinutes;
    
    List<DailyTask> tasks = [];

    // INPUT TASKS
    int watchMinutes = (inputMinutes * 0.6).round();
    int readMinutes = inputMinutes - watchMinutes;

    tasks.add(DailyTask(
      id: 'watch_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Watch: English Series',
      description: 'Watch an episode or video provided in the library.',
      type: 'input',
      category: 'Show',
      durationMinutes: watchMinutes,
      isCompleted: false,
    ));

    tasks.add(DailyTask(
      id: 'read_${DateTime.now().millisecondsSinceEpoch + 1}',
      title: 'Read: English Book',
      description: 'Read a chapter or article provided in the library.',
      type: 'input',
      category: 'Book',
      durationMinutes: readMinutes,
      isCompleted: false,
    ));

    // OUTPUT TASKS
    int timePerOutput = outputMinutes > 0 && outputTypes.isNotEmpty ? (outputMinutes / outputTypes.length).round() : 0;
    
    if (timePerOutput > 0) {
      for (int i = 0; i < outputTypes.length; i++) {
        tasks.add(DailyTask(
          id: 'output_${DateTime.now().millisecondsSinceEpoch + 2 + i}',
          title: outputTypes[i],
          description: 'Practice this output skill.',
          type: 'output',
          category: 'Output',
          durationMinutes: timePerOutput,
          isCompleted: false,
        ));
      }
    } else if (outputMinutes > 0) {
       // Fallback if no specific types but time allocated
        tasks.add(DailyTask(
          id: 'output_gen_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Speaking / Writing Practice',
          description: 'Practice your output skills.',
          type: 'output',
          category: 'Output',
          durationMinutes: outputMinutes,
          isCompleted: false,
        ));
    }

    // Fix total duration matching (rounding errors)
    int calculatedTotal = tasks.fold(0, (sum, t) => sum + t.durationMinutes);
    if (calculatedTotal != totalMinutes && tasks.isNotEmpty) {
      // Adjust first task
      int diff = totalMinutes - calculatedTotal;
      int newDuration = tasks[0].durationMinutes + diff;
      if (newDuration > 0) {
        tasks[0] = tasks[0].copyWith(durationMinutes: newDuration);
      }
    }

    return DailyPlan(
      date: date,
      tasks: tasks,
      totalDurationMinutes: totalMinutes,
      completedDurationMinutes: 0,
    );
  }
}

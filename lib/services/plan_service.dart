import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plan_model.dart';
import '../models/user_model.dart';
import '../models/content_model.dart';

class PlanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Content Data ---

  // Beginner (A1/A2)
  static final List<TaskContent> _beginnerShows = [
    TaskContent('Peppa Pig', 'Simple language, daily vocabulary'),
    TaskContent('Extra English', 'Sitcom specifically for learners'),
    TaskContent('Muzzy in Gondoland', 'Classic educational content'),
    TaskContent('Ben and Holly’s Little Kingdom', 'Slow speech'),
    TaskContent('Dora the Explorer', 'Simple repetitions'),
  ];

  static final List<TaskContent> _beginnerBooks = [
    TaskContent('Penguin Readers – Level 1–2', 'Simplified classics'),
    TaskContent('Oxford Bookworms – Starter / Stage 1', 'Graded readers'),
    TaskContent('Cambridge English Readers – Starter', 'Beginner fiction'),
  ];

  // Intermediate (B1/B2)
  static final List<TaskContent> _intermediateShows = [
    TaskContent('Friends', 'Daily conversation, clear pronunciation'),
    TaskContent('How I Met Your Mother', 'Simple dialogue'),
    TaskContent('Modern Family', 'Natural but understandable'),
    TaskContent('The Good Place', 'Ideal language level'),
    TaskContent('Young Sheldon', 'Slow and clear English'),
    // B2 specific
    TaskContent('The Office (US)', 'Workplace humor (B2)'),
    TaskContent('Brooklyn 99', 'Police comedy (B2)'),
    TaskContent('Stranger Things', 'Sci-fi/Mystery (B2)'),
    TaskContent('Sherlock', 'Advanced vocabulary but exciting (B2)'),
  ];

  static final List<TaskContent> _intermediateBooks = [
    TaskContent('Oxford Bookworms Stage 3–4', 'Graded readers'),
    TaskContent('Penguin Readers Level 3–4', 'Graded readers'),
    TaskContent('Harry Potter 1–2', 'Simple fantasy'),
    TaskContent('The Curious Incident of the Dog in the Night-Time', 'Simple perspective'),
    TaskContent('Diary of a Wimpy Kid', 'Casual language'),
    TaskContent('The Giver', 'Dystopian fiction'),
    // B2
    TaskContent('The Alchemist', 'Philosophical but simple'),
    TaskContent('The Hunger Games', 'Engaging YA fiction'),
    TaskContent('The Hobbit', 'Classic fantasy'),
  ];

  // Advanced (C1)
  static final List<TaskContent> _advancedShows = [
    TaskContent('Breaking Bad', 'Complex slang and drama'),
    TaskContent('Game of Thrones', 'Archaic and complex'),
    TaskContent('House of Cards', 'Political jargon'),
    TaskContent('Black Mirror', 'Tech vocabulary and dialects'),
    TaskContent('The Crown', 'Formal British English'),
    TaskContent('Suits', 'Legal vocabulary'),
  ];

  static final List<TaskContent> _advancedBooks = [
    TaskContent('1984 – George Orwell', 'Political classic'),
    TaskContent('The Catcher in the Rye', 'Slang and colloquialisms'),
    TaskContent('To Kill a Mockingbird', 'Southern dialect'),
    TaskContent('The Great Gatsby', 'Literary prose'),
    TaskContent('Sapiens', 'Non-fiction content'),
  ];

  // --- Generation Logic ---

  Future<DailyPlan> getOrGenerateDailyPlan(UserModel user, List<ContentModel> libraryContents) async {
    final today = DateTime.now().toIso8601String().split('T').first; // YYYY-MM-DD
    final planRef = _firestore
        .collection('users')
        .doc(user.id)
        .collection('daily_plans')
        .doc(today);

    final doc = await planRef.get();
    if (doc.exists) {
      // Check if we need to update duration because of settings change
      DailyPlan existingPlan = DailyPlan.fromMap(doc.data()!);
      int targetMinutes = (user.dailyStudyGoal > 0 ? user.dailyStudyGoal : 1) * 60;
      
      if (existingPlan.totalDurationMinutes != targetMinutes) {
         // Re-balance the plan
         return _updatePlanDuration(existingPlan, targetMinutes, user, libraryContents);
      }
      return existingPlan;
    }

    // Generate new plan
    final plan = _generatePlan(user, today, libraryContents);
    
    // Save to Firestore
    await planRef.set(plan.toMap());
    
    return plan;
  }
  
  // Method to re-balance plan if settings change
  Future<DailyPlan> _updatePlanDuration(DailyPlan oldPlan, int newTotalMinutes, UserModel user, List<ContentModel> libraryContents) async {
     // If we are just scaling times, we can do that. But removing/adding tasks is cleaner if complete regeneration
     // However, we must preserve 'isCompleted' status of tasks.
     // Simple approach: Keep completed tasks, regenerate remaining time with new tasks.
     
     // For simplicity in this iteration: We will regenerate the whole plan structure but keep completed tasks if they match.
     // OR simpler: Just scaling the uncompleted tasks? 
     // Let's Regenerate a fresh plan logic but try to match existing content if possible.
     
     // Actually, simpler logic: Just regenerate from scratch using CURRENT library contents (which might be the same).
     // Ideally we want to persist the 'same' content the user was doing.
     
     // Let's just regenerate for the new duration using standard logic.
     final newPlan = _generatePlan(user, oldPlan.date, libraryContents);
     
     // If the old plan had completed tasks, we can't easily map them unless IDs match.
     // But since we generate new random IDs, we lose progress. 
     // Decision: For now, if user changes settings, it resets the day's progress OR we just scale.
     // Let's try to preserve completed tasks if their content title matches.
     
     List<DailyTask> preservedTasks = [];
     for(var oldTask in oldPlan.tasks) {
        if(oldTask.isCompleted) matched: {
             // If we found a match in newPlan, mark it. 
             // But newPlan is random. 
        }
     }
     
     // Better User Experience: Just Overwrite. 
     // "Changing your daily goal resets today's uncompleted tasks." - acceptable trade-off.
     
      final planRef = _firestore
        .collection('users')
        .doc(user.id)
        .collection('daily_plans')
        .doc(oldPlan.date);
        
      await planRef.set(newPlan.toMap());
      return newPlan;
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
    
    // Recalculate completed minutes (optional logic if we want to track specific progress)
    int completedMinutes = 0;
    for (var t in updatedTasks) {
      if (t.isCompleted) completedMinutes += t.durationMinutes;
    }

    final updatedPlan = DailyPlan(
      date: plan.date,
      tasks: updatedTasks,
      totalDurationMinutes: plan.totalDurationMinutes,
      completedDurationMinutes: completedMinutes,
    );
    
    await planRef.update(updatedPlan.toMap());
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

  DailyPlan _generatePlan(UserModel user, String date, List<ContentModel> libraryContents) {
    int totalMinutes = (user.dailyStudyGoal > 0 ? user.dailyStudyGoal : 1) * 60;
    String level = user.level; // Beginner, Intermediate, Advanced (or raw text)

    // Normalize level
    if (level.toLowerCase().contains('beginner') || level.contains('A1') || level.contains('A2')) {
      return _createPlan(date, totalMinutes, 0.85, _beginnerShows, _beginnerBooks, ['Shadowing', 'Mini writing'], libraryContents);
    } else if (level.toLowerCase().contains('advanced') || level.contains('C1') || level.contains('C2')) {
       return _createPlan(date, totalMinutes, 0.45, _advancedShows, _advancedBooks, ['Paragraph Writing', 'Speaking Practice', 'Interaction Output'], libraryContents);
    } else {
      // Default to Intermediate (B1/B2)
      return _createPlan(date, totalMinutes, 0.65, _intermediateShows, _intermediateBooks, ['Paragraph Writing', 'Speaking Practice', 'Interaction Output'], libraryContents);
    }
  }

  DailyPlan _createPlan(
    String date,
    int totalMinutes,
    double inputRatio,
    List<TaskContent> shows,
    List<TaskContent> books,
    List<String> outputTypes,
    List<ContentModel> libraryContents,
  ) {
    int inputMinutes = (totalMinutes * inputRatio).round();
    int outputMinutes = totalMinutes - inputMinutes;
    
    List<DailyTask> tasks = [];
    Random rnd = Random();

    // INPUT TASKS
    int watchMinutes = (inputMinutes * 0.6).round();
    int readMinutes = inputMinutes - watchMinutes;

    // --- Watch Task ---
    // 1. Try to find active SHOW in library
    var activeShows = libraryContents.where((c) => c.type == 'series' && !c.isCompleted).toList();
    ActiveContentSelection showSelection;
    
    if (activeShows.isNotEmpty) {
      // Pick first or random active show
      var existing = activeShows.first;
      showSelection = ActiveContentSelection(existing.title, 'Continue watching your series');
    } else {
      // Pick new random
       var newShow = shows[rnd.nextInt(shows.length)];
       showSelection = ActiveContentSelection(newShow.title, newShow.reason, isNew: true, type: 'series', level: 'Intermediate'); // simplified level assumption
    }

    tasks.add(DailyTask(
      id: 'watch_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Watch: ${showSelection.title}',
      description: showSelection.reason,
      type: 'input',
      category: 'Show',
      durationMinutes: watchMinutes,
      isCompleted: false,
      userContentData: showSelection.isNew ? {'new_content': 'true', 'type': 'series', 'title': showSelection.title} : null,
    ));

    // --- Read Task ---
    // 1. Try to find active BOOK in library
    var activeBooks = libraryContents.where((c) => c.type == 'book' && !c.isCompleted).toList();
    ActiveContentSelection bookSelection;
    
    if (activeBooks.isNotEmpty) {
       var existing = activeBooks.first;
       bookSelection = ActiveContentSelection(existing.title, 'Continue reading your book');
    } else {
       var newBook = books[rnd.nextInt(books.length)];
       bookSelection = ActiveContentSelection(newBook.title, newBook.reason, isNew: true, type: 'book', level: 'Intermediate');
    }

    tasks.add(DailyTask(
      id: 'read_${DateTime.now().millisecondsSinceEpoch + 1}',
      title: 'Read: ${bookSelection.title}',
      description: bookSelection.reason,
      type: 'input',
      category: 'Book',
      durationMinutes: readMinutes,
      isCompleted: false,
      userContentData: bookSelection.isNew ? {'new_content': 'true', 'type': 'book', 'title': bookSelection.title} : null,
    ));

    // OUTPUT TASKS
    int timePerOutput = (outputMinutes / outputTypes.length).round();
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

    return DailyPlan(
      date: date,
      tasks: tasks,
      totalDurationMinutes: totalMinutes,
      completedDurationMinutes: 0,
    );
  }
}

class ActiveContentSelection {
  final String title;
  final String reason;
  final bool isNew;
  final String? type;
  final String? level;

  ActiveContentSelection(this.title, this.reason, {this.isNew = false, this.type, this.level});
}

class TaskContent {
  final String title;
  final String reason;
  TaskContent(this.title, this.reason);
}

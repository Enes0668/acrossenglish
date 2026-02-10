import 'package:flutter/material.dart';
import '../models/content_model.dart';
import '../models/activity_model.dart';
import '../repositories/content_repository.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class ContentProvider with ChangeNotifier {
  // All available content from the repository
  final List<ContentModel> _allRepoContent = ContentRepository.allContent;

  List<ContentModel> get contents => _allRepoContent;


  // Content currently assigned to the user (Library)
  List<ContentModel> _activeContent = [];

  // Completed content IDs (synced with User)
  List<String> _completedIds = [];

  final List<ActivityModel> _history = [];

  List<ContentModel> get activeContent => _activeContent;
  List<ActivityModel> get history => _history;

  // Initialize or Sync with User
  // Call this when app starts or user logs in
  void initForUser(UserModel user) {
    _completedIds = List.from(user.completedContentIds);
    _loadActiveContentForUser(user);
    notifyListeners();
  }

  void _loadActiveContentForUser(UserModel user) {
    // Current Rule: User should have 1 Book and 1 Series active at all times
    // corresponding to their level.
    
    // 1. Check if we have an active Series
    bool hasSeries = _activeContent.any((c) => c.type == 'series' && !c.isCompleted);
    if (!hasSeries) {
      _assignNewContent(user.level, 'series');
    }

    // 2. Check if we have an active Book
    bool hasBook = _activeContent.any((c) => c.type == 'book' && !c.isCompleted);
    if (!hasBook) {
      _assignNewContent(user.level, 'book');
    }
  }

  void _assignNewContent(String level, String type) {
    // Find content of this level and type that is NOT completed
    // and NOT already active.
    
    // Normalized Level check
    var candidates = _allRepoContent.where((c) {
      return c.type == type && 
             c.level == level && 
             !_completedIds.contains(c.id) &&
             !_activeContent.any((active) => active.id == c.id);
    }).toList();

    if (candidates.isNotEmpty) {
      // Pick first or random
      candidates.shuffle();
      _activeContent.add(candidates.first);
    } else {
      // Fallback: If no content left for this level, maybe suggest next level? 
      // For now, just leave it empty or repeat (logic can be improved)
      debugPrint("No more $type content for level $level!");
    }
  }

  Future<void> markAsCompleted(String contentId) async {
    // 1. Find content
    final index = _activeContent.indexWhere((c) => c.id == contentId);
    if (index == -1) return;

    final content = _activeContent[index];
    
    // 2. Mark locally
    content.isCompleted = true;
    _activeContent.removeAt(index); // Remove from active list
    _completedIds.add(contentId);
    _addToHistory(contentId);

    // 3. Update User in Firestore (completedIds) + Check Level Up
    final authService = AuthService();
    final user = authService.currentUser;
    
    if (user != null) {
      // Clone user and update list
      List<String> newCompleted = List.from(user.completedContentIds)..add(contentId);
      
      // LEVEL UP LOGIC
      // Simple rule: 2 items (1 book + 1 series) = +10 score. 
      // Level thresholds: Beginner (0-50), Intermediate (50-100), Advanced (100+)
      // Or simple count: Complete 3 items to level up.
      
      int currentScore = int.tryParse(user.levelScore) ?? 0;
      int newScore = currentScore + 10; 
      String newLevel = user.level;

      if (newLevel == 'Beginner' && newScore >= 30) { // 3 items
         newLevel = 'Intermediate';
         newScore = 0; // Reset score for next level or keep accumulating? Let's keep accumulating.
      } else if (newLevel == 'Intermediate' && newScore >= 80) { // 5 more items
         newLevel = 'Advanced';
      }

      // Update User Model locally (optimistic) and remote
      // We need a method in AuthService or FirestoreService to update these fields.
      // Assuming AuthService has direct access or we use a UserService.
      // For now, let's assume we can call a method similar to update used elsewhere.
      
      await authService.updateUserProgress(
        user.id, 
        completedContentIds: newCompleted,
        level: newLevel,
        levelScore: newScore.toString()
      );
      
      // 4. Assign Replacement Content (based on possibly NEW level)
      // Since we just awaited the update, AuthService.currentUser should ideally be updated 
      // OR we manually trigger logic with new params.
      
      // Let's refetch user to be safe or use local vars
      _assignNewContent(newLevel, content.type);
    }

    notifyListeners();
  }
  
  // Method to add new content (manually if needed)
  void addNewContent(ContentModel content) {
    if (!_activeContent.any((c) => c.id == content.id)) {
      _activeContent.add(content);
      notifyListeners();
    }
  }

  void _addToHistory(String contentId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final existingIndex = _history.indexWhere((h) => 
      h.date.year == today.year && 
      h.date.month == today.month && 
      h.date.day == today.day
    );

    if (existingIndex != -1) {
      final existing = _history[existingIndex];
       // Check if already in history to avoid dupe stats if multiple clicks
       if(!existing.completedContentIds.contains(contentId)) {
          _history[existingIndex] = ActivityModel(
            date: existing.date,
            completedContentIds: [...existing.completedContentIds, contentId],
            studyDurationMinutes: existing.studyDurationMinutes,
          );
       }
    } else {
      _history.add(ActivityModel(
        date: today, 
        completedContentIds: [contentId], 
        studyDurationMinutes: 0
      ));
    }
  }
}

import 'package:flutter/material.dart';
import '../models/content_model.dart';
import '../models/activity_model.dart';

class ContentProvider with ChangeNotifier {
  final List<ContentModel> _contents = [
    // Mock Data
    ContentModel(
      id: '1',
      title: 'The Little Prince',
      imageUrl: 'https://m.media-amazon.com/images/I/71OZyJBkd+L._AC_UF1000,1000_QL80_.jpg', // Placeholder
      type: 'book',
      level: 'Pre-Intermediate',
    ),
    ContentModel(
      id: '2',
      title: 'Harry Potter',
      imageUrl: 'https://m.media-amazon.com/images/I/71-++hbbERL._AC_UF1000,1000_QL80_.jpg',
      type: 'book',
      level: 'Intermediate',
    ),
    ContentModel(
      id: '3',
      title: 'Friends',
      imageUrl: 'https://m.media-amazon.com/images/M/MV5BNDVkYjU0MzctMzg1YS00NzE3LWhhYWQtMTRmZTE3NjA5YzdhXkEyXkFqcGdeQXVyMTEyMjM2NDc2._V1_FMjpg_UX1000_.jpg',
      type: 'series',
      level: 'Intermediate',
    ),
     ContentModel(
      id: '4',
      title: 'Sherlock',
      imageUrl: 'https://m.media-amazon.com/images/M/MV5BMWY3NTljMjEtYzRiMi00NWM2LTkzNjItAwYzZjE3ODI3NjE3XkEyXkFqcGdeQXVyMjYwNDA2MDE@._V1_.jpg',
      type: 'series',
      level: 'Advanced',
    ),
  ];

  final List<ActivityModel> _history = [];

  List<ContentModel> get contents => _contents;
  List<ActivityModel> get history => _history;

    // Get active (not completed) content
  List<ContentModel> get activeContent => 
      _contents.where((c) => !c.isCompleted).toList();


  void markAsCompleted(String contentId) {
    final index = _contents.indexWhere((c) => c.id == contentId);
    if (index != -1) {
      _contents[index].isCompleted = true;
      _addToHistory(contentId);
      notifyListeners();
    }
  }
  
  // Method to add new content (called when user runs out of active content)
  void addNewContent(ContentModel content) {
    // Avoid duplicates
    if (!_contents.any((c) => c.title == content.title)) {
      _contents.add(content);
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
      _history[existingIndex] = ActivityModel(
        date: existing.date,
        completedContentIds: [...existing.completedContentIds, contentId],
        studyDurationMinutes: existing.studyDurationMinutes,
      );
    } else {
      _history.add(ActivityModel(
        date: today, 
        completedContentIds: [contentId], 
        studyDurationMinutes: 0
      ));
    }
  }
}

class DailyPlan {
  final String date;
  final List<DailyTask> tasks;
  final int totalDurationMinutes;
  final int completedDurationMinutes;

  DailyPlan({
    required this.date,
    required this.tasks,
    required this.totalDurationMinutes,
    required this.completedDurationMinutes,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'tasks': tasks.map((t) => t.toMap()).toList(),
      'totalDurationMinutes': totalDurationMinutes,
      'completedDurationMinutes': completedDurationMinutes,
    };
  }

  factory DailyPlan.fromMap(Map<String, dynamic> map) {
    return DailyPlan(
      date: map['date'] ?? '',
      tasks: List<DailyTask>.from(
        (map['tasks'] as List<dynamic>? ?? []).map((x) => DailyTask.fromMap(x)),
      ),
      totalDurationMinutes: map['totalDurationMinutes'] ?? 0,
      completedDurationMinutes: map['completedDurationMinutes'] ?? 0,
    );
  }
}

class DailyTask {
  final String id;
  final String title;
  final String description; // "Why is it suitable?" or details
  final String type; // 'input' or 'output'
  final String category; // 'Show', 'Book', 'Writing', 'Speaking'
  final Map<String, String>? userContentData;
  final int durationMinutes;
  final bool isCompleted;

  DailyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.durationMinutes,
    required this.isCompleted,
    this.userContentData,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'category': category,
      'durationMinutes': durationMinutes,
      'isCompleted': isCompleted,
      'userContentData': userContentData,
    };
  }

  factory DailyTask.fromMap(Map<String, dynamic> map) {
    return DailyTask(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? '',
      category: map['category'] ?? '',
      durationMinutes: map['durationMinutes'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      userContentData: map['userContentData'] != null ? Map<String, String>.from(map['userContentData']) : null,
    );
  }

  DailyTask copyWith({
    String? title,
    String? description,
    String? type,
    String? category,
    int? durationMinutes,
    bool? isCompleted,
    Map<String, String>? userContentData,
  }) {
    return DailyTask(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      userContentData: userContentData ?? this.userContentData,
    );
  }
}

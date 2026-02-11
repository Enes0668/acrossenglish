class UserModel {
  final String id;
  final String email;
  final String username;
  final String password;
  final String createdAt;
  final String lastLogin;
  final String dailyTime;
  final String level;
  final String levelScore;
  final int dailyStudyMinutes;
  final int currentStreak;
  final int bestStreak;
  final String lastCompletedDate;
  final List<String> completedContentIds;
  final String notificationTime;
  final bool isNotificationsEnabled;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.password,
    required this.createdAt,
    required this.lastLogin,
    required this.dailyTime,
    required this.level,
    required this.levelScore,
    this.dailyStudyMinutes = 30,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastCompletedDate = '',
    this.completedContentIds = const [],
    this.notificationTime = '',
    this.isNotificationsEnabled = true,
  });

  // Factory method to create a UserModel from a Map (Firestore data)
  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    // Handle migration from dailyStudyGoal (hours) to dailyStudyMinutes
    int minutes = 30;
    if (data.containsKey('dailyStudyMinutes')) {
      minutes = (data['dailyStudyMinutes'] ?? 30) as int;
    } else if (data.containsKey('dailyStudyGoal')) {
      // Assuming old goal was hours, convert to minutes. 
      // Safely handle if it was stored as int or string
      var oldGoal = data['dailyStudyGoal'];
      if (oldGoal is int) {
         minutes = oldGoal * 60;
      } else if (oldGoal is String) {
         minutes = (int.tryParse(oldGoal) ?? 1) * 60;
      }
    }

    return UserModel(
      id: documentId,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      password: data['password'] ?? '',
      createdAt: data['createdAt'] ?? '',
      lastLogin: data['lastLogin'] ?? '',
      dailyTime: data['dailyTime'] ?? '0',
      level: data['level'] ?? 'Beginner',
      levelScore: data['levelScore'] ?? '0',
      dailyStudyMinutes: minutes,
      currentStreak: (data['currentStreak'] ?? 0) as int,
      bestStreak: (data['bestStreak'] ?? 0) as int,
      lastCompletedDate: data['lastCompletedDate'] ?? '',
      completedContentIds: List<String>.from(data['completedContentIds'] ?? []),
      notificationTime: data['notificationTime'] ?? '',
      isNotificationsEnabled: data['isNotificationsEnabled'] ?? true,
    );
  }

  // Method to convert UserModel to a Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'password': password,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
      'dailyTime': dailyTime,
      'level': level,
      'levelScore': levelScore,
      'dailyStudyMinutes': dailyStudyMinutes,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'lastCompletedDate': lastCompletedDate,
      'completedContentIds': completedContentIds,
      'notificationTime': notificationTime,
      'isNotificationsEnabled': isNotificationsEnabled,
    };
  }
}

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
  final int dailyStudyGoal;

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
    this.dailyStudyGoal = 0,
  });

  // Factory method to create a UserModel from a Map (Firestore data)
  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      id: documentId,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      password: data['password'] ?? '',
      createdAt: data['createdAt'] ?? '',
      lastLogin: data['lastLogin'] ?? '',
      dailyTime: data['dailyTime'] ?? '0',
      level: data['level'] ?? '1',
      levelScore: data['levelScore'] ?? '0',
      dailyStudyGoal: (data['dailyStudyGoal'] ?? 0) as int,
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
      'dailyStudyGoal': dailyStudyGoal,
    };
  }
}

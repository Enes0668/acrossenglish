import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class SettingsProvider with ChangeNotifier {
  bool _notificationsEnabled = true;
  int _dailyGoalMinutes = 30;
  String _notificationTime = ''; // Format "HH:mm"

  bool get notificationsEnabled => _notificationsEnabled;
  int get dailyGoalMinutes => _dailyGoalMinutes;
  String get notificationTime => _notificationTime;

  SettingsProvider() {
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    _dailyGoalMinutes = prefs.getInt('dailyGoalMinutes') ?? 30;
    _notificationTime = prefs.getString('notificationTime') ?? '';
    
    // Also try to sync from User model if logged in
    final user = AuthService().currentUser;
    if (user != null) {
        _notificationsEnabled = user.isNotificationsEnabled;
        _notificationTime = user.notificationTime;
        _dailyGoalMinutes = user.dailyStudyMinutes;
    }
    notifyListeners();
  }

  Future<void> setNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', enabled);

    final user = AuthService().currentUser;
    if (user != null) {
      await AuthService().updateNotificationPreferences(
        user.id, 
        time: _notificationTime, 
        enabled: enabled
      );
    }
     
    if (enabled && _notificationTime.isNotEmpty) {
      _scheduleNotification(_notificationTime);
    } else {
      NotificationService().cancelNotifications();
    }
  }

  Future<void> setNotificationTime(String time) async {
    _notificationTime = time;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notificationTime', time);

    final user = AuthService().currentUser;
    if (user != null) {
      await AuthService().updateNotificationPreferences(
        user.id, 
        time: time, 
        enabled: _notificationsEnabled
      );
    }

    if (_notificationsEnabled) {
      _scheduleNotification(time);
    }
  }
  
  void _scheduleNotification(String timeStr) {
      try {
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        
        NotificationService().scheduleDailyNotification(
            id: 0, 
            title: "Time to Study!", 
            body: "Keep up your streak! It's time for your daily English practice.", 
            hour: hour, 
            minute: minute
        );
      } catch (e) {
          debugPrint("Error scheduling notification: $e");
      }
  }

  void setDailyGoal(int minutes) async {
    _dailyGoalMinutes = minutes;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dailyGoalMinutes', minutes);
  }
}

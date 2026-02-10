import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _notificationsEnabled = true;
  int _dailyGoalMinutes = 30;

  bool get notificationsEnabled => _notificationsEnabled;
  int get dailyGoalMinutes => _dailyGoalMinutes;

  SettingsProvider() {
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    _dailyGoalMinutes = prefs.getInt('dailyGoalMinutes') ?? 30;
    notifyListeners();
  }

  void setNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', enabled);
  }

  void setDailyGoal(int minutes) async {
    _dailyGoalMinutes = minutes;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dailyGoalMinutes', minutes);
  }
}

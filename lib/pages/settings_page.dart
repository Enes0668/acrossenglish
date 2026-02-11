import 'package:acrossenglish/providers/settings_provider.dart';
import 'package:acrossenglish/providers/theme_provider.dart';
import 'package:acrossenglish/services/auth_service.dart';
import 'package:acrossenglish/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer2<SettingsProvider, ThemeProvider>(
        builder: (context, settings, theme, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader(context, 'Preferences'),
              SwitchListTile(
                title: const Text('Notifications'),
                subtitle: const Text('Get daily reminders to practice'),
                value: settings.notificationsEnabled,
                onChanged: (value) async {
                  if (value) {
                    await NotificationService().requestPermissions();
                  }
                  settings.setNotifications(value);
                },
              ),
              SwitchListTile(
                title: const Text('Dark Theme'),
                subtitle: const Text('Switch between light and dark mode'),
                value: theme.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  theme.toggleTheme(value);
                },
              ),
              if (settings.notificationsEnabled)
                ListTile(
                  title: const Text('Reminder Time'),
                  subtitle: Text(settings.notificationTime.isEmpty ? 'Not set' : settings.notificationTime),
                  trailing: const Icon(Icons.edit),
                  onTap: () async {
                    TimeOfDay initialTime = TimeOfDay.now();
                    if (settings.notificationTime.isNotEmpty) {
                      try {
                        final parts = settings.notificationTime.split(':');
                        initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
                      } catch (_) {}
                    }
                    
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: initialTime,
                    );
                    
                    if (picked != null) {
                       final hour = picked.hour.toString().padLeft(2, '0');
                       final minute = picked.minute.toString().padLeft(2, '0');
                       settings.setNotificationTime('$hour:$minute');
                    }
                  },
                ),
              const Divider(),
              _buildSectionHeader(context, 'Study Goals'),
              ListTile(
                title: const Text('Daily Study Goal'),
                subtitle: Text('${settings.dailyGoalMinutes} minutes per day'),
                trailing: DropdownButton<int>(
                  value: settings.dailyGoalMinutes,
                  items: [30, 45, 60, 90, 120].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value min'),
                    );
                  }).toList(),
                  onChanged: (int? newValue) async {
                    if (newValue != null) {
                      settings.setDailyGoal(newValue);
                      // Sync with Firestore
                      final user = AuthService().currentUser;
                      if (user != null) {
                        await AuthService().updateDailyStudyMinutes(user.id, newValue);
                      }
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white 
              : Colors.deepPurple,
        ),
      ),
    );
  }
}

import 'package:acrossenglish/providers/settings_provider.dart';
import 'package:acrossenglish/providers/theme_provider.dart';
import 'package:acrossenglish/services/auth_service.dart';
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
              _buildSectionHeader('Preferences'),
              SwitchListTile(
                title: const Text('Notifications'),
                subtitle: const Text('Get daily reminders to practice'),
                value: settings.notificationsEnabled,
                onChanged: (value) {
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
              const Divider(),
              _buildSectionHeader('Study Goals'),
              ListTile(
                title: const Text('Daily Study Goal'),
                subtitle: Text('${settings.dailyGoalHours} hours per day'),
                trailing: DropdownButton<int>(
                  value: settings.dailyGoalHours,
                  items: [1, 2, 3, 4].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value h'),
                    );
                  }).toList(),
                  onChanged: (int? newValue) async {
                    if (newValue != null) {
                      settings.setDailyGoal(newValue);
                      // Sync with Firestore
                      final user = AuthService().currentUser;
                      if (user != null) {
                        await AuthService().updateDailyStudyGoal(user.id, newValue);
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }
}

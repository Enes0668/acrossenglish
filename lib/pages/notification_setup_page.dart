import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import 'main_screen.dart';

class NotificationSetupPage extends StatefulWidget {
  const NotificationSetupPage({super.key});

  @override
  State<NotificationSetupPage> createState() => _NotificationSetupPageState();
}

class _NotificationSetupPageState extends State<NotificationSetupPage> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 20, minute: 0); // Default 8 PM
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Request permissions immediately when landing on this page
    NotificationService().requestPermissions();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _saveAndContinue() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      
      // Save time and enable notifications
      // Format time as HH:mm
      final timeString = _formatTime(_selectedTime);
      
      await settingsProvider.setNotificationTime(timeString);
      await settingsProvider.setNotifications(true);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _skip() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.notifications_active_outlined,
                size: 80,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 32),
              const Text(
                'Set a Daily Reminder',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Consistency is key! Choose a time when you can dedicate 15-30 minutes to study English.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              
              InkWell(
                onTap: () => _selectTime(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.deepPurple.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Daily Reminder Time',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _selectedTime.format(context),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                ElevatedButton(
                  onPressed: _saveAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Set Reminder & Continue',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                TextButton(
                  onPressed: _skip,
                  child: const Text('I\'ll set it later'),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

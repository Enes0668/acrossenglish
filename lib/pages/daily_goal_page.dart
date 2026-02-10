import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'main_screen.dart'; // Navigate to MainScreen, not just HomePage which is a sub-tab

class DailyGoalPage extends StatefulWidget {
  const DailyGoalPage({super.key});

  @override
  State<DailyGoalPage> createState() => _DailyGoalPageState();
}

class _DailyGoalPageState extends State<DailyGoalPage> {
  int? _selectedMinutes;
  bool _isLoading = false;

  void _saveGoal() async {
    if (_selectedMinutes == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = AuthService().currentUser;
      if (user != null) {
        await AuthService().updateDailyStudyMinutes(user.id, _selectedMinutes!);
        
        if (mounted) {
           // Update local provider to avoid mismatch loop on Home Page
           Provider.of<SettingsProvider>(context, listen: false).setDailyGoal(_selectedMinutes!);

           Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving goal: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple, Colors.indigo],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Set Your Daily Goal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'How much time would you like to dedicate to learning English each day?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: ListView(
                    children: [30, 45, 60, 90, 120].map((minutes) => Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedMinutes = minutes;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                              decoration: BoxDecoration(
                                color: _selectedMinutes == minutes
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$minutes Minutes',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedMinutes == minutes
                                          ? Colors.deepPurple
                                          : Colors.white,
                                    ),
                                  ),
                                  if (_selectedMinutes == minutes)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.deepPurple,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        )).toList(),
                  ),
                ),
                ElevatedButton(
                  onPressed: _selectedMinutes != null && !_isLoading ? _saveGoal : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'CONTINUE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

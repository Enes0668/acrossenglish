import 'package:flutter/material.dart';
import '../data/level_test_data.dart';
import '../services/auth_service.dart';

class LevelTestPage extends StatefulWidget {
  const LevelTestPage({super.key});

  @override
  State<LevelTestPage> createState() => _LevelTestPageState();
}

class _LevelTestPageState extends State<LevelTestPage> {
  // Test State
  List<Question> _currentBatch = [];
  int _currentQuestionIndex = 0; // Index within the batch (0-4)
  int _batchScore = 0;
  String _currentLevel = "A2"; // Start at A2
  int _totalQuestionsAnswered = 0;
  
  // Track used questions to prevent repetition
  final Set<String> _usedQuestionContexts = {};
  
  // UI State
  String? _selectedOption;
  bool _isLoading = false;

  final List<String> _levels = ["A1", "A2", "B1", "B2", "C1"];

  @override
  void initState() {
    super.initState();
    _loadQuestionsForLevel(_currentLevel);
  }

  void _loadQuestionsForLevel(String level) {
    setState(() {
      _currentLevel = level;
      
      // Get all questions, remove used ones, shuffle, and take 5
      List<Question> availableQuestions = List.from(levelTestQuestions[level] ?? []);
      availableQuestions.removeWhere((q) => _usedQuestionContexts.contains(q.context));
      availableQuestions.shuffle();
      
      // Take up to 5 questions
      int count = availableQuestions.length < 5 ? availableQuestions.length : 5;
      
      if (count == 0) {
        // No questions left for this level? 
        // In a real app we might reset used questions or just finish.
        // For now, let's finish the test to avoid "Error loading questions" or infinite loop.
        // We'll treat it as stabilized at this level.
         _finishTest(_currentLevel);
         return;
      }

      _currentBatch = availableQuestions.sublist(0, count);
      
      // Mark these as used
      for (var q in _currentBatch) {
        _usedQuestionContexts.add(q.context);
      }

      _currentQuestionIndex = 0;
      _batchScore = 0;
      _selectedOption = null;
    });
  }

  void _answerQuestion() {
     if (_selectedOption == null) return;

    // Check answer
    if (_selectedOption == _currentBatch[_currentQuestionIndex].options[_currentBatch[_currentQuestionIndex].correctAnswerIndex]) {
      _batchScore++;
    }

    _totalQuestionsAnswered++;

    if (_currentQuestionIndex < _currentBatch.length - 1) {
      // Next question in batch
      setState(() {
        _currentQuestionIndex++;
        _selectedOption = null;
      });
    } else {
      // Batch finished
      _evaluateBatch();
    }
  }

  void _evaluateBatch() {
    // Adaptive Logic
    // 0-2 correct -> Move DOWN
    // 3 correct -> Stay (Stabilized) -> FINISH
    // 4-5 correct -> Move UP
    
    // Stop condition: 15 questions max
    if (_totalQuestionsAnswered >= 15) {
      _finishTest(_currentLevel); // End at current level approximation
      return;
    }

    if (_batchScore <= 2) {
      // Move DOWN
      int currentIndex = _levels.indexOf(_currentLevel);
      if (currentIndex > 0) {
        String nextLevel = _levels[currentIndex - 1];
        _loadQuestionsForLevel(nextLevel);
      } else {
        // Already at A1 and failed -> Finish at A1
        _finishTest("A1");
      }
    } else if (_batchScore == 3) {
      // Stabilized
      _finishTest(_currentLevel);
    } else {
      // Move UP (4-5 correct)
      int currentIndex = _levels.indexOf(_currentLevel);
      if (currentIndex < _levels.length - 1) {
        String nextLevel = _levels[currentIndex + 1];
        _loadQuestionsForLevel(nextLevel);
      } else {
        // Already at Max (C1) and passed -> Finish at C1
        _finishTest("C1");
      }
    }
  }

  void _finishTest(String finalLevel) {
    _showResultDialog(finalLevel);
  }

  void _showResultDialog(String level) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Test Completed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 20),
            const Text(
              'Your estimated English level is:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              level,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 10),
            Text(
              _getLevelDescription(level),
               textAlign: TextAlign.center,
               style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
               // Save result and go home
               final user = AuthService().currentUser;
               if (user != null) {
                 try {
                   // We save the level. Score is less relevant across adaptive levels, but we can save the last batch score or just 'N/A'
                   await AuthService().updateUserLevel(user.id, level, "Adaptive");
                 } catch (e) {
                   debugPrint('Error saving result: $e');
                 }
               }
               if (context.mounted) {
                 // pop the dialog
                 Navigator.of(context).pop(); 
                 
                 // POP THE PAGE to go back to Home
                 Navigator.of(context).pop();
               }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  String _getLevelDescription(String level) {
    switch (level) {
      case "A1": return "Beginner";
      case "A2": return "Elementary";
      case "B1": return "Intermediate";
      case "B2": return "Upper Intermediate";
      case "C1": return "Advanced";
      default: return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentBatch.isEmpty) {
       return const Scaffold(body: Center(child: Text("Error loading questions")));
    }

    final question = _currentBatch[_currentQuestionIndex];
    // Progress is tricky in adaptive, maybe just show "Question X" without total, or "Question X / 15" (max)
    final double progress = _totalQuestionsAnswered / 15.0; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('English Level Test'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(), // Hide back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              color: Colors.deepPurple,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_totalQuestionsAnswered + 1}', // Absolute count
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                 // Debug indicator (optional, maybe remove for prod)
                 // Text("Level: $_currentLevel", style: TextStyle(color: Colors.grey[400])),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.1)),
              ),
              child: Text(
                question.context,
                style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              question.question,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: question.options.map((option) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedOption = option;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: _selectedOption == option ? Colors.deepPurple.withValues(alpha: 0.1) : null,
                      side: BorderSide(
                        color: _selectedOption == option ? Colors.deepPurple : Colors.grey[300]!,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedOption == option ? Colors.deepPurple : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ),
            ElevatedButton(
              onPressed: _selectedOption == null ? null : _answerQuestion,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'NEXT',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

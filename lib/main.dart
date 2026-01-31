import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'pages/welcome_page.dart';
import 'pages/level_test_page.dart';
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Across English',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Create a singleton instance or use a provider in a real app
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    // If AuthService was created here, we might want to dispose it, 
    // but since it uses a broadcast stream and mimics a singleton service, 
    // we just leave it be or implement better DI.
    // _authService.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Since we are using a StreamController without an initial value seeded in the stream itself 
        // (unless we seed it), the first event might be null or waiting.
        // However, for this simple implementation, we can check if data exists.
        
        if (snapshot.hasData) {
          final user = snapshot.data!;
          if (user.level == 'I would like a level test') {
            return const LevelTestPage();
          }
          return const HomePage();
        } else {
          return const WelcomePage();
        }
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Across English'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, ${user?.username ?? 'User'}!'),
            const SizedBox(height: 10),
            Text('Email: ${user?.email ?? ''}'),
            const SizedBox(height: 20),
            const Text('You are logged in.'),
          ],
        ),
      ),
    );
  }
}

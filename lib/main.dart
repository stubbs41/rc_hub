import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_screen.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  final supabaseService = SupabaseService();
  await supabaseService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RC Hub',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final SupabaseService _supabaseService = SupabaseService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _supabaseService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.session != null) {
          // User is authenticated, show home screen
          return const HomeScreen();
        } else {
          // User is not authenticated, show auth screen
          return const AuthScreen();
        }
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SupabaseService _supabaseService = SupabaseService();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('RC Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _supabaseService.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to RC Hub!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Logged in as: ${_supabaseService.currentUser?.email}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            const Text(
              'Your RC Garage is empty.',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to add vehicle screen
              },
              child: const Text('Add Your First RC Vehicle'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_hub/screens/auth_screen.dart';
import 'package:rc_hub/services/supabase_service.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mock SupabaseService
class MockSupabaseService extends Mock implements SupabaseService {
  @override
  Future<AuthResponse> signIn({required String email, required String password}) async {
    // Return a successful response for testing
    return Future.value(AuthResponse(
      session: Session(
        accessToken: 'test_token',
        tokenType: '',
        refreshToken: '',
        expiresIn: 3600,
        user: User(
          id: 'test_user_id',
          appMetadata: {},
          userMetadata: {},
          aud: '',
          email: email,
          createdAt: '',
        ),
      ),
      user: User(
        id: 'test_user_id',
        appMetadata: {},
        userMetadata: {},
        aud: '',
        email: email,
        createdAt: '',
      ),
    ));
  }

  @override
  Future<AuthResponse> signUp({required String email, required String password}) async {
    // Return a successful response for testing
    return Future.value(AuthResponse(
      session: Session(
        accessToken: 'test_token',
        tokenType: '',
        refreshToken: '',
        expiresIn: 3600,
        user: User(
          id: 'test_user_id',
          appMetadata: {},
          userMetadata: {},
          aud: '',
          email: email,
          createdAt: '',
        ),
      ),
      user: User(
        id: 'test_user_id',
        appMetadata: {},
        userMetadata: {},
        aud: '',
        email: email,
        createdAt: '',
      ),
    ));
  }
}

void main() {
  group('AuthScreen Tests', () {
    testWidgets('AuthScreen renders correctly', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(),
        ),
      );

      // Verify that the login form is displayed
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('RC Hub'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password fields
      expect(find.byType(ElevatedButton), findsOneWidget); // Login button
    });

    testWidgets('Can toggle between login and signup', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(),
        ),
      );

      // Initially in login mode
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Don\'t have an account? Sign Up'), findsOneWidget);

      // Tap the toggle button
      await tester.tap(find.text('Don\'t have an account? Sign Up'));
      await tester.pump();

      // Now in signup mode
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Already have an account? Login'), findsOneWidget);
    });

    // More tests would be added for form validation, submission, error handling, etc.
  });
}

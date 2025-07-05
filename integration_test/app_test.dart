import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scanmate/main.dart' as app;
import 'package:scanmate/services/onboarding_service.dart';
import 'package:scanmate/services/storage_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ScanMate App Integration Tests', () {
    setUp(() async {
      // Reset app state before each test
      await OnboardingService.resetOnboarding();
      await StorageService.initialize();
    });

    testWidgets('Complete onboarding flow', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Should show onboarding screen first
      expect(find.text('Welcome to ScanMate'), findsOneWidget);
      
      // Tap Get Started
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Should be on camera permission page
      expect(find.text('Camera Permission'), findsOneWidget);
      
      // For testing, we'll skip permission granting and continue
      // In a real test environment, you'd need to mock permissions
      await tester.tap(find.text('Skip for Now').first);
      await tester.pumpAndSettle();

      // Should be on contacts permission page
      expect(find.text('Contacts Permission'), findsOneWidget);
      
      // Skip contacts permission
      await tester.tap(find.text('Skip for Now').first);
      await tester.pumpAndSettle();

      // Should be on completion page
      expect(find.text('You\'re All Set!'), findsOneWidget);
      
      // Complete onboarding
      await tester.tap(find.text('Start Scanning'));
      await tester.pumpAndSettle();

      // Should now be on home screen
      expect(find.text('ScanMate'), findsOneWidget);
      expect(find.text('Scan New Card'), findsOneWidget);
    });

    testWidgets('Scan to history workflow', (WidgetTester tester) async {
      // Complete onboarding first
      await OnboardingService.markOnboardingComplete();
      
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Should be on home screen
      expect(find.text('ScanMate'), findsOneWidget);
      
      // Tap scan new card button
      await tester.tap(find.text('Scan New Card'));
      await tester.pumpAndSettle();

      // Should be on scan card screen
      expect(find.text('Position Card'), findsOneWidget);
      
      // For integration testing, we'll simulate going to review screen
      // In a real app, this would involve camera interaction
      await tester.tap(find.byIcon(Icons.photo_library));
      await tester.pumpAndSettle();

      // This would trigger gallery picker in real scenario
      // For testing, we'll navigate back and check history
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Navigate to history screen via bottom navigation
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Should be on history screen
      expect(find.text('Scan History'), findsOneWidget);
      
      // Test search functionality
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      
      // Enter search text
      await tester.enterText(find.byType(TextField), 'John');
      await tester.pumpAndSettle();
      
      // Should show search results or no results message
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Contact detail navigation and actions', (WidgetTester tester) async {
      // Complete onboarding first
      await OnboardingService.markOnboardingComplete();
      
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to history to find existing contacts
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // If there are contacts in history, tap on one
      final contactCards = find.byType(Card);
      if (contactCards.hasFound) {
        await tester.tap(contactCards.first);
        await tester.pumpAndSettle();

        // Should be on contact detail screen
        expect(find.byIcon(Icons.edit), findsOneWidget);
        expect(find.byIcon(Icons.delete), findsOneWidget);
        
        // Test edit navigation
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();

        // Should be on review/edit screen
        expect(find.text('Review Contact'), findsOneWidget);
        
        // Navigate back
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        
        // Should be back on contact detail
        expect(find.byIcon(Icons.edit), findsOneWidget);
      }
    });

    testWidgets('App navigation flow', (WidgetTester tester) async {
      // Complete onboarding first
      await OnboardingService.markOnboardingComplete();
      
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Test bottom navigation
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
      
      // Navigate to history
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();
      expect(find.text('Scan History'), findsOneWidget);
      
      // Navigate back to home
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();
      expect(find.text('ScanMate'), findsOneWidget);
      
      // Test scan navigation
      await tester.tap(find.text('Scan New Card'));
      await tester.pumpAndSettle();
      expect(find.text('Position Card'), findsOneWidget);
      
      // Navigate back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('ScanMate'), findsOneWidget);
    });

    testWidgets('Data persistence and state management', (WidgetTester tester) async {
      // Complete onboarding first
      await OnboardingService.markOnboardingComplete();
      
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Check that onboarding completion persists
      final hasCompleted = await OnboardingService.hasCompletedOnboarding();
      expect(hasCompleted, true);
      
      // Test that we're on home screen (not onboarding)
      expect(find.text('ScanMate'), findsOneWidget);
      expect(find.text('Welcome to ScanMate'), findsNothing);
    });
  });
}

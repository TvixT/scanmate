import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scanmate/main.dart' as app;
import 'package:scanmate/services/onboarding_service.dart';
import 'package:scanmate/services/storage_service.dart';
import 'package:scanmate/models/contact.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Scan to History Workflow Tests', () {
    setUp(() async {
      // Initialize services and complete onboarding for testing
      await StorageService.initialize();
      await OnboardingService.markOnboardingComplete();
    });

    testWidgets('End-to-end scan workflow simulation', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify we're on home screen (onboarding completed)
      expect(find.text('ScanMate'), findsOneWidget);
      expect(find.text('Scan New Card'), findsOneWidget);

      // Tap the scan button
      await tester.tap(find.text('Scan New Card'));
      await tester.pumpAndSettle();

      // Should be on scan screen
      expect(find.text('Position Card'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);

      // Simulate selecting from gallery (most testable option)
      await tester.tap(find.byIcon(Icons.photo_library));
      await tester.pumpAndSettle();

      // Note: In a real test environment, you'd need to mock the image picker
      // For this demo, we'll simulate the result by adding a contact directly
      await _simulateSuccessfulScan(tester);
    });

    testWidgets('Contact creation and history verification', (WidgetTester tester) async {
      // Create a test contact to simulate scan result
      final testContact = Contact(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Jane Smith',
        email: 'jane.smith@example.com',
        phone: '+1 (555) 987-6543',
        company: 'Design Co',
        title: 'UX Designer',
        website: 'https://designco.com',
        address: '456 Design Ave, Creative City',
        createdAt: DateTime.now(),
        source: 'camera',
        confidence: 0.92,
      );

      // Save the contact to storage
      await StorageService.saveContact(testContact);

      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to history screen
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Verify we're on history screen
      expect(find.text('Scan History'), findsOneWidget);

      // Look for our test contact
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Design Co'), findsOneWidget);

      // Tap on the contact to view details
      await tester.tap(find.text('Jane Smith'));
      await tester.pumpAndSettle();

      // Should be on contact detail screen
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('jane.smith@example.com'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('History search and filtering', (WidgetTester tester) async {
      // Create multiple test contacts
      final contacts = [
        Contact(
          id: 'test_1',
          name: 'Alice Johnson',
          email: 'alice@tech.com',
          company: 'Tech Corp',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          source: 'camera',
          confidence: 0.88,
        ),
        Contact(
          id: 'test_2',
          name: 'Bob Wilson',
          email: 'bob@sales.com',
          company: 'Sales Inc',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          source: 'gallery',
          confidence: 0.75,
        ),
      ];

      // Save all contacts
      for (final contact in contacts) {
        await StorageService.saveContact(contact);
      }

      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to history
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Verify both contacts are shown
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('Bob Wilson'), findsOneWidget);

      // Test search functionality
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Search for "Alice"
      await tester.enterText(find.byType(TextField), 'Alice');
      await tester.pumpAndSettle();

      // Should show only Alice
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('Bob Wilson'), findsNothing);

      // Clear search
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      // Both should be visible again
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('Bob Wilson'), findsOneWidget);
    });

    testWidgets('Contact editing workflow', (WidgetTester tester) async {
      // Create a test contact
      final testContact = Contact(
        id: 'edit_test',
        name: 'Edit Test',
        email: 'edit@test.com',
        phone: '+1 555 123 4567',
        company: 'Test Company',
        createdAt: DateTime.now(),
        source: 'camera',
        confidence: 0.85,
      );

      await StorageService.saveContact(testContact);

      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to history
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Tap on the test contact
      await tester.tap(find.text('Edit Test'));
      await tester.pumpAndSettle();

      // Tap edit button
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Should be on edit screen
      expect(find.text('Review Contact'), findsOneWidget);

      // Find name field and update it
      final nameField = find.widgetWithText(TextFormField, 'Edit Test');
      if (nameField.hasFound) {
        await tester.enterText(nameField, 'Updated Name');
        await tester.pumpAndSettle();
      }

      // Save changes
      await tester.tap(find.text('Save Contact'));
      await tester.pumpAndSettle();

      // Should navigate back to detail screen
      expect(find.text('Updated Name'), findsOneWidget);
    });

    testWidgets('Contact deletion workflow', (WidgetTester tester) async {
      // Create a test contact for deletion
      final testContact = Contact(
        id: 'delete_test',
        name: 'Delete Test',
        email: 'delete@test.com',
        company: 'Delete Co',
        createdAt: DateTime.now(),
        source: 'camera',
        confidence: 0.90,
      );

      await StorageService.saveContact(testContact);

      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to history
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Verify contact exists
      expect(find.text('Delete Test'), findsOneWidget);

      // Tap on the contact
      await tester.tap(find.text('Delete Test'));
      await tester.pumpAndSettle();

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Delete Contact'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Confirm deletion
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Should navigate back to history
      expect(find.text('Scan History'), findsOneWidget);

      // Contact should no longer exist
      expect(find.text('Delete Test'), findsNothing);
    });
  });
}

// Helper function to simulate successful scan workflow
Future<void> _simulateSuccessfulScan(WidgetTester tester) async {
  // In a real test, this would involve mocking the camera/gallery picker
  // and OCR results. For this demo, we'll navigate back to demonstrate
  // the workflow completion.
  
  // Navigate back from scan screen
  if (find.byIcon(Icons.arrow_back).hasFound) {
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
  }

  // Should be back on home screen
  expect(find.text('ScanMate'), findsOneWidget);
}

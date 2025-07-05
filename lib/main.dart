import 'package:flutter/material.dart';
import 'config/app_router.dart';
import 'services/storage_service.dart';
import 'models/contact.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage service (includes Hive initialization)
  await StorageService.initialize();
  
  // Add a test contact for debugging (remove in production)
  await _addTestContactIfNeeded();
  
  runApp(const MyApp());
}

Future<void> _addTestContactIfNeeded() async {
  try {
    final contacts = await StorageService.getAllContacts();
    if (contacts.isEmpty) {
      final testContact = Contact(
        id: '1751728470857', // Using the ID from the error for testing
        name: 'John Doe',
        email: 'john.doe@example.com',
        phone: '+1 (555) 123-4567',
        company: 'Tech Corp',
        title: 'Software Engineer',
        website: 'https://example.com',
        address: '123 Main St, City, State',
        createdAt: DateTime.now(),
        imagePath: null,
        source: 'camera',
        confidence: 0.85,
      );
      await StorageService.saveContact(testContact);
      print('Test contact added for debugging');
    }
  } catch (e) {
    print('Error adding test contact: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: Constants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(AppColors.primaryColor),
        ),
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
    );
  }
}


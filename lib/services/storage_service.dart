import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/contact.dart';
import '../utils/logger.dart';

class StorageService {
  static const String _contactsBoxName = 'contacts';
  static const String _imagesBoxName = 'images';
  static Box<Contact>? _contactsBox;
  static Box<String>? _imagesBox;

  /// Initialize Hive storage
  static Future<void> initialize() async {
    try {
      // Initialize Hive
      await Hive.initFlutter();
      
      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ContactAdapter());
      }

      // Open boxes
      _contactsBox = await Hive.openBox<Contact>(_contactsBoxName);
      _imagesBox = await Hive.openBox<String>(_imagesBoxName);
      
      Logger.info('Storage service initialized successfully');
    } catch (e) {
      Logger.error('Error initializing storage service: $e');
      rethrow;
    }
  }

  /// Save a contact to local storage
  static Future<bool> saveContact(Contact contact) async {
    try {
      if (_contactsBox == null) {
        await initialize();
      }
      
      await _contactsBox!.put(contact.id, contact);
      Logger.info('Contact saved to local storage: ${contact.name}');
      return true;
    } catch (e) {
      Logger.error('Error saving contact to local storage: $e');
      return false;
    }
  }

  /// Get all contacts from local storage
  static Future<List<Contact>> getAllContacts() async {
    try {
      if (_contactsBox == null) {
        await initialize();
      }
      
      final contacts = _contactsBox!.values.toList();
      // Sort by created date, newest first
      contacts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      Logger.info('Retrieved ${contacts.length} contacts from local storage');
      return contacts;
    } catch (e) {
      Logger.error('Error getting contacts from local storage: $e');
      return [];
    }
  }

  /// Get a specific contact by ID
  static Future<Contact?> getContact(String id) async {
    try {
      if (_contactsBox == null) {
        await initialize();
      }
      
      final contact = _contactsBox!.get(id);
      if (contact != null) {
        Logger.info('Retrieved contact from local storage: ${contact.name}');
      }
      return contact;
    } catch (e) {
      Logger.error('Error getting contact from local storage: $e');
      return null;
    }
  }

  /// Update a contact in local storage
  static Future<bool> updateContact(Contact contact) async {
    try {
      if (_contactsBox == null) {
        await initialize();
      }
      
      await _contactsBox!.put(contact.id, contact);
      Logger.info('Contact updated in local storage: ${contact.name}');
      return true;
    } catch (e) {
      Logger.error('Error updating contact in local storage: $e');
      return false;
    }
  }

  /// Delete a contact from local storage
  static Future<bool> deleteContact(String id) async {
    try {
      if (_contactsBox == null) {
        await initialize();
      }
      
      final contact = _contactsBox!.get(id);
      if (contact != null) {
        // Delete associated image if exists
        if (contact.imagePath != null) {
          await deleteImage(contact.imagePath!);
        }
        
        await _contactsBox!.delete(id);
        Logger.info('Contact deleted from local storage: ${contact.name}');
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Error deleting contact from local storage: $e');
      return false;
    }
  }

  /// Save an image to local storage and return the saved path
  static Future<String?> saveImage(String sourcePath) async {
    try {
      // Get the app's documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/images');
      
      // Create images directory if it doesn't exist
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = sourcePath.split('.').last;
      final fileName = 'card_$timestamp.$extension';
      final destinationPath = '${imagesDir.path}/$fileName';
      
      // Copy the image file
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(destinationPath);
        
        // Store image path reference in Hive
        if (_imagesBox == null) {
          await initialize();
        }
        await _imagesBox!.put(fileName, destinationPath);
        
        Logger.info('Image saved to local storage: $destinationPath');
        return destinationPath;
      }
      
      Logger.warning('Source image file does not exist: $sourcePath');
      return null;
    } catch (e) {
      Logger.error('Error saving image to local storage: $e');
      return null;
    }
  }

  /// Delete an image from local storage
  static Future<bool> deleteImage(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
        
        // Remove from Hive box
        if (_imagesBox == null) {
          await initialize();
        }
        
        final fileName = imagePath.split('/').last;
        await _imagesBox!.delete(fileName);
        
        Logger.info('Image deleted from local storage: $imagePath');
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Error deleting image from local storage: $e');
      return false;
    }
  }

  /// Search contacts by name, email, phone, or company
  static Future<List<Contact>> searchContacts(String query) async {
    try {
      final allContacts = await getAllContacts();
      final lowerQuery = query.toLowerCase();
      
      final filteredContacts = allContacts.where((contact) {
        return contact.name.toLowerCase().contains(lowerQuery) ||
               (contact.email?.toLowerCase().contains(lowerQuery) ?? false) ||
               (contact.phone?.contains(query) ?? false) ||
               (contact.company?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
      
      Logger.info('Found ${filteredContacts.length} contacts matching "$query"');
      return filteredContacts;
    } catch (e) {
      Logger.error('Error searching contacts: $e');
      return [];
    }
  }

  /// Get recent contacts (last 10)
  static Future<List<Contact>> getRecentContacts({int limit = 10}) async {
    try {
      final allContacts = await getAllContacts();
      final recentContacts = allContacts.take(limit).toList();
      
      Logger.info('Retrieved ${recentContacts.length} recent contacts');
      return recentContacts;
    } catch (e) {
      Logger.error('Error getting recent contacts: $e');
      return [];
    }
  }

  /// Clear all data from local storage
  static Future<bool> clearAllData() async {
    try {
      if (_contactsBox == null || _imagesBox == null) {
        await initialize();
      }
      
      // Clear contacts
      await _contactsBox!.clear();
      
      // Clear images
      await _imagesBox!.clear();
      
      // Delete all image files
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/images');
      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
      }
      
      Logger.info('All data cleared from local storage');
      return true;
    } catch (e) {
      Logger.error('Error clearing all data: $e');
      return false;
    }
  }

  /// Legacy methods for compatibility
  static Future<void> init() async {
    await initialize();
  }

  static Future<void> store(String key, dynamic value) async {
    // Legacy method - not used in current implementation
    Logger.warning('Legacy store method called with key: $key');
  }

  static dynamic get(String key, {dynamic defaultValue}) {
    // Legacy method - not used in current implementation
    Logger.warning('Legacy get method called with key: $key');
    return defaultValue;
  }

  static Future<void> delete(String key) async {
    // Legacy method - not used in current implementation
    Logger.warning('Legacy delete method called with key: $key');
  }

  static Future<void> clear() async {
    await clearAllData();
  }

  /// Close all Hive boxes
  static Future<void> close() async {
    try {
      await _contactsBox?.close();
      await _imagesBox?.close();
      _contactsBox = null;
      _imagesBox = null;
      Logger.info('Storage service closed');
    } catch (e) {
      Logger.error('Error closing storage service: $e');
    }
  }

  /// Get total number of contacts
  static Future<int> getTotalContactCount() async {
    try {
      if (_contactsBox == null) {
        await initialize();
      }
      
      final count = _contactsBox!.length;
      Logger.info('Total contact count: $count');
      return count;
    } catch (e) {
      Logger.error('Error getting total contact count: $e');
      return 0;
    }
  }

  /// Get number of contacts added this week
  static Future<int> getContactsThisWeekCount() async {
    try {
      final allContacts = await getAllContacts();
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1))
          .copyWith(hour: 0, minute: 0, second: 0, microsecond: 0);
      
      final thisWeekContacts = allContacts.where((contact) {
        return contact.createdAt.isAfter(startOfWeek);
      }).length;
      
      Logger.info('Contacts added this week: $thisWeekContacts');
      return thisWeekContacts;
    } catch (e) {
      Logger.error('Error getting contacts this week count: $e');
      return 0;
    }
  }

  /// Get number of contacts added today
  static Future<int> getContactsTodayCount() async {
    try {
      final allContacts = await getAllContacts();
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      final todayContacts = allContacts.where((contact) {
        return contact.createdAt.isAfter(startOfDay);
      }).length;
      
      Logger.info('Contacts added today: $todayContacts');
      return todayContacts;
    } catch (e) {
      Logger.error('Error getting contacts today count: $e');
      return 0;
    }
  }
}

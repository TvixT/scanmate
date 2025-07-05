import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/contact.dart' as app_models;
import '../utils/logger.dart';

class ContactService {
  /// Checks if the app has contacts permission
  static Future<bool> requestPermission() async {
    try {
      final permission = await FlutterContacts.requestPermission();
      Logger.info('Contacts permission status: $permission');
      return permission;
    } catch (e) {
      Logger.error('Error requesting contacts permission: $e');
      return false;
    }
  }

  /// Saves a contact to the device's contact list
  static Future<bool> saveToDevice(app_models.Contact contact) async {
    try {
      // Check permission first
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        Logger.warning('Contacts permission denied');
        return false;
      }

      // Parse name into first and last name
      final nameParts = contact.name.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 
          ? nameParts.sublist(1).join(' ') 
          : '';

      // Create a new device contact
      final deviceContact = Contact(
        name: Name(
          first: firstName,
          last: lastName,
        ),
        emails: contact.email != null && contact.email!.isNotEmpty 
            ? [Email(contact.email!)] 
            : [],
        phones: contact.phone != null && contact.phone!.isNotEmpty 
            ? [Phone(contact.phone!)] 
            : [],
        organizations: contact.company != null && contact.company!.isNotEmpty 
            ? [Organization(
                company: contact.company!,
                title: contact.title ?? '',
              )] 
            : [],
        websites: contact.website != null && contact.website!.isNotEmpty 
            ? [Website(contact.website!)] 
            : [],
        addresses: contact.address != null && contact.address!.isNotEmpty
            ? [Address(contact.address!)]
            : [],
      );

      // Save to device
      await deviceContact.insert();
      Logger.info('Contact saved to device: ${contact.name}');
      return true;
    } catch (e) {
      Logger.error('Error saving contact to device: $e');
      return false;
    }
  }

  /// Gets all contacts from the device
  static Future<List<Contact>> getDeviceContacts() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        Logger.warning('Contacts permission denied');
        return [];
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      
      Logger.info('Retrieved ${contacts.length} contacts from device');
      return contacts;
    } catch (e) {
      Logger.error('Error getting device contacts: $e');
      return [];
    }
  }

  /// Get all contacts from device - Legacy method
  static Future<List<Contact>> getAllContacts() async {
    return getDeviceContacts();
  }

  /// Add a new contact to device - Legacy method
  static Future<void> addContact(app_models.Contact contact) async {
    await saveToDevice(contact);
  }

  /// Updates an existing contact on the device
  static Future<bool> updateDeviceContact(Contact deviceContact) async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        Logger.warning('Contacts permission denied');
        return false;
      }

      await deviceContact.update();
      Logger.info('Contact updated on device: ${deviceContact.displayName}');
      return true;
    } catch (e) {
      Logger.error('Error updating contact on device: $e');
      return false;
    }
  }

  /// Deletes a contact from the device
  static Future<bool> deleteDeviceContact(Contact deviceContact) async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        Logger.warning('Contacts permission denied');
        return false;
      }

      await deviceContact.delete();
      Logger.info('Contact deleted from device: ${deviceContact.displayName}');
      return true;
    } catch (e) {
      Logger.error('Error deleting contact from device: $e');
      return false;
    }
  }

  /// Finds and deletes a contact from the device using app contact data
  static Future<bool> deleteFromDevice(app_models.Contact appContact) async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        Logger.warning('Contacts permission denied - cannot delete from device');
        return false;
      }

      // Search for the contact by name and phone/email
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
      );

      Contact? matchingContact;
      
      for (final contact in contacts) {
        // Try to match by name first
        final fullName = '${contact.name.first} ${contact.name.last}'.trim();
        if (fullName.toLowerCase() == appContact.name.toLowerCase()) {
          // Verify with additional fields if available
          bool isMatch = true;
          
          // Check phone number if available
          if (appContact.phone != null && appContact.phone!.isNotEmpty) {
            final hasMatchingPhone = contact.phones.any((phone) => 
              phone.number.replaceAll(RegExp(r'\D'), '') == 
              appContact.phone!.replaceAll(RegExp(r'\D'), ''));
            if (!hasMatchingPhone) {
              isMatch = false;
            }
          }
          
          // Check email if available
          if (isMatch && appContact.email != null && appContact.email!.isNotEmpty) {
            final hasMatchingEmail = contact.emails.any((email) => 
              email.address.toLowerCase() == appContact.email!.toLowerCase());
            if (!hasMatchingEmail) {
              isMatch = false;
            }
          }
          
          if (isMatch) {
            matchingContact = contact;
            break;
          }
        }
      }

      if (matchingContact != null) {
        await matchingContact.delete();
        Logger.info('Successfully deleted contact from device: ${appContact.name}');
        return true;
      } else {
        Logger.warning('Contact not found on device: ${appContact.name}');
        return false;
      }
    } catch (e) {
      Logger.error('Error deleting contact from device: $e');
      return false;
    }
  }
}

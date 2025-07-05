import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';

enum PermissionType {
  camera,
  contacts,
  storage,
}

class PermissionService {
  /// Check if a specific permission is granted
  static Future<bool> isPermissionGranted(PermissionType type) async {
    try {
      final permission = _getPermission(type);
      final status = await permission.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      Logger.error('Error checking permission status: $e');
      return false;
    }
  }

  /// Request a specific permission
  static Future<PermissionStatus> requestPermission(PermissionType type) async {
    try {
      final permission = _getPermission(type);
      final status = await permission.request();
      
      Logger.info('Permission ${type.name} request result: $status');
      return status;
    } catch (e) {
      Logger.error('Error requesting permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Request multiple permissions at once
  static Future<Map<PermissionType, PermissionStatus>> requestMultiplePermissions(
    List<PermissionType> types,
  ) async {
    try {
      final permissions = types.map(_getPermission).toList();
      final statuses = await permissions.request();
      
      final result = <PermissionType, PermissionStatus>{};
      for (int i = 0; i < types.length; i++) {
        result[types[i]] = statuses[permissions[i]] ?? PermissionStatus.denied;
      }
      
      Logger.info('Multiple permissions request result: $result');
      return result;
    } catch (e) {
      Logger.error('Error requesting multiple permissions: $e');
      return {for (var type in types) type: PermissionStatus.denied};
    }
  }

  /// Check if permission is permanently denied and needs settings access
  static Future<bool> isPermanentlyDenied(PermissionType type) async {
    try {
      final permission = _getPermission(type);
      final status = await permission.status;
      return status == PermissionStatus.permanentlyDenied;
    } catch (e) {
      Logger.error('Error checking permanently denied status: $e');
      return false;
    }
  }

  /// Open app settings for permission management
  static Future<bool> openSettings() async {
    try {
      final opened = await openAppSettings();
      Logger.info('App settings opened: $opened');
      return opened;
    } catch (e) {
      Logger.error('Error opening app settings: $e');
      return false;
    }
  }

  /// Check all required permissions for the app
  static Future<Map<PermissionType, PermissionStatus>> checkAllPermissions() async {
    final requiredPermissions = [
      PermissionType.camera,
      PermissionType.contacts,
    ];
    
    final result = <PermissionType, PermissionStatus>{};
    
    for (final type in requiredPermissions) {
      try {
        final permission = _getPermission(type);
        final status = await permission.status;
        result[type] = status;
      } catch (e) {
        Logger.error('Error checking permission $type: $e');
        result[type] = PermissionStatus.denied;
      }
    }
    
    return result;
  }

  /// Get user-friendly permission description
  static String getPermissionDescription(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return 'Camera access is needed to scan business cards and QR codes. This allows you to capture images for text recognition.';
      case PermissionType.contacts:
        return 'Contacts access allows you to save scanned business cards directly to your device contacts for easy access.';
      case PermissionType.storage:
        return 'Storage access is needed to save business card images and maintain your scan history.';
    }
  }

  /// Get user-friendly permission title
  static String getPermissionTitle(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return 'Camera Permission';
      case PermissionType.contacts:
        return 'Contacts Permission';
      case PermissionType.storage:
        return 'Storage Permission';
    }
  }

  /// Get icon for permission type
  static String getPermissionIcon(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return '📷';
      case PermissionType.contacts:
        return '👥';
      case PermissionType.storage:
        return '💾';
    }
  }

  /// Check if the app can function with limited permissions
  static bool canFunctionWithoutPermission(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return false; // Camera is essential for the app's core functionality
      case PermissionType.contacts:
        return true; // Can still save to local storage only
      case PermissionType.storage:
        return true; // Can function with in-memory storage
    }
  }

  /// Get the corresponding Permission object
  static Permission _getPermission(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return Permission.camera;
      case PermissionType.contacts:
        return Permission.contacts;
      case PermissionType.storage:
        return Permission.storage;
    }
  }

  /// Get features available without permission
  static List<String> getFeaturesWithoutPermission(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return [
          'View saved contacts',
          'Import from photo gallery',
          'Browse scan history',
        ];
      case PermissionType.contacts:
        return [
          'Scan and save to app storage',
          'Export contact information',
          'Local contact management',
        ];
      case PermissionType.storage:
        return [
          'Temporary scanning',
          'Basic contact extraction',
          'Session-based history',
        ];
    }
  }

  /// Get features requiring permission
  static List<String> getFeaturesWithPermission(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return [
          'Live camera scanning',
          'Real-time card detection',
          'Instant OCR processing',
        ];
      case PermissionType.contacts:
        return [
          'Save to device contacts',
          'Sync with contact apps',
          'Cloud backup integration',
        ];
      case PermissionType.storage:
        return [
          'Persistent scan history',
          'Image storage and retrieval',
          'Offline functionality',
        ];
    }
  }
}

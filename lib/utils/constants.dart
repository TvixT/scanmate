class Constants {
  // App information
  static const String appName = 'ScanMate';
  static const String appVersion = '1.0.0';
  
  // Storage keys
  static const String recentScansKey = 'recent_scans';
  static const String settingsKey = 'app_settings';
  
  // Default values
  static const int maxRecentScans = 50;
  static const Duration scanTimeout = Duration(seconds: 30);
}

class AppColors {
  static const int primaryColor = 0xFF2196F3;
  static const int accentColor = 0xFF03DAC6;
  static const int errorColor = 0xFFB00020;
}

class AppStrings {
  static const String scanBarcodeTitle = 'Scan Barcode';
  static const String scanTextTitle = 'Scan Text';
  static const String contactsTitle = 'Contacts';
  static const String settingsTitle = 'Settings';
  static const String noDataFound = 'No data found';
  static const String scanningError = 'Error occurred while scanning';
}

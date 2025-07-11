# ScanMate

A professional business card scanning and contact management application built with Flutter. ScanMate uses advanced OCR technology to extract contact information from business cards and seamlessly integrate it with your device contacts.

## Features

- **📱 Live Camera Scanning**: Real-time business card scanning with camera preview and guidance overlay
- **🖼️ Gallery Import**: Import and process existing business card photos from device gallery
- **🤖 Advanced OCR**: Powered by Google ML Kit for accurate text recognition and contact extraction
- **📞 Smart Contact Parsing**: Intelligent extraction of names, phone numbers, emails, websites, and company information
- **💾 Contact Management**: Direct integration with device contacts for seamless saving and editing
- **🎨 Modern UI**: Clean, professional interface with Material 3 design principles
- **📊 Scan History**: Track and manage all scanned business cards with search and filtering
- **⚡ Offline Processing**: On-device OCR processing ensures privacy and works without internet connection

## Key Capabilities

### Scanning Methods
- **Camera Capture**: Live camera preview with card outline guidance
- **Gallery Import**: Select and process images from device photo library
- **Batch Processing**: Handle multiple business cards efficiently

### OCR Intelligence
- **Multi-format Support**: Recognizes various business card layouts and designs
- **Contact Field Extraction**: Automatically identifies and categorizes contact information
- **Error Correction**: Smart algorithms to handle OCR inconsistencies
- **Quality Validation**: Ensures extracted data meets quality standards before saving

## Project Structure

```
lib/
├── main.dart              # App entry point with initialization
├── ui/                    # User Interface Layer
│   ├── screens/           # Application screens
│   └── widgets/           # Reusable UI components
├── models/                # Data Models
│   └── contact.dart       # Contact data structure
├── services/              # Business Logic Layer
│   ├── scan_service.dart      # ML Kit scanning operations
│   ├── contact_service.dart   # Device contact management
│   └── storage_service.dart   # Local data persistence
└── utils/                 # Utility Functions
    ├── constants.dart     # App constants and configuration
    └── logger.dart        # Centralized logging
```

## Dependencies

- `google_mlkit_barcode_scanning`: Barcode and QR code scanning
- `google_mlkit_text_recognition`: Text recognition from images
- `flutter_contacts`: Device contact integration
- `hive` & `hive_flutter`: Local database storage
- `path_provider`: File system access

## Getting Started

### Prerequisites

- Flutter SDK (3.8.1 or higher)
- Android Studio / VS Code
- Android NDK 27.0.12077973 or higher

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

### Build APK

```bash
flutter build apk --debug
```

## Development Notes

- The app uses Material 3 design with a custom blue color scheme
- Hive storage is initialized asynchronously before app startup
- All services include proper error handling and exception management
- Logging is centralized through the Logger utility class

## Architecture

ScanMate follows a clean architecture pattern with clear separation of concerns:

- **UI Layer**: Handles user interface and user interactions
- **Service Layer**: Contains business logic and external API interactions
- **Model Layer**: Defines data structures and entities
- **Utils Layer**: Provides helper functions and app-wide utilities

## Development Log

For detailed development progress and technical decisions, see [dev_log.md](dev_log.md).

## License

This project is created for educational and development purposes.

---
*Created: July 5, 2025*
#   s c a n m a t e  
 
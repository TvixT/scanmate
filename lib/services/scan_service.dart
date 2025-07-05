import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ScanService {
  static final BarcodeScanner _barcodeScanner = BarcodeScanner();
  static final TextRecognizer _textRecognizer = TextRecognizer();

  // Scan barcode from image
  static Future<List<Barcode>> scanBarcode(InputImage inputImage) async {
    try {
      final List<Barcode> barcodes = await _barcodeScanner.processImage(inputImage);
      return barcodes;
    } catch (e) {
      throw Exception('Failed to scan barcode: $e');
    }
  }

  // Recognize text from image
  static Future<RecognizedText> recognizeText(InputImage inputImage) async {
    try {
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText;
    } catch (e) {
      throw Exception('Failed to recognize text: $e');
    }
  }

  // Extract contact information from recognized text
  static Future<Map<String, String>> extractContactInfo(String recognizedText) async {
    final contactData = <String, String>{};
    
    if (recognizedText.isEmpty) {
      return contactData;
    }

    // Clean up the text
    final lines = recognizedText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    // Extract patterns
    for (final line in lines) {
      // Email extraction
      final emailRegex = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
      final emailMatch = emailRegex.firstMatch(line);
      if (emailMatch != null && !contactData.containsKey('email')) {
        contactData['email'] = emailMatch.group(0)!;
      }

      // Phone extraction
      final phoneRegex = RegExp(r'(\+?1?[-.\s]?)?\(?([0-9]{3})\)?[-.\s]?([0-9]{3})[-.\s]?([0-9]{4})');
      final phoneMatch = phoneRegex.firstMatch(line);
      if (phoneMatch != null && !contactData.containsKey('phone')) {
        contactData['phone'] = phoneMatch.group(0)!.replaceAll(RegExp(r'[^\d+]'), '');
        // Format phone number
        if (contactData['phone']!.length == 10) {
          final phone = contactData['phone']!;
          contactData['phone'] = '+1 (${phone.substring(0, 3)}) ${phone.substring(3, 6)}-${phone.substring(6)}';
        }
      }

      // Website extraction
      final websiteRegex = RegExp(r'(www\.[\w\-\.]+\.\w+)|([\w\-\.]+\.(com|org|net|edu|gov|mil|int|co|io))', caseSensitive: false);
      final websiteMatch = websiteRegex.firstMatch(line);
      if (websiteMatch != null && !contactData.containsKey('website')) {
        String website = websiteMatch.group(0)!;
        if (!website.startsWith('www.') && !website.startsWith('http')) {
          website = 'www.$website';
        }
        contactData['website'] = website;
      }
    }

    // Extract name and company (heuristic approach)
    _extractNameAndCompany(lines, contactData);

    return contactData;
  }

  static void _extractNameAndCompany(List<String> lines, Map<String, String> contactData) {
    // Skip lines that contain email, phone, or website
    final contentLines = lines.where((line) {
      final lowerLine = line.toLowerCase();
      return !lowerLine.contains('@') &&
          !RegExp(r'\d{3}[-.\s]?\d{3}[-.\s]?\d{4}').hasMatch(line) &&
          !lowerLine.contains('www.') &&
          !lowerLine.contains('.com') &&
          !lowerLine.contains('.org') &&
          !lowerLine.contains('.net') &&
          line.length > 2;
    }).toList();

    if (contentLines.isNotEmpty) {
      // First meaningful line is likely the name
      final potentialName = contentLines[0];
      if (_isLikelyName(potentialName)) {
        contactData['name'] = potentialName;
      }

      // Look for company name in remaining lines
      for (int i = 1; i < contentLines.length; i++) {
        final line = contentLines[i];
        if (_isLikelyCompany(line) && !contactData.containsKey('company')) {
          contactData['company'] = line;
          break;
        }
      }

      // If no name found yet, try to extract from other lines
      if (!contactData.containsKey('name')) {
        for (final line in contentLines) {
          if (_isLikelyName(line)) {
            contactData['name'] = line;
            break;
          }
        }
      }
    }
  }

  static bool _isLikelyName(String text) {
    // Check if it looks like a person's name
    final words = text.split(' ');
    if (words.length < 1 || words.length > 4) return false;
    
    // Check if words start with capital letters
    final hasCapitalizedWords = words.every((word) => 
        word.isNotEmpty && word[0].toUpperCase() == word[0]);
    
    // Check if it's not all caps (likely company name)
    final isAllCaps = text == text.toUpperCase();
    
    return hasCapitalizedWords && !isAllCaps && text.length > 2;
  }

  static bool _isLikelyCompany(String text) {
    // Check for common company indicators
    final companyIndicators = [
      'inc', 'corp', 'llc', 'ltd', 'company', 'co', 'corporation',
      'incorporated', 'limited', 'group', 'enterprises', 'solutions',
      'services', 'consulting', 'technology', 'tech', 'systems'
    ];
    
    final lowerText = text.toLowerCase();
    return companyIndicators.any((indicator) => lowerText.contains(indicator)) ||
           text == text.toUpperCase(); // All caps might be company name
  }

  // Dispose resources
  static void dispose() {
    _barcodeScanner.close();
    _textRecognizer.close();
  }
}

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ScanService {
  static final BarcodeScanner _barcodeScanner = BarcodeScanner();
  static final TextRecognizer _textRecognizer = TextRecognizer();

  // Scan barcode from image
  static Future<List<Barcode>> scanBarcode(InputImage inputImage) async {
    try {
      final List<Barcode> barcodes = await _barcodeScanner.processImage(
        inputImage,
      );
      return barcodes;
    } catch (e) {
      throw Exception('Failed to scan barcode: $e');
    }
  }

  // Recognize text from image
  static Future<RecognizedText> recognizeText(InputImage inputImage) async {
    try {
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );
      return recognizedText;
    } catch (e) {
      throw Exception('Failed to recognize text: $e');
    }
  }

  // Extract contact information from recognized text
  static Future<Map<String, String>> extractContactInfo(
    String recognizedText,
  ) async {
    final contactData = <String, String>{};

    if (recognizedText.isEmpty) {
      return contactData;
    }

    // Debug: print recognized text before extraction
    print('[ScanService] Recognized text before extraction:');
    print(recognizedText);

    // Clean up the text
    final lines = recognizedText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    // Extract patterns
    for (final line in lines) {
      // Email extraction
      final emailRegex = RegExp(
        r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
      );
      final emailMatch = emailRegex.firstMatch(line);
      if (emailMatch != null && !contactData.containsKey('email')) {
        contactData['email'] = emailMatch.group(0)!;
      }

      // Phone extraction
      // Match common US/international formats or any 8+ digit sequence
      final phonePattern = RegExp(
        r'(\+\d{7,}|[1-9]\d{2}-\d{3}-\d{4}|\(\d{3}\) \d{3}-\d{4}|[1-9]\d{2} \d{3} \d{4}|[1-9]\d{2}\.\d{3}\.\d{4})',
      );
      final digitPattern = RegExp(r'(\+?\d[\d\s\-\.\(\)]{7,}\d)'); // 8+ digits, allows separators
      if (!contactData.containsKey('phone')) {
        final phoneMatches = phonePattern.allMatches(line);
        String? phoneCandidate;
        if (phoneMatches.isNotEmpty) {
          phoneCandidate = phoneMatches.first.group(0);
        } else {
          final digitMatches = digitPattern.allMatches(line);
          if (digitMatches.isNotEmpty) {
            phoneCandidate = digitMatches.first.group(0);
          }
        }
        if (phoneCandidate != null) {
          // Clean up: keep + and digits only
          final cleaned = phoneCandidate.replaceAll(RegExp(r'[^\d+]'), '');
          if (cleaned.length >= 8) {
            contactData['phone'] = cleaned;
          }
        }
      }

      // Website extraction
      final websiteRegex = RegExp(
        r'(www\.[\w\-\.]+\.\w+)|([\w\-\.]+\.(com|org|net|edu|gov|mil|int|co|io))',
        caseSensitive: false,
      );
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

    // Debug: print extracted contact data
    print('[ScanService] Extracted contact data:');
    contactData.forEach((key, value) {
      print('  $key: $value');
    });
    return contactData;
  }

  // Extract name and company (heuristic approach)
  static void _extractNameAndCompany(
    List<String> lines,
    Map<String, String> contactData,
  ) {
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

    // Title extraction logic
    final titleKeywords = [
      'manager',
      'engineer',
      'developer',
      'director',
      'lead',
      'officer',
      'president',
      'analyst',
      'consultant',
      'specialist',
      'coordinator',
      'administrator',
      'designer',
      'architect',
      'supervisor',
      'head',
      'chief',
      'founder',
      'owner',
      'partner',
      'executive',
      'assistant',
      'associate',
      'intern',
      'representative',
      'scientist',
      'technician',
      'strategist',
      'producer',
      'editor',
      'writer',
      'accountant',
      'marketer',
      'sales',
      'trainer',
      'teacher',
      'professor',
      'principal',
      'officer',
      'agent',
      'advisor',
      'auditor',
      'planner',
      'controller',
      'inspector',
      'broker',
      'attorney',
      'lawyer',
      'counsel',
      'paralegal',
      'recruiter',
      'researcher',
      'student',
    ];
    for (final line in contentLines) {
      final lowerLine = line.toLowerCase();
      final startsWithUpper =
          line.isNotEmpty && line[0] == line[0].toUpperCase();
      if (titleKeywords.any((kw) => lowerLine.contains(kw)) &&
          (startsWithUpper || line == line.toUpperCase())) {
        contactData['title'] = line;
        break;
      }
    }

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

      // Address extraction logic
      for (final line in contentLines) {
        final hasCommaOrDot = line.contains(',') || line.contains('.');
        final hasNumber = RegExp(r'\d').hasMatch(line);
        final hasLetter = RegExp(r'[A-Za-z]').hasMatch(line);
        if (hasCommaOrDot &&
            hasNumber &&
            hasLetter &&
            !contactData.containsKey('address')) {
          contactData['address'] = line;
          break;
        }
      }

      // Fallback for non-English or unrecognized fields
      final fallback = contentLines.first;
      if (!contactData.containsKey('name')) {
        contactData['name'] = fallback;
      }
      if (!contactData.containsKey('title')) {
        contactData['title'] = fallback;
      }
    }
  }

  static bool _isLikelyName(String text) {
    // Name: full uppercase and exactly two words
    final words = text.split(' ');
    return text == text.toUpperCase() && words.length == 2;
  }

  static bool _isLikelyCompany(String text) {
    // Company: full uppercase and exactly one word, or contains company indicators
    final words = text.split(' ');
    final companyIndicators = [
      'inc',
      'corp',
      'llc',
      'ltd',
      'company',
      'co',
      'corporation',
      'incorporated',
      'limited',
      'group',
      'enterprises',
      'solutions',
      'services',
      'consulting',
      'technology',
      'tech',
      'systems',
    ];
    final lowerText = text.toLowerCase();
    return (text == text.toUpperCase() && words.length == 1) ||
        companyIndicators.any((indicator) => lowerText.contains(indicator));
  }

  // Dispose resources
  static void dispose() {
    _barcodeScanner.close();
    _textRecognizer.close();
  }
}

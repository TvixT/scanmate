import 'package:hive/hive.dart';

part 'contact.g.dart'; // Required for Hive type adapter generation

@HiveType(typeId: 0)
class Contact extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String? email;
  
  @HiveField(3)
  final String? phone;
  
  @HiveField(4)
  final DateTime createdAt;
  
  @HiveField(5)
  final String? company;
  
  @HiveField(6)
  final String? title;
  
  @HiveField(7)
  final String? website;
  
  @HiveField(8)
  final String? address;
  
  @HiveField(9)
  final String? imagePath;
  
  @HiveField(10)
  final String? source; // 'camera' or 'gallery'
  
  @HiveField(11)
  final double? confidence;

  Contact({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.createdAt,
    this.company,
    this.title,
    this.website,
    this.address,
    this.imagePath,
    this.source,
    this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
      'company': company,
      'title': title,
      'website': website,
      'address': address,
      'imagePath': imagePath,
      'source': source,
      'confidence': confidence,
    };
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      createdAt: DateTime.parse(json['createdAt']),
      company: json['company'],
      title: json['title'],
      website: json['website'],
      address: json['address'],
      imagePath: json['imagePath'],
      source: json['source'],
      confidence: json['confidence']?.toDouble(),
    );
  }

  // Factory constructor from extracted contact data
  factory Contact.fromExtractedData(Map<String, String> extractedData) {
    return Contact(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: extractedData['name'] ?? 'Unknown',
      email: extractedData['email'],
      phone: extractedData['phone'],
      company: extractedData['company'],
      title: extractedData['title'],
      website: extractedData['website'],
      address: extractedData['address'],
      imagePath: extractedData['imagePath'],
      source: extractedData['source'],
      createdAt: DateTime.now(),
      confidence: _calculateOverallConfidence(extractedData),
    );
  }

  static double? _calculateOverallConfidence(Map<String, String> data) {
    final fields = ['name', 'email', 'phone', 'company', 'title', 'website', 'address'];
    final nonEmptyFields = fields.where((field) => 
        data[field] != null && data[field]!.isNotEmpty).length;
    
    if (nonEmptyFields == 0) return null;
    return (nonEmptyFields / fields.length) * 100;
  }

  // Get display name for UI
  String get displayName => name.isNotEmpty ? name : 'Unknown Contact';

  // Get initials for avatar
  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    } else {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
  }

  // Check if contact has complete information
  bool get isComplete => name.isNotEmpty && (email != null || phone != null);
}

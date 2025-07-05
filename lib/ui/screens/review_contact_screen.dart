import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../config/app_router.dart';
import '../../utils/logger.dart';
import '../../models/contact.dart';
import '../../services/contact_service.dart';
import '../../services/storage_service.dart';

class ReviewContactScreen extends StatefulWidget {
  final Map<String, dynamic>? contactData;
  final String? editingContactId;

  const ReviewContactScreen({
    super.key, 
    this.contactData,
    this.editingContactId,
  });

  @override
  State<ReviewContactScreen> createState() => _ReviewContactScreenState();
}

class _ReviewContactScreenState extends State<ReviewContactScreen> {
  late TextEditingController _nameController;
  late TextEditingController _companyController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;
  late TextEditingController _titleController;
  late TextEditingController _addressController;
  
  bool _isLoading = false;
  bool _isLoadingContact = false;
  final _formKey = GlobalKey<FormState>();
  
  // Confidence scores (mock data for demonstration)
  final Map<String, double> _confidenceScores = {};
  
  // Image source detection
  String? _imageSource;
  bool get _isFromCamera => _imageSource == 'camera';
  
  // For editing existing contacts
  Contact? _existingContact;
  bool get _isEditMode => widget.editingContactId != null;

  @override
  void initState() {
    super.initState();
    
    if (_isEditMode) {
      // Initialize with empty values and load existing contact
      _initializeEmptyControllers();
      _loadExistingContact();
    } else {
      // Initialize controllers with scanned data or empty values
      final data = widget.contactData ?? {};
      _initializeControllers(data);
    }
  }
  
  void _initializeEmptyControllers() {
    _nameController = TextEditingController();
    _companyController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _websiteController = TextEditingController();
    _titleController = TextEditingController();
    _addressController = TextEditingController();
    _imageSource = 'unknown';
  }
  
  void _initializeControllers(Map<String, dynamic> data) {
    _nameController = TextEditingController(text: data['name'] ?? '');
    _companyController = TextEditingController(text: data['company'] ?? '');
    _emailController = TextEditingController(text: data['email'] ?? '');
    _phoneController = TextEditingController(text: data['phone'] ?? '');
    _websiteController = TextEditingController(text: data['website'] ?? '');
    _titleController = TextEditingController(text: data['title'] ?? '');
    _addressController = TextEditingController(text: data['address'] ?? '');
    
    // Detect image source (default to camera if not specified)
    _imageSource = data['source'] as String? ?? 'camera';
    
    // Generate confidence scores based on field content
    _generateConfidenceScores(data);
  }

  Future<void> _loadExistingContact() async {
    if (widget.editingContactId == null) return;
    
    setState(() {
      _isLoadingContact = true;
    });
    
    try {
      final contact = await StorageService.getContact(widget.editingContactId!);
      if (contact != null && mounted) {
        setState(() {
          _existingContact = contact;
          _nameController.text = contact.name;
          _companyController.text = contact.company ?? '';
          _emailController.text = contact.email ?? '';
          _phoneController.text = contact.phone ?? '';
          _websiteController.text = contact.website ?? '';
          _titleController.text = contact.title ?? '';
          _addressController.text = contact.address ?? '';
          _imageSource = contact.source ?? 'unknown';
          
          // Generate confidence scores for existing contact
          _generateConfidenceScoresFromContact(contact);
        });
      }
    } catch (e) {
      Logger.error('Failed to load contact for editing: $e');
      if (mounted) {
        _showError('Failed to load contact. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingContact = false;
        });
      }
    }
  }
  
  void _generateConfidenceScoresFromContact(Contact contact) {
    _confidenceScores['name'] = _calculateFieldConfidence(contact.name);
    _confidenceScores['company'] = _calculateFieldConfidence(contact.company);
    _confidenceScores['email'] = _calculateEmailConfidence(contact.email);
    _confidenceScores['phone'] = _calculatePhoneConfidence(contact.phone);
    _confidenceScores['website'] = _calculateWebsiteConfidence(contact.website);
    _confidenceScores['title'] = _calculateFieldConfidence(contact.title);
    _confidenceScores['address'] = _calculateFieldConfidence(contact.address);
  }

  void _generateConfidenceScores(Map<String, dynamic> data) {
    // Simulate confidence scores based on data quality
    _confidenceScores['name'] = _calculateFieldConfidence(data['name']);
    _confidenceScores['company'] = _calculateFieldConfidence(data['company']);
    _confidenceScores['email'] = _calculateEmailConfidence(data['email']);
    _confidenceScores['phone'] = _calculatePhoneConfidence(data['phone']);
    _confidenceScores['website'] = _calculateWebsiteConfidence(data['website']);
    _confidenceScores['title'] = _calculateFieldConfidence(data['title']);
    _confidenceScores['address'] = _calculateFieldConfidence(data['address']);
  }
  
  double _calculateFieldConfidence(String? value) {
    if (value == null || value.isEmpty) return 0.0;
    if (value.length < 3) return 0.6;
    if (value.length < 10) return 0.8;
    return 0.95;
  }
  
  double _calculateEmailConfidence(String? email) {
    if (email == null || email.isEmpty) return 0.0;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email) ? 0.98 : 0.7;
  }
  
  double _calculatePhoneConfidence(String? phone) {
    if (phone == null || phone.isEmpty) return 0.0;
    final phoneRegex = RegExp(r'[\d\s\-\(\)\+]{10,}');
    return phoneRegex.hasMatch(phone) ? 0.92 : 0.75;
  }
  
  double _calculateWebsiteConfidence(String? website) {
    if (website == null || website.isEmpty) return 0.0;
    final websiteRegex = RegExp(r'^(www\.)?[\w\-\.]+\.\w+');
    return websiteRegex.hasMatch(website) ? 0.90 : 0.65;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _titleController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingContact) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildAppBar(),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading contact...',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Card Preview Section
                    _buildCardPreview(),
                    
                    // Contact Information Form
                    _buildContactForm(),
                    
                    // Confidence Overview
                    _buildConfidenceOverview(),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            // Bottom Action Bar
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: const Color(0xFF1E293B),
      title: Text(
        _isEditMode ? 'Edit Contact' : 'Review Contact',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline_rounded),
          onPressed: _showHelpDialog,
          tooltip: 'Help',
        ),
      ],
    );
  }

  Widget _buildCardPreview() {
    String? imagePath;
    
    if (_isEditMode) {
      imagePath = _existingContact?.imagePath;
    } else {
      imagePath = widget.contactData?['imagePath'] as String?;
    }
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isEditMode 
                    ? Icons.edit_rounded
                    : (_isFromCamera ? Icons.camera_alt_rounded : Icons.photo_library_rounded),
                color: const Color(0xFF3B82F6),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                _isEditMode 
                    ? 'Edit Contact Information'
                    : (_isFromCamera ? 'Scanned Business Card' : 'Imported Business Card'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Card Thumbnail or Placeholder
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 2,
              ),
            ),
            child: imagePath != null && File(imagePath).existsSync()
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 40,
                          color: Color(0xFF94A3B8),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Business Card Image',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          
          const SizedBox(height: 16),
          
          // OCR Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF10B981),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _isFromCamera ? 'Camera Scan Complete' : 'Gallery Import Complete',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactForm() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_rounded,
                color: Color(0xFF3B82F6),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Name field
          _buildEnhancedTextField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_outline,
            required: true,
            confidence: _confidenceScores['name'] ?? 0.0,
          ),
          
          const SizedBox(height: 20),
          
          // Company field
          _buildEnhancedTextField(
            controller: _companyController,
            label: 'Company',
            icon: Icons.business_outlined,
            confidence: _confidenceScores['company'] ?? 0.0,
          ),
          
          const SizedBox(height: 20),
          
          // Title field
          _buildEnhancedTextField(
            controller: _titleController,
            label: 'Job Title',
            icon: Icons.work_outline,
            confidence: _confidenceScores['title'] ?? 0.0,
          ),
          
          const SizedBox(height: 20),
          
          // Email field
          _buildEnhancedTextField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            confidence: _confidenceScores['email'] ?? 0.0,
            validator: _validateEmail,
          ),
          
          const SizedBox(height: 20),
          
          // Phone field
          _buildEnhancedTextField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            confidence: _confidenceScores['phone'] ?? 0.0,
          ),
          
          const SizedBox(height: 20),
          
          // Website field
          _buildEnhancedTextField(
            controller: _websiteController,
            label: 'Website',
            icon: Icons.language_outlined,
            keyboardType: TextInputType.url,
            confidence: _confidenceScores['website'] ?? 0.0,
            validator: _validateWebsite,
          ),
          
          const SizedBox(height: 20),
          
          // Address field
          _buildEnhancedTextField(
            controller: _addressController,
            label: 'Address',
            icon: Icons.location_on_outlined,
            maxLines: 2,
            confidence: _confidenceScores['address'] ?? 0.0,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
    double confidence = 0.0,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field label with confidence indicator
        Row(
          children: [
            Text(
              required ? '$label *' : label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const Spacer(),
            if (confidence > 0.0) _buildConfidenceIndicator(confidence),
          ],
        ),
        const SizedBox(height: 8),
        
        // Text field
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF1F2937),
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF6B7280),
              size: 20,
            ),
            hintText: 'Enter $label',
            hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 16,
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF3B82F6),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceIndicator(double confidence) {
    Color indicatorColor;
    String confidenceText;
    IconData indicatorIcon;
    
    if (confidence >= 0.9) {
      indicatorColor = const Color(0xFF10B981);
      confidenceText = 'High';
      indicatorIcon = Icons.check_circle;
    } else if (confidence >= 0.7) {
      indicatorColor = const Color(0xFFF59E0B);
      confidenceText = 'Medium';
      indicatorIcon = Icons.warning_rounded;
    } else {
      indicatorColor = const Color(0xFFEF4444);
      confidenceText = 'Low';
      indicatorIcon = Icons.error_outline;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            indicatorIcon,
            size: 12,
            color: indicatorColor,
          ),
          const SizedBox(width: 4),
          Text(
            confidenceText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: indicatorColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceOverview() {
    final extractedFields = _confidenceScores.entries
        .where((entry) => entry.value > 0.0)
        .toList();
    
    if (extractedFields.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final overallConfidence = extractedFields
        .map((e) => e.value)
        .reduce((a, b) => a + b) / extractedFields.length;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                color: Color(0xFF3B82F6),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Extraction Quality',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Overall confidence
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall Confidence',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(overallConfidence * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: overallConfidence >= 0.8
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${extractedFields.length} fields extracted',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: overallConfidence >= 0.8
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Please review and edit the information above to ensure accuracy.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Retake/Re-import button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _handleRetakeOrReimport(),
                icon: Icon(
                  _isFromCamera ? Icons.camera_alt_outlined : Icons.photo_library_outlined,
                  size: 18,
                ),
                label: Text(_isFromCamera ? 'Retake' : 'Re-import'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6B7280),
                  side: const BorderSide(
                    color: Color(0xFFE5E7EB),
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Save button
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveContact,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.save_outlined,
                        size: 18,
                      ),
                label: Text(_isLoading 
                    ? (_isEditMode ? 'Updating...' : 'Saving...') 
                    : (_isEditMode ? 'Update Contact' : 'Save Contact')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleRetakeOrReimport() {
    if (_isFromCamera) {
      // Go back to camera scanning
      context.pop();
    } else {
      // Go back to gallery import (return to home or previous screen)
      // Since gallery import can be triggered from multiple places,
      // we'll just go back to let the user choose their next action
      context.pop();
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFF3B82F6)),
            SizedBox(width: 12),
            Text('How to Review'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• Check extracted information for accuracy\n'
              '• Green indicators show high confidence\n'
              '• Yellow/Red indicators suggest verification needed\n'
              '• Edit any incorrect information\n'
              '• Tap "Save Contact" when ready\n\n'
              '${_isFromCamera ? "• Tap \"Retake\" to scan a new card" : "• Tap \"Re-import\" to select a different image"}',
              style: const TextStyle(height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(value) ? null : 'Please enter a valid email';
  }

  String? _validateWebsite(String? value) {
    if (value == null || value.isEmpty) return null;
    final websiteRegex = RegExp(r'^(https?:\/\/)?(www\.)?[\w\-\.]+\.\w+');
    return websiteRegex.hasMatch(value) ? null : 'Please enter a valid website';
  }

  void _saveContact() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate required fields
    if (_nameController.text.trim().isEmpty) {
      _showError('Name is required to save the contact');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Contact contact;
      
      if (_isEditMode && _existingContact != null) {
        // Update existing contact
        contact = Contact(
          id: _existingContact!.id,
          name: _nameController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          company: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
          title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
          website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          createdAt: _existingContact!.createdAt, // Keep original creation time
          imagePath: _existingContact!.imagePath, // Keep existing image
          source: _existingContact!.source ?? 'unknown',
          confidence: _existingContact!.confidence,
        );
        
        // Update contact in storage
        await StorageService.saveContact(contact);
        
        // Update device contacts
        final deviceSaved = await ContactService.saveToDevice(contact);
        
        if (mounted) {
          // Navigate back with success message
          final message = deviceSaved 
              ? 'Contact "${contact.name}" has been updated in your device and app history!'
              : 'Contact "${contact.name}" has been updated in app history!';
          
          context.pushReplacement(
            AppRouter.success,
            extra: message,
          );
        }
      } else {
        // Create new contact
        contact = Contact(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          company: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
          title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
          website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          createdAt: DateTime.now(),
          imagePath: widget.contactData?['imagePath'],
          source: _imageSource ?? 'unknown',
          confidence: widget.contactData?['confidence']?.toDouble(),
        );

        // Save image to local storage if available
        String? savedImagePath;
        if (widget.contactData?['imagePath'] != null) {
          savedImagePath = await StorageService.saveImage(widget.contactData!['imagePath']);
          if (savedImagePath != null) {
            // Update contact with saved image path
            final updatedContact = Contact(
              id: contact.id,
              name: contact.name,
              email: contact.email,
              phone: contact.phone,
              company: contact.company,
              title: contact.title,
              website: contact.website,
              address: contact.address,
              createdAt: contact.createdAt,
              imagePath: savedImagePath,
              source: contact.source,
              confidence: contact.confidence,
            );
            
            // Save to local storage
            await StorageService.saveContact(updatedContact);
            
            // Save to device contacts
            final deviceSaved = await ContactService.saveToDevice(updatedContact);
            
            if (mounted) {
              // Navigate to success screen
              final message = deviceSaved 
                  ? 'Contact "${contact.name}" has been saved to your device and app history!'
                  : 'Contact "${contact.name}" has been saved to app history!';
              
              context.pushReplacement(
                AppRouter.success,
                extra: message,
              );
            }
          } else {
            throw Exception('Failed to save contact image');
          }
        } else {
          // Save without image
          await StorageService.saveContact(contact);
          
          // Save to device contacts
          final deviceSaved = await ContactService.saveToDevice(contact);
          
          if (mounted) {
            // Navigate to success screen
            final message = deviceSaved 
                ? 'Contact "${contact.name}" has been saved to your device and app history!'
                : 'Contact "${contact.name}" has been saved to app history!';
            
            context.pushReplacement(
              AppRouter.success,
              extra: message,
            );
          }
        }
      }
    } catch (e) {
      Logger.error('Failed to ${_isEditMode ? 'update' : 'save'} contact: $e');
      if (mounted) {
        _showError('Failed to ${_isEditMode ? 'update' : 'save'} contact. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

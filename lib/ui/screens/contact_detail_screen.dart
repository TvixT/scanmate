import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../models/contact.dart';
import '../../services/storage_service.dart';
import '../../services/contact_service.dart';
import '../../utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';

class ContactDetailScreen extends StatefulWidget {
  final String? contactId;

  const ContactDetailScreen({super.key, this.contactId});

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  Contact? _contact;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContact();
  }

  Future<void> _loadContact() async {
    if (widget.contactId != null) {
      try {
        print('Loading contact with ID: ${widget.contactId}');
        final contact = await StorageService.getContact(widget.contactId!);
        print('Loaded contact: ${contact?.name ?? 'null'}');
        if (mounted) {
          setState(() {
            _contact = contact;
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error loading contact: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      print('No contact ID provided');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_contact == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          title: const Text('Contact Not Found'),
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_off_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Contact not found',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Contact ID: ${widget.contactId ?? 'null'}',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final contact = _contact!;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: CustomScrollView(
        slivers: [
          // Custom Header with Gradient
          SliverAppBar(
            expandedHeight: 70,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF2563EB),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.7, 1.0],
                    colors: [Color(0xFF2563EB), Color(0xFF22D3EE)],
                  ),
                ),
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  size: 24,
                  color: Colors.white,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
            title: const Text(
              'Contact Details',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),
            centerTitle: true,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    if (_contact != null) {
                      context.push('/edit-contact/${_contact!.id}');
                    }
                  },
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 22,
                    color: Colors.white,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => _showDeleteConfirmation(),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 22,
                    color: Colors.white,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),

          // Contact Info Content with Floating Avatar
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Main content with top padding for avatar space
                Container(
                  margin: const EdgeInsets.only(
                    top: 45,
                  ), // Space for floating avatar
                  child: Column(
                    children: [
                      // Profile Section (without avatar)
                      _buildProfileSectionWithoutAvatar(context, contact),

                      // Contact Info Section
                      _buildContactInfoSection(context, contact),

                      // Bottom padding
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Floating Avatar positioned below header
                Positioned(
                  top: 0, // Position at the top of content area, below header
                  left: 0,
                  right: 0,
                  child: _buildFloatingAvatar(context, contact),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingAvatar(BuildContext context, Contact contact) {
    return Center(
      child: Container(
        height: 90,
        width: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(45),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            41,
          ), // Slightly smaller to account for border
          child: _buildAvatarFallback(contact.name),
        ),
      ),
    );
  }

  Widget _buildProfileSectionWithoutAvatar(
    BuildContext context,
    Contact contact,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Space for floating avatar
          const SizedBox(height: 45),

          // Name
          Text(
            contact.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF22223B),
            ),
          ),

          // Company
          if (contact.company != null)
            Container(
              margin: const EdgeInsets.fromLTRB(0, 2, 0, 10),
              child: Text(
                contact.company!,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF64748B),
                ),
              ),
            ),

          // Action Buttons
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionButton(
                  icon: Icons.call_rounded,
                  label: 'Call',
                  isPrimary: true,
                  onPressed: () => _callContact(contact.phone),
                ),
                _buildActionButton(
                  icon: Icons.chat_rounded,
                  label: 'Message',
                  isPrimary: false,
                  onPressed: () => _messageContact(contact.phone),
                ),
                _buildActionButton(
                  icon: Icons.email_rounded,
                  label: 'Email',
                  isPrimary: false,
                  onPressed: () => _emailContact(contact.email),
                ),
                // View Card button if image exists
                if (contact.imagePath != null)
                  _buildActionButton(
                    icon: Icons.credit_card_rounded,
                    label: 'View Card',
                    isPrimary: false,
                    onPressed: () => _showCardImage(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection(BuildContext context, Contact contact) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text(
              'Contact Info',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),

          if (contact.phone != null) ...[
            _buildInfoRow(
              icon: Icons.call_rounded,
              label: 'Phone',
              value: contact.phone!,
              hasAction: true,
              onTap: () => _callContact(contact.phone),
            ),
            _buildDivider(),
          ],

          if (contact.email != null) ...[
            _buildInfoRow(
              icon: Icons.email_rounded,
              label: 'Email',
              value: contact.email!,
              hasAction: true,
              onTap: () => _emailContact(contact.email),
            ),
            _buildDivider(),
          ],

          if (contact.company != null) ...[
            _buildInfoRow(
              icon: Icons.business_rounded,
              label: 'Company',
              value: contact.company!,
              hasAction: false,
            ),
            _buildDivider(),
          ],

          if (contact.website != null) ...[
            _buildInfoRow(
              icon: Icons.language_rounded,
              label: 'Website',
              value: contact.website!,
              hasAction: true,
              onTap: () => _openWebsite(contact.website),
            ),
            _buildDivider(),
          ],

          // Scan metadata section
          if (contact.source != null) ...[
            _buildInfoRow(
              icon: contact.source == 'camera'
                  ? Icons.camera_alt_rounded
                  : Icons.photo_library_rounded,
              label: 'Scan Source',
              value: contact.source == 'camera'
                  ? 'Camera Capture'
                  : 'Gallery Import',
              hasAction: false,
            ),
            _buildDivider(),
          ],

          if (contact.confidence != null) ...[
            _buildInfoRow(
              icon: Icons.analytics_rounded,
              label: 'OCR Confidence',
              value: '${(contact.confidence! * 100).toStringAsFixed(0)}%',
              hasAction: false,
              customValue: _buildConfidenceIndicator(contact.confidence!),
            ),
            _buildDivider(),
          ],

          _buildInfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Added',
            value: _formatDate(contact.createdAt),
            hasAction: false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }

  Widget _buildConfidenceIndicator(double confidence) {
    Color confidenceColor;
    String confidenceText;

    if (confidence >= 0.9) {
      confidenceColor = Colors.green;
      confidenceText = 'Excellent';
    } else if (confidence >= 0.8) {
      confidenceColor = Colors.lightGreen;
      confidenceText = 'Good';
    } else if (confidence >= 0.7) {
      confidenceColor = Colors.orange;
      confidenceText = 'Fair';
    } else {
      confidenceColor = Colors.red;
      confidenceText = 'Poor';
    }

    return Row(
      children: [
        Text(
          '${(confidence * 100).toStringAsFixed(0)}%',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: confidenceColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: confidenceColor.withOpacity(0.3)),
          ),
          child: Text(
            confidenceText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: confidenceColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isPrimary
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              )
            : null,
        color: isPrimary ? null : Colors.white,
        border: isPrimary
            ? null
            : Border.all(color: const Color(0xFF2563EB), width: 1.5),
        borderRadius: BorderRadius.circular(22),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isPrimary ? Colors.white : const Color(0xFF2563EB),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPrimary ? Colors.white : const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool hasAction,
    bool isLast = false,
    VoidCallback? onTap,
    Widget? customValue,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasAction ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, isLast ? 20 : 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF), // Light blue background
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF2563EB)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8), // Label color
                      ),
                    ),
                    const SizedBox(height: 2),
                    customValue ??
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold, // Value bold
                            color: Color(0xFF1E293B),
                          ),
                        ),
                  ],
                ),
              ),
              if (hasAction)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 1,
      color: const Color(0xFFF1F5F9),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(
          41,
        ), // Circular to match the ClipRRect
      ),
      child: Center(
        child: Text(
          _getInitials(name),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    ); // Close Container in _buildAvatarFallback
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    } else {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
  }

  void _callContact(String? phoneNumber) async {
    if (phoneNumber != null) {
      // Only allow if phone number has at least 8 digits
      final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      if (cleaned.length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number is too short to call.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $uri'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Calling $phoneNumber');
    }
  }

  void _messageContact(String? phoneNumber) async {
    if (phoneNumber != null) {
      // Only allow if phone number has at least 8 digits
      final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      if (cleaned.length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number is too short to message.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final Uri uri = Uri(scheme: 'sms', path: phoneNumber);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $uri'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Messaging $phoneNumber');
    }
  }

  void _emailContact(String? email) async {
    if (email != null && email.isNotEmpty) {
      final Email emailToSend = Email(
        recipients: [email],
        subject: '',
        body: '',
        isHTML: false,
      );
      try {
        await FlutterEmailSender.send(emailToSend);
        print('Email intent sent to $email');
      } catch (e) {
        print('Error launching email client: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open email client.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      print('Invalid email address: $email');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid email address'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openWebsite(String? website) async {
    if (website != null) {
      final Uri uri = Uri.parse(website);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        ); // Open in browser
      } else {
        throw 'Could not launch $website';
      }
      print('Opening $website');
    }
  }

  Future<void> _showDeleteConfirmation() async {
    if (_contact == null) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Delete Contact',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete "${_contact!.name}"?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will remove the contact from both the app and your device contacts.',
                        style: TextStyle(fontSize: 14, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _deleteContact();
    }
  }

  Future<void> _deleteContact() async {
    if (_contact == null) return;

    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Delete from local storage
      await StorageService.deleteContact(_contact!.id);
      Logger.info('Contact deleted from local storage: ${_contact!.name}');

      // Try to delete from device contacts
      try {
        await ContactService.deleteFromDevice(_contact!);
        Logger.info('Contact deleted from device: ${_contact!.name}');
      } catch (e) {
        Logger.error('Failed to delete from device contacts: $e');
        // Continue anyway - local deletion succeeded
      }

      // Delete contact image if it exists
      if (_contact!.imagePath != null) {
        try {
          final imageFile = File(_contact!.imagePath!);
          if (await imageFile.exists()) {
            await imageFile.delete();
            Logger.info('Contact image deleted: ${_contact!.imagePath}');
          }
        } catch (e) {
          Logger.error('Failed to delete contact image: $e');
          // Continue anyway - contact data deletion succeeded
        }
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Contact "${_contact!.name}" deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        // Navigate back to history or home
        context.pop();
      }
    } catch (e) {
      Logger.error('Failed to delete contact: $e');

      // Close loading dialog if open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete contact: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _showCardImage() async {
    if (_contact?.imagePath == null) return;

    final imageFile = File(_contact!.imagePath!);
    if (!await imageFile.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Original card image not found'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with close button
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Original Business Card',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Image
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    child: Image.file(imageFile, fit: BoxFit.contain),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

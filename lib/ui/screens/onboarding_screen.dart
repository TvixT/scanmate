import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/app_router.dart';
import '../../services/permission_service.dart';
import '../../services/onboarding_service.dart';
import '../../utils/logger.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  
  // Permission tracking
  Map<PermissionType, PermissionStatus> _permissionStatuses = {};
  bool _isRequestingPermissions = false;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      icon: Icons.scanner_rounded,
      title: 'Welcome to ScanMate',
      description: 'Transform your business card management with intelligent scanning and automatic contact organization.',
      buttonText: 'Get Started',
    ),
    OnboardingPageData(
      icon: Icons.camera_alt_rounded,
      title: 'Camera Permission',
      description: 'ScanMate needs camera access to scan business cards and extract contact information using advanced OCR technology.',
      buttonText: 'Grant Camera Access',
      permissionType: PermissionType.camera,
      isPermissionPage: true,
    ),
    OnboardingPageData(
      icon: Icons.contacts_rounded,
      title: 'Contacts Permission',
      description: 'Allow ScanMate to save contacts directly to your device for seamless integration with your existing contact apps.',
      buttonText: 'Grant Contacts Access',
      permissionType: PermissionType.contacts,
      isPermissionPage: true,
      isOptional: true,
    ),
    OnboardingPageData(
      icon: Icons.check_circle_rounded,
      title: 'You\'re All Set!',
      description: 'Start scanning business cards and building your digital contact library. Your data stays secure on your device.',
      buttonText: 'Start Scanning',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _checkInitialPermissions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkInitialPermissions() async {
    final statuses = await PermissionService.checkAllPermissions();
    if (mounted) {
      setState(() {
        _permissionStatuses = statuses;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handlePermissionRequest(PermissionType permissionType) async {
    setState(() {
      _isRequestingPermissions = true;
    });

    try {
      final status = await PermissionService.requestPermission(permissionType);
      
      if (mounted) {
        setState(() {
          _permissionStatuses[permissionType] = status;
          _isRequestingPermissions = false;
        });

        if (status == PermissionStatus.granted) {
          _nextPage();
        } else if (status == PermissionStatus.permanentlyDenied) {
          _showPermissionDeniedDialog(permissionType);
        } else {
          _showPermissionExplanation(permissionType);
        }
      }
    } catch (e) {
      Logger.error('Error requesting permission: $e');
      if (mounted) {
        setState(() {
          _isRequestingPermissions = false;
        });
      }
    }
  }

  void _showPermissionDeniedDialog(PermissionType permissionType) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.settings_rounded,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Permission Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permission for ${PermissionService.getPermissionTitle(permissionType).toLowerCase()} has been permanently denied.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To enable this feature:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Tap "Open Settings" below\n2. Find "Permissions" or "App Permissions"\n3. Enable ${PermissionService.getPermissionTitle(permissionType)}',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (PermissionService.canFunctionWithoutPermission(permissionType))
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _nextPage();
              },
              child: const Text('Skip for Now'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await PermissionService.openSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showPermissionExplanation(PermissionType permissionType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Why We Need This Permission',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              PermissionService.getPermissionDescription(permissionType),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Features with permission:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
            ...PermissionService.getFeaturesWithPermission(permissionType)
                .map((feature) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.check, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(feature)),
                        ],
                      ),
                    )),
            if (PermissionService.canFunctionWithoutPermission(permissionType)) ...[
              const SizedBox(height: 12),
              Text(
                'Limited features without permission:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
              ...PermissionService.getFeaturesWithoutPermission(permissionType)
                  .map((feature) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(feature)),
                          ],
                        ),
                      )),
            ],
          ],
        ),
        actions: [
          if (PermissionService.canFunctionWithoutPermission(permissionType))
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _nextPage();
              },
              child: const Text('Continue Without'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handlePermissionRequest(permissionType);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    // Mark onboarding as completed
    await OnboardingService.markOnboardingComplete();
    await OnboardingService.markPermissionsAsked();
    
    Logger.info('Onboarding completed with permissions: $_permissionStatuses');
    
    if (mounted) {
      context.go(AppRouter.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Container(
              margin: const EdgeInsets.all(20),
              child: Row(
                children: List.generate(
                  _pages.length,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < _pages.length - 1 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? const Color(0xFF2563EB)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _buildPage(page);
                },
              ),
            ),

            // Navigation buttons
            Container(
              margin: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  
                  if (_currentPage > 0) const SizedBox(width: 16),
                  
                  Expanded(
                    flex: 2,
                    child: _buildPrimaryButton(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPageData page) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2563EB),
                  const Color(0xFF1D4ED8),
                ],
              ),
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 40),

          // Title
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Permission status indicator (for permission pages)
          if (page.isPermissionPage && page.permissionType != null)
            _buildPermissionStatus(page.permissionType!),
        ],
      ),
    );
  }

  Widget _buildPermissionStatus(PermissionType permissionType) {
    final status = _permissionStatuses[permissionType];
    
    if (status == PermissionStatus.granted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text(
              'Permission Granted',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildPrimaryButton() {
    final currentPage = _pages[_currentPage];
    
    return ElevatedButton(
      onPressed: _isRequestingPermissions ? null : () {
        if (currentPage.isPermissionPage && currentPage.permissionType != null) {
          final status = _permissionStatuses[currentPage.permissionType!];
          if (status == PermissionStatus.granted) {
            _nextPage();
          } else {
            _handlePermissionRequest(currentPage.permissionType!);
          }
        } else {
          _nextPage();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: _isRequestingPermissions
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              currentPage.buttonText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

class OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;
  final String buttonText;
  final PermissionType? permissionType;
  final bool isPermissionPage;
  final bool isOptional;

  const OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
    this.permissionType,
    this.isPermissionPage = false,
    this.isOptional = false,
  });
}

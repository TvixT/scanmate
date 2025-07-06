import 'dart:io';
//import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/app_router.dart';
import '../../services/scan_service.dart';
import '../../utils/logger.dart';

class ScanCardScreen extends StatefulWidget {
  const ScanCardScreen({super.key});

  @override
  State<ScanCardScreen> createState() => _ScanCardScreenState();
}

class _ScanCardScreenState extends State<ScanCardScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isScanning = false;
  bool _isFlashOn = false;
  String _scanInstructions = 'Position the business card within the frame';
  final ImagePicker _imagePicker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      Logger.error('Failed to initialize camera: $e');
      if (mounted) {
        _showError('Failed to initialize camera. Please check permissions.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Camera preview
          _buildCameraPreview(),

          // Scanning overlay
          _buildScanningOverlay(),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),

          // Loading overlay
          if (_isScanning) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'Scan Business Card',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.photo_library_rounded, color: Colors.white),
          onPressed: _selectFromGallery,
          tooltip: 'Import from Gallery',
        ),
        IconButton(
          icon: Icon(
            _isFlashOn ? Icons.flash_on : Icons.flash_off,
            color: Colors.white,
          ),
          onPressed: _toggleFlash,
          tooltip: _isFlashOn ? 'Turn off flash' : 'Turn on flash',
        ),
      ],
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[800],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Initializing Camera...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: CameraPreview(_cameraController!),
    );
  }

  Widget _buildScanningOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: CustomPaint(
        painter: ScanOverlayPainter(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Card outline frame
              Container(
                width: 320,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isScanning ? Colors.green : Colors.white,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isScanning
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.green,
                            ),
                          ),
                        ),
                      )
                    : null, // No more Stack with corner indicators
              ),

              const SizedBox(height: 32),

              // Instructions
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _scanInstructions,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery button
          _buildControlButton(
            icon: Icons.photo_library_outlined,
            onPressed: _selectFromGallery,
            size: 28,
          ),

          // Capture button
          GestureDetector(
            onTap: _isScanning ? null : _captureImage,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                color: _isScanning ? Colors.grey[600] : Colors.transparent,
              ),
              child: _isScanning
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
            ),
          ),

          // Switch camera button
          _buildControlButton(
            icon: Icons.switch_camera_outlined,
            onPressed: _switchCamera,
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required double size,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.3),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: size),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Processing image...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFlash() async {
    if (_cameraController != null && _isCameraInitialized) {
      try {
        await _cameraController!.setFlashMode(
          _isFlashOn ? FlashMode.off : FlashMode.torch,
        );
        setState(() {
          _isFlashOn = !_isFlashOn;
        });
      } catch (e) {
        Logger.error('Failed to toggle flash: $e');
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras != null && _cameras!.length > 1) {
      try {
        final currentCameraIndex = _cameras!.indexOf(
          _cameraController!.description,
        );
        final newCameraIndex = (currentCameraIndex + 1) % _cameras!.length;

        await _cameraController!.dispose();

        _cameraController = CameraController(
          _cameras![newCameraIndex],
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        setState(() {});
      } catch (e) {
        Logger.error('Failed to switch camera: $e');
      }
    }
  }

  Future<String> _saveToTempFile(String originalPath) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = originalPath.split(Platform.pathSeparator).last;
    final tempPath = '${tempDir.path}/scanmate_$fileName';
    final tempFile = File(originalPath).copySync(tempPath);
    return tempFile.path;
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_isCameraInitialized || _isScanning) {
      return;
    }

    setState(() {
      _isScanning = true;
      _scanInstructions = 'Processing image...';
    });

    try {
      final XFile image = await _cameraController!.takePicture();
      final tempPath = await _saveToTempFile(image.path);
      await _processImage(tempPath);
    } catch (e) {
      Logger.error('Failed to capture image: $e');
      _showError('Failed to capture image. Please try again.');
      setState(() {
        _isScanning = false;
        _scanInstructions = 'Position the business card within the frame';
      });
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isScanning = true;
          _scanInstructions = 'Processing image...';
        });
        final tempPath = await _saveToTempFile(image.path);
        await _processGalleryImage(tempPath);
      }
    } catch (e) {
      Logger.error('Failed to select image from gallery: $e');
      _showError('Failed to select image. Please try again.');
    }
  }

  Future<File> _cropToScanArea(String imagePath) async {
    // Load image
    final bytes = await File(imagePath).readAsBytes();
    final original = img.decodeImage(bytes);
    if (original == null) return File(imagePath);

    // Camera preview size (full image)
    final width = original.width;
    final height = original.height;

    // Scan area size (as in overlay)
    const scanAreaWidth = 320.0;
    const scanAreaHeight = 200.0;
    // Assume preview is 360x640 (portrait)
    final cropWidth = (scanAreaWidth / 360.0) * width;
    final cropHeight = (scanAreaHeight / 640.0) * height;
    final left = ((width - cropWidth) / 2).round();
    final top = ((height - cropHeight) / 2).round();

    final cropped = img.copyCrop(
      original,
      x: left,
      y: top,
      width: cropWidth.round(),
      height: cropHeight.round(),
    );

    // Save cropped image to temp file
    final croppedFile = File('${imagePath}_cropped.jpg');
    await croppedFile.writeAsBytes(img.encodeJpg(cropped));
    return croppedFile;
  }

  Future<void> _processImage(String imagePath) async {
    try {
      // Crop to scan area
      final croppedFile = await _cropToScanArea(imagePath);
      final inputImage = InputImage.fromFilePath(croppedFile.path);

      // Perform OCR
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Extract contact information using ScanService
      final contactData = await ScanService.extractContactInfo(
        recognizedText.text,
      );

      // Add image path and source to contact data
      contactData['imagePath'] = imagePath;
      contactData['source'] = 'camera'; // Mark as camera source

      if (mounted) {
        if (contactData.isNotEmpty && contactData.length > 2) {
          // More than just imagePath and source
          // Navigate to review screen with extracted data
          await context.push(AppRouter.reviewContact, extra: contactData);
          if (mounted) {
            setState(() {
              _isScanning = false;
              _scanInstructions = 'Position the business card within the frame';
            });
          }
        } else {
          _showError(
            'No text found in the image. Please try again with a clearer photo.',
          );
          setState(() {
            _isScanning = false;
            _scanInstructions = 'Position the business card within the frame';
          });
        }
      }
    } catch (e) {
      Logger.error('Failed to process image: $e');
      if (mounted) {
        _showError('Failed to process image. Please try again.');
        setState(() {
          _isScanning = false;
          _scanInstructions = 'Position the business card within the frame';
        });
      }
    }
  }

  Future<void> _processGalleryImage(String imagePath) async {
    try {
      // Crop to scan area
      final croppedFile = await _cropToScanArea(imagePath);
      final inputImage = InputImage.fromFilePath(croppedFile.path);

      // Perform OCR
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Extract contact information using ScanService
      final contactData = await ScanService.extractContactInfo(
        recognizedText.text,
      );

      // Add image path and source to contact data
      contactData['imagePath'] = imagePath;
      contactData['source'] = 'gallery'; // Mark as gallery source

      if (mounted) {
        if (contactData.isNotEmpty && contactData.length > 2) {
          // More than just imagePath and source
          // Navigate to review screen with extracted data
          await context.push(AppRouter.reviewContact, extra: contactData);
          if (mounted) {
            setState(() {
              _isScanning = false;
              _scanInstructions = 'Position the business card within the frame';
            });
          }
        } else {
          _showError(
            'No text found in the image. Please try again with a clearer photo.',
          );
          setState(() {
            _isScanning = false;
            _scanInstructions = 'Position the business card within the frame';
          });
        }
      }
    } catch (e) {
      Logger.error('Failed to process image: $e');
      if (mounted) {
        _showError('Failed to process image. Please try again.');
        setState(() {
          _isScanning = false;
          _scanInstructions = 'Position the business card within the frame';
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// Custom painter for scan overlay
class ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final scanAreaWidth = 320.0;
    final scanAreaHeight = 200.0;
    final scanAreaLeft = (size.width - scanAreaWidth) / 2;
    final scanAreaTop = (size.height - scanAreaHeight) / 2.5;

    final scanRect = Rect.fromLTWH(
      scanAreaLeft,
      scanAreaTop,
      scanAreaWidth,
      scanAreaHeight,
    );

    // Overlay (everything except scan area)
    final fullScreenPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final scanAreaPath = Path()
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(12)));
    final overlayPath = Path.combine(
      PathOperation.difference,
      fullScreenPath,
      scanAreaPath,
    );
    canvas.drawPath(overlayPath, paint);

    // Draw triangle corner indicators
    final trianglePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    //const triangleSize = 18.0;
    const borderRadius = 12.0;

    // Top-left
    final topLeft = Offset(scanAreaLeft, scanAreaTop);
    final topLeftTriangle = Path()
      ..moveTo(topLeft.dx + borderRadius, topLeft.dy)
      ..lineTo(topLeft.dx, topLeft.dy)
      ..lineTo(topLeft.dx, topLeft.dy + borderRadius)
      ..close();
    canvas.drawPath(topLeftTriangle, trianglePaint);

    // Top-right
    final topRight = Offset(scanAreaLeft + scanAreaWidth, scanAreaTop);
    final topRightTriangle = Path()
      ..moveTo(topRight.dx - borderRadius, topRight.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(topRight.dx, topRight.dy + borderRadius)
      ..close();
    canvas.drawPath(topRightTriangle, trianglePaint);

    // Bottom-left
    final bottomLeft = Offset(scanAreaLeft, scanAreaTop + scanAreaHeight);
    final bottomLeftTriangle = Path()
      ..moveTo(bottomLeft.dx + borderRadius, bottomLeft.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy - borderRadius)
      ..close();
    canvas.drawPath(bottomLeftTriangle, trianglePaint);

    // Bottom-right
    final bottomRight = Offset(
      scanAreaLeft + scanAreaWidth,
      scanAreaTop + scanAreaHeight,
    );
    final bottomRightTriangle = Path()
      ..moveTo(bottomRight.dx - borderRadius, bottomRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy - borderRadius)
      ..close();
    canvas.drawPath(bottomRightTriangle, trianglePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

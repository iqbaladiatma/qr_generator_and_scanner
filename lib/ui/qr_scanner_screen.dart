import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  String? _barcodeValue;
  Uint8List? _capturedImage;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: true,
      formats: [BarcodeFormat.qrCode],
    );
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const ScanGuideBottomSheet(),
      );
    });
  }

  Future<void> _initializeCamera() async {
    try {
      if (kIsWeb) {
        // On Web, browser handles permission automatically
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          await _controller.start();
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        // For mobile platforms, request camera permission
        final status = await Permission.camera.status;
        if (!status.isGranted) {
          final result = await Permission.camera.request();
          if (result.isGranted) {
            await _controller.start();
            setState(() {
              _isLoading = false;
            });
          } else if (result.isPermanentlyDenied) {
            openAppSettings();
            setState(() {
              _isLoading = false;
              _errorMessage = 'Camera permission denied. Please enable in settings.';
            });
          } else {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Camera permission denied.';
            });
          }
        } else {
          await _controller.start();
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to initialize camera: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    
    if (state == AppLifecycleState.inactive) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.start();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing camera...'),
                ],
              ),
            )
          else if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      _initializeCamera();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else
            MobileScanner(
              controller: _controller,
              onDetect: _handleBarcode,
              errorBuilder: (context, error, child) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Camera Error: ${error.errorCode.name}',
                        style: const TextStyle(color: Colors.red),
                      ),
                      if (error.errorDetails != null)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            error.errorDetails!.message ?? '',
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          if (!_isLoading && _errorMessage == null)
            Center(
              child: CustomPaint(
                size: const Size(280, 280),
                painter: ScannerOverlayPainter(),
              ),
            ),
          if (!_isLoading && _errorMessage == null)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: const Center(
                child: Text(
                  'Arahkan QR Code ke dalam kotak',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleBarcode(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    final Uint8List? image = capture.image;
    
    if (barcode != null && barcode.rawValue != null) {
      _controller.stop();
      setState(() {
        _barcodeValue = barcode.rawValue;
        _capturedImage = image;
      });
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('QR Terdeteksi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_capturedImage != null)
                  Image.memory(_capturedImage!, height: 180)
                else
                  Container(
                    height: 180,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.qr_code_2, size: 100, color: Colors.grey),
                  ),
                const SizedBox(height: 16),
                SelectableText(
                  _barcodeValue!,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copy'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _barcodeValue!));
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Disalin ke clipboard')),
                );
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.close),
              label: const Text('Tutup'),
              onPressed: () {
                Navigator.pop(ctx);
                _controller.start();
              },
            ),
          ],
        ),
      );
    }
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    const cornerLength = 30.0;
    final path = Path();

    // Kiri atas
    path.moveTo(0, cornerLength);
    path.lineTo(0, 0);
    path.lineTo(cornerLength, 0);

    // Kanan atas
    path.moveTo(size.width - cornerLength, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, cornerLength);

    // Kiri bawah
    path.moveTo(0, size.height - cornerLength);
    path.lineTo(0, size.height);
    path.lineTo(cornerLength, size.height);

    // Kanan bawah
    path.moveTo(size.width - cornerLength, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, size.height - cornerLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ScanGuideBottomSheet extends StatelessWidget {
  const ScanGuideBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Scan QR Code',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Arahkan kamera ke QR Code di dalam kotak agar hasil lebih akurat.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Image.asset(
            'assets/images/scan-icon.png',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mulai Scan'),
          ),
        ],
      ),
    );
  }
}
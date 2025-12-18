import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerWidget extends StatefulWidget {
  final Function(String barcode) onBarcodeDetected;
  final VoidCallback onClose;

  const BarcodeScannerWidget({
    Key? key,
    required this.onBarcodeDetected,
    required this.onClose,
  }) : super(key: key);

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  late MobileScannerController controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcode = capture.barcodes.first;
    if (barcode.rawValue != null) {
      _isProcessing = true;
      widget.onBarcodeDetected(barcode.rawValue!);

      // Add a small delay before closing to prevent multiple scans
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          widget.onClose();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              controller.toggleTorch();
            },
            icon: const Icon(Icons.flash_on),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _handleBarcode,
          ),
          // Scanner overlay
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: BarcodeScannerOverlayPainter(),
          ),
          // Instructions
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Align barcode within the frame to scan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BarcodeScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Draw dark overlay except for the scan area
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.7,
      height: size.width * 0.3,
    );

    // Top overlay
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, scanRect.top),
      paint,
    );

    // Bottom overlay
    canvas.drawRect(
      Rect.fromLTWH(0, scanRect.bottom, size.width, size.height - scanRect.bottom),
      paint,
    );

    // Left overlay
    canvas.drawRect(
      Rect.fromLTWH(0, scanRect.top, scanRect.left, scanRect.height),
      paint,
    );

    // Right overlay
    canvas.drawRect(
      Rect.fromLTWH(scanRect.right, scanRect.top, size.width - scanRect.right, scanRect.height),
      paint,
    );

    // Draw scan frame
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final borderRect = RRect.fromRectAndRadius(scanRect, const Radius.circular(12));
    canvas.drawRRect(borderRect, borderPaint);

    // Draw corner brackets
    final cornerPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final cornerLength = 20.0;
    final cornerWidth = 8.0;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left + cornerWidth, scanRect.top)
        ..lineTo(scanRect.left + cornerLength, scanRect.top)
        ..moveTo(scanRect.left, scanRect.top + cornerWidth)
        ..lineTo(scanRect.left, scanRect.top + cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - cornerLength, scanRect.top)
        ..lineTo(scanRect.right - cornerWidth, scanRect.top)
        ..moveTo(scanRect.right, scanRect.top + cornerWidth)
        ..lineTo(scanRect.right, scanRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left + cornerWidth, scanRect.bottom)
        ..lineTo(scanRect.left + cornerLength, scanRect.bottom)
        ..moveTo(scanRect.left, scanRect.bottom - cornerLength)
        ..lineTo(scanRect.left, scanRect.bottom - cornerWidth),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - cornerLength, scanRect.bottom)
        ..lineTo(scanRect.right - cornerWidth, scanRect.bottom)
        ..moveTo(scanRect.right, scanRect.bottom - cornerLength)
        ..lineTo(scanRect.right, scanRect.bottom - cornerWidth),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
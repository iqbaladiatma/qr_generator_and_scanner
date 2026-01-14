import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const Color primaryColor = Color(0xFF3A2EC3);

const List<Color> qrColors = [
  Colors.white,
  Colors.grey,
  Colors.orange,
  Colors.yellow,
  Colors.green,
  Colors.cyan,
  Colors.purple,
];

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final TextEditingController _textController = TextEditingController();

  String? _qrData;
  Color _qrColor = Colors.white;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _shareQrCode() async {
    if (_qrData == null || _qrData!.isEmpty) return;

    // Wait for ripple effect or keyboard to dismiss
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Capture the QR code widget
    final Uint8List? imageBytes = await _screenshotController.capture(
      pixelRatio: 3.0, // Higher resolution for better quality
    );

    if (imageBytes != null) {
      await Share.shareXFiles(
        [
          XFile.fromData(
            imageBytes,
            name: 'qrcode_${DateTime.now().millisecondsSinceEpoch}.png',
            mimeType: 'image/png',
          ),
        ],
        text: 'QR Code untuk: $_qrData\nDibuat dengan QR S&G',
        subject: 'QR Code dari QR S&G App',
      );
    }
  }

  Future<void> _generateAndPrintPdf() async {
    if (_qrData == null || _qrData!.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final imageBytes = await _screenshotController.capture(pixelRatio: 3.0);

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (imageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil gambar QR Code')),
        );
        return;
      }

      final pdf = pw.Document();
      final qrImage = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('QR Code Generated', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 20),
                  pw.Image(qrImage, width: 200, height: 200),
                  pw.SizedBox(height: 20),
                  pw.Text('Link/Teks: $_qrData', style: const pw.TextStyle(fontSize: 14)),
                  pw.SizedBox(height: 10),
                  pw.Text('Dibuat oleh: QR S&G App', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'QR_Code_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (mounted) {
        // Try to close dialog if it's still open (though we tried to pop earlier)
        // If the error happened before pop, we need to pop.
        // But we can't easily know if it was popped.
        // A safer way is to use a local flag or just rely on the user to dismiss if it gets stuck?
        // Or just pop and ignore error?
        // We'll assume if we are here and the dialog is still up, we should pop?
        // Actually, let's just show the snackbar.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _resetQrCode() {
    setState(() {
      _qrData = null;
      _qrColor = Colors.white;
      _textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create QR', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background design
          Column(
            children: [
              Container(height: 220, color: primaryColor),
              Expanded(child: Container(color: Colors.grey.shade50)),
            ],
          ),
          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildQrPreview(),
                        const SizedBox(height: 24),
                        _buildInputSection(),
                        const SizedBox(height: 24),
                        _buildColorPicker(),
                        const SizedBox(height: 32),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrPreview() {
    return Screenshot(
      controller: _screenshotController,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _qrColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: _qrData == null || _qrData!.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  'Masukkan teks/link untuk generate QR',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : PrettyQrView.data(
                data: _qrData!,
                decoration: const PrettyQrDecoration(
                  shape: PrettyQrSmoothSymbol(),
                ),
              ),
      ),
    );
  }

  Widget _buildInputSection() {
    return TextField(
      controller: _textController,
      decoration: InputDecoration(
        labelText: 'Link atau Teks',
        hintText: 'https://example.com atau teks apa saja',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      maxLines: 3,
      onChanged: (value) {
        setState(() {
          _qrData = value.trim().isEmpty ? null : value.trim();
        });
      },
    );
  }

  Widget _buildColorPicker() {
    return Column(
      children: [
        Text(
          'Pilih Warna Background QR',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: qrColors.map((color) {
            return GestureDetector(
              onTap: () => setState(() => _qrColor = color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _qrColor == color ? Colors.black : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final bool hasData = _qrData != null && _qrData!.isNotEmpty;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _resetQrCode,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Reset'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: hasData ? _shareQrCode : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: hasData ? _generateAndPrintPdf : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.print),
            label: const Text('Print / Save PDF'),
          ),
        ),
      ],
    );
  }
}

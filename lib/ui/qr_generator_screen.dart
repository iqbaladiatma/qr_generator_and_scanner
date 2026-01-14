import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const Color kPrimaryBlue = Color(0xFF0D47A1);
const Color kSecondaryBlue = Color(0xFF1565C0);
const Color kAccentBlue = Color(0xFF1E88E5);

const List<Color> qrColors = [
  Colors.white,
  Color(0xFFE3F2FD),
  Color(0xFFBBDEFB),
  Color(0xFFE8EAF6),
  Color(0xFFF3E5F5),
  Color(0xFFE0F7FA),
  Color(0xFFE8F5E9),
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
    await Future.delayed(const Duration(milliseconds: 100));
    final Uint8List? imageBytes = await _screenshotController.capture(pixelRatio: 3.0);
    if (imageBytes != null) {
      await Share.shareXFiles(
        [XFile.fromData(imageBytes, name: 'qrcode.png', mimeType: 'image/png')],
        text: 'QR Code untuk: $_qrData\nDibuat dengan QRODE',
      );
    }
  }

  Future<void> _generateAndPrintPdf() async {
    if (_qrData == null || _qrData!.isEmpty) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: kPrimaryBlue)),
    );
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final imageBytes = await _screenshotController.capture(pixelRatio: 3.0);
      if (!mounted) return;
      Navigator.pop(context);
      if (imageBytes == null) return;
      final pdf = pw.Document();
      final qrImage = pw.MemoryImage(imageBytes);
      pdf.addPage(pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('QR Code', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Image(qrImage, width: 200, height: 200),
              pw.SizedBox(height: 20),
              pw.Text('Content: $_qrData'),
            ],
          ),
        ),
      ));
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      if (mounted) Navigator.pop(context);
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kPrimaryBlue, kSecondaryBlue],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              const SizedBox(height: 20),
              Expanded(child: _buildMainContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Expanded(
            child: Text('Create QR Code', textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FA),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildQrCard(),
            const SizedBox(height: 20),
            _buildInputCard(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [_buildQrPreview(), const SizedBox(height: 24), _buildColorPicker()],
      ),
    );
  }

  Widget _buildQrPreview() {
    return Screenshot(
      controller: _screenshotController,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _qrColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kAccentBlue.withOpacity(0.2), width: 2),
        ),
        child: _qrData == null || _qrData!.isEmpty
            ? SizedBox(
                width: 180, height: 180,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2, size: 80, color: kAccentBlue.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Text('QR akan muncul di sini', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                  ],
                ),
              )
            : SizedBox(
                width: 180, height: 180,
                child: PrettyQrView.data(data: _qrData!, decoration: const PrettyQrDecoration(shape: PrettyQrSmoothSymbol(color: kPrimaryBlue))),
              ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Masukkan Konten', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: 'https://example.com',
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kAccentBlue, width: 2)),
              prefixIcon: Icon(Icons.link_rounded, color: Colors.grey[400]),
            ),
            maxLines: 3,
            minLines: 1,
            onChanged: (value) => setState(() => _qrData = value.trim().isEmpty ? null : value.trim()),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker() {
    return Column(
      children: [
        Text('Warna Background', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: qrColors.map((color) {
            final isSelected = _qrColor == color;
            return GestureDetector(
              onTap: () => setState(() => _qrColor = color),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle,
                  border: Border.all(color: isSelected ? kPrimaryBlue : Colors.grey[300]!, width: isSelected ? 3 : 1),
                ),
                child: isSelected ? const Icon(Icons.check, color: kPrimaryBlue, size: 20) : null,
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
            Expanded(child: _buildButton('Reset', Icons.refresh, Colors.red[400]!, true, _resetQrCode)),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: _buildGradientButton('Share QR', Icons.share_rounded, hasData, _shareQrCode)),
          ],
        ),
        const SizedBox(height: 12),
        _buildGradientButton('Print / Save PDF', Icons.picture_as_pdf_rounded, hasData, _generateAndPrintPdf, fullWidth: true),
      ],
    );
  }

  Widget _buildButton(String text, IconData icon, Color color, bool enabled, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: color)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(icon, color: color), const SizedBox(width: 8), Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600))],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton(String text, IconData icon, bool enabled, VoidCallback onTap, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        gradient: enabled ? const LinearGradient(colors: [kPrimaryBlue, kSecondaryBlue]) : null,
        color: enabled ? null : Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: enabled ? Colors.white : Colors.grey[500]),
                const SizedBox(width: 8),
                Text(text, style: TextStyle(color: enabled ? Colors.white : Colors.grey[500], fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

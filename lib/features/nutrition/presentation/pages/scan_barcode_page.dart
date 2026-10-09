import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_theme.dart';

/// สแกนบาร์โค้ดสินค้า pop กลับด้วยเลขบาร์โค้ด
class ScanBarcodePage extends StatefulWidget {
  const ScanBarcodePage({super.key});

  @override
  State<ScanBarcodePage> createState() => _ScanBarcodePageState();
}

class _ScanBarcodePageState extends State<ScanBarcodePage> {
  /// บาร์โค้ดสินค้าทั่วไป ไม่สแกน QR จะได้ไม่จับผิดตัว
  final _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );

  /// กล้องส่งผลมาหลายเฟรม กัน pop ซ้ำ
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish(String code) {
    if (_done) return;
    _done = true;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(code);
  }

  void _onDetect(BarcodeCapture capture) {
    final code = capture.barcodes.map((b) => b.rawValue).nonNulls.firstOrNull;
    if (code != null) _finish(code);
  }

  /// ใช้เมื่อกล้องอ่านไม่ออก หรือเครื่องไม่มีกล้อง (simulator)
  Future<void> _typeCode() async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _BarcodeInputDialog(),
    );
    if (code != null) _finish(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('สแกนบาร์โค้ด'),
        actions: [
          IconButton(
            tooltip: 'ไฟฉาย',
            icon: const Icon(Icons.flashlight_on_rounded),
            onPressed: _controller.toggleTorch,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _ScannerError(error: error),
          ),
          const Center(child: _ScanFrame()),
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: SafeArea(
              child: Column(
                children: [
                  const Text(
                    'เล็งบาร์โค้ดบนบรรจุภัณฑ์ให้อยู่ในกรอบ',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.keyboard_rounded),
                    label: const Text('พิมพ์เลขบาร์โค้ดเอง'),
                    onPressed: _typeCode,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 160,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lime, width: 3),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final text = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'แอปไม่ได้รับสิทธิ์ใช้กล้อง เปิดได้ที่การตั้งค่าของเครื่อง',
      MobileScannerErrorCode.unsupported => 'เครื่องนี้ไม่มีกล้องที่ใช้สแกนได้',
      _ => 'เปิดกล้องไม่สำเร็จ',
    };
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            '$text\nพิมพ์เลขบาร์โค้ดเองได้ที่ปุ่มด้านล่าง',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _BarcodeInputDialog extends StatefulWidget {
  const _BarcodeInputDialog();

  @override
  State<_BarcodeInputDialog> createState() => _BarcodeInputDialogState();
}

class _BarcodeInputDialogState extends State<_BarcodeInputDialog> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_code.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('เลขบาร์โค้ด'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _code,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(hintText: 'เช่น 8850999320007'),
          // EAN-8, UPC-E (8), UPC-A (12), EAN-13 (13)
          validator: (v) => const {8, 12, 13}.contains(v?.trim().length)
              ? null
              : 'บาร์โค้ดต้องมี 8, 12 หรือ 13 หลัก',
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(onPressed: _submit, child: const Text('ค้นหา')),
      ],
    );
  }
}

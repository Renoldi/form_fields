import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// ---------------------------------------------------------------------------
/// FormFieldsBarcodeScan Widget
/// ---------------------------------------------------------------------------
/// A reusable, organized, and professional barcode/QR code scanner form field
/// for Flutter, using mobile_scanner. Designed to match the API and style of
/// FormFields for consistency.
///
/// Example:
///   FormFieldsBarcodeScan(
///     label: 'Scan Barcode',
///     onChanged: (value) { /* ... */ },
///   )
/// ---------------------------------------------------------------------------
class FormFieldsBarcodeScan extends StatefulWidget {
  /// Callback when barcode value changes
  final ValueChanged<String?> onChanged;

  /// Current value (barcode string)
  final String? currentValue;

  /// Field label text
  final String label;

  /// Label position relative to input
  final LabelPosition labelPosition;

  /// Custom validator function
  final FormFieldValidator<String>? validator;

  /// Whether field is required
  final bool isRequired;

  /// When to show validation errors
  final AutovalidateMode autovalidateMode;

  /// Custom input decoration
  final InputDecoration? inputDecoration;

  /// Custom text style for label
  final TextStyle? labelTextStyle;

  /// Custom text style for barcode value
  final TextStyle? valueTextStyle;

  /// Icon for scan button
  final IconData scanIcon;

  /// Constructor
  const FormFieldsBarcodeScan({
    super.key,
    required this.onChanged,
    required this.label,
    this.currentValue,
    this.labelPosition = LabelPosition.top,
    this.validator,
    this.isRequired = false,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.inputDecoration,
    this.labelTextStyle,
    this.valueTextStyle,
    this.scanIcon = Icons.qr_code_scanner,
  });

  @override
  State<FormFieldsBarcodeScan> createState() => _FormFieldsBarcodeScanState();
}

class _FormFieldsBarcodeScanState extends State<FormFieldsBarcodeScan> {
  String? _barcodeValue;

  @override
  void initState() {
    super.initState();
    _barcodeValue = widget.currentValue;
  }

  @override
  void didUpdateWidget(covariant FormFieldsBarcodeScan oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentValue != widget.currentValue) {
      setState(() {
        _barcodeValue = widget.currentValue;
      });
    }
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (context) => _BarcodeScannerPage(),
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _barcodeValue = result;
      });
      widget.onChanged(result);
    }
  }

  String? _validate(String? value) {
    if (widget.validator != null) {
      final customError = widget.validator!(value);
      if (customError != null) return customError;
    }
    if (widget.isRequired && (value == null || value.isEmpty)) {
      return 'Field "${widget.label}" is required';
    }
    return null;
  }

  Widget _buildLabel() {
    if (widget.labelPosition == LabelPosition.none) {
      return const SizedBox.shrink();
    }
    final defaultLabelStyle =
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
    final labelStyle = (widget.labelTextStyle ?? defaultLabelStyle)
        .copyWith(color: Colors.black87);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(widget.label, style: labelStyle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final field = FormField<String>(
      initialValue: _barcodeValue,
      autovalidateMode: widget.autovalidateMode,
      validator: _validate,
      builder: (state) {
        return InputDecorator(
          decoration:
              (widget.inputDecoration ?? const InputDecoration()).copyWith(
            errorText: state.errorText,
            suffixIcon: IconButton(
              icon: Icon(widget.scanIcon),
              onPressed: _scanBarcode,
            ),
          ),
          child: Text(
            _barcodeValue ?? '-',
            style: widget.valueTextStyle ?? const TextStyle(fontSize: 16),
          ),
        );
      },
    );

    switch (widget.labelPosition) {
      case LabelPosition.top:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(),
            field,
          ],
        );
      case LabelPosition.bottom:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            field,
            _buildLabel(),
          ],
        );
      case LabelPosition.left:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 120, child: _buildLabel()),
            const SizedBox(width: 12),
            Expanded(child: field),
          ],
        );
      case LabelPosition.right:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: field),
            const SizedBox(width: 12),
            SizedBox(width: 120, child: _buildLabel()),
          ],
        );
      case LabelPosition.inBorder:
      case LabelPosition.none:
        return field;
    }
  }
}

/// Barcode scanner page using mobile_scanner
class _BarcodeScannerPage extends StatefulWidget {
  @override
  State<_BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<_BarcodeScannerPage> {
  MobileScannerController controller = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (_scanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final code = barcodes.first.rawValue;
                if (code != null && code.isNotEmpty) {
                  setState(() => _scanned = true);
                  Navigator.of(context).pop(code);
                }
              }
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

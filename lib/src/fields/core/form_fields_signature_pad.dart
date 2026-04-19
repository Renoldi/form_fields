import 'dart:io';

import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:signature/signature.dart';

/// ---------------------------------------------------------------------------
/// FormFields SignaturePad Component (menggunakan package signature)
/// ---------------------------------------------------------------------------
/// Komponen signature pad berbasis plugin signature (https://pub.dev/packages/signature)
class FormFieldsSignaturePad extends StatefulWidget {
  final double height;
  final double width;
  final Color backgroundColor;
  final Color penColor;
  final double penStrokeWidth;
  final void Function(MyimageResult?)? onExported;

  const FormFieldsSignaturePad({
    super.key,
    this.height = 200,
    this.width = double.infinity,
    this.backgroundColor = Colors.white,
    this.penColor = Colors.black,
    this.penStrokeWidth = 3.0,
    this.onExported,
  });

  @override
  State<FormFieldsSignaturePad> createState() => _FormFieldsSignaturePadState();
}

class _FormFieldsSignaturePadState extends State<FormFieldsSignaturePad> {
  late SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: widget.penStrokeWidth,
      penColor: widget.penColor,
      exportBackgroundColor: widget.backgroundColor,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _exportSignature() async {
    if (widget.onExported != null) {
      final data = await _controller.toPngBytes();
      if (data == null) {
        widget.onExported!(null);
        return;
      }
      // Simulasikan file sementara dari bytes PNG
      final tempDir = Directory.systemTemp;
      final file = await File(
              '${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png')
          .create();
      await file.writeAsBytes(data);
      final result = await MyimageResult.fromFile(file);
      widget.onExported!(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = FormFieldsLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Container(
              color: widget.backgroundColor,
              width: widget.width,
              height: widget.height,
              child: Signature(
                controller: _controller,
                backgroundColor: widget.backgroundColor,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: const Icon(Icons.delete_forever,
                      color: Colors.deepPurple),
                  tooltip: localizations.get('signatureClear'),
                  onPressed: () {
                    _controller.clear();
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Material(
            color: Colors.transparent,
            child: IconButton(
              icon: const Icon(Icons.verified,
                  color: Colors.deepPurple, size: 32),
              tooltip: localizations.get('signatureExport'),
              onPressed: _exportSignature,
            ),
          ),
        ),
      ],
    );
  }
}

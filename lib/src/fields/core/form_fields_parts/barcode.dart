part of '../form_fields.dart';

extension _FormFieldsBarcodeX<T> on _FormFieldsState<T> {
  // Barcode scanner dialog for scanBarcode type
  Future<void> _showBarcodeScannerDialog({
    required ValueChanged<String> onScanned,
    String? cancelButtonLabel,
    Color? overlayColor,
    Color? overlayBorderColor,
    double overlayBorderWidth = 3.0,
    double overlayBorderRadius = 16.0,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return _BarcodeScannerDialog(
          cancelButtonLabel: cancelButtonLabel,
          overlayColor: overlayColor,
          overlayBorderColor: overlayBorderColor,
          overlayBorderWidth: overlayBorderWidth,
          overlayBorderRadius: overlayBorderRadius,
        );
      },
    );

    // The field may have been removed while the scanner was open.
    if (result != null && mounted) {
      onScanned(result);
    }
  }

  // Barcode scan field builder
  Widget _buildBarcodeScanField() {
    final String? value = widget.currentValue as String?;
    final errorText = widget.externalErrorText;
    final label = widget.label.toTitleCases;
    final scanIcon = const Icon(Icons.qr_code_scanner);
    // final scanButtonLabel = 'Scan';
    final cancelButtonLabel = context.formTr('cancel');
    final overlayColor = resolveTextColor(
      context,
      muted: true,
    ).withValues(alpha: 0.5);
    final overlayBorderColor = Theme.of(context).colorScheme.onSurface;
    final overlayBorderWidth = 3.0;
    final overlayBorderRadius = 16.0;

    void handleScan(String? code) {
      if (code != null) {
        widget.onChanged(code as T);
      }
    }

    // Ensure the shared controller reflects the current value without
    // creating a new controller each build (which can cause lifecycle
    // and disposal issues).
    final current = value ?? '';
    if (model.controller.text != current) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        model.setControllerSilent(current);
      });
    }

    return TextFormField(
      controller: model.controller,
      readOnly: widget.readOnly,
      decoration: _effectiveInputDecoration(widget.inputDecoration).copyWith(
        labelText: widget.labelPosition == LabelPosition.inBorder
            ? label
            : null,
        errorText: errorText,
        suffixIcon: IconButton(
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          iconSize: 20,
          splashRadius: 20,
          icon: scanIcon,
          onPressed: widget.readOnly
              ? null
              : () {
                  _showBarcodeScannerDialog(
                    onScanned: handleScan,
                    cancelButtonLabel: cancelButtonLabel,
                    overlayColor: overlayColor,
                    overlayBorderColor: overlayBorderColor,
                    overlayBorderWidth: overlayBorderWidth,
                    overlayBorderRadius: overlayBorderRadius,
                  );
                },
        ),
      ),
      onChanged: (text) {
        widget.onChanged(text as T);
      },
    );
  }
}

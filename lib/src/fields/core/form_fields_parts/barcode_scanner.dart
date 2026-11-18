part of '../form_fields.dart';

// Top-level dialog widget that owns its MobileScannerController lifecycle.
class _BarcodeScannerDialog extends StatefulWidget {
  final String? cancelButtonLabel;
  final Color? overlayColor;
  final Color? overlayBorderColor;
  final double overlayBorderWidth;
  final double overlayBorderRadius;

  const _BarcodeScannerDialog({
    this.cancelButtonLabel,
    this.overlayColor,
    this.overlayBorderColor,
    this.overlayBorderWidth = 3.0,
    this.overlayBorderRadius = 16.0,
  });

  @override
  State<_BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<_BarcodeScannerDialog> {
  late final MobileScannerController _controller;

  /// The scanner reports every frame that contains a code, so `onDetect` can
  /// fire again before the route is gone. Only the first result may close it.
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.unrestricted,
    );
  }

  @override
  void dispose() {
    try {
      _controller.dispose();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedOverlay =
        widget.overlayColor ??
        theme.colorScheme.surface.withValues(alpha: 0.54);
    final resolvedBorder =
        widget.overlayBorderColor ?? theme.colorScheme.onSurface;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          PermissionGate(
            child: MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                final barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final code = barcodes.first.rawValue;
                  if (code != null && !_closed && context.mounted) {
                    _closed = true;
                    Navigator.of(context).pop(code);
                  }
                }
              },
            ),
          ),
          _ScannerOverlay(
            overlayColor: resolvedOverlay,
            borderColor: resolvedBorder,
            borderWidth: widget.overlayBorderWidth,
            borderRadius: widget.overlayBorderRadius,
          ),
          Positioned(
            top: 48,
            right: 24,
            child: IconButton(
              icon: Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.onSurface,
                size: 32,
              ),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: widget.cancelButtonLabel ?? context.formTr('cancel'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay({
    this.overlayColor,
    this.borderColor,
    this.borderWidth = 3.0,
    this.borderRadius = 16.0,
  });

  final Color? overlayColor;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * 0.8;
        final height = constraints.maxHeight * 0.4;
        final theme = Theme.of(context);
        final resolvedOverlay =
            overlayColor ?? theme.colorScheme.surface.withValues(alpha: 0.5);
        final resolvedBorder = borderColor ?? theme.colorScheme.onSurface;
        return Stack(
          children: [
            Container(color: resolvedOverlay),
            Center(
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  border: Border.all(color: resolvedBorder, width: borderWidth),
                  borderRadius: BorderRadius.circular(borderRadius),
                  color: Colors.transparent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

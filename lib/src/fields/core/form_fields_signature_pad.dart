import 'dart:io';
import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:signature/signature.dart';

/// ---------------------------------------------------------------------------
/// Result of a signature pad export, optionally including a live camera capture.
/// ---------------------------------------------------------------------------
class SignaturePadExportResult {
  /// The exported signature image.
  final MyimageResult signature;

  /// The live camera capture taken at export time (null if live camera disabled
  /// or no photo was captured).
  final MyimageResult? liveCapture;

  const SignaturePadExportResult({
    required this.signature,
    this.liveCapture,
  });
}

/// ---------------------------------------------------------------------------
/// FormFields SignaturePad Component (menggunakan package signature)
/// ---------------------------------------------------------------------------
/// Komponen signature pad berbasis plugin signature (https://pub.dev/packages/signature)
///
/// ### Live Camera
/// Set [showLiveCamera] to `true` to display a front-camera live preview
/// alongside the signature pad.
///
/// **Auto-capture behaviour:** as soon as the user begins drawing the
/// signature (`onDrawStart`), the widget automatically takes a photo from the
/// front camera — no gallery or camera dialog is shown.  The captured image
/// is forwarded through [onExportedResult] as
/// [SignaturePadExportResult.liveCapture].
///
/// Pass your own [liveCameraController] to read / pre-fill the captured image
/// from outside the widget. If omitted, an internal controller is used.
///
/// Use [layoutBuilder] to fully customise the arrangement of the signature pad
/// and the camera widget. When omitted the camera appears below the pad.
///
/// Use [liveCameraBuilder] to wrap or replace just the camera section itself
/// while keeping the default column layout.
class FormFieldsSignaturePad extends StatefulWidget {
  // ── Signature pad ──────────────────────────────────────────────────────────
  final double height;
  final double width;
  final Color backgroundColor;
  final Color penColor;
  final double penStrokeWidth;

  /// Jika null, export PNG transparan. Jika diisi, gunakan warna ini untuk background PNG.
  final Color? exportBackgroundColor;

  // ── Callbacks ──────────────────────────────────────────────────────────────

  /// Called with the signature only (backward-compatible).
  final void Function(MyimageResult?)? onExported;

  /// Called with signature + optional live capture.
  /// Preferred over [onExported] when [showLiveCamera] is enabled.
  final void Function(SignaturePadExportResult)? onExportedResult;

  /// Called immediately after the auto-capture fires (on draw start).
  /// Useful to show a thumbnail or indicator before the user finishes signing.
  final void Function(MyimageResult captured)? onLiveCaptured;

  // ── Live camera ────────────────────────────────────────────────────────────

  /// Show a front-camera live preview.  Auto-captures when signing starts.
  final bool showLiveCamera;

  /// Height of the camera preview widget. Defaults to 200.
  final double liveCameraHeight;

  /// External controller — will be updated with the auto-captured image.
  /// When null, the widget manages its own internal controller.
  final FormFieldsMyImageController? liveCameraController;

  /// Fully custom layout.
  /// Receives the built [signaturePad] and [cameraWidget]
  /// (null when [showLiveCamera] is false). Return your own arrangement.
  final Widget Function(
    BuildContext context,
    Widget signaturePad,
    Widget? cameraWidget,
  )? layoutBuilder;

  /// Custom wrapper for only the camera section.
  /// Receives the live-preview widget; return a decorated version.
  /// Ignored when [layoutBuilder] is provided.
  final Widget Function(BuildContext context, Widget camera)? liveCameraBuilder;

  const FormFieldsSignaturePad({
    super.key,
    this.height = 200,
    this.width = double.infinity,
    this.backgroundColor = Colors.white,
    this.penColor = Colors.black,
    this.penStrokeWidth = 3.0,
    this.onExported,
    this.onExportedResult,
    this.onLiveCaptured,
    this.exportBackgroundColor,
    this.showLiveCamera = false,
    this.liveCameraHeight = 200,
    this.liveCameraController,
    this.layoutBuilder,
    this.liveCameraBuilder,
  });

  @override
  State<FormFieldsSignaturePad> createState() => _FormFieldsSignaturePadState();
}

class _FormFieldsSignaturePadState extends State<FormFieldsSignaturePad> {
  late SignatureController _signatureController;
  late FormFieldsMyImageController _cameraController;
  bool _ownsCamera = false;

  /// Key used to trigger capture/reset on the separated live-camera widget.
  final _liveCameraKey = GlobalKey<FormFieldsLiveCameraCaptureState>();

  /// Guards auto-capture so it fires only once per signing session.
  /// Reset to false when the clear button is pressed.
  bool _hasCaptured = false;

  @override
  void initState() {
    super.initState();
    _initCameraController();
    _signatureController = SignatureController(
      penStrokeWidth: widget.penStrokeWidth,
      penColor: widget.penColor,
      exportBackgroundColor:
          widget.exportBackgroundColor ?? widget.backgroundColor,
      onDrawStart: _onDrawStart,
    );
  }

  void _initCameraController() {
    if (widget.liveCameraController != null) {
      _cameraController = widget.liveCameraController!;
      _ownsCamera = false;
    } else {
      _cameraController = FormFieldsMyImageController();
      _ownsCamera = true;
    }
  }

  @override
  void didUpdateWidget(FormFieldsSignaturePad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.liveCameraController != oldWidget.liveCameraController) {
      if (_ownsCamera) _cameraController.dispose();
      _initCameraController();
    }
  }

  @override
  void dispose() {
    _signatureController.dispose();
    if (_ownsCamera) _cameraController.dispose();
    super.dispose();
  }

  // ── Auto-capture on draw start ─────────────────────────────────────────────

  Future<void> _onDrawStart() async {
    if (!widget.showLiveCamera) return;
    if (_hasCaptured) return; // already captured this session
    _hasCaptured = true;
    final result = await _liveCameraKey.currentState?.capture();
    if (result == null) {
      // Allow retry if capture failed during draw start.
      _hasCaptured = false;
    }
  }

  // ── Export ─────────────────────────────────────────────────────────────────

  Future<void> _exportSignature() async {
    final hasCallback =
        widget.onExported != null || widget.onExportedResult != null;
    if (!hasCallback) return;

    final data = await _signatureController.toPngBytes();
    if (data == null) {
      widget.onExported?.call(null);
      return;
    }

    final tempDir = Directory.systemTemp;
    final file = await File(
      '${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png',
    ).create();
    await file.writeAsBytes(data);
    final signatureResult = await MyimageResult.fromFile(file);

    widget.onExported?.call(signatureResult);

    if (widget.onExportedResult != null) {
      final liveCapture =
          widget.showLiveCamera && _cameraController.images.isNotEmpty
              ? _cameraController.images.first
              : null;
      widget.onExportedResult!(
        SignaturePadExportResult(
          signature: signatureResult,
          liveCapture: liveCapture,
        ),
      );
    }
  }

  // ── Build helpers ──────────────────────────────────────────────────────────

  Widget _buildSignaturePad(FormFieldsLocalizations localizations) {
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
                controller: _signatureController,
                backgroundColor: widget.backgroundColor,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Tooltip(
                message: localizations.get('signatureClear'),
                child: AppButton(
                  icon: const Icon(Icons.delete_forever,
                      color: Colors.deepPurple),
                  text: '',
                  size: AppButtonSize.small,
                  type: AppButtonType.icon,
                  onPressed: () {
                    _signatureController.clear();
                    // Reset capture flag so the next draw triggers a fresh photo.
                    _hasCaptured = false;
                    _liveCameraKey.currentState?.resetCapture();
                    _cameraController.clear();
                  },
                  customIconSize: 24,
                  customHeight: 36,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Tooltip(
            message: localizations.get('signatureExport'),
            child: AppButton(
              icon: const Icon(Icons.verified,
                  color: Colors.deepPurple, size: 32),
              text: '',
              size: AppButtonSize.small,
              type: AppButtonType.icon,
              onPressed: _exportSignature,
              customIconSize: 32,
              customHeight: 48,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraWidget(BuildContext context) {
    final preview = FormFieldsLiveCameraCapture(
      key: _liveCameraKey,
      height: widget.liveCameraHeight,
      cameraController: _cameraController,
      onCaptured: widget.onLiveCaptured,
    );
    if (widget.liveCameraBuilder != null) {
      return widget.liveCameraBuilder!(context, preview);
    }
    return _DefaultCameraSection(child: preview);
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final localizations = FormFieldsLocalizations.of(context);
    final pad = _buildSignaturePad(localizations);
    final cameraWidget =
        widget.showLiveCamera ? _buildCameraWidget(context) : null;

    if (widget.layoutBuilder != null) {
      return widget.layoutBuilder!(context, pad, cameraWidget);
    }

    if (cameraWidget == null) return pad;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        pad,
        const SizedBox(height: 16),
        cameraWidget,
      ],
    );
  }
}

/// Default visual wrapper for the live camera section.
class _DefaultCameraSection extends StatelessWidget {
  final Widget child;
  const _DefaultCameraSection({required this.child});

  @override
  Widget build(BuildContext context) {
    final localizations = FormFieldsLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.camera_front_outlined,
                size: 18, color: Colors.deepPurple),
            Text(
              localizations.get('liveCaptureTitle'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                localizations.get('liveCaptureAutoOnSign'),
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

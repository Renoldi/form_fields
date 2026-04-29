import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  /// Key used to call [_LiveCameraPreviewState.capture] programmatically.
  final _liveCameraKey = GlobalKey<_LiveCameraPreviewState>();

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
    if (result != null) {
      _cameraController.images = [result];
      widget.onLiveCaptured?.call(result);
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
    final preview = _LiveCameraPreview(
      key: _liveCameraKey,
      height: widget.liveCameraHeight,
      cameraController: _cameraController,
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

// ── Shared camera manager (singleton) ─────────────────────────────────────────
//
// Only ONE [CameraController] is ever active for the front camera, shared
// across all [_LiveCameraPreview] instances.  This avoids the CameraX
// "No supported surface combination" error that occurs when multiple
// controllers try to bind the same physical camera simultaneously.

class _SharedCameraManager {
  _SharedCameraManager._();
  static final _SharedCameraManager instance = _SharedCameraManager._();

  CameraController? _controller;
  int _refCount = 0;
  bool _initializing = false;
  String? _errorMessage;

  // Listeners notified when init completes or fails.
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback cb) => _listeners.add(cb);
  void removeListener(VoidCallback cb) => _listeners.remove(cb);
  void _notify() {
    for (final l in List<VoidCallback>.of(_listeners)) {
      l();
    }
  }

  /// Increments ref-count and initialises the controller if needed.
  Future<void> acquire() async {
    _refCount++;
    if (_controller != null && _controller!.value.isInitialized) return;
    if (_initializing) {
      // Another instance is already initialising — just wait.
      await Future.doWhile(() async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return _initializing;
      });
      return;
    }
    _initializing = true;
    _errorMessage = null;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _errorMessage = 'No cameras found';
        _initializing = false;
        _notify();
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final ctrl = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        // No imageFormatGroup — only Preview use case, avoids surface errors.
      );
      await ctrl.initialize();
      _controller = ctrl;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _initializing = false;
    _notify();
  }

  /// Decrements ref-count; disposes the controller when no one holds it.
  void release() {
    _refCount = (_refCount - 1).clamp(0, double.maxFinite.toInt());
    if (_refCount == 0) {
      _controller?.dispose();
      _controller = null;
      _errorMessage = null;
    }
  }

  CameraController? get controller => _controller;
  String? get errorMessage => _errorMessage;
  bool get isReady => _controller != null && _controller!.value.isInitialized;
  bool get isInitializing => _initializing;
}

// ── Live camera preview ────────────────────────────────────────────────────────

class _LiveCameraPreview extends StatefulWidget {
  final double height;

  /// Read-only reference — the widget writes the latest capture here
  /// so [FormFieldsSignaturePad]'s controller stays in sync.
  final FormFieldsMyImageController cameraController;

  const _LiveCameraPreview({
    super.key,
    required this.height,
    required this.cameraController,
  });

  @override
  State<_LiveCameraPreview> createState() => _LiveCameraPreviewState();
}

class _LiveCameraPreviewState extends State<_LiveCameraPreview> {
  final _cam = _SharedCameraManager.instance;

  // RepaintBoundary key — screenshot-based capture avoids ImageCapture use
  // case, so no additional surface combination is needed.
  final _previewKey = GlobalKey();

  /// Non-null once the user has been auto-captured; shows full photo.
  MyimageResult? _capturedResult;

  @override
  void initState() {
    super.initState();
    _cam.addListener(_onCameraReady);
    _cam.acquire();
  }

  void _onCameraReady() {
    if (mounted) setState(() {});
  }

  /// Captures the live preview via [RepaintBoundary] screenshot.
  /// No [ImageCapture] use case is required — zero surface combination issues.
  Future<MyimageResult?> capture() async {
    if (!_cam.isReady) return null;
    try {
      // Wait one frame so the camera preview has rendered.
      await Future<void>.delayed(const Duration(milliseconds: 80));
      final boundary = _previewKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 1.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final bytes = byteData.buffer.asUint8List();
      final tempDir = Directory.systemTemp;
      final file = await File(
        '${tempDir.path}/live_capture_${DateTime.now().millisecondsSinceEpoch}.png',
      ).create();
      await file.writeAsBytes(bytes);
      final result = await MyimageResult.fromFile(file);
      if (mounted) setState(() => _capturedResult = result);
      return result;
    } catch (_) {
      return null;
    }
  }

  /// Resets to live preview mode — called when the signature is cleared.
  void resetCapture() {
    if (mounted) setState(() => _capturedResult = null);
  }

  @override
  void dispose() {
    _cam.removeListener(_onCameraReady);
    _cam.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = FormFieldsLocalizations.of(context);
    final errorMessage = _cam.errorMessage == 'No cameras found'
        ? localizations.get('cameraNoCamerasFound')
        : _cam.errorMessage;

    if (errorMessage != null) {
      return _CameraPlaceholder(
        height: widget.height,
        icon: Icons.no_photography_outlined,
        message: errorMessage,
      );
    }
    if (!_cam.isReady) {
      return _CameraPlaceholder(
        height: widget.height,
        icon: Icons.camera_front,
        message: localizations.get('cameraInitializing'),
        showSpinner: true,
      );
    }

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Layer 1: live preview (always present, hidden when captured) ──
            Opacity(
              opacity: _capturedResult == null ? 1.0 : 0.0,
              child: RepaintBoundary(
                key: _previewKey,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _cam.controller!.value.previewSize?.height ?? 1,
                    height: _cam.controller!.value.previewSize?.width ?? 1,
                    child: CameraPreview(_cam.controller!),
                  ),
                ),
              ),
            ),
            // ── Layer 2: captured photo (full-size, shown after capture) ──
            if (_capturedResult != null)
              _CapturedPhoto(result: _capturedResult!),
            // ── Layer 3: status badge ──
            Positioned(
              bottom: 8,
              right: 8,
              child: _capturedResult == null
                  ? _Badge(
                      icon: Icons.camera_front,
                      label: localizations.get('cameraReady'),
                      color: Colors.black54,
                    )
                  : _Badge(
                      icon: Icons.check_circle_outline,
                      label: localizations.get('cameraCaptured'),
                      color: Colors.green.shade700,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Supporting widgets ─────────────────────────────────────────────────────────

/// Full-size captured photo overlay, shown after auto-capture.
class _CapturedPhoto extends StatelessWidget {
  final MyimageResult result;
  const _CapturedPhoto({required this.result});

  @override
  Widget build(BuildContext context) {
    return result.path.isNotEmpty
        ? Image.file(File(result.path),
            fit: BoxFit.cover, width: double.infinity)
        : Image.memory(
            Uri.parse(result.base64).data!.contentAsBytes(),
            fit: BoxFit.cover,
            width: double.infinity,
          );
  }
}

/// Small status badge shown in the bottom-right of the camera area.
class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  final double height;
  final IconData icon;
  final String message;
  final bool showSpinner;
  const _CameraPlaceholder({
    required this.height,
    required this.icon,
    required this.message,
    this.showSpinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSpinner)
              const CircularProgressIndicator(color: Colors.white54)
            else
              Icon(icon, color: Colors.white54, size: 40),
            const SizedBox(height: 8),
            Text(message,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
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

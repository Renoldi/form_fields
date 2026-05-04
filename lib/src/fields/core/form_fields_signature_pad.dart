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

/// Chooses which exported image should be shown as in-pad preview.
enum SignaturePadPreviewSource {
  signature,
  liveCapture,
  both,
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

  /// When true, replace the drawing area with exported preview after confirm.
  /// While preview is shown, export button is hidden until user clears.
  final bool showExportPreview;

  /// Which exported image(s) to render when [showExportPreview] is enabled.
  ///
  /// - [SignaturePadPreviewSource.signature]: preview signature image only
  /// - [SignaturePadPreviewSource.liveCapture]: preview live camera image only
  /// - [SignaturePadPreviewSource.both]: preview both images side-by-side
  ///
  /// Falls back to signature when live capture is unavailable.
  final SignaturePadPreviewSource exportPreviewSource;

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

  // ── Validation ──────────────────────────────────────────────────────────────

  /// Label text shown above (or beside) the signature pad.
  final String? label;

  /// Position of the label relative to the signature pad.
  /// Supports [LabelPosition.top], [LabelPosition.bottom],
  /// [LabelPosition.left], [LabelPosition.right] and [LabelPosition.none].
  final LabelPosition labelPosition;

  /// Custom text style for the label.
  final TextStyle? labelTextStyle;

  /// Whether a signature must be drawn before the form is valid.
  final bool isRequired;

  /// Custom validator. Receives `true` if the pad has content, `false` if empty.
  /// Return an error string, or null if valid.
  final String? Function(bool hasSignature)? validator;

  /// Controls when validation errors are shown (default: onUserInteraction).
  final AutovalidateMode autovalidateMode;

  /// Error text injected from external (e.g. backend validation).
  /// Always displayed when non-null, regardless of [autovalidateMode].
  final String? externalErrorText;

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
    this.showExportPreview = false,
    this.exportPreviewSource = SignaturePadPreviewSource.signature,
    this.exportBackgroundColor,
    this.showLiveCamera = false,
    this.liveCameraHeight = 200,
    this.liveCameraController,
    this.layoutBuilder,
    this.liveCameraBuilder,
    this.label,
    this.labelPosition = LabelPosition.none,
    this.labelTextStyle,
    this.isRequired = false,
    this.validator,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.externalErrorText,
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

  /// Stored after export when [showExportPreview] is enabled.
  MyimageResult? _previewSignatureResult;
  MyimageResult? _previewLiveCaptureResult;

  final _formFieldKey = GlobalKey<FormFieldState<bool>>();
  FormFieldsLocalizations? _localizations;

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
    _signatureController.addListener(_onSignatureChanged);
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
    if (widget.externalErrorText != oldWidget.externalErrorText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _formFieldKey.currentState?.validate();
      });
    }
    if (widget.liveCameraController != oldWidget.liveCameraController) {
      if (_ownsCamera) _cameraController.dispose();
      _initCameraController();
    }
    if (!widget.showExportPreview &&
        oldWidget.showExportPreview != widget.showExportPreview &&
        (_previewSignatureResult != null ||
            _previewLiveCaptureResult != null)) {
      setState(() {
        _previewSignatureResult = null;
        _previewLiveCaptureResult = null;
      });
    }
  }

  @override
  void dispose() {
    _signatureController.removeListener(_onSignatureChanged);
    _signatureController.dispose();
    if (_ownsCamera) _cameraController.dispose();
    super.dispose();
  }

  // ── Auto-capture on draw start ─────────────────────────────────────────────

  void _onSignatureChanged() {
    _formFieldKey.currentState?.didChange(_signatureController.isNotEmpty);
  }

  Widget _buildLabel() {
    final label = widget.label;
    if (label == null ||
        label.isEmpty ||
        widget.labelPosition == LabelPosition.none) {
      return const SizedBox.shrink();
    }
    const defaultStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
    final style =
        (widget.labelTextStyle ?? defaultStyle).copyWith(color: Colors.black87);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: label, style: style),
            if (widget.isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _wrapWithLabel(Widget content) {
    if (widget.label == null ||
        widget.label!.isEmpty ||
        widget.labelPosition == LabelPosition.none) {
      return content;
    }
    final labelWidget = _buildLabel();
    const labelWidth = 120.0;
    const spacing = 12.0;
    switch (widget.labelPosition) {
      case LabelPosition.top:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [labelWidget, content],
        );
      case LabelPosition.bottom:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [content, labelWidget],
        );
      case LabelPosition.left:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: labelWidth, child: labelWidget),
            const SizedBox(width: spacing),
            Expanded(child: content),
          ],
        );
      case LabelPosition.right:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: content),
            const SizedBox(width: spacing),
            SizedBox(width: labelWidth, child: labelWidget),
          ],
        );
      case LabelPosition.inBorder:
      case LabelPosition.none:
        return content;
    }
  }

  String? _validateSignature(bool? hasSignature) {
    if (widget.externalErrorText != null) return widget.externalErrorText;
    if (widget.validator != null) {
      return widget.validator!(hasSignature ?? false);
    }
    if (widget.isRequired && (hasSignature != true)) {
      final l = _localizations;
      if (l == null) return '';
      final label = widget.label;
      return (label != null && label.isNotEmpty)
          ? l.getWithLabel('signatureRequired', label)
          : l.get('signatureRequiredDefault');
    }
    return null;
  }

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

  void _clearSignatureSession() {
    _signatureController.clear();
    // Reset capture flag so the next draw triggers a fresh photo.
    _hasCaptured = false;
    _liveCameraKey.currentState?.resetCapture();
    _cameraController.clear();
    if (_previewSignatureResult != null || _previewLiveCaptureResult != null) {
      setState(() {
        _previewSignatureResult = null;
        _previewLiveCaptureResult = null;
      });
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
    final liveCapture =
        widget.showLiveCamera && _cameraController.images.isNotEmpty
            ? _cameraController.images.first
            : null;

    if (widget.showExportPreview) {
      if (mounted) {
        setState(() {
          _previewSignatureResult = signatureResult;
          _previewLiveCaptureResult = liveCapture;
        });
      }
    }

    widget.onExported?.call(signatureResult);

    if (widget.onExportedResult != null) {
      widget.onExportedResult!(
        SignaturePadExportResult(
          signature: signatureResult,
          liveCapture: liveCapture,
        ),
      );
    }
  }

  // ── Build helpers ──────────────────────────────────────────────────────────

  Widget _buildPreviewImage(MyimageResult result,
      {BoxFit fit = BoxFit.contain}) {
    if (result.path.trim().isNotEmpty) {
      return Image.file(
        File(result.path),
        fit: fit,
      );
    }

    if (result.link.trim().isNotEmpty) {
      return Image.network(
        result.link,
        fit: fit,
      );
    }

    if (result.base64.trim().isNotEmpty) {
      final bytes = Uri.parse(result.base64).data?.contentAsBytes();
      if (bytes != null) {
        return Image.memory(
          bytes,
          fit: fit,
        );
      }
    }

    return Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 28,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildPreviewCanvas() {
    final signature = _previewSignatureResult;
    if (signature == null) {
      return const SizedBox.shrink();
    }

    switch (widget.exportPreviewSource) {
      case SignaturePadPreviewSource.signature:
        return _buildPreviewImage(signature);
      case SignaturePadPreviewSource.liveCapture:
        final live = _previewLiveCaptureResult;
        return _buildPreviewImage(live ?? signature);
      case SignaturePadPreviewSource.both:
        final live = _previewLiveCaptureResult;
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildPreviewImage(signature, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: live != null
                      ? _buildPreviewImage(live, fit: BoxFit.cover)
                      : Container(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: Center(
                            child: Text(
                              'No live capture',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildSignaturePad(FormFieldsLocalizations localizations) {
    final isPreviewMode =
        widget.showExportPreview && _previewSignatureResult != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Container(
              color: widget.backgroundColor,
              width: widget.width,
              height: widget.height,
              child: isPreviewMode
                  ? _buildPreviewCanvas()
                  : Signature(
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
                  icon: const Icon(Icons.delete_forever),
                  text: '',
                  size: AppButtonSize.small,
                  type: AppButtonType.icon,
                  onPressed: _clearSignatureSession,
                  customIconSize: 24,
                  customHeight: 36,
                ),
              ),
            ),
          ],
        ),
        if (!isPreviewMode) ...[
          const SizedBox(height: 12),
          Center(
            child: Tooltip(
              message: localizations.get('signatureExport'),
              child: AppButton(
                icon: const Icon(Icons.verified, size: 32),
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
    _localizations = FormFieldsLocalizations.of(context);
    final localizations = _localizations!;
    final pad = _buildSignaturePad(localizations);
    final cameraWidget =
        widget.showLiveCamera ? _buildCameraWidget(context) : null;

    Widget content;
    if (widget.layoutBuilder != null) {
      content = widget.layoutBuilder!(context, pad, cameraWidget);
    } else if (cameraWidget == null) {
      content = pad;
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          pad,
          const SizedBox(height: 16),
          cameraWidget,
        ],
      );
    }

    return FormField<bool>(
      key: _formFieldKey,
      autovalidateMode: widget.autovalidateMode,
      initialValue: false,
      validator: _validateSignature,
      builder: (state) {
        final inner = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            content,
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        state.errorText!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
        return _wrapWithLabel(inner);
      },
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
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(
              Icons.camera_front_outlined,
              size: 18,
              color: colorScheme.primary,
            ),
            Text(
              localizations.get('liveCaptureTitle'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                localizations.get('liveCaptureAutoOnSign'),
                style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.primary,
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

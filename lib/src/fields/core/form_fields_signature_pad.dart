import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields/src/models/direct_upload_payload.dart';
import 'package:form_fields/src/utilities/base64_image.dart';
import 'package:form_fields/src/utilities/theme_helpers.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:signature/signature.dart';
import 'package:form_fields/src/service/permission_gate.dart';
import 'package:form_fields/src/utilities/network_status.dart';
import 'package:form_fields/src/utilities/upload_request_helpers.dart';
import 'package:form_fields/src/widgets/form_field_label.dart';
import 'package:form_fields/src/utilities/signature_pad_export_nullable_result.dart';
import 'package:form_fields/src/utilities/debug_log.dart';
import 'package:form_fields/src/utilities/persisted_headers.dart';
import 'package:form_fields/src/utilities/url_origin.dart';
part 'form_fields_signature_pad_parts/signature_pad_widget.dart';

part 'form_fields_signature_pad_parts/signature_pad_controllers.dart';
part 'form_fields_signature_pad_parts/signature_pad_drawing.dart';
part 'form_fields_signature_pad_parts/signature_pad_export.dart';
part 'form_fields_signature_pad_parts/signature_pad_upload.dart';
part 'form_fields_signature_pad_parts/signature_pad_view.dart';
part 'form_fields_signature_pad_parts/default_camera_section.dart';

// SignaturePadExportResult lives in lib/src/utilities/signature_pad_export_result.dart
// SignaturePadPreviewSource lives in lib/src/utilities/enums.dart

class _FormFieldsSignaturePadState extends State<FormFieldsSignaturePad> {
  // State fields moved here from the widget area
  bool _autoExportInProgress = false;

  /// Key used to trigger capture/reset on the separated live-camera widget.
  final _liveCameraKey = GlobalKey<FormFieldsLiveCameraCaptureState>();

  /// Guards auto-capture so it fires only once per signing session.
  /// Reset to false when the clear button is pressed.
  bool _hasCaptured = false;

  late FormFieldsSignaturePadProvider _padProvider;
  // Buffer for payloads emitted by the embedded live camera so we can
  // merge them with signature export payloads and emit a single combined
  // callback to the caller.
  final List<DirectUploadPayload> _embeddedQueuedPayloads = [];

  final _formFieldKey = GlobalKey<FormFieldState<bool>>();
  FormFieldsLocalizations? _localizations;

  // Other internal state members
  late SignatureController _signatureController;
  bool _hasSignatureController = false;
  late FormFieldsMyImageController _cameraController;
  bool _ownsCamera = false;
  // True while this widget holds a reference on the shared camera, so that
  // release() is only ever paired with an acquire() that succeeded.
  bool _holdsSilentCamera = false;
  Timer? _autoExportTimer;
  final Duration _autoExportDebounce = const Duration(milliseconds: 700);
  @override
  void initState() {
    super.initState();
    _padProvider = FormFieldsSignaturePadProvider();
    _initCameraController();
    // Bound once here. Doing it in didChangeDependencies would add the same
    // listener again on every dependency change.
    _bindSignaturePadController(widget.signaturePadController);
    // SignatureController initialized in didChangeDependencies to allow
    // resolving theme-aware default colors via Theme.of(context).
    // Acquire camera for silent background capture, but only after permission.
    if (widget.silentLiveCapture && !widget.showLiveCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final granted = await PermissionGate.ensureCameraPermission(context);
        if (!mounted) return;
        if (granted) {
          try {
            // Use a lower resolution for background/silent capture to speed
            // up camera initialization.
            await SharedCameraManager.instance.acquire(ResolutionPreset.low);
            _holdsSilentCamera = true;
          } catch (_) {}
          // Disposed while the camera was starting: give the reference back.
          if (!mounted) _releaseSilentCamera();
        }
      });
    }
    // Pre-seed preview from controller if it already holds a result.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPreviewFromSignaturePadController();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize SignatureController here so Theme.of(context) is available
    // and we can resolve theme-aware defaults when the widget didn't
    // provide explicit colors.
    final theme = Theme.of(context);
    final resolvedPen = widget.penColor ?? theme.colorScheme.onSurface;
    final resolvedBg =
        widget.exportBackgroundColor ??
        widget.backgroundColor ??
        theme.colorScheme.surface;
    // Dependency changes also fire for unrelated inherited updates. The
    // controller is replaced only when its colors change, so the drawing is
    // not wiped on every one of them.
    if (_hasSignatureController &&
        _signatureController.penColor == resolvedPen &&
        _signatureController.exportBackgroundColor == resolvedBg) {
      return;
    }
    // The colors of a SignatureController are final, so a new one is needed.
    // The strokes move to it, and the old one is released.
    // A growable list: the controller appends to it while drawing.
    final previousPoints = _hasSignatureController
        ? List<Point>.of(_signatureController.points)
        : <Point>[];
    if (_hasSignatureController) {
      _signatureController.removeListener(_onSignatureChanged);
      _signatureController.dispose();
    }
    _signatureController = SignatureController(
      penStrokeWidth: widget.penStrokeWidth,
      penColor: resolvedPen,
      exportBackgroundColor: resolvedBg,
      onDrawStart: _onDrawStart,
    );
    _signatureController.points = previousPoints;
    _signatureController.addListener(_onSignatureChanged);
    _hasSignatureController = true;
  }

  @override
  void didUpdateWidget(FormFieldsSignaturePad oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.externalErrorText != widget.externalErrorText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _formFieldKey.currentState?.validate();
      });
    }

    if (!widget.showExportPreview &&
        oldWidget.showExportPreview != widget.showExportPreview &&
        (_padProvider.previewSignatureResult != null ||
            _padProvider.previewLiveCaptureResult != null)) {
      _padProvider.clearPreviewResults();
    }
    if (widget.signaturePadController != oldWidget.signaturePadController) {
      _unbindSignaturePadController(oldWidget.signaturePadController);
      _bindSignaturePadController(widget.signaturePadController);
      _syncPreviewFromSignaturePadController();
    }
    // If the external liveCameraController changed, rebind/unbind so the
    // OfflineUploadManager and listeners attach to the new controller.
    if (widget.liveCameraController != oldWidget.liveCameraController) {
      _disposeCameraControllerBinding();
      if (_ownsCamera) {
        try {
          _cameraController.dispose();
        } catch (_) {}
      }
      _initCameraController();
    }
  }

  @override
  void dispose() {
    _autoExportTimer?.cancel();
    _unbindSignaturePadController(widget.signaturePadController);
    _disposeCameraControllerBinding();
    _signatureController.removeListener(_onSignatureChanged);
    _signatureController.dispose();
    if (_ownsCamera) _cameraController.dispose();
    _releaseSilentCamera();
    _padProvider.dispose();
    super.dispose();
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _localizations = FormFieldsLocalizations.of(context);
    return ChangeNotifierProvider.value(
      value: _padProvider,
      child: Consumer<FormFieldsSignaturePadProvider>(
        builder: (context, provider, _) {
          final localizations = _localizations!;
          final pad = _buildSignaturePad(localizations, provider);
          final cameraWidget = widget.showLiveCamera
              ? _buildCameraWidget(context)
              : null;

          Widget content;
          if (widget.layoutBuilder != null) {
            content = widget.layoutBuilder!(context, pad, cameraWidget);
          } else if (cameraWidget == null) {
            content = pad;
          } else {
            content = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [pad, const SizedBox(height: 16), cameraWidget],
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
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              state.errorText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
              return FormFieldLabelLayout(
                label: widget.label,
                labelPosition: widget.labelPosition,
                labelTextStyle: widget.labelTextStyle,
                isRequired: widget.isRequired,
                child: inner,
              );
            },
          );
        },
      ),
    );
  }
}

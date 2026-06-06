import 'dart:io';

import 'package:flutter/material.dart';
import 'presenter.dart';
import 'view_model.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';

Widget _buildImageFrom(MyImageResult r, BuildContext context,
    {double? height, BoxFit fit = BoxFit.cover}) {
  if (r.link.isNotEmpty) {
    return Image.network(r.link, height: height, fit: fit);
  }
  if (r.path.isNotEmpty && File(r.path).existsSync()) {
    return Image.file(File(r.path), height: height, fit: fit);
  }
  final bytes = Uri.tryParse(r.base64)?.data?.contentAsBytes();
  if (bytes != null && bytes.isNotEmpty) {
    return Image.memory(bytes, height: height, fit: fit);
  }
  return Container(
    height: height ?? 80,
    color: Colors.grey.shade200,
    child: Center(
      child: Icon(Icons.image_not_supported_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

class View extends PresenterState {
  final GlobalKey<FormFieldsLiveCameraCaptureState> _standaloneCameraKey =
      GlobalKey<FormFieldsLiveCameraCaptureState>();
  final GlobalKey<FormFieldsLiveCameraCaptureState> _hiddenCameraKey =
      GlobalKey<FormFieldsLiveCameraCaptureState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ViewModel(),
      child: Consumer<ViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF4F6FB),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Basic ───────────────────────────────────────────────
                  _ExampleCard(
                    index: 1,
                    title: 'Basic Signature',
                    subtitle:
                        'Preview exported signature; controller is synced before callback',
                    snippet: 'FormFieldsSignaturePad(\n'
                        '  signaturePadController: controller,\n'
                        '  showExportPreview: true,\n'
                        '  exportPreviewSource: SignaturePadPreviewSource.signature,\n'
                        '  onExported: (result) {\n'
                        '    // controller.exportResult sudah update di sini\n'
                        '  },\n'
                        ')',
                    result: viewModel.signatureResult != null
                        ? _SignaturePreview(result: viewModel.signatureResult!)
                        : null,
                    child: FormFieldsSignaturePad(
                      showExportPreview: true,
                      exportPreviewSource: SignaturePadPreviewSource.signature,
                      onExported: viewModel.setSignature,
                      backgroundColor: Colors.white,
                      exportBackgroundColor: Colors.transparent,
                      isDirectUpload: true,
                      // uploadFileFieldName: 'file',
                      // uploadIncludeReqType: false,
                      showLiveCamera: true,
                      uploadUrl:
                          'https://app.smartsafetee.com/mobile-api/api/HseFormData/SaveAttachment',
                      uploadToken:
                          "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9zaWQiOiIzYTg4NGZjMy1iMDZjLTQzYjAtYWQwYi03Yjk3ZTliZTVjM2QiLCJVc2VyTmFtZSI6Im9iaXRlc3R1c2VyQG1haWwuY29tIiwiU3Vic2NyaXB0aW9uSWQiOiJjYzlkMWJmNC1kOThiLTQ3MjYtODcwYS05OTk2ZWI0MzM3ZWYiLCJDb21wYW55TmFtZSI6Ind3dmUiLCJuYmYiOjE3ODA3MTE3NjQsImV4cCI6MTc4MDc1NDk2NCwiaWF0IjoxNzgwNzExNzY0fQ.a_IXBOFzh13R3m7gZn6UCMzSgO4-PoPA5R-vDzlqKjo",
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── 2. Live camera ─────────────────────────────────────────
                  _ExampleCard(
                    index: 2,
                    title: 'Live Camera',
                    subtitle:
                        'Front camera auto-captures; camera controller is synced before onLiveCaptured',
                    snippet: 'FormFieldsSignaturePad(\n'
                        '  showLiveCamera: true,\n'
                        '  showExportPreview: true,\n'
                        '  exportPreviewSource: SignaturePadPreviewSource.liveCapture,\n'
                        '  onLiveCaptured: (img) { },\n'
                        '  onExportedResult: (r) {\n'
                        '    r.signature    // signature image\n'
                        '    r.liveCapture  // auto-captured selfie\n'
                        '  },\n'
                        ')',
                    result: (viewModel.liveCaptureResult != null ||
                            viewModel.exportResult != null)
                        ? _LiveResultPreview(
                            liveCapture: viewModel.liveCaptureResult,
                            exportResult: viewModel.exportResult,
                          )
                        : null,
                    child: FormFieldsSignaturePad(
                      showLiveCamera: true,
                      showExportPreview: true,
                      exportPreviewSource:
                          SignaturePadPreviewSource.liveCapture,
                      liveCameraController: viewModel.liveCameraController,
                      onLiveCaptured: viewModel.setLiveCapture,
                      onExportedResult: viewModel.setExportResult,
                      backgroundColor: Colors.white,
                      exportBackgroundColor: Colors.transparent,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── 3. Custom layout ───────────────────────────────────────
                  _ExampleCard(
                    index: 3,
                    title: 'Preview Both',
                    subtitle:
                        'Show signature and live capture together after export',
                    snippet: 'FormFieldsSignaturePad(\n'
                        '  showLiveCamera: true,\n'
                        '  showExportPreview: true,\n'
                        '  exportPreviewSource: SignaturePadPreviewSource.both,\n'
                        ')',
                    child: FormFieldsSignaturePad(
                      // showLiveCamera: true,
                      showExportPreview: true,
                      exportPreviewSource: SignaturePadPreviewSource.both,
                      height: 160,
                      backgroundColor: Colors.white,
                      exportBackgroundColor: Colors.transparent,
                      onExportedResult: (_) {},
                      silentLiveCapture: true,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── 4. Custom camera wrapper ───────────────────────────────
                  _ExampleCard(
                    index: 4,
                    title: 'Custom Camera Wrapper',
                    subtitle:
                        'Decorate the camera section with liveCameraBuilder',
                    snippet: 'FormFieldsSignaturePad(\n'
                        '  showLiveCamera: true,\n'
                        '  liveCameraBuilder: (ctx, cam) =>\n'
                        '    Container(\n'
                        '      decoration: BoxDecoration(...),\n'
                        '      child: cam,\n'
                        '    ),\n'
                        ')',
                    child: FormFieldsSignaturePad(
                      showLiveCamera: true,
                      backgroundColor: Colors.white,
                      exportBackgroundColor: Colors.transparent,
                      onExportedResult: (_) {},
                      liveCameraBuilder: (ctx, cam) => Container(
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.deepPurple, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: cam,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── 5. Standalone live camera ─────────────────────────────
                  _ExampleCard(
                    index: 5,
                    title: 'Standalone Live Camera',
                    subtitle:
                        'Use live camera capture without FormFieldsSignaturePad',
                    snippet:
                        'final key = GlobalKey<FormFieldsLiveCameraCaptureState>();\n\n'
                        'FormFieldsLiveCameraCapture(\n'
                        '  cameraController: controller,\n'
                        '  key: key,\n'
                        '  height: 200,\n'
                        '  onCaptured: (img) {\n'
                        '    // controller.images.first sudah berisi img\n'
                        '  },\n'
                        ')\n\n'
                        'await key.currentState?.capture();\n'
                        'key.currentState?.resetCapture();',
                    result: viewModel.standaloneCaptureResult != null
                        ? _StandaloneLiveCapturePreview(
                            result: viewModel.standaloneCaptureResult!,
                          )
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FormFieldsLiveCameraCapture(
                          key: _standaloneCameraKey,
                          height: 200,
                          cameraController:
                              viewModel.standaloneCameraController,
                          // onCaptured: viewModel.setStandaloneCapture,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _standaloneCameraKey.currentState
                                      ?.resetCapture();
                                  viewModel.setStandaloneCapture(null);
                                },
                                icon: const Icon(Icons.restart_alt, size: 18),
                                label: const Text('Reset'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () async {
                                  final result = await _standaloneCameraKey
                                      .currentState
                                      ?.capture();
                                  if (result != null) {
                                    viewModel.setStandaloneCapture(result);
                                  }
                                },
                                icon: const Icon(Icons.camera_alt, size: 18),
                                label: const Text('Capture'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── 6. Controller capture ──────────────────────────────────
                  _ExampleCard(
                    index: 6,
                    title: 'Controller Capture',
                    subtitle:
                        'Trigger capture and reset directly from FormFieldsMyImageController',
                    snippet:
                        'final controller = FormFieldsMyImageController();\n\n'
                        'FormFieldsLiveCameraCapture(\n'
                        '  cameraController: controller,\n'
                        '  onCaptured: (img) { },\n'
                        ')\n\n'
                        '// Capture from controller:\n'
                        'await controller.capture();\n'
                        '// Reset from controller:\n'
                        'controller.resetCapture();',
                    result: viewModel.controllerCaptureResult != null
                        ? _StandaloneLiveCapturePreview(
                            result: viewModel.controllerCaptureResult!,
                          )
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FormFieldsLiveCameraCapture(
                          height: 200,
                          cameraController:
                              viewModel.controllerCaptureController,
                          onCaptured: viewModel.setControllerCapture,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  viewModel.controllerCaptureController
                                      .resetCapture();
                                  viewModel.setControllerCapture(null);
                                },
                                icon: const Icon(Icons.restart_alt, size: 18),
                                label: const Text('Reset'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () async {
                                  final result = await viewModel
                                      .controllerCaptureController
                                      .capture();
                                  if (result != null) {
                                    viewModel.setControllerCapture(result);
                                  }
                                },
                                icon: const Icon(Icons.camera_alt, size: 18),
                                label: const Text('Capture'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── 7. Validation & Label ──────────────────────────────────
                  _ExampleCard(
                    index: 7,
                    title: 'Validation & Label',
                    subtitle:
                        'isRequired, label, labelPosition — integrates with Form.validate()',
                    snippet: 'FormFieldsSignaturePad(\n'
                        '  label: \'Signature\',\n'
                        '  labelPosition: LabelPosition.top,\n'
                        '  isRequired: true,\n'
                        '  autovalidateMode: AutovalidateMode.onUserInteraction,\n'
                        '  onExported: (result) { },\n'
                        ')',
                    child: _SignatureValidationExample(),
                  ),

                  const SizedBox(height: 20),

                  // ── 8. Direct Upload ───────────────────────────────────────
                  _ExampleCard(
                    index: 8,
                    title: 'Direct Upload',
                    subtitle:
                        'Signature is auto-uploaded; callback receives server result and controller already synced',
                    snippet: 'FormFieldsSignaturePad(\n'
                        '  isDirectUpload: true,\n'
                        '  uploadUrl: \'https://catbox.moe/user/api.php\',\n'
                        '  showUploadResultDialog: true,\n'
                        '  showUploadLoading: true,   // overlay while uploading\n'
                        '  showExportPreview: true,\n'
                        '  onExported: (result) {\n'
                        '    result.link     // server URL after upload\n'
                        '    result.imageId  // server ID after upload\n'
                        '    // signaturePadController.exportResult juga sudah update\n'
                        '  },\n'
                        ')',
                    result: viewModel.uploadedSignatureResult != null
                        ? _UploadResultPreview(
                            label: 'Uploaded signature',
                            result: viewModel.uploadedSignatureResult!,
                          )
                        : null,
                    child: FormFieldsSignaturePad(
                      isDirectUpload: true,
                      uploadUrl: 'https://catbox.moe/user/api.php',
                      showUploadResultDialog: true,
                      showUploadLoading: true,
                      showExportPreview: true,
                      exportPreviewSource: SignaturePadPreviewSource.signature,
                      backgroundColor: Colors.white,
                      exportBackgroundColor: Colors.transparent,
                      onExported: (val) {
                        debugPrint(
                            'Exported signature result: link=${val!.link}, imageId=${val.imageId}');
                        viewModel.setUploadedSignature(val);
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── 9. Direct Upload + Live Camera ─────────────────────────
                  _ExampleCard(
                    index: 9,
                    title: 'Direct Upload + Live Camera',
                    subtitle:
                        'Signature & live capture both uploaded; callbacks return server results',
                    snippet: 'FormFieldsSignaturePad(\n'
                        '  isDirectUpload: true,\n'
                        '  uploadUrl: \'https://catbox.moe/user/api.php\',\n'
                        '  showUploadLoading: true,   // overlay on pad + camera\n'
                        '  showLiveCamera: true,\n'
                        '  showExportPreview: true,\n'
                        '  exportPreviewSource: SignaturePadPreviewSource.both,\n'
                        '  onExportedResult: (r) {\n'
                        '    r.signature.link     // uploaded signature URL\n'
                        '    r.liveCapture?.link  // uploaded selfie URL\n'
                        '  },\n'
                        ')',
                    result: viewModel.uploadedExportResult != null
                        ? _LiveResultPreview(
                            exportResult: viewModel.uploadedExportResult,
                          )
                        : null,
                    child: FormFieldsSignaturePad(
                      isDirectUpload: true,
                      uploadUrl: 'https://catbox.moe/user/api.php',
                      showUploadResultDialog: false,
                      showUploadLoading: true,
                      showLiveCamera: true,
                      showExportPreview: true,
                      exportPreviewSource: SignaturePadPreviewSource.both,
                      backgroundColor: Colors.white,
                      exportBackgroundColor: Colors.transparent,
                      onExportedResult: viewModel.setUploadedExportResult,
                      onError: (val) {
                        debugPrint(
                            'Direct upload error: signature upload ${val.signature.link.isEmpty ? 'failed' : 'succeeded'}, live capture upload ${val.liveCapture.link.isEmpty == true ? 'failed' : 'succeeded'}');
                        // viewModel.setUploadError(val);
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── 10. Prefilled Live Camera ────────────────────────────
                  _ExampleCard(
                    index: 10,
                    title: 'Prefilled Live Camera',
                    subtitle:
                        'Seed live camera with initial image using FormFieldsMyImageController.fromImages',
                    snippet:
                        'final prefilledController = FormFieldsMyImageController.fromImages(\n'
                        '  [MyimageResult(link: \'https://picsum.photos/seed/live-prefill/800/600\')],\n'
                        ');\n\n'
                        'FormFieldsSignaturePad(\n'
                        '  showLiveCamera: true,\n'
                        '  liveCameraController: prefilledController,\n'
                        '  showExportPreview: true,\n'
                        '  exportPreviewSource: SignaturePadPreviewSource.both,\n'
                        '  onExportedResult: (r) { ... },\n'
                        ')',
                    result: viewModel.prefilledExportResult != null
                        ? _LiveResultPreview(
                            exportResult: viewModel.prefilledExportResult,
                          )
                        : null,
                    child: FormFieldsSignaturePad(
                      showLiveCamera: true,
                      liveCameraController:
                          viewModel.prefilledLiveCameraController,
                      showExportPreview: true,
                      exportPreviewSource: SignaturePadPreviewSource.both,
                      backgroundColor: Colors.white,
                      exportBackgroundColor: Colors.transparent,
                      onExportedResult: viewModel.setPrefilledExportResult,
                    ),
                  ),

                  // ── 11: Prefilled Signature ───────────────────────────
                  _ExampleCard(
                    index: 11,
                    title: 'Prefilled Signature',
                    subtitle: 'Seed the pad with an existing signature using '
                        'FormFieldsSignaturePadController.fromSignature',
                    snippet: 'final ctrl = FormFieldsSignaturePadController\n'
                        '    .fromSignature(\n'
                        '  MyimageResult.network(\'https://...\'),\n'
                        ');\n\n'
                        'FormFieldsSignaturePad(\n'
                        '  signaturePadController: ctrl,\n'
                        '  showExportPreview: true,\n'
                        '  onExportedResult: (r) { ... },\n'
                        ')',
                    result: viewModel.prefilledSignatureExportResult != null
                        ? _LiveResultPreview(
                            exportResult:
                                viewModel.prefilledSignatureExportResult,
                          )
                        : null,
                    child: FormFieldsSignaturePad(
                      signaturePadController:
                          viewModel.prefilledSignatureController,
                      showExportPreview: true,
                      exportPreviewSource: SignaturePadPreviewSource.signature,
                      backgroundColor: Colors.white,
                      exportBackgroundColor: Colors.transparent,
                      onExportedResult:
                          viewModel.setPrefilledSignatureExportResult,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── 13. Silent Live Capture ────────────────────────────────
                  _ExampleCard(
                    index: 13,
                    title: 'Silent Live Capture',
                    subtitle:
                        'Camera captures silently on draw start — no preview widget shown',
                    snippet: 'FormFieldsSignaturePad(\n'
                        '  silentLiveCapture: true,\n'
                        '  showExportPreview: true,\n'
                        '  onLiveCaptured: (img) {\n'
                        '    // foto kamera depan, tanpa preview di UI\n'
                        '  },\n'
                        '  onExportedResult: (r) {\n'
                        '    r.signature    // signature image\n'
                        '    r.liveCapture  // captured selfie (silent)\n'
                        '  },\n'
                        ')',
                    result: (viewModel.silentCaptureResult != null ||
                            viewModel.silentExportResult != null)
                        ? _LiveResultPreview(
                            liveCapture: viewModel.silentCaptureResult,
                            exportResult: viewModel.silentExportResult,
                          )
                        : null,
                    child: FormFieldsSignaturePad(
                      silentLiveCapture: true,
                      showExportPreview: true,
                      exportPreviewSource: SignaturePadPreviewSource.signature,
                      backgroundColor: Colors.white,
                      exportBackgroundColor: Colors.transparent,
                      onLiveCaptured: viewModel.setSilentCapture,
                      onExportedResult: viewModel.setSilentExportResult,
                    ),
                  ),

                  // ── 12: Prefilled Signature + Live Camera ─────────────────
                  _ExampleCard(
                    index: 12,
                    title: 'Prefilled Signature + Live Camera -',
                    subtitle: 'Seed both signature and live capture using '
                        'FormFieldsSignaturePadController.fromExportResult',
                    snippet: 'final ctrl = FormFieldsSignaturePadController\n'
                        '    .fromExportResult(\n'
                        '  SignaturePadExportResult(\n'
                        '    signature: MyimageResult.network(\'https://...\'),\n'
                        '    liveCapture: MyimageResult.network(\'https://...\'),\n'
                        '  ),\n'
                        ');\n\n'
                        'FormFieldsSignaturePad(\n'
                        '  signaturePadController: ctrl,\n'
                        '  showLiveCamera: true,\n'
                        '  showExportPreview: true,\n'
                        '  exportPreviewSource: SignaturePadPreviewSource.both,\n'
                        ')',
                    result: viewModel.prefilledBothExportResult != null
                        ? _LiveResultPreview(
                            exportResult: viewModel.prefilledBothExportResult,
                          )
                        : null,
                    child: FormFieldsSignaturePad(
                      signaturePadController: viewModel.prefilledBothController,
                      showLiveCamera: true,
                      showExportPreview: true,
                      exportPreviewSource: SignaturePadPreviewSource.both,
                      backgroundColor: Colors.white,
                      exportBackgroundColor: Colors.transparent,
                      onExportedResult: viewModel.setPrefilledBothExportResult,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── 14. Hidden Live Camera (hidePreview) ──────────────────────
                  _ExampleCard(
                    index: 14,
                    title: 'Hidden Live Camera',
                    subtitle:
                        'Camera runs in background (hidePreview: true) — capture anytime, no preview shown',
                    snippet:
                        'final key = GlobalKey<FormFieldsLiveCameraCaptureState>();\n\n'
                        'FormFieldsLiveCameraCapture(\n'
                        '  key: key,\n'
                        '  hidePreview: true,   // invisible, camera still ready\n'
                        '  cameraController: controller,\n'
                        '  onCaptured: (img) { },\n'
                        ')\n\n'
                        'await key.currentState?.capture();\n'
                        'key.currentState?.resetCapture();',
                    result: viewModel.hiddenCaptureResult != null
                        ? _StandaloneLiveCapturePreview(
                            result: viewModel.hiddenCaptureResult!,
                          )
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Widget ini tak terlihat, tapi kamera tetap aktif.
                        FormFieldsLiveCameraCapture(
                          key: _hiddenCameraKey,
                          hidePreview: true,
                          cameraController:
                              viewModel.hiddenLiveCameraController,
                          onCaptured: viewModel.setHiddenCapture,
                        ),
                        Text(
                          'Camera is running in the background (no preview rendered).',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _hiddenCameraKey.currentState?.resetCapture();

                                  viewModel.clearHiddenCapture();
                                },
                                icon: const Icon(Icons.restart_alt, size: 18),
                                label: const Text('Reset'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () async {
                                  final result = await _hiddenCameraKey
                                      .currentState
                                      ?.capture();
                                  // final result = await viewModel
                                  //     .hiddenLiveCameraController
                                  //     .capture();
                                  if (result != null) {
                                    viewModel.setHiddenCapture(result);
                                  }
                                },
                                icon: const Icon(Icons.camera_alt, size: 18),
                                label: const Text('Capture'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Card wrapper ─────────────────────────────────────────────────────────────

class _ExampleCard extends StatefulWidget {
  final int index;
  final String title;
  final String subtitle;
  final String snippet;
  final Widget child;
  final Widget? result;

  const _ExampleCard({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.snippet,
    required this.child,
    this.result,
  });

  @override
  State<_ExampleCard> createState() => _ExampleCardState();
}

class _ExampleCardState extends State<_ExampleCard> {
  bool _showSnippet = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: .12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      Text(widget.subtitle,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                // Code toggle button
                GestureDetector(
                  onTap: () => setState(() => _showSnippet = !_showSnippet),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _showSnippet
                          ? Colors.deepPurple.withValues(alpha: .12)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.code_rounded,
                          size: 14,
                          color: _showSnippet
                              ? Colors.deepPurple
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Code',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _showSnippet
                                ? Colors.deepPurple
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Code snippet (collapsible) ───────────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _showSnippet
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(
                  widget.snippet,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Color(0xFFCDD6F4),
                    height: 1.6,
                  ),
                ),
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),

          // ── Widget ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: widget.child,
            ),
          ),

          // ── Result preview ───────────────────────────────────────────────
          if (widget.result != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: widget.result!,
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Result widgets ───────────────────────────────────────────────────────────

class _SignaturePreview extends StatelessWidget {
  final MyImageResult result;
  const _SignaturePreview({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: .2)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.draw_outlined,
                  size: 14, color: Colors.deepPurple),
              const SizedBox(width: 6),
              Text('Exported signature',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple.shade700)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.memory(
              Uri.parse(result.base64).data!.contentAsBytes(),
              height: 90,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveResultPreview extends StatelessWidget {
  final MyImageResult? liveCapture;
  final SignaturePadExportResult? exportResult;
  const _LiveResultPreview({this.liveCapture, this.exportResult});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: .2)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live capture indicator
          if (liveCapture != null) ...[
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text('Auto-captured on draw start',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: _buildImageFrom(liveCapture!, context,
                  height: 80, fit: BoxFit.cover),
            ),
          ],

          // Export result
          if (exportResult != null) ...[
            if (liveCapture != null) const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.verified_outlined,
                    size: 14, color: Colors.deepPurple),
                const SizedBox(width: 6),
                Text('Export result',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple.shade700)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ResultTile(
                    label: 'signature',
                    child: _buildImageFrom(exportResult!.signature, context,
                        height: 70, fit: BoxFit.contain),
                  ),
                ),
                ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ResultTile(
                      label: 'liveCapture',
                      child: _buildImageFrom(exportResult!.liveCapture, context,
                          height: 70, fit: BoxFit.cover),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final String label;
  final Widget child;
  const _ResultTile({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: child,
        ),
      ],
    );
  }
}

// ── Upload result preview ─────────────────────────────────────────────────────

class _UploadResultPreview extends StatelessWidget {
  final String label;
  final MyImageResult result;
  const _UploadResultPreview({required this.label, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FFF8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.withValues(alpha: .3)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_done_outlined,
                  size: 14, color: Colors.green),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (result.link.isNotEmpty)
            Text(
              'link: ${result.link}',
              style: const TextStyle(fontSize: 10, color: Colors.black54),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (result.imageId.isNotEmpty)
            Text(
              'imageId: ${result.imageId}',
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: (result.path.isNotEmpty && File(result.path).existsSync())
                ? Image.file(File(result.path), height: 80, fit: BoxFit.contain)
                : result.base64.isNotEmpty
                    ? Image.memory(
                        Uri.parse(result.base64).data!.contentAsBytes(),
                        height: 80,
                        fit: BoxFit.contain,
                      )
                    : Image.network(result.link,
                        height: 80, fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }
}

class _StandaloneLiveCapturePreview extends StatelessWidget {
  final MyImageResult result;
  const _StandaloneLiveCapturePreview({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: .2)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_camera_back,
                  size: 14, color: Colors.deepPurple),
              const SizedBox(width: 6),
              Text(
                'Standalone capture result',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: result.path.isNotEmpty
                ? Image.file(
                    File(result.path),
                    height: 100,
                    fit: BoxFit.cover,
                  )
                : Image.memory(
                    Uri.parse(result.base64).data!.contentAsBytes(),
                    height: 100,
                    fit: BoxFit.cover,
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Validation example (self-contained stateful widget) ──────────────────────

class _SignatureValidationExample extends StatefulWidget {
  const _SignatureValidationExample();

  @override
  State<_SignatureValidationExample> createState() =>
      _SignatureValidationExampleState();
}

class _SignatureValidationExampleState
    extends State<_SignatureValidationExample> {
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;
  MyImageResult? _exportedSignature;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Label top + isRequired ───────────────────────────────────────
          FormFieldsSignaturePad(
            label: 'Customer Signature',
            labelPosition: LabelPosition.top,
            isRequired: true,
            autovalidateMode: _submitted
                ? AutovalidateMode.always
                : AutovalidateMode.onUserInteraction,
            backgroundColor: Colors.white,
            exportBackgroundColor: Colors.transparent,
            onExported: (result) => setState(() => _exportedSignature = result),
          ),
          const SizedBox(height: 8),

          // ── Label left + custom validator ────────────────────────────────
          const Divider(height: 28),
          const Text(
            'With custom validator:',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          FormFieldsSignaturePad(
            label: 'Witness',
            labelPosition: LabelPosition.left,
            labelTextStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple),
            validator: (hasSignature) =>
                hasSignature ? null : 'Witness signature is required',
            autovalidateMode: _submitted
                ? AutovalidateMode.always
                : AutovalidateMode.onUserInteraction,
            backgroundColor: Colors.white,
            height: 140,
            onExported: (_) {},
          ),
          const SizedBox(height: 16),

          // ── Submit button ────────────────────────────────────────────────
          FilledButton.icon(
            onPressed: () {
              setState(() => _submitted = true);
              if (_formKey.currentState?.validate() ?? false) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Form submitted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Submit'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),

          // ── Export preview ───────────────────────────────────────────────
          if (_exportedSignature != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8FF),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: Colors.deepPurple.withValues(alpha: .2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.draw_outlined,
                          size: 14, color: Colors.deepPurple),
                      const SizedBox(width: 6),
                      Text(
                        'Exported signature',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      Uri.parse(_exportedSignature!.base64)
                          .data!
                          .contentAsBytes(),
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

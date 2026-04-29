import 'dart:io';

import 'package:flutter/material.dart';
import 'presenter.dart';
import 'view_model.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';

class View extends PresenterState {
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
                    subtitle: 'Export as MyimageResult on tap confirm',
                    snippet: 'FormFieldsSignaturePad(\n'
                        '  onExported: (result) { },\n'
                        ')',
                    result: viewModel.signatureResult != null
                        ? _SignaturePreview(result: viewModel.signatureResult!)
                        : null,
                    child: FormFieldsSignaturePad(
                      onExported: viewModel.setSignature,
                      backgroundColor: Colors.white,
                      exportBackgroundColor: Colors.transparent,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── 2. Live camera ─────────────────────────────────────────
                  _ExampleCard(
                    index: 2,
                    title: 'Live Camera',
                    subtitle:
                        'Front camera auto-captures the moment signing starts',
                    snippet: 'FormFieldsSignaturePad(\n'
                        '  showLiveCamera: true,\n'
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
                    title: 'Custom Layout',
                    subtitle:
                        'Signature pad and camera side-by-side via layoutBuilder',
                    snippet: 'FormFieldsSignaturePad(\n'
                        '  showLiveCamera: true,\n'
                        '  layoutBuilder: (ctx, pad, camera) =>\n'
                        '    Row(children: [\n'
                        '      Expanded(child: pad),\n'
                        '      SizedBox(width: 140, child: camera!),\n'
                        '    ]),\n'
                        ')',
                    child: FormFieldsSignaturePad(
                      showLiveCamera: true,
                      height: 160,
                      backgroundColor: Colors.white,
                      exportBackgroundColor: Colors.transparent,
                      onExportedResult: (_) {},
                      layoutBuilder: (ctx, pad, camera) => Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: pad),
                          if (camera != null) ...[
                            const SizedBox(width: 12),
                            SizedBox(width: 140, child: camera),
                          ],
                        ],
                      ),
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
  final MyimageResult result;
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
  final MyimageResult? liveCapture;
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
              child: liveCapture!.path.isNotEmpty
                  ? Image.file(File(liveCapture!.path),
                      height: 80, fit: BoxFit.cover)
                  : Image.memory(
                      Uri.parse(liveCapture!.base64).data!.contentAsBytes(),
                      height: 80,
                      fit: BoxFit.cover,
                    ),
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
                    child: Image.memory(
                      Uri.parse(exportResult!.signature.base64)
                          .data!
                          .contentAsBytes(),
                      height: 70,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (exportResult!.liveCapture != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ResultTile(
                      label: 'liveCapture',
                      child: exportResult!.liveCapture!.path.isNotEmpty
                          ? Image.file(
                              File(exportResult!.liveCapture!.path),
                              height: 70,
                              fit: BoxFit.cover,
                            )
                          : Image.memory(
                              Uri.parse(exportResult!.liveCapture!.base64)
                                  .data!
                                  .contentAsBytes(),
                              height: 70,
                              fit: BoxFit.cover,
                            ),
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

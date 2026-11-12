import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:form_fields/form_fields.dart';

/// Bottom sheet that asks for a description before an image is added.
///
/// Pops with the trimmed description, or with `null` when cancelled.
class ImageDescriptionSheet extends StatefulWidget {
  final AutovalidateMode autovalidateMode;

  const ImageDescriptionSheet({
    super.key,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });

  @override
  State<ImageDescriptionSheet> createState() => _ImageDescriptionSheetState();
}

class _ImageDescriptionSheetState extends State<ImageDescriptionSheet> {
  late final TextEditingController _descController;
  late final FocusNode _descFocusNode;
  late final FocusNode _rawKeyboardFocusNode;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Set once the sheet has been submitted or cancelled. Several inputs can
  /// close it (Enter, the submit action, the Yes and Cancel buttons), and each
  /// one pops the route. Only the first may do it.
  bool _closed = false;

  void _submit() {
    if (_closed) return;
    if (!(_formKey.currentState?.validate() ?? true)) return;
    if (!context.mounted) return;
    _closed = true;
    Navigator.pop(context, _descController.text.trim());
  }

  void _cancel() {
    if (_closed || !context.mounted) return;
    _closed = true;
    Navigator.pop(context, null);
  }

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController();
    _descFocusNode = FocusNode();
    _rawKeyboardFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Wait a short time for the sheet animation to finish so that
      // the Flutter view is "served" and IME can attach reliably.
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      try {
        FocusScope.of(context).requestFocus(_descFocusNode);
        SystemChannels.textInput.invokeMethod('TextInput.show');
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    _descFocusNode.dispose();
    _rawKeyboardFocusNode.dispose();
    super.dispose();
  }

  /// Raw key handling. Enter always submits. Typing and Backspace are handled
  /// here only when the text field does not have focus. The field itself
  /// handles them while it is focused, so handling them here as well would
  /// type or delete twice.
  void _onRawKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;
    // Enter is safe to handle here too: `_submit` runs once, whichever input
    // reports it first.
    if (key == LogicalKeyboardKey.enter) {
      _submit();
      return;
    }

    if (_descFocusNode.hasFocus) return;

    if (key == LogicalKeyboardKey.backspace) {
      final text = _descController.text;
      final sel = _descController.selection;
      if (sel.start > 0) {
        final newStart = sel.start - 1;
        _descController.text = text.replaceRange(newStart, sel.start, '');
        _descController.selection = TextSelection.collapsed(offset: newStart);
      }
      return;
    }

    final char = event.character;
    if (char != null && char.isNotEmpty) {
      final text = _descController.text;
      final sel = _descController.selection;
      final start = sel.start >= 0 ? sel.start : text.length;
      final end = sel.end >= 0 ? sel.end : text.length;
      _descController.text = text.replaceRange(start, end, char);
      _descController.selection = TextSelection.collapsed(
        offset: start + char.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dl = FormFieldsLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KeyboardListener(
                focusNode: _rawKeyboardFocusNode,
                onKeyEvent: _onRawKey,
                child: TextFormField(
                  controller: _descController,
                  focusNode: _descFocusNode,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: dl.get('description'),
                  ).applyDefaults(Theme.of(context).inputDecorationTheme),
                  autovalidateMode: widget.autovalidateMode,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return dl.getWithLabel('required', dl.get('description'));
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: AppButton(
                        type: AppButtonType.outlined,
                        size: AppSize.medium,
                        useSafeArea: false,
                        text: dl.cancel,
                        onPressed: _cancel,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 12),
                      child: AppButton(
                        type: AppButtonType.filled,
                        size: AppSize.medium,
                        useSafeArea: false,
                        text: dl.yes,
                        onPressed: _submit,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

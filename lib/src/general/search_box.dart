library;

import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';

/// A professional search box that uses `FormField` for form integration
/// and `AppButton` for optional external search action.
class SearchBox extends StatefulWidget {
  final String? initialValue;
  final String? hintText;
  final Widget? icon;
  final bool
      iconInside; // true: inside field as suffixIcon, false: outside as AppButton
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onSearchPressed;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;

  const SearchBox({
    super.key,
    this.initialValue,
    this.hintText,
    this.icon,
    this.iconInside = true,
    this.onChanged,
    this.onSubmitted,
    this.onSearchPressed,
    this.controller,
    this.validator,
  });

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  late final TextEditingController _controller;
  final GlobalKey<FormFieldState<String>> _fieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant SearchBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller &&
        widget.controller != null) {
      _controller.removeListener(_onTextChanged);
      _controller = widget.controller!;
      _controller.addListener(_onTextChanged);
      _fieldKey.currentState?.didChange(_controller.text);
    }
  }

  void _onTextChanged() {
    _fieldKey.currentState?.didChange(_controller.text);
    widget.onChanged?.call(_controller.text);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIcon = widget.icon ?? const Icon(Icons.search);

    return FormField<String>(
      key: _fieldKey,
      initialValue: widget.initialValue ?? _controller.text,
      validator: widget.validator,
      builder: (state) {
        final errorText = state.errorText;
        final input = Expanded(
          child: TextField(
            controller: _controller,
            onSubmitted: widget.onSubmitted,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: widget.hintText ?? 'Search',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              errorText: errorText,
              suffixIcon: widget.iconInside
                  ? IconButton(
                      icon: effectiveIcon,
                      onPressed:
                          widget.onSearchPressed ?? () => _triggerSearch(),
                    )
                  : null,
            ),
          ),
        );

        if (widget.iconInside) {
          return input;
        }

        return Row(
          children: [
            input,
            const SizedBox(width: 8),
            AppButton(
              type: AppButtonType.icon,
              size: AppSize.medium,
              customHeight: kFieldHeightMedium + 12,
              customIconSize: 20,
              customHorizontalPadding: 8,
              icon: effectiveIcon,
              onPressed: widget.onSearchPressed ?? () => _triggerSearch(),
            ),
          ],
        );
      },
    );
  }

  void _triggerSearch() {
    widget.onSearchPressed?.call();
    widget.onSubmitted?.call(_controller.text);
  }
}

part of '../form_fields.dart';

extension _FormFieldsWidgetsX<T> on _FormFieldsState<T> {
  void _handleClearIconTap(FormFieldsController vm) {
    if (widget.readOnly) return;
    if (widget.onRemove != null) {
      widget.onRemove!();
    }
    if (_isIntType()) {
      if (_isNullable()) {
        vm.setController = "";
        widget.onChanged(null as T);
        return;
      }
      vm.setController = _formatNumber(0);
      widget.onChanged(0 as T);
    } else if (_isDoubleType()) {
      if (_isNullable()) {
        vm.setController = "";
        widget.onChanged(null as T);
        return;
      }
      vm.setController = _formatNumber(0.0);
      widget.onChanged(0.0 as T);
    } else if (_isStringType()) {
      vm.setController = "";
      if (_isNullable()) {
        widget.onChanged(null as T);
      } else {
        widget.onChanged("" as T);
      }
    } else if (_isDateTimeType() || _isDateTimeRangeType()) {
      vm.setController = "";
      if (_isNullable()) {
        widget.onChanged(null as T);
      }
    } else {
      vm.setController = "";
      if (_isNullable()) {
        widget.onChanged(null as T);
      }
    }
    // Update extra bottom spacing used to reserve room for validation
    // messages so the field height stays consistent after clearing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final error = _computeMainFieldValidation(
        vm.controller.text,
        vm,
        context,
      );
      final hasText = vm.controller.text.trim().isNotEmpty;
      _effectiveFieldExtraBottom.value =
          (error != null || (hasText && _effectiveFocusNode.hasFocus))
          ? _FormFieldsState._kExtraFieldBottom
          : 0.0;
    });
  }

  void _handleVisibilityToggleTap(FormFieldsController vm) {
    if (widget.readOnly) return;

    vm.obscure = !vm.obscure;
  }

  /// Builds the label widget for the form field
  Widget _buildLabel(FormFieldsController vm) {
    // Don't show label for none or inBorder positions
    if (widget.labelPosition == LabelPosition.none ||
        widget.labelPosition == LabelPosition.inBorder) {
      return const SizedBox.shrink();
    }

    final defaultLabelStyle = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    final theme = Theme.of(context);
    final labelStyle = (widget.labelTextStyle ?? defaultLabelStyle).copyWith(
      color: resolveTextColor(context),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: vm.label.toTitleCases, style: labelStyle),
            if (widget.isRequired)
              TextSpan(
                text: ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Positions the text field with its label based on labelPosition setting
  Widget _buildFieldWithLabel(Widget textField, FormFieldsController vm) {
    // When label is hidden (`LabelPosition.none`) add a small top padding so
    // the field aligns vertically with other controls like `AppButton`
    // which uses a default `topPadding` of 12.
    if (widget.labelPosition == LabelPosition.none) {
      return textField;
    }

    final label = _buildLabel(vm);
    const labelWidth = 120.0;
    const spacing = 12.0;

    switch (widget.labelPosition) {
      case LabelPosition.top:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [label, textField],
        );
      case LabelPosition.bottom:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [textField, label],
        );
      case LabelPosition.left:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: labelWidth, child: label),
            const SizedBox(width: spacing),
            Expanded(child: textField),
          ],
        );
      case LabelPosition.right:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: textField),
            const SizedBox(width: spacing),
            SizedBox(width: labelWidth, child: label),
          ],
        );
      case LabelPosition.inBorder:
      case LabelPosition.none:
        return textField;
    }
  }

  Color _effectiveBorderColor(
    BuildContext context, {
    bool isError = false,
    bool isFocused = false,
  }) {
    final theme = Theme.of(context);
    final normal = theme.dividerColor;
    final focus = theme.colorScheme.primary;
    final error = theme.colorScheme.error;
    return isError ? error : (isFocused ? focus : normal);
  }

  InputBorder _buildBorderFromType(
    BuildContext context,
    BorderType type, {
    double radius = 8.0,
    bool isError = false,
    bool isFocused = false,
  }) {
    final color = _effectiveBorderColor(
      context,
      isError: isError,
      isFocused: isFocused,
    );
    switch (type) {
      case BorderType.none:
        return InputBorder.none;
      case BorderType.underlineInputBorder:
        return UnderlineInputBorder(borderSide: BorderSide(color: color));
      case BorderType.outlineInputBorder:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: color, width: isFocused ? 1.8 : 1.5),
        );
    }
  }
}

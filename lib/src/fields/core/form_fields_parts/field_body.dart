part of '../form_fields.dart';

/// Builds the field content (decoration, input, and validation) for the
/// current [FormFieldsController] value.
extension _FormFieldsFieldBodyX<T> on _FormFieldsState<T> {
  Widget _buildFieldBody(
    BuildContext ctx,
    FormFieldsController vm,
    Widget? child,
    BuildContext context,
  ) {
    // Barcode scan field integration
    if (widget.formType == FormType.scanBarcode) {
      return _buildBarcodeScanField();
    }

    if (_isVerificationType() && widget.verificationAsOtp) {
      final verificationField = _buildVerificationOtpField(vm, context);
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: verificationField,
      );
    }

    final phonePrefixIcon = _isPhoneType() && widget.prefixIcon == null
        ? _buildPhoneCountryCodeDropdown()
        : null;

    final singleLine =
        (vm.formType == FormType.password ||
        _isVerificationType() ||
        widget.multiLine <= 1);

    final baseDecoration =
        widget.inputDecoration ??
        InputDecoration(
          contentPadding: (widget.multiLine > 1)
              ? const EdgeInsets.symmetric(vertical: 22, horizontal: 16)
              : const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          suffix:
              vm.formType == FormType.password ||
                  (_isVerificationType() && widget.verificationHidden)
              ? null
              : widget.suffix,
          suffixIcon:
              vm.formType == FormType.password ||
                  (_isVerificationType() && widget.verificationHidden)
              ? IconButton(
                  splashRadius: 20,
                  iconSize: 20,
                  icon: Icon(
                    vm.obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                  onPressed: widget.readOnly
                      ? null
                      : () => _handleVisibilityToggleTap(vm),
                )
              : (_isDateTimeType() ||
                    _isTimeOfDayType() ||
                    _isDateTimeRangeType())
              ? IconButton(
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  iconSize: 20,
                  splashRadius: 20,
                  icon: Icon(_getPickerIcon()),
                  onPressed: widget.readOnly
                      ? null
                      : () async {
                          if (!mounted) return;
                          final ctx = context;
                          await _showPicker(ctx, vm);
                        },
                )
              : widget.suffixIcon ??
                    IconButton(
                      constraints: const BoxConstraints.tightFor(
                        width: 36,
                        height: 36,
                      ),
                      iconSize: 20,
                      splashRadius: 20,
                      icon: const Icon(Icons.close),
                      onPressed: widget.readOnly
                          ? null
                          : () => _handleClearIconTap(vm),
                    ),
          prefix: widget.prefix,
          prefixIcon: phonePrefixIcon ?? widget.prefixIcon,
          hintText:
              '${_getLocalizations(context).enterPrefix}${vm.label.toTitleCases}',
          labelText: widget.labelPosition == LabelPosition.inBorder
              ? '${_getLocalizations(context).enterPrefix}${vm.label.toTitleCases}${widget.isRequired ? ' *' : ''}'
              : null,
          focusedErrorBorder: _buildBorderFromType(
            ctx,
            widget.borderType,
            radius: widget.radius,
            isError: true,
            isFocused: true,
          ),
          focusedBorder: _buildBorderFromType(
            ctx,
            widget.borderType,
            radius: widget.radius,
            isFocused: true,
          ),
          enabledBorder: _buildBorderFromType(
            ctx,
            widget.borderType,
            radius: widget.radius,
          ),
          border: _buildBorderFromType(
            ctx,
            widget.borderType,
            radius: widget.radius,
          ),
          disabledBorder: _buildBorderFromType(
            ctx,
            widget.borderType,
            radius: widget.radius,
          ),
        );

    final effectiveDecoration = _effectiveInputDecoration(baseDecoration);

    final textField = TextFormField(
      textAlignVertical: singleLine
          ? TextAlignVertical.center
          : TextAlignVertical.top,
      textAlign: TextAlign.start,
      readOnly: widget.readOnly,
      maxLength: _isVerificationType() ? widget.verificationLength : null,
      maxLines:
          vm.formType == FormType.password ||
              _isVerificationType() ||
              widget.multiLine <= 1
          ? 1
          : widget.multiLine,
      obscureText:
          vm.formType == FormType.password ||
              (_isVerificationType() && widget.verificationHidden)
          ? vm.obscure
          : false,
      obscuringCharacter: '•',
      autovalidateMode: widget.autovalidateMode,
      focusNode: _effectiveFocusNode,
      onFieldSubmitted: (_) {
        _commitPendingInput();
        widget.nextFocusNode?.requestFocus();
      },
      keyboardType:
          _isDateTimeType() || _isTimeOfDayType() || _isDateTimeRangeType()
          ? TextInputType.none
          : _isIntType() || _isDoubleType()
          ? TextInputType.number
          : vm.formType == FormType.phone
          ? TextInputType.phone
          : _isVerificationType()
          ? TextInputType.number
          : vm.formType == FormType.email
          ? TextInputType.emailAddress
          : widget.multiLine == 0
          ? TextInputType.text
          : TextInputType.multiline,
      inputFormatters: _getInputFormatters(),
      onChanged: (v) => _onTextInput(v),
      onEditingComplete: () {
        _commitPendingInput();
        // Trim whitespace from input
        vm.controller.text = vm.controller.text.trim();

        // stripSeparators only works for numeric types (int, double)
        if ((_isIntType() || _isDoubleType()) && widget.stripSeparators) {
          final text = vm.controller.text;
          if (text.isEmpty) return;
          final cleaned = _stripSeparatorsForParse(text);
          if (cleaned.isEmpty || cleaned == '-' || cleaned.endsWith('.')) {
            return;
          }

          if (_isIntType()) {
            final parsed = int.tryParse(cleaned);
            if (parsed != null) {
              vm.setController = _formatNumber(parsed);
            }
          } else if (_isDoubleType()) {
            final parsed = double.tryParse(cleaned);
            if (parsed != null) {
              vm.setController = _formatNumber(parsed);
            }
          }
        }
      },
      validator: (value) {
        final error = _computeMainFieldValidation(value, vm, context);
        final hasText =
            (value != null && value.trim().isNotEmpty) ||
            vm.controller.text.trim().isNotEmpty;
        // Avoid updating ValueNotifier synchronously during build
        // which can call markNeedsBuild. Defer update to next frame.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _effectiveFieldExtraBottom.value =
              (error != null || (hasText && _effectiveFocusNode.hasFocus))
              ? _FormFieldsState._kExtraFieldBottom
              : 0.0;
        });
        return error;
      },
      controller: vm.controller,
      onTap: () async {
        if (widget.readOnly) return;
        if (!mounted) return;
        final ctx = context;
        await _showPicker(ctx, vm);
      },
      autofocus: false,
      decoration: effectiveDecoration,
    );

    double fieldHeight;
    switch (widget.fieldSize) {
      case AppSize.small:
        fieldHeight = kFieldHeightSmall;
        break;
      case AppSize.medium:
        fieldHeight = kFieldHeightMedium;
        break;
      case AppSize.large:
        fieldHeight = kFieldHeightLarge;
        break;
      case AppSize.custom:
        fieldHeight = widget.customFieldHeight ?? kFieldHeightDefault;
        break;
    }

    return ValueListenableBuilder<double>(
      valueListenable: _effectiveFieldExtraBottom,
      builder: (ctx2, extra, _) {
        final effectiveExtra = singleLine
            ? _FormFieldsState._kExtraFieldBottom
            : extra;
        final effectiveField = singleLine
            ? SizedBox(height: fieldHeight + effectiveExtra, child: textField)
            : textField;
        return Container(
          margin: widget.labelPosition == LabelPosition.none
              ? EdgeInsets.zero
              : const EdgeInsets.only(bottom: 20),
          child: _buildFieldWithLabel(effectiveField, vm),
        );
      },
    );
  }
}

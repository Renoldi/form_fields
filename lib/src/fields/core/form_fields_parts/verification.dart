part of '../form_fields.dart';

extension _FormFieldsVerificationX<T> on _FormFieldsState<T> {
  /// Resets the countdown and starts ticking. Callers that run after the first
  /// frame must wrap this in `setState` so the new state is rendered.
  void _startOtpCountdown() {
    _otpCountdownTimer?.cancel();
    _otpCountdownRemaining = widget.otpCountdownDuration.inSeconds;
    _otpCountdownFinished = false;
    _otpCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _applyStateChange(() {
        if (_otpCountdownRemaining > 0) {
          _otpCountdownRemaining--;
        }
        _otpCountdownFinished = _otpCountdownRemaining == 0;
      });
      if (_otpCountdownRemaining == 0) {
        timer.cancel();
        if (widget.onOtpCountdownComplete != null) {
          widget.onOtpCountdownComplete!();
        }
      }
    });
  }

  // ============================================================================
  // VERIFICATION (OTP) INPUT HANDLING
  // ============================================================================

  void _initializeVerificationInputs() {
    _disposeVerificationInputs();

    if (!_isVerificationType() || !widget.verificationAsOtp) {
      return;
    }

    _verificationControllers = List.generate(
      widget.verificationLength,
      (_) => TextEditingController(),
    );

    _verificationFocusNodes = List.generate(
      widget.verificationLength,
      (_) => FocusNode(),
    );

    for (int i = 0; i < _verificationFocusNodes.length; i++) {
      final index = i;
      _verificationFocusNodes[index].addListener(() {
        if (_verificationFocusNodes[index].hasFocus) {
          _selectVerificationDigit(index);
        }
      });
    }

    _syncVerificationControllersFromCode(model.controller.text);
  }

  void _disposeVerificationInputs() {
    for (final controller in _verificationControllers) {
      controller.dispose();
    }
    for (final focusNode in _verificationFocusNodes) {
      focusNode.dispose();
    }
    _verificationControllers = [];
    _verificationFocusNodes = [];
  }

  void _syncVerificationControllersFromCode(String code) {
    if (_verificationControllers.isEmpty) return;

    final normalized = code.length > widget.verificationLength
        ? code.substring(0, widget.verificationLength)
        : code;

    for (int i = 0; i < _verificationControllers.length; i++) {
      final char = i < normalized.length ? normalized[i] : '';
      if (_verificationControllers[i].text != char) {
        _verificationControllers[i].text = char;
        _verificationControllers[i].selection = TextSelection.collapsed(
          offset: char.length,
        );
      }
    }
  }

  String _collectVerificationCode() {
    if (_verificationControllers.isEmpty) return model.controller.text;
    return _verificationControllers.map((e) => e.text).join();
  }

  void _selectVerificationDigit(int index) {
    if (index < 0 || index >= _verificationControllers.length) {
      return;
    }

    final controller = _verificationControllers[index];
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  void _focusVerificationDigit(int index, {bool selectAll = true}) {
    if (index < 0 || index >= _verificationFocusNodes.length) {
      return;
    }

    _verificationFocusNodes[index].requestFocus();

    if (!selectAll) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _selectVerificationDigit(index);
    });
  }

  void _emitVerificationValue(FormFieldState<String> state) {
    final code = _collectVerificationCode();

    if (model.controller.text != code) {
      model.setController = code;
    }

    state.didChange(code);
    widget.onChanged(code as T);

    if (code.length == widget.verificationLength) {
      widget.nextFocusNode?.requestFocus();
    }
  }

  void _handleVerificationDigitChanged(
    int index,
    String rawValue,
    FormFieldState<String> state,
  ) {
    final digits = rawValue;

    if (digits.isEmpty) {
      if (_verificationControllers[index].text.isNotEmpty) {
        _verificationControllers[index].clear();
      }

      if (index > 0) {
        _focusVerificationDigit(index - 1);
      }

      _emitVerificationValue(state);
      return;
    }

    if (digits.length > 1) {
      int cursor = index;
      for (
        int i = 0;
        i < digits.length && cursor < widget.verificationLength;
        i++
      ) {
        final char = digits[i];
        _verificationControllers[cursor].text = char;
        _verificationControllers[cursor].selection =
            const TextSelection.collapsed(offset: 1);
        cursor++;
      }

      if (cursor < widget.verificationLength) {
        _focusVerificationDigit(cursor);
      } else {
        _verificationFocusNodes.last.unfocus();
      }

      _emitVerificationValue(state);
      return;
    }

    if (_verificationControllers[index].text != digits) {
      _verificationControllers[index].text = digits;
    }

    _verificationControllers[index].selection = TextSelection.collapsed(
      offset: _verificationControllers[index].text.length,
    );

    if (index < widget.verificationLength - 1) {
      _focusVerificationDigit(index + 1);
    } else {
      _verificationFocusNodes[index].unfocus();
    }

    _emitVerificationValue(state);
  }

  /// Builds the input decoration for OTP boxes with proper error states
  InputDecoration _buildOtpInputDecoration({required bool hasError}) {
    final base = widget.inputDecoration;

    // Default style: no background
    final theme = Theme.of(context);
    final defaultDecoration = InputDecoration(
      filled: false,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: theme.dividerColor, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.6),
      ),
    );

    // For each OTP digit, we want to show underline if focused/has input/error, else border
    // But since InputDecoration is per box, we handle in _buildOtpDigitBox
    return _effectiveInputDecoration(base ?? defaultDecoration).copyWith(
      counterText: '',
      hintText: null,
      labelText: null,
      helperText: null,
      prefix: null,
      prefixIcon: null,
      suffix: null,
      suffixIcon: null,
      filled: base?.filled ?? false,
      fillColor: base?.fillColor ?? defaultDecoration.fillColor,
      contentPadding: base?.contentPadding ?? defaultDecoration.contentPadding,
    );
  }

  /// Builds a single OTP digit input box
  Widget _buildOtpDigitBox({
    required int index,
    required InputDecoration decoration,
    required FormFieldState<String> state,
    required FormFieldsController vm,
  }) {
    final isLastDigit = index == widget.verificationLength - 1;
    final isFocused = _verificationFocusNodes[index].hasFocus;
    final hasError = state.hasError;

    // Border style sesuai otpBorderType
    final color = _effectiveBorderColor(
      context,
      isError: hasError,
      isFocused: isFocused,
    );

    // Draw the border with a parent Container instead of relying on the
    // TextField's InputBorder. This avoids stroke clipping caused by the
    // TextField internals or parent layout clipping on some devices.
    final double borderWidth = hasError ? 2 : (isFocused ? 2 : 1.2);
    final borderRadius = BorderRadius.circular(widget.radius);

    return SizedBox(
      width: widget.otpBoxWidth,
      height: widget.otpBoxWidth,
      child: Container(
        decoration: BoxDecoration(
          color: decoration.fillColor ?? Colors.transparent,
          borderRadius: borderRadius,
          border: Border.all(color: color, width: borderWidth),
        ),
        padding: EdgeInsets.zero,
        child: Center(
          child: TextField(
            controller: _verificationControllers[index],
            focusNode: _verificationFocusNodes[index],
            readOnly: widget.readOnly,
            keyboardType: widget.verificationOtpAlphanumeric
                ? TextInputType.visiblePassword
                : TextInputType.number,
            obscureText: widget.verificationHidden && vm.obscure,
            obscuringCharacter: '•',
            textInputAction: isLastDigit
                ? TextInputAction.done
                : TextInputAction.next,
            textAlign: TextAlign.center,
            style:
                widget.otpTextStyle ??
                const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            inputFormatters:
                widget.otpInputFormatters ??
                (widget.verificationOtpAlphanumeric
                    ? [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9]'),
                        ),
                        LengthLimitingTextInputFormatter(
                          widget.verificationLength,
                        ),
                      ]
                    : [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(
                          widget.verificationLength,
                        ),
                      ]),
            onTap: () => _selectVerificationDigit(index),
            onChanged: (value) =>
                _handleVerificationDigitChanged(index, value, state),
            decoration: decoration.copyWith(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the OTP verification field with multiple digit boxes
  Widget _buildVerificationOtpField(
    FormFieldsController vm,
    BuildContext context,
  ) {
    return FormField<String>(
      initialValue: model.controller.text,
      autovalidateMode: widget.autovalidateMode,
      validator: (value) => _validateRequired(
        value as T?,
        widget.label.toTitleCases,
        widget.isRequired,
        vm,
        context,
      ),
      builder: (state) {
        final hasError = state.hasError;
        final boxDecoration = _buildOtpInputDecoration(hasError: hasError);

        // Add small horizontal padding so outline borders of the first
        // and last OTP boxes are not clipped by parent layouts or pixel
        // rounding when rendered at the screen edge.
        final otpBoxes = Padding(
          // Increase horizontal + vertical padding so the outline stroke of the
          // first/last boxes isn't clipped by parent bounds or pixel
          // rounding on different devices.
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: widget.otpBoxSpacing,
              runSpacing: widget.otpBoxSpacing,
              children: [
                for (var i = 0; i < widget.verificationLength; i++)
                  _buildOtpDigitBox(
                    index: i,
                    decoration: boxDecoration,
                    state: state,
                    vm: vm,
                  ),
                if (widget.verificationHidden)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      splashRadius: 18,
                      iconSize: 18,
                      icon: Icon(
                        vm.obscure
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                      onPressed: widget.readOnly
                          ? null
                          : () => _handleVisibilityToggleTap(vm),
                    ),
                  ),
              ],
            ),
          ),
        );

        final countdown = widget.isOtpCountdown
            ? Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!_otpCountdownFinished)
                      Text(
                        (widget.otpCountdownTextBuilder ??
                            FormFields._defaultOtpCountdownTextBuilder)(
                          context,
                          _otpCountdownRemaining,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: resolveActiveColor(context, null),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: FormFields.defaultOtpResendText(
                          context: context,
                          onResend: _otpCountdownFinished
                              ? () {
                                  _applyStateChange(_startOtpCountdown);
                                  if (widget.onOtpCountdownReload != null) {
                                    widget.onOtpCountdownReload!();
                                  }
                                }
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink();

        final List<Widget>? errorWidgets = hasError && state.errorText != null
            ? [
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    state.errorText!,
                    style: TextStyle(
                      color: _effectiveBorderColor(context, isError: true),
                      fontSize: 12,
                    ),
                  ),
                ),
              ]
            : null;

        // Gabungkan semua bagian utama OTP
        final otpContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [otpBoxes, ...?errorWidgets, countdown],
        );

        // Gunakan _buildFieldWithLabel agar label mengikuti labelPosition
        return _buildFieldWithLabel(otpContent, vm);
      },
    );
  }
}

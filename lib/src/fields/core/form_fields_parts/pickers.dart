part of '../form_fields.dart';

extension _FormFieldsPickersX<T> on _FormFieldsState<T> {
  // ============================================================================
  // DATE/TIME PICKERS
  // ============================================================================

  Future<void> _handleDatePicker(
    BuildContext ctx,
    FormFieldsController vm,
  ) async {
    final now = DateTime.now();
    final first = widget.firstDate ?? now.subtract(vm.d100YEARS);
    final last = widget.lastDate ?? now;
    final locale = _parseLocale(ctx);

    final date = await showDatePicker(
      context: ctx,
      initialDate: now.isAfter(last)
          ? last
          : (now.isBefore(first) ? first : now),
      firstDate: first,
      lastDate: last,
      locale: locale,
    );

    if (date != null && mounted) {
      vm.setController = widget.customFormat != null
          ? DateFormat(widget.customFormat).format(date)
          : DateFormat.yMMMd().format(date);
      widget.onChanged(date as T);
    }
  }

  Future<void> _handleTimePicker(
    BuildContext ctx,
    FormFieldsController vm,
  ) async {
    final locale = _parseLocale(ctx);

    final time = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay.now(),
      builder: locale == null
          ? null
          : (context, child) => Localizations.override(
              context: context,
              locale: locale,
              child: child!,
            ),
    );

    if (time != null && mounted) {
      final now = DateTime.now();
      final dateTime = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
      vm.setController = widget.customFormat != null
          ? DateFormat(widget.customFormat).format(dateTime)
          : DateFormat.jm().format(dateTime);
      widget.onChanged(dateTime as T);
    }
  }

  Future<void> _handleTimeOfDayPicker(
    BuildContext ctx,
    FormFieldsController vm,
  ) async {
    final locale = _parseLocale(ctx);

    final time = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay.now(),
      builder: locale == null
          ? null
          : (context, child) => Localizations.override(
              context: context,
              locale: locale,
              child: child!,
            ),
    );

    if (time != null && mounted) {
      vm.setController = _formatTimeOfDay(time);
      widget.onChanged(time as T);
    }
  }

  Future<void> _handleDateTimePicker(
    BuildContext ctx,
    FormFieldsController vm,
  ) async {
    final now = DateTime.now();
    final first = widget.firstDate ?? now.subtract(vm.d100YEARS);
    final last = widget.lastDate ?? now;
    final locale = _parseLocale(ctx);

    final date = await showDatePicker(
      context: ctx,
      initialDate: now.isAfter(last)
          ? last
          : (now.isBefore(first) ? first : now),
      firstDate: first,
      lastDate: last,
      locale: locale,
    );

    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: ctx,
        initialTime: TimeOfDay.now(),
        builder: locale == null
            ? null
            : (context, child) => Localizations.override(
                context: context,
                locale: locale,
                child: child!,
              ),
      );

      if (time != null && mounted) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        vm.setController = widget.customFormat != null
            ? DateFormat(widget.customFormat).format(dateTime)
            : DateFormat.yMMMd().add_jm().format(dateTime);
        widget.onChanged(dateTime as T);
      }
    }
  }

  Future<void> _handleDateRangePicker(
    BuildContext ctx,
    FormFieldsController vm,
  ) async {
    if (!mounted) return;
    final now = DateTime.now();
    final first = widget.firstDate ?? now.subtract(vm.d100YEARS);
    final last = widget.lastDate ?? now;
    final locale = _parseLocale(ctx);

    // Calculate smart initial date range
    DateTime initialStart;
    DateTime initialEnd;

    if (widget.currentValue != null) {
      // Use current value if available. It can fall outside the picker bounds
      // when the bounds changed after it was set, and the picker asserts that
      // the initial range lies inside them. Clamp it.
      final currentRange = widget.currentValue as DateTimeRange;
      DateTime clampToBounds(DateTime d) =>
          d.isBefore(first) ? first : (d.isAfter(last) ? last : d);
      initialStart = clampToBounds(currentRange.start);
      initialEnd = clampToBounds(currentRange.end);
      if (initialEnd.isBefore(initialStart)) initialEnd = initialStart;
    } else {
      // Create default 7-day range respecting constraints
      initialStart = now.isAfter(last)
          ? last.subtract(const Duration(days: 7))
          : (now.isBefore(first) ? first : now);
      initialEnd = initialStart.add(const Duration(days: 7));

      // Ensure end date doesn't exceed lastDate
      if (initialEnd.isAfter(last)) {
        initialEnd = last;
      }

      // Ensure start date is not before firstDate
      if (initialStart.isBefore(first)) {
        initialStart = first;
      }
    }

    if (widget.useDatePickerForRange) {
      if (!mounted) return; // Guard before first async operation
      final startDate = await showDatePicker(
        // ignore: use_build_context_synchronously
        context: ctx,
        initialDate: initialStart,
        firstDate: first,
        lastDate: last,
        locale: locale,
      );

      if (startDate == null) {
        return;
      }

      final normalizedInitialEnd = initialEnd.isBefore(startDate)
          ? startDate
          : (initialEnd.isAfter(last) ? last : initialEnd);

      if (!mounted) return; // Guard before second async operation
      final endDate = await showDatePicker(
        // ignore: use_build_context_synchronously
        context: ctx,
        initialDate: normalizedInitialEnd,
        firstDate: startDate,
        lastDate: last,
        locale: locale,
      );

      if (endDate != null && mounted) {
        final dateRange = DateTimeRange(start: startDate, end: endDate);
        vm.setController = _formatDateRange(dateRange);
        widget.onChanged(dateRange as T);
      }
      return;
    }

    if (!mounted) return; // Guard before third async operation
    final dateRange = await showDateRangePicker(
      // ignore: use_build_context_synchronously
      context: ctx,
      firstDate: first,
      lastDate: last,
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      locale: locale,
      builder: (dialogContext, child) {
        final parentTheme = Theme.of(dialogContext);
        // Use widget.saveButtonColor if provided, otherwise fall back to
        // the dialog's primary color. Allow overriding the text color via
        // `saveButtonTextColor` so callers can set e.g. red text.
        final resolvedSaveColor =
            widget.saveButtonColor ?? parentTheme.colorScheme.primary;

        final resolvedTextColor =
            widget.saveButtonTextColor ?? parentTheme.colorScheme.onPrimary;

        // Create an explicit ButtonStyle to ensure colors, shape and padding
        // match the datepicker's confirm button while preserving any
        // dialog-level customizations the app may provide.
        final backgroundColor = resolvedSaveColor;
        final foregroundColor = resolvedTextColor;

        // Start from the dialog's existing TextButton style so we inherit
        // padding/shape defined by the app theme, then override colors.
        final baseTextButtonStyle =
            parentTheme.textButtonTheme.style ?? const ButtonStyle();

        final buttonStyle = baseTextButtonStyle.copyWith(
          backgroundColor: WidgetStatePropertyAll(backgroundColor),
          foregroundColor: WidgetStatePropertyAll(foregroundColor),
          textStyle: WidgetStatePropertyAll(TextStyle(color: foregroundColor)),
          overlayColor: WidgetStatePropertyAll(
            foregroundColor.withValues(alpha: 0.08),
          ),
          padding: WidgetStatePropertyAll(
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );

        final customTheme = parentTheme.copyWith(
          colorScheme: parentTheme.colorScheme.copyWith(
            primary: resolvedSaveColor,
            onPrimary: resolvedTextColor,
          ),
          textButtonTheme: TextButtonThemeData(style: buttonStyle),
        );

        return Theme(
          data: customTheme,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (dateRange != null && mounted) {
      vm.setController = _formatDateRange(dateRange);
      widget.onChanged(dateRange as T);
    }
  }

  Future<void> _showPicker(BuildContext ctx, FormFieldsController vm) async {
    if (widget.readOnly) return;

    if (_isDateTimeType()) {
      switch (widget.formType) {
        case FormType.date:
          await _handleDatePicker(ctx, vm);
          break;
        case FormType.time:
          await _handleTimePicker(ctx, vm);
          break;
        case FormType.dateTime:
          await _handleDateTimePicker(ctx, vm);
          break;
        default:
          await _handleDatePicker(ctx, vm);
          break;
      }
    } else if (_isTimeOfDayType()) {
      await _handleTimeOfDayPicker(ctx, vm);
    } else if (_isDateTimeRangeType()) {
      await _handleDateRangePicker(ctx, vm);
    }
  }

  // ============================================================================
  // ICON HANDLING
  // ============================================================================

  IconData _getPickerIcon() {
    if (_isDateTimeRangeType()) {
      return Icons.date_range;
    }

    switch (widget.formType) {
      case FormType.time:
        return Icons.access_time;
      case FormType.dateTime:
        return Icons.calendar_today;
      case FormType.date:
      default:
        return Icons.calendar_today;
    }
  }
}

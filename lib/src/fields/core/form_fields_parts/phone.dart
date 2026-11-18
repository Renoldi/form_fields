part of '../form_fields.dart';

extension _FormFieldsPhoneX<T> on _FormFieldsState<T> {
  // ============================================================================
  // PHONE INPUT HANDLING
  // ============================================================================

  List<String> _effectivePhoneCountryCodes() {
    return widget.phoneCountryCodes.isNotEmpty
        ? widget.phoneCountryCodes
        : const ['+62'];
  }

  void _initializePhoneCountryCode(String? value) {
    final candidates = _effectivePhoneCountryCodes();

    if (widget.initialCountryCode != null &&
        candidates.contains(widget.initialCountryCode)) {
      _selectedCountryCode = widget.initialCountryCode!;
      return;
    }

    if (value != null && value.startsWith('+')) {
      final prefix = value.split('-').first;
      if (candidates.contains(prefix)) {
        _selectedCountryCode = prefix;
        return;
      }
    }

    // Default to Indonesia (+62) if available, otherwise use first code
    _selectedCountryCode = candidates.contains('+62')
        ? '+62'
        : candidates.first;
  }

  String _stripPhoneToDigits(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _extractLocalPhoneDigits(String value) {
    final digits = _stripPhoneToDigits(value);
    final codeDigits = _stripPhoneToDigits(_selectedCountryCode);

    if (codeDigits.isNotEmpty && digits.startsWith(codeDigits)) {
      return digits.substring(codeDigits.length);
    }

    return digits;
  }

  String _formatPhoneWithCode(String value) {
    final localDigits = _extractLocalPhoneDigits(value);
    final code = _selectedCountryCode.isNotEmpty ? _selectedCountryCode : '+62';

    if (localDigits.isEmpty) {
      return code;
    }

    final first = localDigits.substring(0, localDigits.length.clamp(0, 3));
    final remaining = localDigits.length > 3 ? localDigits.substring(3) : '';
    final second = remaining.substring(0, remaining.length.clamp(0, 4));
    final tail = remaining.length > 4 ? remaining.substring(4) : '';
    final third = tail.substring(0, tail.length.clamp(0, 4));

    final parts = <String>[];
    if (first.isNotEmpty) parts.add(first);
    if (second.isNotEmpty) parts.add(second);
    if (third.isNotEmpty) parts.add(third);

    return parts.isEmpty ? code : '$code-${parts.join('-')}';
  }

  String _formatPhoneLocalOnly(String value) {
    // Format only local digits without country code (for display in text field)
    final localDigits = _extractLocalPhoneDigits(value);

    if (localDigits.isEmpty) {
      return '';
    }

    final first = localDigits.substring(0, localDigits.length.clamp(0, 3));
    final remaining = localDigits.length > 3 ? localDigits.substring(3) : '';
    final second = remaining.substring(0, remaining.length.clamp(0, 4));
    final tail = remaining.length > 4 ? remaining.substring(4) : '';
    final third = tail.substring(0, tail.length.clamp(0, 4));

    final parts = <String>[];
    if (first.isNotEmpty) parts.add(first);
    if (second.isNotEmpty) parts.add(second);
    if (third.isNotEmpty) parts.add(third);

    return parts.join('-');
  }

  String _getPhoneWithoutFormatting(String value) {
    // Remove all dashes and return only country code + digits
    // Input: +62-812-3456-7890
    // Output: +628123456789
    return value.replaceAll('-', '');
  }

  Widget _buildPhoneCountryCodeDropdown() {
    final codes = _effectivePhoneCountryCodes();
    final selected = codes.contains(_selectedCountryCode)
        ? _selectedCountryCode
        : codes.first;

    if (_selectedCountryCode != selected) {
      _selectedCountryCode = selected;
    }

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.only(left: 4, right: 4),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          style: TextStyle(fontSize: 14, color: resolveTextColor(context)),
          onChanged: widget.readOnly
              ? null
              : (value) {
                  if (value == null) return;
                  _selectedCountryCode = value;
                  _notifier.setSelectedCountryCode(value);
                  // Update text field to show only local digits
                  final localFormatted = widget.formatPhone
                      ? _formatPhoneLocalOnly(model.controller.text)
                      : _extractLocalPhoneDigits(model.controller.text);
                  if (model.controller.text != localFormatted) {
                    model.setController = localFormatted;
                  }
                },
          items: codes
              .map(
                (code) => DropdownMenuItem<String>(
                  value: code,
                  child: Text(code, style: const TextStyle(fontSize: 14)),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

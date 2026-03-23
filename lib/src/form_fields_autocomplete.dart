import 'package:flutter/material.dart';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'utilities/enums.dart';

/// FormFieldsAutocomplete supports:
/// - Custom query param and token header
/// - Custom InputDecoration (see #sym:InputDecoration)
/// - Custom result processing (resultProcessor)
/// - Use with FormFields and LabelPosition, BorderType (see #sym:LabelPosition, #sym:BorderType)
class FormFieldsAutocomplete extends StatelessWidget {
  static final Logger _logger = Logger();
  final String label;
  final String url;
  final String? token;
  final void Function(String) onSelected;
  final InputDecoration? decoration;
  final String queryParam;
  final String tokenHeader;
  final List<String> Function(dynamic data)? resultProcessor;
  final LabelPosition labelPosition;
  final BorderType borderType;
  final Widget? suffixIcon;
  final bool removeSuffixIcon;

  const FormFieldsAutocomplete({
    super.key,
    required this.label,
    required this.url,
    this.token,
    required this.onSelected,
    this.decoration,
    this.queryParam = 'q',
    this.tokenHeader = 'Authorization',
    this.resultProcessor,
    this.labelPosition = LabelPosition.none,
    this.borderType = BorderType.outlineInputBorder,
    this.suffixIcon,
    this.removeSuffixIcon = false,
  });

  /// Fetches options from the URL using Dio, with custom query param, token header, and result processing.
  Future<List<String>> _fetchOptions(String query) async {
    if (query.isEmpty) return [];
    try {
      final dio = Dio();
      if (token != null && tokenHeader.isNotEmpty) {
        dio.options.headers[tokenHeader] =
            tokenHeader == 'Authorization' ? 'Bearer $token' : token;
      }
      _logger.i('Fetching options from: $url with query: $query');
      final response = await dio.get(url, queryParameters: {queryParam: query});
      final data = response.data;
      _logger.d('Response data: $data');
      if (resultProcessor != null) {
        return resultProcessor!(data);
      }
      if (data is List) {
        return data.map((e) => e.toString()).toList();
      } else if (data is Map && data['results'] is List) {
        return (data['results'] as List).map((e) => e.toString()).toList();
      }
      return [];
    } catch (e, stack) {
      _logger.e('FormFieldsAutocomplete fetch error',
          error: e, stackTrace: stack);
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget field = Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        return await _fetchOptions(textEditingValue.text);
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        InputBorder border;
        switch (borderType) {
          case BorderType.underlineInputBorder:
            border = const UnderlineInputBorder();
            break;
          case BorderType.none:
            border = InputBorder.none;
            break;
          case BorderType.outlineInputBorder:
            border = OutlineInputBorder(borderRadius: BorderRadius.circular(8));
            break;
        }
        final baseDecoration =
            (decoration ?? InputDecoration(hintText: label)).copyWith(
          border: border,
        );
        InputDecoration effectiveDecoration;
        if (removeSuffixIcon) {
          effectiveDecoration = baseDecoration.copyWith(
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                controller.clear();
                onSelected("");
              },
            ),
          );
        } else {
          effectiveDecoration = baseDecoration.copyWith(
            suffixIcon: suffixIcon,
          );
        }
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: effectiveDecoration,
        );
      },
    );

    // Optionally wrap with label based on labelPosition
    switch (labelPosition) {
      case LabelPosition.top:
        field = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            field,
          ],
        );
        break;
      case LabelPosition.bottom:
        field = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            field,
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        );
        break;
      case LabelPosition.left:
        field = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Expanded(child: field),
          ],
        );
        break;
      case LabelPosition.right:
        field = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: field),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        );
        break;
      case LabelPosition.inBorder:
        // Let InputDecoration handle floating label
        break;
      case LabelPosition.none:
        // No label
        break;
    }
    return field;
  }
}
